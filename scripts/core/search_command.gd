class_name SearchCommand
extends GameCommand

var entity_id: int


func _init(p_entity_id: int) -> void:
	entity_id = p_entity_id


func get_entity_id() -> int:
	return entity_id


func execute(world: GameWorld) -> bool:
	return world.process_search_command(self)
