class_name LineOfSight
extends RefCounted

static func has_line_of_sight(game_map: GameMap, from: Vector2i, to: Vector2i) -> bool:
	if from == to:
		return true

	for pos in _line_tiles(from, to):
		if pos == from or pos == to:
			continue
		if blocks_sight(game_map, pos):
			return false
	return true


static func blocks_sight(game_map: GameMap, pos: Vector2i) -> bool:
	if not GridPosition.is_in_bounds(pos, game_map.width, game_map.height):
		return true
	if game_map.is_wall(pos):
		return true
	var door_state := game_map.get_door_state(pos)
	return door_state == DoorState.State.CLOSED or door_state == DoorState.State.HIDDEN


static func _line_tiles(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var points: Array[Vector2i] = []
	var x0 := from.x
	var y0 := from.y
	var x1 := to.x
	var y1 := to.y

	var dx := absi(x1 - x0)
	var dy := absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx - dy

	while true:
		points.append(Vector2i(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 > -dy:
			err -= dy
			x0 += sx
		if e2 < dx:
			err += dx
			y0 += sy

	return points
