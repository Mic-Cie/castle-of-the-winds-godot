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
