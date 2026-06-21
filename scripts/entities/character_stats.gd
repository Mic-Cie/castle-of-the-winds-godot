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
var _experience: int = GameConstants.DEFAULT_EXPERIENCE
var _experience_to_level_up: int = 0
var _drained_hit_points: int = GameConstants.DEFAULT_DRAINED_HIT_POINTS
var _carry_weight: int = 0
var _current_carry_weight: int = GameConstants.DEFAULT_CURRENT_CARRY_WEIGHT
var _movement_speed: int = GameConstants.MOVEMENT_SPEED_LIGHT_LOAD
var armor: int = GameConstants.DEFAULT_ARMOR

var carry_weight: int:
	get:
		return _carry_weight

var current_carry_weight: int:
	get:
		return _current_carry_weight
	set(value):
		var clamped := maxi(value, 0)
		if _current_carry_weight != clamped:
			_current_carry_weight = clamped
			changed.emit(&"current_carry_weight")

var movement_speed: int:
	get:
		return _movement_speed

var level: int:
	get:
		return _level
	set(value):
		var clamped := maxi(value, 1)
		if _level != clamped:
			_level = clamped
			changed.emit(&"level")

var experience: int:
	get:
		return _experience
	set(value):
		var clamped := maxi(value, 0)
		if _experience != clamped:
			_experience = clamped
			changed.emit(&"experience")

var experience_to_level_up: int:
	get:
		return _experience_to_level_up

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
	hp = RangedStat.new(GameConstants.DEFAULT_HP, GameConstants.DEFAULT_HP_MAX, false)
	mana = RangedStat.new(GameConstants.DEFAULT_MANA, GameConstants.DEFAULT_MANA_MAX, false)
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


## Reverse speed multiplier: base_cost / (speed_percent / 100).
func get_time_cost(base_cost: int) -> int:
	return _speed_scaled_time_cost(base_cost, speed)


## Step cost uses character speed and movement speed as separate reverse multipliers.
func get_step_time_cost(base_cost: int) -> int:
	var after_speed := _speed_scaled_time_cost(base_cost, speed)
	return _speed_scaled_time_cost(after_speed, movement_speed)


## Attack cost uses character speed only.
func get_attack_time_cost(base_cost: int) -> int:
	return get_time_cost(base_cost)


## Attack power from strength; see GameConstants attack tuning constants.
func get_attack_value() -> int:
	var str := strength.current
	var str_delta := str - GameConstants.ATTACK_STRENGTH_REFERENCE
	var str_span := (
		GameConstants.ATTACK_HIGH_STRENGTH_REFERENCE
		- GameConstants.ATTACK_STRENGTH_REFERENCE
	)
	var damage_span := (
		GameConstants.ATTACK_DAMAGE_AT_HIGH_STRENGTH
		- GameConstants.ATTACK_DAMAGE_AT_REFERENCE
	)
	var scaled := float(str_delta) * float(damage_span) / float(str_span)
	return maxi(0, GameConstants.ATTACK_DAMAGE_AT_REFERENCE + int(round(scaled)))


static func calculate_hit_chance(attacker_dex: int, defender_dex: int) -> float:
	var dex_sum := attacker_dex + defender_dex
	if dex_sum <= 0:
		return 50.0
	var hit_chance := 100.0 * float(attacker_dex) / float(dex_sum)
	return clampf(hit_chance, 10.0, 95.0)


static func rolls_hit(attacker_dex: int, defender_dex: int) -> bool:
	return randf() * 100.0 < calculate_hit_chance(attacker_dex, defender_dex)


static func calculate_damage(attack: int, defender_armor: int) -> int:
	var base_damage := attack - defender_armor
	if base_damage <= 0:
		return randi() % 2
	return maxi(0, int(round(float(base_damage) * randf_range(0.9, 1.1))))


func _speed_scaled_time_cost(base_cost: int, speed_percent: int) -> int:
	if speed_percent <= 0:
		return maxi(GameConstants.ACTION_TIME_COST_MIN, base_cost)
	var scaled := float(base_cost) * 100.0 / float(speed_percent)
	return maxi(GameConstants.ACTION_TIME_COST_MIN, int(round(scaled)))


func recalculate_max_health() -> void:
	var health_ratio := _buffer_health_ratio()
	hp.set_max_unclamped(_calculate_max_health())
	recalculate_current_health(health_ratio)


