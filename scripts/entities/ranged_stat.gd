class_name RangedStat
extends RefCounted

signal changed

var current: int:
	get:
		return _current
	set(value):
		set_current_clamped(value)


var _current: int = 0
var _max_value: int = 0
var _clamp_current: bool = true


func _init(p_current: int = 0, p_max: int = 0, p_clamp_current: bool = true) -> void:
	_clamp_current = p_clamp_current
	_set_max_value(p_max, true)
	_current = _clamp_current_to_max(p_current) if _clamp_current else p_current


func set_current_clamped(value: int) -> void:
	var new_value := _clamp_current_to_max(value) if _clamp_current else value
	if _current != new_value:
		_current = new_value
		changed.emit()


func set_current_unclamped(value: int) -> void:
	if _current != value:
		_current = value
		changed.emit()


var max_value: int:
	get:
		return _max_value
	set(value):
		_set_max_value(value, false)


func set_max_unclamped(value: int) -> void:
	if _max_value != value:
		_max_value = value
		changed.emit()


func _set_max_value(value: int, allow_negative: bool) -> void:
	var new_max := value if allow_negative else maxi(value, 0)
	if _max_value != new_max:
		_max_value = new_max
		if _clamp_current:
			_current = _clamp_current_to_max(_current)
		changed.emit()


func _clamp_current_to_max(value: int) -> int:
	if _max_value >= 0:
		return clampi(value, 0, _max_value)
	return clampi(value, _max_value, 0)
