class_name GameWorld
extends RefCounted

const _Monster = preload("res://scripts/entities/monster.gd")
const _MonsterAI = preload("res://scripts/ai/monster_ai.gd")
const _Kobold = preload("res://scripts/entities/kobold.gd")

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
var difficulty: int = GameConstants.DEFAULT_DIFFICULTY

var _next_entity_id: int = 1
var _entity_activities: Dictionary = {}


func _init(
	p_game_map: GameMap,
	p_game_mode: int = GameConstants.DEFAULT_GAME_MODE,
	p_difficulty: int = GameConstants.DEFAULT_DIFFICULTY,
) -> void:
	game_map = p_game_map
	game_mode = p_game_mode
	difficulty = p_difficulty


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


func create_kobold(spawn_position: Vector2i, asleep: bool = true) -> _Monster:
	var kobold: _Monster = _Kobold.new(_next_entity_id, spawn_position)
	_next_entity_id += 1
	kobold.is_asleep = asleep
	return kobold


func add_monster(monster: _Monster) -> _Monster:
	_register_entity(monster)
	entity_added.emit(monster)
	return monster


func get_primary_player() -> Player:
	for entity_id in entities:
		var entity: Entity = entities[entity_id]
		if entity is Player:
			return entity as Player
	return null


func get_entity(entity_id: int) -> Entity:
	return entities.get(entity_id)


func get_entity_at(position: Vector2i) -> Entity:
	for entity_id in entities:
		var entity: Entity = entities[entity_id]
		if entity.grid_position == position:
			return entity
	return null


func get_monster_at(position: Vector2i) -> _Monster:
	var entity := get_entity_at(position)
	if entity is _Monster:
		return entity as _Monster
	return null


func post_player_message(entity_id: int, message: String) -> void:
	if get_entity(entity_id) == null:
		return
	player_message.emit(entity_id, message)


func examine_tile(entity_id: int, pos: Vector2i) -> String:
	var entity := get_entity(entity_id)
	if entity == null or not entity is Player:
		return MessageTemplates.EXAMINE_UNSEEN_LOCATION
	var player := entity as Player
	return Examine.examine(
		game_map,
		player.vision,
		player.grid_position,
		pos,
		get_monster_at(pos),
	)


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
	var entity := get_entity(command.entity_id)
	if entity == null:
		return false

	var target := entity.grid_position + command.direction
	var occupant := get_entity_at(target)
	if occupant is _Monster and entity is Player:
		return process_attack_on_target(command.entity_id, occupant.entity_id)

	if not try_move_entity(command.entity_id, command.direction):
		return false

	var time_cost := entity.stats.get_step_time_cost(GameConstants.STEP_TIME_COST)
	var activity := _get_activity(command.entity_id)
	if game_mode == GameMode.Mode.SINGLE_PLAYER:
		_advance_time(time_cost)
	else:
		activity.busy_until = game_time + time_cost
	return true


func process_attack_command(command) -> bool:
	return process_attack_on_target(command.entity_id, command.target_entity_id)


func process_attack_on_target(attacker_id: int, target_id: int) -> bool:
	if not try_attack(attacker_id, target_id):
		return false

	var attacker := get_entity(attacker_id)
	var time_cost := attacker.stats.get_attack_time_cost(GameConstants.ATTACK_TIME_COST)
	var activity := _get_activity(attacker_id)
	if game_mode == GameMode.Mode.SINGLE_PLAYER:
		_advance_time(time_cost)
	else:
		activity.busy_until = game_time + time_cost
	return true


func try_attack(attacker_id: int, defender_id: int) -> bool:
	var attacker := get_entity(attacker_id)
	var defender := get_entity(defender_id)
	if attacker == null or defender == null:
		return false
	if not GridPosition.is_adjacent(attacker.grid_position, defender.grid_position):
		return false

	if attacker is Player and defender is _Monster:
		return _resolve_melee_attack(attacker, defender)
	if attacker is _Monster and defender is Player:
		return _resolve_melee_attack(attacker, defender)
	return false


func _resolve_melee_attack(attacker: Entity, defender: Entity) -> bool:
	var message_entity_id := defender.entity_id if attacker is _Monster else attacker.entity_id
	if not CharacterStats.rolls_hit(attacker.stats.dexterity.current, defender.stats.dexterity.current):
		var miss_message := (
			MessageTemplates.format_monster_misses_you(attacker.get_display_name())
			if attacker is _Monster
			else MessageTemplates.format_you_miss_monster(defender.get_display_name())
		)
		post_player_message(message_entity_id, miss_message)
		return true

	var damage := CharacterStats.calculate_damage(
		attacker.stats.get_attack_value(),
		defender.stats.armor,
	)
	defender.take_damage(damage)

	var hit_message := (
		MessageTemplates.format_monster_hits_you(attacker.get_display_name())
		if attacker is _Monster
		else MessageTemplates.format_you_hit_monster(defender.get_display_name())
	)
	post_player_message(message_entity_id, hit_message)
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
	_process_ready_monsters()
	time_changed.emit(game_time)
	tick_completed.emit()


