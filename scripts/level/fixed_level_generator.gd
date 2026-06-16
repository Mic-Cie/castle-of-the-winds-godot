class_name FixedLevelGenerator
extends LevelGenerator

const MAP_WIDTH := 80
const MAP_HEIGHT := 80

const _CARDINAL_OFFSETS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0),
]


func generate() -> GameMap:
	var game_map := GameMap.new(MAP_WIDTH, MAP_HEIGHT)
	game_map.fill(TileType.Type.WALL)

	var rooms: Array[Rect2i] = [
		Rect2i(4, 4, 12, 10),
		Rect2i(22, 4, 14, 8),
		Rect2i(44, 6, 12, 10),
		Rect2i(62, 8, 12, 9),
		Rect2i(8, 22, 10, 12),
		Rect2i(26, 20, 16, 14),
		Rect2i(50, 22, 14, 12),
		Rect2i(66, 26, 10, 10),
		Rect2i(6, 42, 14, 10),
		Rect2i(28, 42, 12, 12),
		Rect2i(48, 44, 16, 10),
		Rect2i(68, 44, 8, 14),
		Rect2i(12, 60, 18, 12),
		Rect2i(38, 58, 20, 14),
		Rect2i(64, 62, 12, 10),
	]

	for room in rooms:
		game_map.fill_rect(room, TileType.Type.FLOOR)

	game_map.set_default_uncovered_rect(rooms[0], true)

	var door_segments: Array[Dictionary] = []

	_collect_horizontal_door_segment(door_segments, rooms[0], rooms[1], 8)
	_collect_horizontal_door_segment(door_segments, rooms[1], rooms[2], 8)
	_collect_horizontal_door_segment(door_segments, rooms[2], rooms[3], 12)
	_collect_vertical_door_segment(door_segments, rooms[0], rooms[4], 10)
	_collect_vertical_door_segment(door_segments, rooms[1], rooms[5], 27)
	_collect_vertical_door_segment(door_segments, rooms[2], rooms[6], 28)
	_collect_vertical_door_segment(door_segments, rooms[3], rooms[7], 31)
	_collect_horizontal_door_segment(door_segments, rooms[4], rooms[5], 32)
	_collect_horizontal_door_segment(door_segments, rooms[5], rooms[6], 32)
	_collect_horizontal_door_segment(door_segments, rooms[6], rooms[7], 32)
	_collect_vertical_door_segment(door_segments, rooms[4], rooms[8], 18)
	_collect_vertical_door_segment(door_segments, rooms[5], rooms[9], 48)
	_collect_vertical_door_segment(door_segments, rooms[6], rooms[10], 50)
	_collect_vertical_door_segment(door_segments, rooms[7], rooms[11], 54)
	_collect_horizontal_door_segment(door_segments, rooms[8], rooms[9], 54)
	_collect_horizontal_door_segment(door_segments, rooms[9], rooms[10], 54)
	_collect_horizontal_door_segment(door_segments, rooms[10], rooms[11], 54)
	_collect_vertical_door_segment(door_segments, rooms[8], rooms[12], 22)
	_collect_vertical_door_segment(door_segments, rooms[9], rooms[13], 48)
	_collect_vertical_door_segment(door_segments, rooms[10], rooms[14], 66)
	_collect_horizontal_door_segment(door_segments, rooms[12], rooms[13], 66)
	_collect_horizontal_door_segment(door_segments, rooms[13], rooms[14], 66)

	_connect_rooms_horizontally(game_map, rooms[0], rooms[1], 8)
	_connect_rooms_horizontally(game_map, rooms[1], rooms[2], 8)
	_connect_rooms_horizontally(game_map, rooms[2], rooms[3], 12)
	_connect_rooms_vertically(game_map, rooms[0], rooms[4], 10)
	_connect_rooms_vertically(game_map, rooms[1], rooms[5], 27)
	_connect_rooms_vertically(game_map, rooms[2], rooms[6], 28)
	_connect_rooms_vertically(game_map, rooms[3], rooms[7], 31)
	_connect_rooms_horizontally(game_map, rooms[4], rooms[5], 32)
	_connect_rooms_horizontally(game_map, rooms[5], rooms[6], 32)
	_connect_rooms_horizontally(game_map, rooms[6], rooms[7], 32)
	_connect_rooms_vertically(game_map, rooms[4], rooms[8], 18)
	_connect_rooms_vertically(game_map, rooms[5], rooms[9], 48)
	_connect_rooms_vertically(game_map, rooms[6], rooms[10], 50)
	_connect_rooms_vertically(game_map, rooms[7], rooms[11], 54)
	_connect_rooms_horizontally(game_map, rooms[8], rooms[9], 54)
	_connect_rooms_horizontally(game_map, rooms[9], rooms[10], 54)
	_connect_rooms_horizontally(game_map, rooms[10], rooms[11], 54)
	_connect_rooms_vertically(game_map, rooms[8], rooms[12], 22)
	_connect_rooms_vertically(game_map, rooms[9], rooms[13], 48)
	_connect_rooms_vertically(game_map, rooms[10], rooms[14], 66)
	_connect_rooms_horizontally(game_map, rooms[12], rooms[13], 66)
	_connect_rooms_horizontally(game_map, rooms[13], rooms[14], 66)

	# Diagonal shortcuts between rooms (1 tile wide, best traversed with diagonal movement).
	_connect_rooms_diagonally(game_map, Vector2i(8, 13), Vector2i(12, 22))   # rooms[0] -> rooms[4], down-left
	_connect_rooms_diagonally(game_map, Vector2i(54, 16), Vector2i(62, 23))  # rooms[2] -> rooms[6], down-right
	_connect_rooms_diagonally(game_map, Vector2i(19, 51), Vector2i(30, 62))  # rooms[8] -> rooms[12], down-right
	_connect_rooms_diagonally(game_map, Vector2i(73, 36), Vector2i(65, 44))  # rooms[7] -> rooms[11], down-left

	_place_corridor_doors(game_map, door_segments)
	_apply_door_variants(game_map)

	var lit_rooms: Array[Rect2i] = [rooms[0], rooms[2], rooms[5], rooms[9], rooms[13]]
	for room in lit_rooms:
		game_map.set_lit_rect(room)

	return game_map


