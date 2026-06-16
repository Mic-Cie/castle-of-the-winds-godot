class_name Player
extends Entity

var player_id: int = 0
var vision: PlayerVision


func _init(p_entity_id: int, p_player_id: int, p_position: Vector2i) -> void:
	super(p_entity_id, p_position)
	player_id = p_player_id
	entity_type = &"player"
