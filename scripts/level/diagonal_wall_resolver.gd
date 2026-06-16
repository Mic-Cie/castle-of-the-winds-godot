class_name DiagonalWallResolver
extends RefCounted

## Diagonal wall sprites from tiles.png columns 2-5 (1-based; column 1 = atlas x 0).
## Row 3 = unlit, row 6 = lit.

## Each rule: two floor tiles (cardinal) + one outer wall tile (diagonal corner).
const RULES: Array[Dictionary] = [
	{
		"column": 2,
		"floors": [Vector2i(0, -1), Vector2i(1, 0)],
		"corner_wall": Vector2i(1, -1),
	},
	{
		"column": 3,
		"floors": [Vector2i(0, 1), Vector2i(1, 0)],
		"corner_wall": Vector2i(1, 1),
	},
	{
		"column": 4,
		"floors": [Vector2i(0, 1), Vector2i(-1, 0)],
		"corner_wall": Vector2i(-1, 1),
	},
	{
		"column": 5,
		"floors": [Vector2i(0, -1), Vector2i(-1, 0)],
		"corner_wall": Vector2i(-1, -1),
	},
]

const DEBUG_PRINT := false


static func resolve(pos: Vector2i, game_map: GameMap) -> Dictionary:
	if not game_map.is_wall(pos):
		return _default()

	for rule in RULES:
		if _rule_matches(pos, rule, game_map):
			return _special(pos, game_map, rule)

	return _default()


static func _rule_matches(pos: Vector2i, rule: Dictionary, game_map: GameMap) -> bool:
	if not game_map.is_wall(pos + rule["corner_wall"]):
		return false

	var touches_diagonal_corridor := false
	for floor_offset: Vector2i in rule["floors"]:
		var floor_pos := pos + floor_offset
		if not game_map.is_floor(floor_pos):
			return false
		if game_map.is_diagonal_floor(floor_pos):
			touches_diagonal_corridor = true

	return touches_diagonal_corridor


static func _special(pos: Vector2i, game_map: GameMap, rule: Dictionary) -> Dictionary:
	var lit := _is_lit_for_rule(pos, rule, game_map)
	var column: int = rule["column"]
	var atlas := GameConstants.diag_wall_atlas(column, lit)
	if DEBUG_PRINT:
		print("[DiagWall] wall=(%d, %d) column=%d lit=%s" % [pos.x, pos.y, column, lit])
	return {
		"use_special": true,
		"atlas": atlas,
		"alternative": 0,
	}


static func _is_lit_for_rule(pos: Vector2i, rule: Dictionary, game_map: GameMap) -> bool:
	for floor_offset: Vector2i in rule["floors"]:
		if not game_map.is_lit(pos + floor_offset):
			return false
	return true


static func _default() -> Dictionary:
	return {
		"use_special": false,
		"atlas": GameConstants.WALL_TILE,
		"alternative": 0,
	}
