class_name Examine
extends RefCounted

const _Monster = preload("res://scripts/entities/monster.gd")
const _MonsterVisibility = preload("res://scripts/vision/monster_visibility.gd")


static func examine(
	game_map: GameMap,
	vision: PlayerVision,
	observer_pos: Vector2i,
	target_pos: Vector2i,
	monster_at_tile = null,
) -> String:
	if not GridPosition.is_in_bounds(target_pos, game_map.width, game_map.height):
		return MessageTemplates.EXAMINE_UNSEEN_LOCATION

	var tile_objects := _describe_tile(game_map, target_pos)
	var monster_description := _describe_visible_monster(
		game_map,
		observer_pos,
		monster_at_tile,
	)
	var has_los := LineOfSight.has_line_of_sight(game_map, observer_pos, target_pos)
	var is_on_map := vision.is_uncovered(target_pos)
	var can_detect := _can_detect_tile(game_map, vision, observer_pos, target_pos)

	var see_objects: Array[String] = []
	var detect_objects: Array[String] = []
	var map_objects: Array[String] = []

	if monster_description != "":
		see_objects.append(monster_description)

	if has_los and is_on_map:
		see_objects.append_array(tile_objects)
	elif is_on_map:
		map_objects.append_array(tile_objects)
	elif can_detect:
		detect_objects.append_array(tile_objects)

	if see_objects.is_empty() and detect_objects.is_empty() and map_objects.is_empty():
		return MessageTemplates.EXAMINE_UNSEEN_LOCATION

	return _format_output(see_objects, detect_objects, map_objects)


static func _describe_visible_monster(
	game_map: GameMap,
	observer_pos: Vector2i,
	monster_at_tile,
) -> String:
	if monster_at_tile == null or not monster_at_tile is _Monster:
		return ""

	var monster: _Monster = monster_at_tile
	if not _MonsterVisibility.can_see_monster(game_map, observer_pos, monster.grid_position):
		return ""

	return monster.get_examine_description()


static func _can_detect_tile(
	_game_map: GameMap,
	_vision: PlayerVision,
	_observer_pos: Vector2i,
	_target_pos: Vector2i,
) -> bool:
	return false


static func _describe_tile(game_map: GameMap, pos: Vector2i) -> Array[String]:
	var result: Array[String] = []
	var door_state := game_map.get_door_state(pos)

	if door_state == DoorState.State.HIDDEN:
		result.append(MessageTemplates.EXAMINE_ROCK)
		return result

	if game_map.is_floor(pos):
		result.append(MessageTemplates.EXAMINE_DUNGEON_FLOOR)
	elif game_map.is_wall(pos):
		result.append(MessageTemplates.EXAMINE_ROCK)

	match door_state:
		DoorState.State.CLOSED:
			result.append(MessageTemplates.EXAMINE_CLOSED_DOOR)
		DoorState.State.OPEN:
			result.append(MessageTemplates.EXAMINE_OPEN_DOOR)
		DoorState.State.DESTROYED:
			result.append(MessageTemplates.EXAMINE_BROKEN_DOOR)

	return result


static func _format_output(
	see_objects: Array[String],
	detect_objects: Array[String],
	map_objects: Array[String],
) -> String:
	var lines: Array[String] = []

	if not see_objects.is_empty():
		lines.append(MessageTemplates.EXAMINE_HEADER_SEE)
		lines.append_array(see_objects)
	if not detect_objects.is_empty():
		lines.append(MessageTemplates.EXAMINE_HEADER_DETECT)
		lines.append_array(detect_objects)
	if not map_objects.is_empty():
		lines.append(MessageTemplates.EXAMINE_HEADER_MAP)
		lines.append_array(map_objects)

	return "\n".join(lines)
