class_name RangedStat
extends RefCounted

signal changed

var current: int:
	get:
		return _current
	set(value):
		var clamped := _clamp_current_to_max(value)
		if _current != clamped:
			_current = clamped
			changed.emit()

var max_value: int:
	get:
		return _max_value
	set(value):
		_set_max_value(value, false)


func set_max_unclamped(value: int) -> void:
	_set_max_value(value, true)

var _current: int = 0
var _max_value: int = 0


func _init(p_current: int = 0, p_max: int = 0) -> void:
	_set_max_value(p_max, true)
	_current = _clamp_current_to_max(p_current)


func _set_max_value(value: int, allow_negative: bool) -> void:
	var new_max := value if allow_negative else maxi(value, 0)
	if _max_value != new_max:
		_max_value = new_max
		_current = _clamp_current_to_max(_current)
		changed.emit()


func _clamp_current_to_max(value: int) -> int:
	if _max_value >= 0:
		return clampi(value, 0, _max_value)
	return clampi(value, _max_value, 0)
