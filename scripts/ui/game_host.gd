extends Control

## Keeps the split child minimum independent from the nested game viewport size.
func _get_minimum_size() -> Vector2:
	return custom_minimum_size
