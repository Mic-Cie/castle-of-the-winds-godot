class_name ScrollableTextPanel
extends PanelContainer

@onready var _scroll: ScrollContainer = %ScrollContainer
@onready var _text_label: RichTextLabel = %TextLabel
@onready var _h_scroll: HScrollBar = %HScroll
@onready var _v_scroll: VScrollBar = %VScroll


func _ready() -> void:
	_text_label.fit_content = true
	_text_label.scroll_active = false
	_text_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_scroll.resized.connect(_update_scrollbars)
	_text_label.resized.connect(_update_scrollbars)
	call_deferred("_setup_scrollbars")


func _setup_scrollbars() -> void:
	var inner_h := _scroll.get_h_scroll_bar()
	var inner_v := _scroll.get_v_scroll_bar()
	inner_h.hide()
	inner_v.hide()
	_h_scroll.value_changed.connect(func(value: float) -> void:
		inner_h.value = value
	)
	_v_scroll.value_changed.connect(func(value: float) -> void:
		inner_v.value = value
	)
	inner_h.value_changed.connect(func(value: float) -> void:
		_h_scroll.set_value_no_signal(value)
	)
	inner_v.value_changed.connect(func(value: float) -> void:
		_v_scroll.set_value_no_signal(value)
	)
	inner_h.changed.connect(_update_scrollbars)
	inner_v.changed.connect(_update_scrollbars)
	_update_scrollbars()


func _update_scrollbars() -> void:
	var inner_h := _scroll.get_h_scroll_bar()
	var inner_v := _scroll.get_v_scroll_bar()
	_copy_scrollbar_range(_h_scroll, inner_h)
	_copy_scrollbar_range(_v_scroll, inner_v)


func _copy_scrollbar_range(target: ScrollBar, source: ScrollBar) -> void:
	target.min_value = source.min_value
	target.max_value = source.max_value
	target.page = source.page
	target.step = source.step
	target.set_value_no_signal(source.value)


func append_text(text: String) -> void:
	_text_label.append_text(text)
	call_deferred("_update_scrollbars")
