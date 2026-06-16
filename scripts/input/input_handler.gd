class_name InputHandler
extends Node

const SearchCommand = preload("res://scripts/core/search_command.gd")

## Reads local input and produces commands. In multiplayer, only the owning client
## runs this for their player; commands are sent to the server for validation.

var local_player_id: int = 0
var _world: GameWorld
var _game_view: GameView
var _get_local_entity_id: Callable
var _held_direction: Vector2i = Vector2i.ZERO
var _hold_time: float = 0.0
var _repeat_time: float = 0.0
var _initial_delay_done: bool = false
var _dragging_hero: bool = false


func setup(world: GameWorld, get_local_entity_id: Callable, game_view: GameView) -> void:
	_world = world
	_get_local_entity_id = get_local_entity_id
	_game_view = game_view
	_game_view.connect_viewport_input(_on_viewport_gui_input)
	set_process(true)


func _unhandled_input(event: InputEvent) -> void:
	if _world == null:
		return

	if event.is_action_pressed("search") and not event.is_echo():
		get_viewport().set_input_as_handled()
		trigger_search()
		return

	var direction := _direction_from_event(event)
	if direction == Vector2i.ZERO:
		return

	if event.is_pressed():
		if event.is_echo():
			return
		_stop_drag()
		get_viewport().set_input_as_handled()
		_start_hold(direction)
		_try_move(direction)
	elif not event.is_pressed():
		if direction == _held_direction:
			_clear_hold()


func _process(delta: float) -> void:
	if _dragging_hero:
		_process_drag(delta)
	elif _held_direction != Vector2i.ZERO:
		_process_keyboard_hold(delta)


func _process_keyboard_hold(delta: float) -> void:
	if not _is_direction_held(_held_direction):
		_clear_hold()
		return
	_process_keyboard_hold_timing(delta)


func _process_drag(delta: float) -> void:
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_stop_drag()
		return

	var cursor_map := _game_view.get_viewport_local_mouse_map_pixel()
	if _is_cursor_on_blocked_tile(cursor_map):
		_clear_hold()
		return

	var hero_pos := _get_hero_grid_position()
	var direction := _direction_from_map_pixel(cursor_map, hero_pos)
	if direction == Vector2i.ZERO:
		_clear_hold()
		return

	if not _can_move_in_direction(direction, false):
		_clear_hold()
		return

	if direction != _held_direction:
		_start_hold(direction)
		_try_move(direction, false)
		return

	_process_drag_repeat(delta)


func _on_viewport_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed:
				if _is_click_on_hero(mouse.position):
					_dragging_hero = true
					_clear_hold()
					_game_view.accept_viewport_input()
				elif _try_toggle_door_at(_game_view.viewport_local_to_map_grid(mouse.position)):
					_stop_drag()
					_game_view.accept_viewport_input()
				return
			if _dragging_hero:
				_stop_drag()
				_game_view.accept_viewport_input()
		elif mouse.button_index == MOUSE_BUTTON_RIGHT and mouse.pressed:
			if GameView.DEBUG_CLICK_MAP:
				var map_pos := _game_view.viewport_local_to_map_grid(mouse.position)
				print("[MapClick] coordinates=(%d, %d)" % [map_pos.x, map_pos.y])
				_game_view.accept_viewport_input()


func _stop_drag() -> void:
	_dragging_hero = false
	_clear_hold()


func _start_hold(direction: Vector2i) -> void:
	_held_direction = direction
	_hold_time = 0.0
	_repeat_time = 0.0
	_initial_delay_done = false


func _clear_hold() -> void:
	_held_direction = Vector2i.ZERO
	_hold_time = 0.0
	_repeat_time = 0.0
	_initial_delay_done = false


func _process_keyboard_hold_timing(delta: float) -> void:
	_hold_time += delta
	if _hold_time < GameConstants.MOVE_HOLD_INITIAL_DELAY:
		return

	if not _initial_delay_done:
		_initial_delay_done = true
		_repeat_time = 0.0
		_try_move(_held_direction, _dragging_hero)

	_process_drag_repeat(delta)


func _process_drag_repeat(delta: float) -> void:
	_repeat_time += delta
	if _repeat_time < GameConstants.MOVE_HOLD_REPEAT_INTERVAL:
		return

	_repeat_time -= GameConstants.MOVE_HOLD_REPEAT_INTERVAL
	_try_move(_held_direction, _dragging_hero)


func trigger_search() -> void:
	_stop_drag()
	_try_search()


func _try_search() -> void:
	var entity_id: int = _get_local_entity_id.call()
	if entity_id < 0:
		return
	_world.process_command(SearchCommand.new(entity_id))


func _try_move(direction: Vector2i, check_fog: bool = true) -> void:
	var entity_id: int = _get_local_entity_id.call()
	if entity_id < 0:
		return
	if not _can_move_in_direction(direction, check_fog):
		return
	_world.process_command(MoveCommand.new(entity_id, direction))


