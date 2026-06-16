class_name SearchCommand
extends GameCommand

var entity_id: int


func _init(p_entity_id: int) -> void:
	entity_id = p_entity_id


func execute(world: GameWorld) -> bool:
	return world.try_search(entity_id)
