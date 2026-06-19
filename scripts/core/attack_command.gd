class_name AttackCommand
extends GameCommand

var entity_id: int
var target_entity_id: int


func _init(p_entity_id: int, p_target_entity_id: int) -> void:
	entity_id = p_entity_id
	target_entity_id = p_target_entity_id


func get_entity_id() -> int:
	return entity_id


func execute(world) -> bool:
	return world.process_attack_command(self)