func _can_move_in_direction(direction: Vector2i, check_fog: bool = true) -> bool:
	var entity := _get_hero_entity()
	if entity == null:
		return false
	var target := entity.grid_position + direction
	if not _world.game_map.can_step_onto(target):
		return false
	if check_fog and entity is Player:
		var player := entity as Player
		if not player.vision.is_uncovered(target):
			return false
	return true


func _is_click_on_hero(viewport_local: Vector2) -> bool:
	var entity := _get_hero_entity()
	if entity == null:
		return false
	var cursor_map := _game_view.viewport_local_to_map_pixel(viewport_local)
	var hero_pos := entity.grid_position
	var tile_size := float(GameConstants.TILE_SIZE)
	var left := float(hero_pos.x) * tile_size
	var top := float(hero_pos.y) * tile_size
	return (
		cursor_map.x >= left
		and cursor_map.x < left + tile_size
		and cursor_map.y >= top
		and cursor_map.y < top + tile_size
	)


func _is_cursor_on_blocked_tile(cursor_map: Vector2) -> bool:
	var grid := Vector2i(
		int(floor(cursor_map.x / GameConstants.TILE_SIZE)),
		int(floor(cursor_map.y / GameConstants.TILE_SIZE)),
	)
	if not GridPosition.is_in_bounds(grid, _world.game_map.width, _world.game_map.height):
		return true
	if not _world.game_map.can_step_onto(grid):
		return true
	return false


func _try_toggle_door_at(pos: Vector2i) -> bool:
	var entity_id: int = _get_local_entity_id.call()
	if entity_id < 0:
		return false
	return _world.try_toggle_door(pos, entity_id)


func _get_hero_entity() -> Entity:
	var entity_id: int = _get_local_entity_id.call()
	if entity_id < 0:
		return null
	return _world.get_entity(entity_id)


func _get_hero_grid_position() -> Vector2i:
	var entity := _get_hero_entity()
	if entity == null:
		return Vector2i.ZERO
	return entity.grid_position


static func _direction_from_map_pixel(cursor_map: Vector2, hero_grid: Vector2i) -> Vector2i:
	var tile_size := float(GameConstants.TILE_SIZE)
	var half := tile_size / 2.0
	var left := float(hero_grid.x) * tile_size
	var top := float(hero_grid.y) * tile_size
	var right := left + tile_size
	var bottom := top + tile_size

	var east := maxf(0.0, cursor_map.x - right)
	var west := maxf(0.0, left - cursor_map.x)
	var south := maxf(0.0, cursor_map.y - bottom)
	var north := maxf(0.0, top - cursor_map.y)

	if south > 0.0 and east > 0.0 and (south >= half or east >= half):
		return Vector2i(1, 1)
	if south > 0.0 and west > 0.0 and (south >= half or west >= half):
		return Vector2i(-1, 1)
	if north > 0.0 and east > 0.0 and (north >= half or east >= half):
		return Vector2i(1, -1)
	if north > 0.0 and west > 0.0 and (north >= half or west >= half):
		return Vector2i(-1, -1)

	if south >= half:
		return Vector2i(0, 1)
	if north >= half:
		return Vector2i(0, -1)
	if east >= half:
		return Vector2i(1, 0)
	if west >= half:
		return Vector2i(-1, 0)

	return Vector2i.ZERO


func _direction_from_event(event: InputEvent) -> Vector2i:
	if event.is_action("move_up"):
		return Vector2i(0, -1)
	if event.is_action("move_down"):
		return Vector2i(0, 1)
	if event.is_action("move_left"):
		return Vector2i(-1, 0)
	if event.is_action("move_right"):
		return Vector2i(1, 0)
	if event.is_action("move_up_left"):
		return Vector2i(-1, -1)
	if event.is_action("move_up_right"):
		return Vector2i(1, -1)
	if event.is_action("move_down_left"):
		return Vector2i(-1, 1)
	if event.is_action("move_down_right"):
		return Vector2i(1, 1)
	return Vector2i.ZERO


func _is_direction_held(direction: Vector2i) -> bool:
	match direction:
		Vector2i(0, -1):
			return Input.is_action_pressed("move_up")
		Vector2i(0, 1):
			return Input.is_action_pressed("move_down")
		Vector2i(-1, 0):
			return Input.is_action_pressed("move_left")
		Vector2i(1, 0):
			return Input.is_action_pressed("move_right")
		Vector2i(-1, -1):
			return Input.is_action_pressed("move_up_left")
		Vector2i(-1, 1):
			return Input.is_action_pressed("move_down_left")
		Vector2i(1, -1):
			return Input.is_action_pressed("move_up_right")
		Vector2i(1, 1):
			return Input.is_action_pressed("move_down_right")
		_:
			return false
