extends Control

const GAME_MIN_HEIGHT := 200
const DEFAULT_BOTTOM_HEIGHT_RATIO := 0.2

@onready var _game_host: Control = %GameHost
@onready var _game_view: GameView = %GameView
@onready var _input_handler: InputHandler = %InputHandler
@onready var _menu_bar: GameMenuBar = %MenuBar
@onready var _content_split: VSplitContainer = %ContentSplit
@onready var _bottom_panel: BottomPanel = %BottomPanel

var _initial_v_split_set := false


func _ready() -> void:
	_game_host.custom_minimum_size.y = GAME_MIN_HEIGHT
	_bottom_panel.custom_minimum_size.y = _bottom_panel.get_required_minimum_height()

	_content_split.dragged.connect(_on_content_split_dragged)
	resized.connect(_on_resized)
	call_deferred("_initialize_content_split")

	_input_handler.setup(
		_game_view.world,
		_game_view.get_local_player_entity_id,
		_game_view,
	)
	_menu_bar.setup(_input_handler)


func _on_resized() -> void:
	if not _initial_v_split_set:
		return
	call_deferred("_clamp_v_split")


func _initialize_content_split() -> void:
	if _content_split.size.y <= 0:
		call_deferred("_initialize_content_split")
		return
	if not _initial_v_split_set:
		var target_top := _default_top_height()
		SplitLayoutUtils.set_split_offset(
			_content_split,
			SplitLayoutUtils.absolute_to_split_offset(_content_split, target_top)
		)
		_initial_v_split_set = true
	_clamp_v_split()


func _on_content_split_dragged(offset: int) -> void:
	var absolute_top := SplitLayoutUtils.split_offset_to_absolute(_content_split, offset)
	var clamped_top := clampi(absolute_top, _min_top_height(), _max_top_height())
	if clamped_top != absolute_top:
		SplitLayoutUtils.set_split_offset(
			_content_split,
			SplitLayoutUtils.absolute_to_split_offset(_content_split, clamped_top)
		)


func _default_top_height() -> int:
	return int(_content_split.size.y * (1.0 - DEFAULT_BOTTOM_HEIGHT_RATIO))


func _min_top_height() -> int:
	var total := int(_content_split.size.y)
	if total <= 0:
		return GAME_MIN_HEIGHT
	var max_bottom := _bottom_panel.get_max_height_for_total(total)
	return maxi(GAME_MIN_HEIGHT, total - max_bottom)


func _max_top_height() -> int:
	var total := int(_content_split.size.y)
	if total <= 0:
		return GAME_MIN_HEIGHT
	return total - _bottom_panel.get_required_minimum_height()


func _clamp_v_split() -> void:
	if _content_split.size.y <= 0:
		return
	var min_top := _min_top_height()
	var max_top := _max_top_height()
	if min_top > max_top:
		min_top = max_top
	var before_offset := SplitLayoutUtils.get_split_offset(_content_split)
	var before_top := SplitLayoutUtils.split_offset_to_absolute(_content_split, before_offset)
	var after_top := clampi(before_top, min_top, max_top)
	if before_top != after_top:
		SplitLayoutUtils.set_split_offset(
			_content_split,
			SplitLayoutUtils.absolute_to_split_offset(_content_split, after_top)
		)