func recalculate_current_health(health_ratio: float) -> void:
	hp.set_current_unclamped(int(round(float(hp.max_value) * health_ratio)))


func recalculate_max_mana() -> void:
	var mana_ratio := _buffer_mana_ratio()
	mana.set_max_unclamped(_calculate_max_mana())
	recalculate_current_mana(mana_ratio)


func recalculate_current_mana(mana_ratio: float) -> void:
	mana.set_current_unclamped(int(round(float(mana.max_value) * mana_ratio)))


func recalculate_carry_weight() -> void:
	var new_weight := _calculate_carry_weight()
	if _carry_weight != new_weight:
		_carry_weight = new_weight
		changed.emit(&"carry_weight")


func recalculate_movement_speed() -> void:
	var new_speed := _calculate_movement_speed()
	if _movement_speed != new_speed:
		_movement_speed = new_speed
		changed.emit(&"movement_speed")


func recalculate_experience_to_level_up(difficulty: int) -> void:
	var difficulty_var := Difficulty.get_multiplier(difficulty)
	var next_exp: int
	if level == 1:
		next_exp = 10 * difficulty_var
	else:
		var base := 20 + 20 * difficulty_var
		var scaled := float(base) * pow(2.0, float(level - 2))
		next_exp = int(min(scaled, float(GameConstants.MAX_EXPERIENCE_TO_LEVEL_UP)))
	next_exp = mini(next_exp, GameConstants.MAX_EXPERIENCE_TO_LEVEL_UP)
	if _experience_to_level_up != next_exp:
		_experience_to_level_up = next_exp
		changed.emit(&"experience_to_level_up")


func _buffer_health_ratio() -> float:
	if hp.max_value == 0:
		return 1.0
	return float(hp.current) / float(hp.max_value)


func _buffer_mana_ratio() -> float:
	if mana.max_value == 0:
		return 1.0
	return float(mana.current) / float(mana.max_value)


func _calculate_movement_speed() -> int:
	var load_ratio := _get_carry_load_ratio()
	var speed_percent: float
	if load_ratio <= 0.5:
		speed_percent = float(GameConstants.MOVEMENT_SPEED_LIGHT_LOAD)
	elif load_ratio <= 1.0:
		speed_percent = lerpf(
			float(GameConstants.MOVEMENT_SPEED_LIGHT_LOAD),
			float(GameConstants.MOVEMENT_SPEED_FULL_LOAD),
			(load_ratio - 0.5) / 0.5
		)
	else:
		speed_percent = 150.0 - 50.0 * load_ratio
	return maxi(GameConstants.MOVEMENT_SPEED_MIN, int(round(speed_percent)))


func _get_carry_load_ratio() -> float:
	if carry_weight <= 0:
		return 0.0
	return float(current_carry_weight) / float(carry_weight)


func _calculate_max_health() -> int:
	var con := constitution.current
	var numerator := con * (4 * level - 1) + GameConstants.HP_MAX_LEVEL_TERM * level + GameConstants.HP_MAX_BASE
	var denominator := 2 * level + GameConstants.HP_MAX_DEN_BASE
	return numerator / denominator - drained_hit_points


func _calculate_max_mana() -> int:
	var int_delta := intelligence.current - GameConstants.MANA_INTELLIGENCE_REFERENCE
	var level_term := _ceil_div((level - 1) * int_delta, GameConstants.MANA_LEVEL_DIVISOR)
	var int_term := _ceil_div(int_delta, GameConstants.MANA_INT_DIVISOR)
	return level_term + int_term


func _calculate_carry_weight() -> int:
	var str := strength.current
	var str_tier := str / GameConstants.CARRY_WEIGHT_STRENGTH_DIVISOR
	return (
		GameConstants.CARRY_WEIGHT_BASE
		+ str * GameConstants.CARRY_WEIGHT_PER_STRENGTH
		+ str_tier * str_tier * GameConstants.CARRY_WEIGHT_QUADRATIC_SCALE
	)


func _ceil_div(numerator: int, denominator: int) -> int:
	return ceili(float(numerator) / float(denominator))


func _connect_ranged_stat(stat: RangedStat, stat_name: StringName) -> void:
	stat.changed.connect(func() -> void: changed.emit(stat_name))
