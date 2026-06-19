class_name GameToolbar
extends PanelContainer

const TEXT_SECTION_MARGIN := 8
const ICON_SPRITE_SIZE := 16
const ICON_BUTTON_SIZE := 24
const TOOLBAR_ITEM_HEIGHT := 24
const TEXT_BUTTON_SEPARATION := 2
const TOOLBAR_VERTICAL_PADDING := 4

const TEXT_BUTTONS: Array[String] = [
	"Get",
	"Free Hand",
	"Search",
	"Disarm",
	"Rest",
	"Save",
]

@onready var _text_buttons: HBoxContainer = %TextButtons
@onready var _icon_buttons: HBoxContainer = %IconButtons
@onready var _toolbar_row: HBoxContainer = $ToolbarRow

var _input_handler: InputHandler


func setup(input_handler: InputHandler, _menu_theme: Theme) -> void:
	_input_handler = input_handler
	custom_minimum_size.y = ICON_BUTTON_SIZE + TOOLBAR_VERTICAL_PADDING * 2
	_toolbar_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	_text_buttons.add_theme_constant_override("separation", TEXT_BUTTON_SEPARATION)
	_icon_buttons.add_theme_constant_override("separation", TEXT_BUTTON_SEPARATION)
	_build_toolbar()


func _build_toolbar() -> void:
	for label in TEXT_BUTTONS:
		var button := Button.new()
		button.text = label
		_style_text_button(button)
		if label == "Get":
			button.pressed.connect(_on_get_pressed)
		elif label == "Search":
			button.pressed.connect(_on_search_pressed)
		_text_buttons.add_child(button)

	for _i in range(10):
		var button := Button.new()
		_style_icon_button(button)
		_icon_buttons.add_child(button)


func _style_text_button(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = TOOLBAR_ITEM_HEIGHT
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_apply_button_font_colors(button)
	_apply_toolbar_button_styles(button, 8, 3)


func _style_icon_button(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(ICON_BUTTON_SIZE, ICON_BUTTON_SIZE)
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_apply_button_font_colors(button)
	var padding := (ICON_BUTTON_SIZE - ICON_SPRITE_SIZE) / 2
	_apply_toolbar_button_styles(button, padding, padding)


func _apply_button_font_colors(button: Button) -> void:
	button.add_theme_color_override("font_color", GameMenuBar.TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", GameMenuBar.TEXT_COLOR)
	button.add_theme_color_override("font_pressed_color", GameMenuBar.TEXT_COLOR)
	button.add_theme_color_override("font_disabled_color", GameMenuBar.TEXT_DISABLED_COLOR)


func _apply_toolbar_button_styles(button: Button, margin_h: int, margin_v: int) -> void:
	var normal := _make_raised_style(Color(0.97, 0.97, 0.97))
	normal.set_content_margin(SIDE_LEFT, margin_h)
	normal.set_content_margin(SIDE_RIGHT, margin_h)
	normal.set_content_margin(SIDE_TOP, margin_v)
	normal.set_content_margin(SIDE_BOTTOM, margin_v)

	var hover := _make_raised_style(GameMenuBar.HOVER_BG_COLOR)
	hover.set_content_margin(SIDE_LEFT, margin_h)
	hover.set_content_margin(SIDE_RIGHT, margin_h)
	hover.set_content_margin(SIDE_TOP, margin_v)
	hover.set_content_margin(SIDE_BOTTOM, margin_v)

	var pressed := _make_sunken_style(Color(0.78, 0.78, 0.78))
	pressed.set_content_margin(SIDE_LEFT, margin_h)
	pressed.set_content_margin(SIDE_RIGHT, margin_h)
	pressed.set_content_margin(SIDE_TOP, margin_v)
	pressed.set_content_margin(SIDE_BOTTOM, margin_v)

	_set_button_styles(button, normal, hover, pressed)


func _make_raised_style(bg_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_width_top = 1
	style.border_width_left = 1
	style.border_width_bottom = 2
	style.border_width_right = 2
	style.border_color = Color(0.95, 0.95, 0.95)
	style.shadow_size = 1
	style.shadow_offset = Vector2(1, 1)
	style.shadow_color = Color(0.35, 0.35, 0.35)
	return style


func _make_sunken_style(bg_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_bottom = 1
	style.border_width_right = 1
	style.border_color = Color(0.35, 0.35, 0.35)
	return style


func _set_button_styles(
	button: Button,
	normal: StyleBoxFlat,
	hover: StyleBoxFlat,
	pressed: StyleBoxFlat,
) -> void:
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", normal)


func _on_get_pressed() -> void:
	if _input_handler:
		_input_handler.trigger_get()


func _on_search_pressed() -> void:
	if _input_handler:
		_input_handler.trigger_search()