func _connect_rooms_horizontally(game_map: GameMap, left: Rect2i, right: Rect2i, corridor_y: int) -> void:
	var left_center_x := left.position.x + left.size.x / 2
	var right_center_x := right.position.x + right.size.x / 2
	game_map.carve_horizontal_corridor(corridor_y, left_center_x, right_center_x)


func _connect_rooms_vertically(game_map: GameMap, top: Rect2i, bottom: Rect2i, corridor_x: int) -> void:
	var top_center_y := top.position.y + top.size.y / 2
	var bottom_center_y := bottom.position.y + bottom.size.y / 2
	game_map.carve_vertical_corridor(corridor_x, top_center_y, bottom_center_y)


func _connect_rooms_diagonally(game_map: GameMap, from: Vector2i, to: Vector2i) -> void:
	game_map.carve_diagonal_corridor(from, to)


func _collect_horizontal_door_segment(
	segments: Array[Dictionary],
	left: Rect2i,
	right: Rect2i,
	corridor_y: int,
) -> void:
	var left_center_x := left.position.x + left.size.x / 2
	var right_center_x := right.position.x + right.size.x / 2
	segments.append({
		"axis": "horizontal",
		"y": corridor_y,
		"x_from": mini(left_center_x, right_center_x),
		"x_to": maxi(left_center_x, right_center_x),
		"near_room_a": left,
		"near_room_b": right,
	})


func _collect_vertical_door_segment(
	segments: Array[Dictionary],
	top: Rect2i,
	bottom: Rect2i,
	corridor_x: int,
) -> void:
	var top_center_y := top.position.y + top.size.y / 2
	var bottom_center_y := bottom.position.y + bottom.size.y / 2
	segments.append({
		"axis": "vertical",
		"x": corridor_x,
		"y_from": mini(top_center_y, bottom_center_y),
		"y_to": maxi(top_center_y, bottom_center_y),
		"near_room_a": top,
		"near_room_b": bottom,
	})


