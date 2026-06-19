class_name MonsterAI
extends RefCounted

const _Monster = preload("res://scripts/entities/monster.gd")

const MOVE_DIRECTIONS: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1, 0), Vector2i(1, 0),
	Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
]


static func update_awareness(world, monster: _Monster) -> void:
	var hero: Player = world.get_primary_player()
	if hero == null:
		return

	var hero_pos: Vector2i = hero.grid_position
	var can_see_hero := LineOfSight.has_line_of_sight(
		world.game_map,
		monster.grid_position,
		hero_pos,
	)

	if can_see_hero:
		if monster.is_asleep:
			if _try_wake(monster, hero_pos):
				monster.is_asleep = false
				monster.chasing = true
				monster.last_known_hero_position = hero_pos
		else:
			monster.chasing = true
			monster.last_known_hero_position = hero_pos
		return

	if monster.chasing and monster.grid_position == monster.last_known_hero_position:
		monster.chasing = false


static func choose_move_direction(world, monster: _Monster) -> Vector2i:
	var valid_directions := _get_valid_directions(world, monster)
	if valid_directions.is_empty():
		return Vector2i.ZERO

	var target_pos := Vector2i.ZERO
	if monster.chasing:
		target_pos = monster.last_known_hero_position
		if target_pos != monster.grid_position:
			var toward := _best_direction_toward(monster.grid_position, valid_directions, target_pos)
			if toward != Vector2i.ZERO:
				return toward

	if _is_corridor(valid_directions):
		if (
			monster.last_move_direction != Vector2i.ZERO
			and monster.last_move_direction in valid_directions
		):
			return monster.last_move_direction

	return valid_directions[randi() % valid_directions.size()]


static func _try_wake(monster: _Monster, hero_pos: Vector2i) -> bool:
	var distance := GridPosition.chebyshev_distance(monster.grid_position, hero_pos)
	var chance := (
		GameConstants.MONSTER_ASLEEP_NOTICE_BASE
		- float(distance) * GameConstants.MONSTER_ASLEEP_NOTICE_DISTANCE_PENALTY
	)
	chance = maxf(chance, GameConstants.MONSTER_ASLEEP_NOTICE_MIN)
	return randf() < chance


static func _get_valid_directions(world, monster: _Monster) -> Array[Vector2i]:
	var directions: Array[Vector2i] = []
	for direction in MOVE_DIRECTIONS:
		if world.can_monster_step_onto(monster, monster.grid_position + direction):
			directions.append(direction)
	return directions


static func _is_corridor(valid_directions: Array[Vector2i]) -> bool:
	if valid_directions.size() != 2:
		return false
	return valid_directions[0] + valid_directions[1] == Vector2i.ZERO


static func _best_direction_toward(
	from: Vector2i,
	valid_directions: Array[Vector2i],
	target: Vector2i,
) -> Vector2i:
	var best_direction := Vector2i.ZERO
	var best_distance := INF
	for direction in valid_directions:
		var next_pos := from + direction
		var distance := float(GridPosition.chebyshev_distance(next_pos, target))
		if distance < best_distance:
			best_distance = distance
			best_direction = direction
	return best_direction
