class_name CommandTool
extends RefCounted

enum Kind {
	NONE,
	EXAMINE,
	OPEN,
	CLOSE,
}

signal started(kind: Kind, label: String)
signal finished()
signal aborted()

var kind: Kind = Kind.NONE
var pending_label: String = ""
var grid_cursor: Vector2i = Vector2i.ZERO
var cursor_map_pixel: Vector2 = Vector2.ZERO

var _uses_mouse: bool = false


func is_active() -> bool:
	return kind != Kind.NONE


func start_examine(start_grid: Vector2i) -> void:
	_start(Kind.EXAMINE, MessageTemplates.COMMAND_LOOK, start_grid)


func start_open(start_grid: Vector2i) -> void:
	_start(Kind.OPEN, MessageTemplates.COMMAND_OPEN, start_grid)


func start_close(start_grid: Vector2i) -> void:
	_start(Kind.CLOSE, MessageTemplates.COMMAND_CLOSE, start_grid)


func _start(command_kind: Kind, label: String, start_grid: Vector2i) -> void:
	kind = command_kind
	pending_label = label
	grid_cursor = start_grid
	cursor_map_pixel = _grid_center_pixel(start_grid)
	_uses_mouse = false
	started.emit(kind, pending_label)


func get_cursor_map_pixel() -> Vector2:
	if _uses_mouse:
		return cursor_map_pixel
	return _grid_center_pixel(grid_cursor)


func get_target_grid() -> Vector2i:
	var pixel := get_cursor_map_pixel()
	return Vector2i(
		int(floor(pixel.x / GameConstants.TILE_SIZE)),
		int(floor(pixel.y / GameConstants.TILE_SIZE)),
	)


func move_grid_cursor(delta: Vector2i, map_width: int, map_height: int) -> void:
	_uses_mouse = false
	grid_cursor = Vector2i(
		clampi(grid_cursor.x + delta.x, 0, map_width - 1),
		clampi(grid_cursor.y + delta.y, 0, map_height - 1),
	)


func set_mouse_map_pixel(pixel: Vector2) -> void:
	_uses_mouse = true
	cursor_map_pixel = pixel


func complete() -> void:
	if not is_active():
		return
	_reset()
	finished.emit()


func abort() -> void:
	if not is_active():
		return
	_reset()
	aborted.emit()
	finished.emit()


func _reset() -> void:
	kind = Kind.NONE
	pending_label = ""
	_uses_mouse = false


static func _grid_center_pixel(grid: Vector2i) -> Vector2:
	var half := float(GameConstants.TILE_SIZE) / 2.0
	return Vector2(float(grid.x) * GameConstants.TILE_SIZE + half, float(grid.y) * GameConstants.TILE_SIZE + half)


static func create_cross_cursor() -> ImageTexture:
	const SIZE := 24
	const HALF := SIZE / 2
	const ARM := 8
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for i in range(HALF - ARM, HALF + ARM + 1):
		image.set_pixel(i, HALF, Color.BLACK)
		image.set_pixel(HALF, i, Color.BLACK)
	return ImageTexture.create_from_image(image)


static func cross_cursor_hotspot() -> Vector2:
	return Vector2(8, 8)
