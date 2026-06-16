class_name GridPosition
extends RefCounted

static func add(a: Vector2i, b: Vector2i) -> Vector2i:
	return a + b

static func is_in_bounds(pos: Vector2i, width: int, height: int) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < width and pos.y < height


static func is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	var delta := a - b
	return absi(delta.x) <= 1 and absi(delta.y) <= 1 and delta != Vector2i.ZERO
