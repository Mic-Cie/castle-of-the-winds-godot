class_name DoorState
extends RefCounted

enum State {
	NONE,
	CLOSED,
	OPEN,
	DESTROYED,
	HIDDEN,
}


static func is_visible(state: int) -> bool:
	return state == State.CLOSED or state == State.OPEN or state == State.DESTROYED


static func blocks_movement(state: int) -> bool:
	return state == State.CLOSED or state == State.HIDDEN
