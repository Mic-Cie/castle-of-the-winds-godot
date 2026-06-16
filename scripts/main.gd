extends Control

@onready var _game_view: GameView = %GameView
@onready var _input_handler: InputHandler = %InputHandler
@onready var _menu_bar: GameMenuBar = %MenuBar


func _ready() -> void:
	_input_handler.setup(
		_game_view.world,
		_game_view.get_local_player_entity_id,
		_game_view,
	)
	_menu_bar.setup(_input_handler)
