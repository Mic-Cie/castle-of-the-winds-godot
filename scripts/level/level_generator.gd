class_name LevelGenerator
extends RefCounted

## Base level generator. Additional generators (procedural, loaded from file, etc.)
## can be added alongside FixedLevelGenerator.


func generate() -> GameMap:
	push_error("LevelGenerator.generate() must be overridden.")
	return null
