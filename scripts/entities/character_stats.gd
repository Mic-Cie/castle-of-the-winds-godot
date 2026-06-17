class_name CharacterStats
extends RefCounted

signal changed(stat_name: StringName)

var hp: RangedStat
var mana: RangedStat
var strength: RangedStat
var constitution: RangedStat
var dexterity: RangedStat
var intelligence: RangedStat

var _speed: int = GameConstants.DEFAULT_SPEED
var _level: int = GameConstants.DEFAULT_LEVEL
var _drained_hit_points: int = GameConstants.DEFAULT_DRAINED_HIT_POINTS

var level: int:
	get:
		return _level
	set(value):
		var clamped := maxi(value, 1)
		if _level != clamped:
			_level = clamped
			changed.emit(&"level")

var drained_hit_points: int:
	get:
		return _drained_hit_points
	set(value):
		var clamped := maxi(value, 0)
		if _drained_hit_points != clamped:
			_drained_hit_points = clamped
			changed.emit(&"drained_hit_points")

var speed: int:
	get:
		return _speed
	set(value):
		if _speed != value:
			_speed = value
			changed.emit(&"speed")


func _init() -> void:
	hp = RangedStat.new(GameConstants.DEFAULT_HP, GameConstants.DEFAULT_HP_MAX)
	mana = RangedStat.new(GameConstants.DEFAULT_MANA, GameConstants.DEFAULT_MANA_MAX)
	strength = RangedStat.new(GameConstants.DEFAULT_STRENGTH, GameConstants.DEFAULT_STRENGTH_MAX)
	constitution = RangedStat.new(GameConstants.DEFAULT_CONSTITUTION, GameConstants.DEFAULT_CONSTITUTION_MAX)
	dexterity = RangedStat.new(GameConstants.DEFAULT_DEXTERITY, GameConstants.DEFAULT_DEXTERITY_MAX)
	intelligence = RangedStat.new(GameConstants.DEFAULT_INTELLIGENCE, GameConstants.DEFAULT_INTELLIGENCE_MAX)

	_connect_ranged_stat(hp, &"hp")
	_connect_ranged_stat(mana, &"mana")
	_connect_ranged_stat(strength, &"strength")
	_connect_ranged_stat(constitution, &"constitution")
	_connect_ranged_stat(dexterity, &"dexterity")
	_connect_ranged_stat(intelligence, &"intelligence")


static func create_default() -> CharacterStats:
	return CharacterStats.new()


func recalculate_max_health() -> void:
	hp.set_max_unclamped(_calculate_max_health())


## Placeholder until a real strength-based formula is added.
func get_movement_speed() -> int:
	return strength.current


func _calculate_max_health() -> int:
	var from_stats := (
		GameConstants.HP_BASE
		+ (constitution.current - GameConstants.HP_CONSTITUTION_REFERENCE) * GameConstants.HP_PER_CONSTITUTION_POINT
	) * level
	return from_stats - drained_hit_points


func _connect_ranged_stat(stat: RangedStat, stat_name: StringName) -> void:
	stat.changed.connect(func() -> void: changed.emit(stat_name))
