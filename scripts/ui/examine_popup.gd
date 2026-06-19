class_name ExaminePopup
extends PanelContainer

var _label: Label


func _init() -> void:
	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_OFF


func _ready() -> void:
	add_child(_label)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_apply_style()
	_apply_label_theme()


func hide_popup() -> void:
	visible = false


func present(cursor_top_left: Vector2, text: String, bounds: Rect2) -> void:
	_label.text = text
	var content_size := _measure_content(text)
	_label.custom_minimum_size = content_size
	var box_size := _measure_box(content_size)
	custom_minimum_size = box_size
	size = box_size
	position = _resolve_position(cursor_top_left, box_size, bounds)
	visible = true


func _apply_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.border_width_left = GameConstants.EXAMINE_POPUP_BORDER_WIDTH
	style.border_width_top = GameConstants.EXAMINE_POPUP_BORDER_WIDTH
	style.border_width_right = GameConstants.EXAMINE_POPUP_BORDER_WIDTH
	style.border_width_bottom = GameConstants.EXAMINE_POPUP_BORDER_WIDTH
	style.border_color = Color.BLACK
	style.set_content_margin_all(GameConstants.EXAMINE_POPUP_PADDING)
	add_theme_stylebox_override("panel", style)


func _apply_label_theme() -> void:
	_label.add_theme_color_override("font_color", Color.BLACK)
	_label.add_theme_color_override("font_shadow_color", Color.BLACK)


func _measure_content(text: String) -> Vector2:
	var font := _label.get_theme_font("font")
	var font_size := _label.get_theme_font_size("font_size")
	if font == null:
		font = ThemeDB.fallback_font
		font_size = ThemeDB.fallback_font_size

	var lines := text.split("\n")
	var max_w := 0.0
	var line_h := font.get_height(font_size)
	for line in lines:
		var line_w := font.get_string_size(
			line,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size,
		).x
		max_w = maxf(max_w, line_w)

	return Vector2(max_w, line_h * maxi(lines.size(), 1))


func _measure_box(content_size: Vector2) -> Vector2:
	var pad := float(GameConstants.EXAMINE_POPUP_PADDING) * 2.0
	var border := float(GameConstants.EXAMINE_POPUP_BORDER_WIDTH) * 2.0
	return content_size + Vector2(pad + border, pad + border)


static func _resolve_position(cursor_top_left: Vector2, box_size: Vector2, bounds: Rect2) -> Vector2:
	var gap := float(GameConstants.EXAMINE_POPUP_CURSOR_GAP)
	var edge := float(GameConstants.EXAMINE_POPUP_EDGE_MARGIN)
	var cursor_size := Vector2(GameConstants.EXAMINE_POPUP_CURSOR_SIZE)
	var inner := Rect2(
		bounds.position + Vector2(edge, edge),
		bounds.size - Vector2(edge * 2.0, edge * 2.0),
	)
	if inner.size.x <= 0.0 or inner.size.y <= 0.0:
		inner = bounds

	var candidates: Array[Vector2] = [
		Vector2(cursor_top_left.x, cursor_top_left.y - gap - box_size.y),
		Vector2(cursor_top_left.x, cursor_top_left.y + cursor_size.y + gap),
		Vector2(cursor_top_left.x - gap - box_size.x, cursor_top_left.y - gap - box_size.y),
		Vector2(cursor_top_left.x + cursor_size.x + gap, cursor_top_left.y - gap - box_size.y),
	]

	for pos in candidates:
		if inner.encloses(Rect2(pos, box_size)):
			return pos

	return _clamp_rect(Rect2(candidates[0], box_size), inner).position


static func _clamp_rect(rect: Rect2, bounds: Rect2) -> Rect2:
	var pos := rect.position
	if rect.size.x > bounds.size.x:
		pos.x = bounds.position.x
	else:
		pos.x = clampf(pos.x, bounds.position.x, bounds.end.x - rect.size.x)
	if rect.size.y > bounds.size.y:
		pos.y = bounds.position.y
	else:
		pos.y = clampf(pos.y, bounds.position.y, bounds.end.y - rect.size.y)
	return Rect2(pos, rect.size)
