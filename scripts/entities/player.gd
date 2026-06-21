class_name Player
extends Entity

var player_id: int = 0
var vision: PlayerVision


func _init(p_entity_id: int, p_player_id: int, p_position: Vector2i) -> void:
	super(p_entity_id, p_position)
	player_id = p_player_id
	entity_type = &"player"
	_apply_hero_default_stats()


func _apply_hero_default_stats() -> void:
	_set_ranged_stat(stats.strength, GameConstants.HERO_DEFAULT_STRENGTH)
	_set_ranged_stat(stats.dexterity, GameConstants.HERO_DEFAULT_DEXTERITY)
	_set_ranged_stat(stats.constitution, GameConstants.HERO_DEFAULT_CONSTITUTION)
	_set_ranged_stat(stats.intelligence, GameConstants.HERO_DEFAULT_INTELLIGENCE)


func _set_ranged_stat(stat: RangedStat, value: int) -> void:
	stat.set_max_unclamped(value)
	stat.set_current_unclamped(value)


func get_sprite_frame() -> int:
	return GameConstants.HERO_SPRITE_FRAME


func get_display_name() -> String:
	return "Hero"