func try_move_entity(entity_id: int, direction: Vector2i) -> bool:
	var entity := get_entity(entity_id)
	if entity == null:
		return false
	if entity is _Monster:
		return try_move_monster(entity_id, direction)

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


func can_monster_step_onto(monster: _Monster, target: Vector2i) -> bool:
	if not GridPosition.is_in_bounds(target, game_map.width, game_map.height):
		return false

	if game_map.is_closed_door(target):
		if monster.can_destroy_doors:
			pass
		elif monster.can_open_doors:
			pass
		else:
			return false

	if not game_map.is_walkable(target):
		return false
	if _is_occupied_by_other(monster.entity_id, target):
		return false
	return true


func try_move_monster(entity_id: int, direction: Vector2i) -> bool:
	var monster := get_entity(entity_id) as _Monster
	if monster == null:
		return false

	var target := monster.grid_position + direction
	if not can_monster_step_onto(monster, target):
		return false

	if game_map.is_closed_door(target):
		if monster.can_destroy_doors:
			pass
		elif monster.can_open_doors:
			pass

	var old_position := monster.grid_position
	monster.grid_position = target
	monster.last_move_direction = direction
	entity_moved.emit(entity_id, old_position, target)
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


func try_open_door(pos: Vector2i, entity_id: int) -> void:
	_try_door_command(
		pos,
		entity_id,
		DoorState.State.CLOSED,
		DoorState.State.OPEN,
		MessageTemplates.NOTHING_TO_OPEN,
	)


func try_close_door(pos: Vector2i, entity_id: int) -> void:
	_try_door_command(
		pos,
		entity_id,
		DoorState.State.OPEN,
		DoorState.State.CLOSED,
		MessageTemplates.NOTHING_TO_CLOSE,
	)


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


func _try_door_command(
	pos: Vector2i,
	entity_id: int,
	required_state: int,
	new_state: int,
	nothing_message: String,
) -> void:
	var entity := get_entity(entity_id)
	if entity == null:
		return

	var messages: Array[String] = []
	if pos == entity.grid_position:
		messages.append(MessageTemplates.IN_THE_WAY)
	elif not GridPosition.is_adjacent(entity.grid_position, pos):
		messages.append(MessageTemplates.CANT_REACH)
	elif game_map.get_door_state(pos) != required_state:
		messages.append(nothing_message)
	else:
		game_map.set_door_state(pos, new_state)
		door_changed.emit(pos)

	messages.append(MessageTemplates.DONE)
	for message in messages:
		player_message.emit(entity_id, message)


func _register_entity(entity: Entity) -> void:
	entities[entity.entity_id] = entity
	_entity_activities[entity.entity_id] = EntityActivity.new()
	entity.stats.recalculate_max_health()
	entity.stats.recalculate_max_mana()
	entity.stats.recalculate_carry_weight()
	entity.stats.recalculate_movement_speed()
	entity.stats.recalculate_experience_to_level_up(difficulty)
	_apply_fixed_max_hp_if_needed(entity)
	_track_entity_stats(entity)


func _apply_fixed_max_hp_if_needed(entity: Entity) -> void:
	if not entity is _Monster:
		return
	var fixed_hp := (entity as _Monster).get_fixed_max_hp()
	if fixed_hp <= 0:
		return
	entity.stats.hp.set_max_unclamped(fixed_hp)
	entity.stats.hp.set_current_unclamped(fixed_hp)


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
	_process_ready_monsters()


func _process_ready_monsters() -> void:
	for monster in _get_all_monsters():
		var safety := 0
		while safety < 20:
			var activity := _get_activity(monster.entity_id)
			if activity.is_busy(game_time):
				break
			_monster_take_turn(monster)
			safety += 1


func _monster_take_turn(monster: _Monster) -> void:
	_MonsterAI.update_awareness(self, monster)

	var attacked := false
	if not monster.is_asleep:
		var hero := get_primary_player()
		if hero != null and GridPosition.is_adjacent(monster.grid_position, hero.grid_position):
			attacked = try_attack(monster.entity_id, hero.entity_id)

	if not attacked:
		var direction := _MonsterAI.choose_move_direction(self, monster)
		if direction != Vector2i.ZERO:
			try_move_monster(monster.entity_id, direction)

	var time_cost := (
		monster.stats.get_attack_time_cost(GameConstants.ATTACK_TIME_COST)
		if attacked
		else monster.stats.get_step_time_cost(GameConstants.STEP_TIME_COST)
	)
	_get_activity(monster.entity_id).busy_until = game_time + time_cost


func _get_all_monsters() -> Array[_Monster]:
	var monsters: Array[_Monster] = []
	for entity_id in entities:
		var entity: Entity = entities[entity_id]
		if entity is _Monster:
			monsters.append(entity as _Monster)
	return monsters


func _is_occupied_by_other(entity_id: int, position: Vector2i) -> bool:
	for other_id in entities:
		if other_id == entity_id:
			continue
		var other: Entity = entities[other_id]
		if other.grid_position == position:
			return true
	return false
