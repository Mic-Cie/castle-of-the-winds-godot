class_name PlayerVision
extends RefCounted

const ADJACENT_OFFSETS: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1, 0), Vector2i(1, 0),
	Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
]

const CARDINAL_OFFSETS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0),
]

var width: int
var height: int
var _uncovered: PackedByteArray = PackedByteArray()


func _init(p_width: int, p_height: int) -> void:
	width = p_width
	height = p_height
	_uncovered.resize(width * height)


func apply_default_from_map(game_map: GameMap) -> Array[Vector2i]:
	var changed: Array[Vector2i] = []
	for y in range(height):
		for x in range(width):
			var pos := Vector2i(x, y)
			if game_map.is_default_uncovered(pos):
				if _mark_uncovered(pos):
					changed.append(pos)
	return changed


func reveal_around(center: Vector2i) -> Array[Vector2i]:
	var changed: Array[Vector2i] = []
	if _mark_uncovered(center):
		changed.append(center)

	for offset in ADJACENT_OFFSETS:
		var pos := center + offset
		if _mark_uncovered(pos):
			changed.append(pos)

	return changed


func reveal_on_step(game_map: GameMap, center: Vector2i) -> Array[Vector2i]:
	var changed: Array[Vector2i] = reveal_around(center)
	if game_map.is_lit(center):
		changed.append_array(_reveal_connected_lit_and_adjacent(game_map, center))
	return changed


func _reveal_connected_lit_and_adjacent(game_map: GameMap, start: Vector2i) -> Array[Vector2i]:
	var lit_component: Array[Vector2i] = []
	var queue: Array[Vector2i] = [start]
	var visited: Dictionary = {start: true}

	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		lit_component.append(current)
		for offset in CARDINAL_OFFSETS:
			var next := current + offset
			if visited.has(next) or not game_map.is_lit(next):
				continue
			visited[next] = true
			queue.append(next)

	var changed: Array[Vector2i] = []
	for lit_pos in lit_component:
		if _mark_uncovered(lit_pos):
			changed.append(lit_pos)
		for offset in ADJACENT_OFFSETS:
			var pos := lit_pos + offset
			if _mark_uncovered(pos):
				changed.append(pos)

	return changed


func is_uncovered(pos: Vector2i) -> bool:
	if not GridPosition.is_in_bounds(pos, width, height):
		return false
	return _uncovered[_index(pos.x, pos.y)] == 1


func _mark_uncovered(pos: Vector2i) -> bool:
	if not GridPosition.is_in_bounds(pos, width, height):
		return false
	var index := _index(pos.x, pos.y)
	if _uncovered[index] == 1:
		return false
	_uncovered[index] = 1
	return true


func _index(x: int, y: int) -> int:
	return y * width + x
