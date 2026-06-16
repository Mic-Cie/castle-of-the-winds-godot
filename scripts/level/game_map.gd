class_name GameMap
extends RefCounted

var width: int
var height: int
var _tiles: Array[int] = []
var _doors: PackedByteArray = PackedByteArray()
var _default_uncovered: PackedByteArray = PackedByteArray()
var _diagonal_floor: PackedByteArray = PackedByteArray()


func _init(p_width: int, p_height: int) -> void:
	width = p_width
	height = p_height
	_tiles.resize(width * height)
	_doors.resize(width * height)
	_default_uncovered.resize(width * height)
	_diagonal_floor.resize(width * height)
	fill(TileType.Type.WALL)


func _index(x: int, y: int) -> int:
	return y * width + x


func get_tile(pos: Vector2i) -> int:
	return _tiles[_index(pos.x, pos.y)]


func set_tile(pos: Vector2i, tile_type: int) -> void:
	_tiles[_index(pos.x, pos.y)] = tile_type


func fill(tile_type: int) -> void:
	for i in range(_tiles.size()):
		_tiles[i] = tile_type


func get_door_state(pos: Vector2i) -> int:
	if not GridPosition.is_in_bounds(pos, width, height):
		return DoorState.State.NONE
	return _doors[_index(pos.x, pos.y)]


func set_door_state(pos: Vector2i, state: int) -> void:
	if not GridPosition.is_in_bounds(pos, width, height):
		return
	_doors[_index(pos.x, pos.y)] = state


func has_door(pos: Vector2i) -> bool:
	return get_door_state(pos) != DoorState.State.NONE


func is_closed_door(pos: Vector2i) -> bool:
	return get_door_state(pos) == DoorState.State.CLOSED


func is_hidden_door(pos: Vector2i) -> bool:
	return get_door_state(pos) == DoorState.State.HIDDEN


func is_walkable(pos: Vector2i) -> bool:
	if not GridPosition.is_in_bounds(pos, width, height):
		return false
	var door_state := get_door_state(pos)
	if DoorState.blocks_movement(door_state):
		return false
	var tile_type := get_tile(pos)
	return tile_type == TileType.Type.FLOOR or tile_type == TileType.Type.LIT_FLOOR


func can_step_onto(pos: Vector2i) -> bool:
	return is_walkable(pos) or is_closed_door(pos)


func is_lit(pos: Vector2i) -> bool:
	return get_tile(pos) == TileType.Type.LIT_FLOOR


func is_floor(pos: Vector2i) -> bool:
	if not GridPosition.is_in_bounds(pos, width, height):
		return false
	var tile_type := get_tile(pos)
	return tile_type == TileType.Type.FLOOR or tile_type == TileType.Type.LIT_FLOOR


func is_wall(pos: Vector2i) -> bool:
	if not GridPosition.is_in_bounds(pos, width, height):
		return false
	return get_tile(pos) == TileType.Type.WALL


func is_diagonal_floor(pos: Vector2i) -> bool:
	if not GridPosition.is_in_bounds(pos, width, height):
		return false
	return _diagonal_floor[_index(pos.x, pos.y)] == 1


func _mark_diagonal_floor(pos: Vector2i) -> void:
	if GridPosition.is_in_bounds(pos, width, height):
		_diagonal_floor[_index(pos.x, pos.y)] = 1


func set_lit_rect(rect: Rect2i) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			var pos := Vector2i(x, y)
			if get_tile(pos) == TileType.Type.FLOOR:
				set_tile(pos, TileType.Type.LIT_FLOOR)


func fill_rect(rect: Rect2i, tile_type: int) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			if GridPosition.is_in_bounds(Vector2i(x, y), width, height):
				set_tile(Vector2i(x, y), tile_type)


func carve_horizontal_corridor(y: int, x_start: int, x_end: int) -> void:
	var from_x := mini(x_start, x_end)
	var to_x := maxi(x_start, x_end)
	for x in range(from_x, to_x + 1):
		set_tile(Vector2i(x, y), TileType.Type.FLOOR)


func carve_vertical_corridor(x: int, y_start: int, y_end: int) -> void:
	var from_y := mini(y_start, y_end)
	var to_y := maxi(y_start, y_end)
	for y in range(from_y, to_y + 1):
		set_tile(Vector2i(x, y), TileType.Type.FLOOR)


func carve_diagonal_corridor(from: Vector2i, to: Vector2i) -> void:
	var x := from.x
	var y := from.y
	var dx := absi(to.x - from.x)
	var dy := absi(to.y - from.y)
	var sx := 1 if from.x < to.x else -1
	var sy := 1 if from.y < to.y else -1
	var err := dx - dy

	while true:
		var pos := Vector2i(x, y)
		set_tile(pos, TileType.Type.FLOOR)
		_mark_diagonal_floor(pos)
		if x == to.x and y == to.y:
			break
		var e2 := 2 * err
		if e2 > -dy:
			err -= dy
			x += sx
		if e2 < dx:
			err += dx
			y += sy


func is_default_uncovered(pos: Vector2i) -> bool:
	if not GridPosition.is_in_bounds(pos, width, height):
		return false
	return _default_uncovered[_index(pos.x, pos.y)] == 1


func set_default_uncovered(pos: Vector2i, uncovered: bool = true) -> void:
	if not GridPosition.is_in_bounds(pos, width, height):
		return
	_default_uncovered[_index(pos.x, pos.y)] = 1 if uncovered else 0


func set_default_uncovered_rect(rect: Rect2i, uncovered: bool = true) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			set_default_uncovered(Vector2i(x, y), uncovered)
