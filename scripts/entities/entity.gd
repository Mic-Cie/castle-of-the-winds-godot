class_name Entity
extends RefCounted

var entity_id: int
var grid_position: Vector2i
var entity_type: StringName = &"entity"
var stats: CharacterStats


func _init(p_entity_id: int, p_position: Vector2i) -> void:
	entity_id = p_entity_id
	grid_position = p_position
	stats = CharacterStats.create_default()
