class_name Monster
extends Entity

var is_asleep: bool = false
var can_open_doors: bool = false
var can_destroy_doors: bool = false

var last_move_direction: Vector2i = Vector2i.ZERO
var chasing: bool = false
var last_known_hero_position: Vector2i = Vector2i.ZERO


func _init(p_entity_id: int, p_position: Vector2i) -> void:
	super(p_entity_id, p_position)
	entity_type = &"monster"


func get_sprite_frame() -> int:
	return 0


func get_display_name() -> String:
	return "Monster"


func get_health_condition() -> String:
	var hp := stats.hp
	if hp.max_value <= 0:
		return MessageTemplates.MONSTER_HEALTH_CRITICALLY_INJURED
	if hp.current >= hp.max_value:
		return MessageTemplates.MONSTER_HEALTH_UNINJURED

	var ratio := float(hp.current) / float(hp.max_value)
	if ratio >= 0.90:
		return MessageTemplates.MONSTER_HEALTH_BARELY_SCRATCHED
	if ratio >= 0.70:
		return MessageTemplates.MONSTER_HEALTH_SLIGHTLY_INJURED
	if ratio >= 0.40:
		return MessageTemplates.MONSTER_HEALTH_INJURED
	if ratio >= 0.20:
		return MessageTemplates.MONSTER_HEALTH_HEAVILY_INJURED
	return MessageTemplates.MONSTER_HEALTH_CRITICALLY_INJURED


func get_examine_description() -> String:
	return "%s %s" % [get_health_condition(), get_display_name()]
