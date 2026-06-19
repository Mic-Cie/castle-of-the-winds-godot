class_name GameWorld
extends RefCounted

signal entity_moved(entity_id: int, old_position: Vector2i, new_position: Vector2i)
signal entity_added(entity: Entity)
signal visibility_changed(player_id: int, uncovered_positions: Array[Vector2i])
signal door_changed(pos: Vector2i)
signal stats_changed(entity_id: int, stat_name: StringName)
signal time_changed(game_time: int)
signal tick_completed()
signal player_message(entity_id: int, message: String)

var game_map: GameMap
var entities: Dictionary = {}
var game_time: int = 0
var game_mode: int = GameMode.Mode.SINGLE_PLAYER

var _next_entity_id: int = 1
var _entity_activities: Dictionary = {}


func _init(p_game_map: GameMap, p_game_mode: int = GameConstants.DEFAULT_GAME_MODE) -> void:
	game_map = p_game_map
	game_mode = p_game_mode


func add_player(player_id: int, spawn_position: Vector2i) -> Player:
	var player := Player.new(_next_entity_id, player_id, spawn_position)
	_next_entity_id += 1
	player.vision = PlayerVision.new(game_map.width, game_map.height)

	var uncovered: Array[Vector2i] = []
	uncovered.append_array(player.vision.apply_default_from_map(game_map))
	uncovered.append_array(player.vision.reveal_on_step(game_map, spawn_position))

	_register_entity(player)
	entity_added.emit(player)
	if not uncovered.is_empty():
		visibility_changed.emit(player.player_id, uncovered)
	return player


func get_entity(entity_id: int) -> Entity:
	return entities.get(entity_id)


func post_player_message(entity_id: int, message: String) -> void:
	if get_entity(entity_id) == null:
		return
	player_message.emit(entity_id, message)


func examine_tile(entity_id: int, pos: Vector2i) -> String:
	var entity := get_entity(entity_id)
	if entity == null or not entity is Player:
		return MessageTemplates.EXAMINE_UNSEEN_LOCATION
	var player := entity as Player
	return Examine.examine(game_map, player.vision, player.grid_position, pos)


func can_accept_command(entity_id: int) -> bool:
	var activity := _get_activity(entity_id)
	if activity.has_pending_search():
		return true
	return not activity.is_busy(game_time)


func process_command(command: GameCommand) -> bool:
	var entity_id := command.get_entity_id()
	if entity_id < 0 or get_entity(entity_id) == null:
		return false

	var activity := _get_activity(entity_id)
	if activity.has_pending_search():
		_cancel_pending(entity_id)
	elif activity.is_busy(game_time):
		return false

	var success := command.execute(self)
	if success:
		_after_player_action()
	return success


func process_move_command(command: MoveCommand) -> bool:
	if not try_move_entity(command.entity_id, command.direction):
		return false

	var entity := get_entity(command.entity_id)
	var time_cost := entity.stats.get_step_time_cost(GameConstants.STEP_TIME_COST)
	var activity := _get_activity(command.entity_id)
	if game_mode == GameMode.Mode.SINGLE_PLAYER:
		_advance_time(time_cost)
	else:
		activity.busy_until = game_time + time_cost
	return true


func process_search_command(command: SearchCommand) -> bool:
	var entity := get_entity(command.entity_id)
	if entity == null:
		return false

	var time_cost := entity.stats.get_time_cost(GameConstants.SEARCH_TIME_COST)
	if game_mode == GameMode.Mode.SINGLE_PLAYER:
		_advance_time(time_cost)
		try_search(command.entity_id)
		return true

	var activity := _get_activity(command.entity_id)
	activity.pending_search = true
	activity.pending_completion_time = game_time + time_cost
	return true


func tick() -> void:
	if game_mode != GameMode.Mode.MULTI_PLAYER:
		return

	game_time += 1
	_resolve_pending_actions()
	time_changed.emit(game_time)
	tick_completed.emit()


func try_move_entity(entity_id: int, direction: Vector2i) -> bool:
	var entity := get_entity(entity_id)
	if entity == null:
		return false

	var target := entity.grid_position + direction
	if not game_map.can_step_onto(target):
		return false
	if _is_occupied_by_other(entity_id, target):
		return false

	var old_position := entity.grid_position
	entity.grid_position = target
	if game_map.is_closed_door(target):
		game_map.set_door_state(target, DoorState.State.OPEN)
		door_changed.emit(target)
	entity_moved.emit(entity_id, old_position, target)

	if entity is Player:
		var player := entity as Player
		var uncovered := player.vision.reveal_on_step(game_map, target)
		if not uncovered.is_empty():
			visibility_changed.emit(player.player_id, uncovered)

	return true


func try_search(entity_id: int) -> bool:
	var entity := get_entity(entity_id)
	if entity == null:
		return false

	var revealed := false
	for offset in PlayerVision.ADJACENT_OFFSETS:
		var pos := entity.grid_position + offset
		if game_map.get_door_state(pos) != DoorState.State.HIDDEN:
			continue
		game_map.set_door_state(pos, DoorState.State.CLOSED)
		door_changed.emit(pos)
		revealed = true

	if revealed:
		player_message.emit(entity_id, MessageTemplates.SECRET_DOOR_FOUND)
	return revealed


func try_toggle_door(pos: Vector2i, entity_id: int) -> bool:
	var entity := get_entity(entity_id)
	if entity == null:
		return false

	var activity := _get_activity(entity_id)
	if activity.has_pending_search():
		_cancel_pending(entity_id)
	elif activity.is_busy(game_time):
		return false

	var state := game_map.get_door_state(pos)
	if state != DoorState.State.CLOSED and state != DoorState.State.OPEN:
		return false
	if not GridPosition.is_adjacent(entity.grid_position, pos):
		return false

	var new_state := DoorState.State.OPEN if state == DoorState.State.CLOSED else DoorState.State.CLOSED
	game_map.set_door_state(pos, new_state)
	door_changed.emit(pos)
	return true


func _register_entity(entity: Entity) -> void:
	entities[entity.entity_id] = entity
	_entity_activities[entity.entity_id] = EntityActivity.new()
	entity.stats.recalculate_max_health()
	entity.stats.recalculate_max_mana()
	entity.stats.recalculate_carry_weight()
	entity.stats.recalculate_movement_speed()
	_track_entity_stats(entity)


func _track_entity_stats(entity: Entity) -> void:
	entity.stats.changed.connect(
		func(stat_name: StringName) -> void: stats_changed.emit(entity.entity_id, stat_name)
	)


func _get_activity(entity_id: int) -> EntityActivity:
	return _entity_activities[entity_id]


func _cancel_pending(entity_id: int) -> void:
	_get_activity(entity_id).clear_pending()


func _advance_time(seconds: int) -> void:
	game_time += seconds
	time_changed.emit(game_time)


func _resolve_pending_actions() -> void:
	for entity_id in _entity_activities:
		var activity: EntityActivity = _entity_activities[entity_id]
		if not activity.pending_search:
			continue
		if game_time < activity.pending_completion_time:
			continue
		activity.clear_pending()
		try_search(entity_id)


func _after_player_action() -> void:
	pass


func _is_occupied_by_other(entity_id: int, position: Vector2i) -> bool:
	for other_id in entities:
		if other_id == entity_id:
			continue
		var other: Entity = entities[other_id]
		if other.grid_position == position:
			return true
	return false
