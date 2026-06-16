class_name ScrollController
extends RefCounted

signal scroll_changed(scroll_offset: Vector2i)

var scroll_offset: Vector2i = Vector2i.ZERO
var visible_tiles: Vector2i = Vector2i(
	GameConstants.DEFAULT_VISIBLE_TILES,
	GameConstants.DEFAULT_VISIBLE_TILES,
)
var map_size: Vector2i = Vector2i.ZERO
var margin_tiles: int = GameConstants.SCROLL_MARGIN_TILES


func setup(p_map_size: Vector2i) -> void:
	map_size = p_map_size
	scroll_offset = Vector2i.ZERO
	_clamp_scroll()


func set_visible_tiles(p_visible_tiles: Vector2i) -> void:
	visible_tiles = Vector2i(
		maxi(p_visible_tiles.x, 1),
		maxi(p_visible_tiles.y, 1),
	)
	_clamp_scroll()
	scroll_changed.emit(scroll_offset)


func set_scroll_offset(offset: Vector2i) -> void:
	scroll_offset = offset
	_clamp_scroll()
	scroll_changed.emit(scroll_offset)


func on_entity_moved(position: Vector2i) -> void:
	var inner_min := scroll_offset + Vector2i(margin_tiles, margin_tiles)
	var inner_max := scroll_offset + visible_tiles - Vector2i(margin_tiles + 1, margin_tiles + 1)

	var outside_x := position.x < inner_min.x or position.x > inner_max.x
	var outside_y := position.y < inner_min.y or position.y > inner_max.y

	if not outside_x and not outside_y:
		return

	var centered := _center_on(position)
	var new_offset := scroll_offset

	if outside_x:
		new_offset.x = centered.x
	if outside_y:
		new_offset.y = centered.y

	set_scroll_offset(new_offset)


func _center_on(position: Vector2i) -> Vector2i:
	var offset := position - visible_tiles / 2
	var max_scroll := get_scroll_max()
	offset.x = clampi(offset.x, 0, max_scroll.x)
	offset.y = clampi(offset.y, 0, max_scroll.y)
	return offset


func get_scroll_max() -> Vector2i:
	return Vector2i(
		maxi(map_size.x - visible_tiles.x, 0),
		maxi(map_size.y - visible_tiles.y, 0),
	)


func _clamp_scroll() -> void:
	var max_scroll := get_scroll_max()
	scroll_offset.x = clampi(scroll_offset.x, 0, max_scroll.x)
	scroll_offset.y = clampi(scroll_offset.y, 0, max_scroll.y)
