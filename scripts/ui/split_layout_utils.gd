class_name SplitLayoutUtils
extends RefCounted

static func split_axis_size(split: SplitContainer) -> int:
	return int(split.size.y if split.vertical else split.size.x)


static func default_dragger_position(split: SplitContainer) -> int:
	var total := split_axis_size(split)
	if total <= 0:
		return 0
	var sep := split.get_theme_constant("separation", "SplitContainer")
	# Godot's two-child expanded default places the dragger near the center.
	return int(total * 0.5 - sep * 0.5)


static func split_offset_to_absolute(split: SplitContainer, offset: int) -> int:
	return default_dragger_position(split) + offset


static func absolute_to_split_offset(split: SplitContainer, absolute_pos: int) -> int:
	return absolute_pos - default_dragger_position(split)


static func get_split_offset(split: SplitContainer) -> int:
	var offsets := split.get_split_offsets()
	if offsets.is_empty():
		return 0
	return offsets[0]


static func set_split_offset(split: SplitContainer, offset: int) -> void:
	split.set_split_offsets(PackedInt32Array([offset]))
