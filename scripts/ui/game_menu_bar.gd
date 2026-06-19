class_name GameMenuBar
extends VBoxContainer

enum Action {
	NEW_GAME,
	LOAD,
	SAVE,
	SAVE_AS,
	OPTIONS,
	REVIEW_STORY,
	EXIT,
	CHARACTER,
	INVENTORY,
	MAP,
	SPELLBOOK,
	CUSTOMIZE_SPELL_MENU,
	VERB_GET,
	VERB_EXAMINE,
	VERB_FREE_HAND,
	VERB_SEARCH,
	VERB_DISARM_TRAP,
	VERB_REST_UNTIL_HEALED,
	VERB_SLEEP_UNTIL_MANA,
	VERB_OPEN,
	VERB_CLOSE,
	VERB_CLIMB_UP,
	VERB_CLIMB_DOWN,
	WINDOW_MOVE_VERTICAL,
	WINDOW_MOVE_HORIZONTAL,
	WINDOW_ARRANGE_ALL,
	HELP_CONTENTS,
	HELP_KEYBOARD,
	HELP_MOUSE,
	HELP_SPELL_DIRECTORY,
	HELP_OBJECT_DIRECTORY,
	HELP_BESTIARY,
	HELP_ON_HELP,
	HELP_HIGH_SCORES,
	HELP_ORDER_INFO,
	HELP_ABOUT,
}

const MENU_ITEM_HEIGHT := 24
const BAR_BG_COLOR := Color(0.925, 0.925, 0.925, 1.0)
const TEXT_COLOR := Color.BLACK
const TEXT_DISABLED_COLOR := Color(0.45, 0.45, 0.45, 1.0)
const HOVER_BG_COLOR := Color(0.82, 0.82, 0.82, 1.0)

@onready var _bar: HBoxContainer = %BarRow
@onready var _left_menus: HBoxContainer = %LeftMenus
@onready var _toolbar: GameToolbar = %Toolbar

var _input_handler: InputHandler
var _menu_theme: Theme


func setup(input_handler: InputHandler) -> void:
	_input_handler = input_handler
	_menu_theme = _create_menu_theme()
	theme = _menu_theme
	_build_menus()
	_toolbar.setup(input_handler, _menu_theme)


func _build_menus() -> void:
	_add_dropdown_menu("File", [
		{"text": "New Game", "id": Action.NEW_GAME},
		{"text": "Load...", "id": Action.LOAD},
		{"text": "Save", "id": Action.SAVE},
		{"text": "Save As...", "id": Action.SAVE_AS},
		{"text": "Options...", "id": Action.OPTIONS},
		{"text": "Review Story...", "id": Action.REVIEW_STORY},
		{"text": "Exit", "id": Action.EXIT},
	])
	_add_clickable_menu("Character!")
	_add_clickable_menu("Inventory!")
	_add_clickable_menu("Map!")
	_add_dropdown_menu("Spell", [
		{"text": "Spellbook...", "id": Action.SPELLBOOK},
		{"text": "Customize Spell Menu...", "id": Action.CUSTOMIZE_SPELL_MENU},
	])
	_add_inactive_dropdown_menu("Activate")
	_add_dropdown_menu("Verbs", [
		{"text": "Get", "id": Action.VERB_GET, "disabled": true},
		{"text": "Examine", "id": Action.VERB_EXAMINE},
		{"text": "Free Hand", "id": Action.VERB_FREE_HAND, "disabled": true},
		{"text": "Search", "id": Action.VERB_SEARCH},
		{"text": "Disarm Trap", "id": Action.VERB_DISARM_TRAP},
		{"text": "Rest Until Healed", "id": Action.VERB_REST_UNTIL_HEALED},
		{"text": "Sleep Until Mana Is Restored", "id": Action.VERB_SLEEP_UNTIL_MANA},
		{"text": "Open", "id": Action.VERB_OPEN},
		{"text": "Close", "id": Action.VERB_CLOSE},
		{"text": "< Climb Up Stairs", "id": Action.VERB_CLIMB_UP},
		{"text": "> Climb Down Stairs", "id": Action.VERB_CLIMB_DOWN},
	])
	_add_dropdown_menu("Window", [
		{"text": "Move Vertical", "id": Action.WINDOW_MOVE_VERTICAL},
		{"text": "Move Horizontal", "id": Action.WINDOW_MOVE_HORIZONTAL},
		{"text": "Arrange All", "id": Action.WINDOW_ARRANGE_ALL},
	])

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.add_child(spacer)

	_add_dropdown_menu("Help", [
		{"text": "Help Contents", "id": Action.HELP_CONTENTS},
		{"text": "Keyboard Commands", "id": Action.HELP_KEYBOARD},
		{"text": "Mouse Commands", "id": Action.HELP_MOUSE},
		{"text": "Spell Directory", "id": Action.HELP_SPELL_DIRECTORY},
		{"text": "Object Directory", "id": Action.HELP_OBJECT_DIRECTORY},
		{"text": "Bestiary", "id": Action.HELP_BESTIARY},
		{"text": "Help On Help", "id": Action.HELP_ON_HELP},
		{"text": "High Scores...", "id": Action.HELP_HIGH_SCORES},
		{"separator": true},
		{"text": "Order Information", "id": Action.HELP_ORDER_INFO},
		{"text": "About Castle of the Winds", "id": Action.HELP_ABOUT},
	], _bar)


