class_name MonsterVisibility
extends RefCounted


static func can_see_monster(game_map: GameMap, observer_pos: Vector2i, monster_pos: Vector2i) -> bool:
	if not LineOfSight.has_line_of_sight(game_map, observer_pos, monster_pos):
		return false
	if game_map.is_lit(monster_pos):
		return true
	return (
		GridPosition.chebyshev_distance(observer_pos, monster_pos)
		<= GameConstants.MONSTER_UNLIT_SIGHT_RANGE
	)