func _apply_door_variants(game_map: GameMap) -> void:
	var doors: Array[Vector2i] = []
	for y in range(game_map.height):
		for x in range(game_map.width):
			var pos := Vector2i(x, y)
			if game_map.get_door_state(pos) == DoorState.State.CLOSED:
				doors.append(pos)

	for i in range(doors.size()):
		if i % 4 == 1:
			game_map.set_door_state(doors[i], DoorState.State.HIDDEN)
		elif i % 4 == 3:
			game_map.set_door_state(doors[i], DoorState.State.DESTROYED)


func _place_corridor_doors(game_map: GameMap, segments: Array[Dictionary]) -> void:
	var placed: Array[Vector2i] = []
	for segment in segments:
		var pos := _find_corridor_door_pos(game_map, segment)
		if pos == Vector2i(-1, -1):
			continue
		if _is_near_existing_door(pos, placed):
			continue
		game_map.set_door_state(pos, DoorState.State.CLOSED)
		placed.append(pos)


func _is_near_existing_door(pos: Vector2i, placed: Array[Vector2i]) -> bool:
	const MIN_DOOR_SPACING := 4
	for existing in placed:
		if maxi(absi(pos.x - existing.x), absi(pos.y - existing.y)) < MIN_DOOR_SPACING:
			return true
	return false


func _find_corridor_door_pos(game_map: GameMap, segment: Dictionary) -> Vector2i:
	if segment["axis"] == "horizontal":
		return _find_horizontal_corridor_door(game_map, segment)
	return _find_vertical_corridor_door(game_map, segment)


func _find_horizontal_corridor_door(game_map: GameMap, segment: Dictionary) -> Vector2i:
	var y: int = segment["y"]
	var room_a: Rect2i = segment["near_room_a"]
	var room_b: Rect2i = segment["near_room_b"]
	var x_from: int = segment["x_from"]
	var x_to: int = segment["x_to"]

	var exit_a := room_a.position.x + room_a.size.x
	for x in range(exit_a, x_to + 1):
		var pos := Vector2i(x, y)
		if _is_valid_door_site(game_map, pos):
			return pos

	var exit_b := room_b.position.x - 1
	for x in range(exit_b, x_from - 1, -1):
		var pos := Vector2i(x, y)
		if _is_valid_door_site(game_map, pos):
			return pos

	for x in range(x_from, x_to + 1):
		var pos := Vector2i(x, y)
		if _is_valid_door_site(game_map, pos):
			return pos

	return Vector2i(-1, -1)


func _find_vertical_corridor_door(game_map: GameMap, segment: Dictionary) -> Vector2i:
	var x: int = segment["x"]
	var room_a: Rect2i = segment["near_room_a"]
	var room_b: Rect2i = segment["near_room_b"]
	var y_from: int = segment["y_from"]
	var y_to: int = segment["y_to"]

	var exit_a := room_a.position.y + room_a.size.y
	for y in range(exit_a, y_to + 1):
		var pos := Vector2i(x, y)
		if _is_valid_door_site(game_map, pos):
			return pos

	var exit_b := room_b.position.y - 1
	for y in range(exit_b, y_from - 1, -1):
		var pos := Vector2i(x, y)
		if _is_valid_door_site(game_map, pos):
			return pos

	for y in range(y_from, y_to + 1):
		var pos := Vector2i(x, y)
		if _is_valid_door_site(game_map, pos):
			return pos

	return Vector2i(-1, -1)


func _is_valid_door_site(game_map: GameMap, pos: Vector2i) -> bool:
	if not game_map.is_floor(pos):
		return false
	return _count_wall_neighbors(game_map, pos) >= 2 and _count_floor_neighbors(game_map, pos) <= 2


func _count_wall_neighbors(game_map: GameMap, pos: Vector2i) -> int:
	var count := 0
	for offset in _CARDINAL_OFFSETS:
		if game_map.is_wall(pos + offset):
			count += 1
	return count


func _count_floor_neighbors(game_map: GameMap, pos: Vector2i) -> int:
	var count := 0
	for offset in _CARDINAL_OFFSETS:
		if game_map.is_floor(pos + offset):
			count += 1
	return count
