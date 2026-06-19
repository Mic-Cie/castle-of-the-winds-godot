class_name ScrollableTextPanel
extends PanelContainer

const INITIAL_SCROLL_MAX_ATTEMPTS := 20

@onready var _scroll: ScrollContainer = %ScrollContainer
@onready var _scroll_content: Control = %ScrollContent
@onready var _message_clip: Control = %MessageClip
@onready var _message_label: RichTextLabel = %MessageLabel

var _lines: Array[String] = []
var _scroll_content_height: int = 0
var _initial_scroll_applied := false
var _initial_scroll_attempts := 0
var _last_viewport_size := Vector2i.ZERO


func _ready() -> void:
	_message_label.fit_content = false
	_message_label.scroll_active = false
	_message_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_scroll_content.clip_contents = true
	_message_clip.clip_contents = true
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	_scroll.resized.connect(_on_viewport_resized)


func set_scroll_content_height(height: int) -> void:
	if height <= 0:
		return
	var ratio := _get_scroll_ratio() if _initial_scroll_applied else 1.0
	_scroll_content_height = height
	_apply_scroll_content_size()
	_update_label_layout()
	if _initial_scroll_applied:
		_restore_scroll_ratio(ratio)
	else:
		ensure_initial_scroll()


func append_line(text: String) -> void:
	_lines.append(text)
	_trim_lines()
	_refresh_text()
	_update_label_layout()


func _trim_lines() -> void:
	while _lines.size() > GameConstants.MESSAGE_LOG_MAX_LINES:
		_lines.pop_front()


func _refresh_text() -> void:
	_message_label.text = "\n".join(_lines)


func _apply_scroll_content_size() -> void:
	var viewport_w := int(_scroll.size.x)
	var width := viewport_w if viewport_w > 0 else int(_scroll_content.custom_minimum_size.x)
	if width > 0:
		_scroll_content.custom_minimum_size = Vector2(width, _scroll_content_height)


func _update_label_layout() -> void:
	var line_h := _get_line_height()
	var text_h := maxi(_lines.size(), 1) * line_h
	var clip_h := _scroll_content_height if _scroll_content_height > 0 else text_h
	var width := int(_scroll.size.x)
	if width <= 0:
		width = int(_scroll_content.custom_minimum_size.x)
	if width <= 0:
		return

	_message_clip.custom_minimum_size = Vector2(width, clip_h)
	_message_label.custom_minimum_size = Vector2(width, text_h)
	_message_label.size = Vector2(width, text_h)
	_message_label.position = Vector2(0, clip_h - text_h)


func _get_line_height() -> int:
	var font := _message_label.get_theme_font("normal_font")
	var font_size := _message_label.get_theme_font_size("normal_font_size")
	if font:
		return maxi(1, int(ceil(font.get_height(font_size))))
	return 16


func _get_scroll_ratio() -> float:
	var bar := _scroll.get_v_scroll_bar()
	if bar.max_value <= 0.0:
		return 1.0
	return bar.value / bar.max_value


func _restore_scroll_ratio(ratio: float) -> void:
	var bar := _scroll.get_v_scroll_bar()
	if bar.max_value > 0.0:
		var target := ratio * bar.max_value
		bar.set_value_no_signal(target)
		_scroll.scroll_vertical = int(target)


func _scroll_to_bottom() -> bool:
	if _scroll_content_height <= 0:
		return false
	_apply_scroll_content_size()
	_update_label_layout()
	var bar := _scroll.get_v_scroll_bar()
	if bar.max_value <= 0.0:
		return false
	bar.value = bar.max_value
	_scroll.scroll_vertical = int(bar.max_value)
	return true


func ensure_initial_scroll() -> void:
	if _scroll_content_height <= 0 or _initial_scroll_applied:
		return
	_initial_scroll_attempts = 0
	call_deferred("_ensure_initial_scroll")


func _ensure_initial_scroll() -> void:
	if _initial_scroll_applied:
		return
	if _scroll_to_bottom():
		_initial_scroll_applied = true
		return
	_initial_scroll_attempts += 1
	if _initial_scroll_attempts >= INITIAL_SCROLL_MAX_ATTEMPTS:
		push_warning("ScrollableTextPanel: could not apply initial scroll-to-bottom.")
		return
	call_deferred("_ensure_initial_scroll")


func _on_viewport_resized() -> void:
	var size := Vector2i(int(_scroll.size.x), int(_scroll.size.y))
	var ratio := _get_scroll_ratio() if _initial_scroll_applied else 1.0
	var viewport_changed := size != _last_viewport_size
	_last_viewport_size = size

	if _scroll_content_height > 0:
		_apply_scroll_content_size()
	_update_label_layout()

	if not _initial_scroll_applied:
		ensure_initial_scroll()
		return

	if viewport_changed:
		call_deferred("_restore_scroll_ratio", ratio)
