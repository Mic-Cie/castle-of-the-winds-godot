class_name MoveCommand
extends GameCommand

var entity_id: int
var direction: Vector2i


func _init(p_entity_id: int, p_direction: Vector2i) -> void:
	entity_id = p_entity_id
	direction = p_direction


func get_entity_id() -> int:
	return entity_id


func execute(world: GameWorld) -> bool:
	return world.process_move_command(self)
