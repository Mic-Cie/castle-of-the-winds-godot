class_name Difficulty
extends RefCounted

enum Level {
	EASY,
	INTERMEDIATE,
	DIFFICULT,
	EXPERTS_ONLY,
}


static func get_display_name(level: int) -> String:
	match level:
		Level.EASY:
			return "Easy"
		Level.INTERMEDIATE:
			return "Intermediate"
		Level.DIFFICULT:
			return "Difficult"
		Level.EXPERTS_ONLY:
			return "Experts Only"
		_:
			return "Unknown"


static func get_multiplier(level: int) -> int:
	match level:
		Level.EASY:
			return 1
		Level.INTERMEDIATE:
			return 2
		Level.DIFFICULT:
			return 3
		Level.EXPERTS_ONLY:
			return 4
		_:
			return 1