func _add_dropdown_menu(
	label: String,
	items: Array,
	parent: Node = null,
) -> MenuButton:
	if parent == null:
		parent = _left_menus

	var button := MenuButton.new()
	button.text = label
	_style_menu_control(button)

	var popup := button.get_popup()
	_style_popup(popup)
	for item in items:
		if item.get("separator", false):
			popup.add_separator()
			continue
		popup.add_item(item["text"], item["id"])
		if item.get("disabled", false):
			popup.set_item_disabled(popup.item_count - 1, true)

	popup.id_pressed.connect(_on_menu_id_pressed)
	parent.add_child(button)
	return button


func _add_inactive_dropdown_menu(label: String) -> MenuButton:
	var button := _add_dropdown_menu(label, [])
	button.disabled = true
	return button


func _add_clickable_menu(label: String) -> Button:
	var button := Button.new()
	button.text = label
	_style_menu_control(button)
	button.pressed.connect(_on_clickable_menu_pressed.bind(label))
	_left_menus.add_child(button)
	return button


func _style_menu_control(control: BaseButton) -> void:
	control.flat = true
	control.focus_mode = Control.FOCUS_NONE
	control.custom_minimum_size.y = MENU_ITEM_HEIGHT
	control.theme = _menu_theme
	control.add_theme_color_override("font_color", TEXT_COLOR)
	control.add_theme_color_override("font_hover_color", TEXT_COLOR)
	control.add_theme_color_override("font_pressed_color", TEXT_COLOR)
	control.add_theme_color_override("font_disabled_color", TEXT_DISABLED_COLOR)


func _style_popup(popup: PopupMenu) -> void:
	popup.theme = _menu_theme


func _create_menu_theme() -> Theme:
	var menu_theme := Theme.new()

	var transparent := StyleBoxFlat.new()
	transparent.bg_color = Color.TRANSPARENT
	transparent.set_content_margin_all(4)

	var hover := StyleBoxFlat.new()
	hover.bg_color = HOVER_BG_COLOR
	hover.set_content_margin_all(4)

	var panel := StyleBoxFlat.new()
	panel.bg_color = BAR_BG_COLOR
	panel.set_border_width_all(1)
	panel.border_color = Color.BLACK
	panel.set_content_margin_all(2)

	for button_type in ["MenuButton", "Button"]:
		menu_theme.set_stylebox("normal", button_type, transparent)
		menu_theme.set_stylebox("hover", button_type, hover)
		menu_theme.set_stylebox("pressed", button_type, hover)
		menu_theme.set_stylebox("focus", button_type, transparent)
		menu_theme.set_color("font_color", button_type, TEXT_COLOR)
		menu_theme.set_color("font_hover_color", button_type, TEXT_COLOR)
		menu_theme.set_color("font_pressed_color", button_type, TEXT_COLOR)
		menu_theme.set_color("font_disabled_color", button_type, TEXT_DISABLED_COLOR)

	menu_theme.set_stylebox("panel", "PopupMenu", panel)
	menu_theme.set_stylebox("hover", "PopupMenu", hover)
	menu_theme.set_color("font_color", "PopupMenu", TEXT_COLOR)
	menu_theme.set_color("font_hover_color", "PopupMenu", TEXT_COLOR)
	menu_theme.set_color("font_accelerator_color", "PopupMenu", TEXT_COLOR)
	menu_theme.set_color("font_disabled_color", "PopupMenu", TEXT_DISABLED_COLOR)

	return menu_theme


func _on_clickable_menu_pressed(label: String) -> void:
	match label:
		"Character!":
			_on_menu_id_pressed(Action.CHARACTER)
		"Inventory!":
			_on_menu_id_pressed(Action.INVENTORY)
		"Map!":
			_on_menu_id_pressed(Action.MAP)


func _on_menu_id_pressed(id: int) -> void:
	match id:
		Action.EXIT:
			get_tree().quit()
		Action.VERB_SEARCH:
			if _input_handler:
				_input_handler.trigger_search()
		Action.VERB_EXAMINE:
			if _input_handler:
				_input_handler.trigger_examine_command()
		_:
			pass
