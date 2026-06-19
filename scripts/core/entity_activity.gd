class_name EntityActivity
extends RefCounted

var busy_until: int = 0
var pending_search: bool = false
var pending_completion_time: int = 0


func is_busy(current_time: int) -> bool:
	return busy_until > current_time


func has_pending_search() -> bool:
	return pending_search


func clear_pending() -> void:
	pending_search = false
	pending_completion_time = 0
