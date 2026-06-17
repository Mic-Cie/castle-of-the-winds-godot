class_name GameWorld
extends RefCounted

signal entity_moved(entity_id: int, old_position: Vector2i, new_position: Vector2i)
signal entity_added(entity: Entity)
signal visibility_changed(player_id: int, uncovered_positions: Array[Vector2i])
signal door_changed(pos: Vector2i)
signal stats_changed(entity_id: int, stat_name: StringName)

var game_map: GameMap
var entities: Dictionary = {}
var _next_entity_id: int = 1


func _init(p_game_map: GameMap) -> void:
	game_map = p_game_map


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


func process_command(command: GameCommand) -> bool:
	return command.execute(self)


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

	return revealed


func try_toggle_door(pos: Vector2i, entity_id: int) -> bool:
	var entity := get_entity(entity_id)
	if entity == null:
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
	entity.stats.recalculate_max_health()
	entity.stats.hp.current = maxi(entity.stats.hp.max_value, 0)
	_track_entity_stats(entity)


func _track_entity_stats(entity: Entity) -> void:
	entity.stats.changed.connect(
		func(stat_name: StringName) -> void: stats_changed.emit(entity.entity_id, stat_name)
	)


func _is_occupied_by_other(entity_id: int, position: Vector2i) -> bool:
	for other_id in entities:
		if other_id == entity_id:
			continue
		var other: Entity = entities[other_id]
		if other.grid_position == position:
			return true
	return false
