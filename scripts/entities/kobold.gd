class_name Kobold
extends Monster


func _init(p_entity_id: int, p_position: Vector2i) -> void:
	super(p_entity_id, p_position)
	entity_type = &"kobold"
	stats.speed = 50


func get_sprite_frame() -> int:
	return GameConstants.KOBOLD_SPRITE_FRAME


func get_display_name() -> String:
	return "Kobold"
