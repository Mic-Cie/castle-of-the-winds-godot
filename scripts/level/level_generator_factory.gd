class_name LevelGeneratorFactory
extends RefCounted

## Creates level generators by name. Additional generator types can be registered here.


static func create(generator_name: String) -> LevelGenerator:
	match generator_name:
		"fixed":
			return FixedLevelGenerator.new()
		_:
			push_error("Unknown level generator: %s" % generator_name)
			return FixedLevelGenerator.new()
