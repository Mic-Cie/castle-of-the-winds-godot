class_name RangedStat
extends RefCounted

signal changed

var current: int:
	get:
		return _current
	set(value):
		var clamped := clampi(value, 0, max_value)
		if _current != clamped:
			_current = clamped
			changed.emit()

var max_value: int:
	get:
		return _max_value
	set(value):
		var clamped := maxi(value, 0)
		if _max_value != clamped:
			_max_value = clamped
			if _current > _max_value:
				_current = _max_value
			changed.emit()

var _current: int = 0
var _max_value: int = 0


func _init(p_current: int = 0, p_max: int = 0) -> void:
	_max_value = maxi(p_max, 0)
	_current = clampi(p_current, 0, _max_value)
