class_name GameCommand
extends RefCounted

## Base command for game actions. In multiplayer, the server validates and executes
## the same command objects received from clients.

func get_entity_id() -> int:
	return -1


func execute(_world: GameWorld) -> bool:
	return false
