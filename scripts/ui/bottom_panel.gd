class_name BottomPanel
extends PanelContainer

const MIN_HEIGHT := 80
const MAX_HEIGHT_RATIO := 0.5
const MIN_LOG_WIDTH := 160
const MIN_STATS_WIDTH := 100
const MAX_STATS_WIDTH_RATIO := 0.5
const DEFAULT_LOG_WIDTH_RATIO := 0.75

@onready var _h_split: HSplitContainer = %HSplit
@onready var _scroll_panel: ScrollableTextPanel = %ScrollPanel
@onready var _stats_panel: PanelContainer = %StatsPanel
@onready var _hp_value: Label = %HpValue
@onready var _mana_value: Label = %ManaValue
@onready var _speed_value: Label = %SpeedValue

var _initial_h_split_set := false
var _stats: CharacterStats


func _ready() -> void:
	custom_minimum_size.y = MIN_HEIGHT
	_scroll_panel.custom_minimum_size = Vector2(MIN_LOG_WIDTH, 0)
	_stats_panel.custom_minimum_size = Vector2(MIN_STATS_WIDTH, 0)

	_h_split.dragged.connect(_on_h_split_dragged)
	_h_split.drag_area_margin_begin = 4
	_h_split.drag_area_margin_end = 4
	call_deferred("_initialize_h_split")


func bind_stats(stats: CharacterStats) -> void:
	if _stats and _stats.changed.is_connected(_on_stats_changed):
		_stats.changed.disconnect(_on_stats_changed)
	_stats = stats
	if _stats:
		_stats.changed.connect(_on_stats_changed)
		_refresh_stats()


func get_required_minimum_height() -> int:
	return maxi(MIN_HEIGHT, int(get_combined_minimum_size().y))


func get_max_height_for_total(total_height: int) -> int:
	return int(total_height * MAX_HEIGHT_RATIO)


func _initialize_h_split() -> void:
	if _h_split.size.x <= 0:
		call_deferred("_initialize_h_split")
		return
	if _initial_h_split_set:
		return
	var target_log_w := _default_log_width()
	SplitLayoutUtils.set_split_offset(
		_h_split,
		SplitLayoutUtils.absolute_to_split_offset(_h_split, target_log_w)
	)
	_initial_h_split_set = true
	_clamp_h_split()


func _on_h_split_dragged(offset: int) -> void:
	var absolute_log_w := SplitLayoutUtils.split_offset_to_absolute(_h_split, offset)
	var clamped_log_w := clampi(absolute_log_w, _min_log_width(), _max_log_width())
	if clamped_log_w != absolute_log_w:
		SplitLayoutUtils.set_split_offset(
			_h_split,
			SplitLayoutUtils.absolute_to_split_offset(_h_split, clamped_log_w)
		)


func _default_log_width() -> int:
	return maxi(int(_h_split.size.x * DEFAULT_LOG_WIDTH_RATIO), MIN_LOG_WIDTH)


func _min_log_width() -> int:
	if _h_split.size.x <= 0:
		return MIN_LOG_WIDTH
	var total := int(_h_split.size.x)
	return maxi(MIN_LOG_WIDTH, total - int(total * MAX_STATS_WIDTH_RATIO))


func _max_log_width() -> int:
	if _h_split.size.x <= 0:
		return MIN_LOG_WIDTH
	return int(_h_split.size.x) - MIN_STATS_WIDTH


func _on_stats_changed(_stat_name: StringName = &"") -> void:
	_refresh_stats()


func _refresh_stats() -> void:
	if _stats == null:
		return
	_hp_value.text = "%d (%d)" % [_stats.hp.current, _stats.hp.max_value]
	_mana_value.text = "%d (%d)" % [_stats.mana.current, _stats.mana.max_value]
	_speed_value.text = "%d%% / %d%%" % [_stats.speed, _stats.get_movement_speed()]


func _clamp_h_split() -> void:
	if _h_split.size.x <= 0:
		return
	var min_log := _min_log_width()
	var max_log := _max_log_width()
	if min_log > max_log:
		min_log = max_log
	var before_offset := SplitLayoutUtils.get_split_offset(_h_split)
	var before_log_w := SplitLayoutUtils.split_offset_to_absolute(_h_split, before_offset)
	var after_log_w := clampi(before_log_w, min_log, max_log)
	if before_log_w != after_log_w:
		SplitLayoutUtils.set_split_offset(
			_h_split,
			SplitLayoutUtils.absolute_to_split_offset(_h_split, after_log_w)
		)
