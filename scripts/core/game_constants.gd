class_name GameConstants
extends RefCounted

const TILE_SIZE := 32
const DEFAULT_VISIBLE_TILES := 32
const SCROLL_MARGIN_TILES := 4

const TILES_TEXTURE_PATH := "res://assets/tiles.png"
const MONSTERS_TEXTURE_PATH := "res://assets/monsters.png"

const TILES_COLUMNS := 10
const TILES_ROWS := 10

## 1-based tile coordinates from the design notes.
const WALL_TILE := Vector2i(0, 0)
const FLOOR_TILE := Vector2i(0, 2)
const LIGHT_TILE := Vector2i(0, 5)
## Diagonal wall tiles: PNG columns 2-5 (1-based; column 1 = atlas x 0), rows 3 / 6.
const DIAG_WALL_COL2_UNLIT := Vector2i(1, 2)
const DIAG_WALL_COL3_UNLIT := Vector2i(2, 2)
const DIAG_WALL_COL4_UNLIT := Vector2i(3, 2)
const DIAG_WALL_COL5_UNLIT := Vector2i(4, 2)
const DIAG_WALL_COL2_LIT := Vector2i(1, 5)
const DIAG_WALL_COL3_LIT := Vector2i(2, 5)
const DIAG_WALL_COL4_LIT := Vector2i(3, 5)
const DIAG_WALL_COL5_LIT := Vector2i(4, 5)
## Door tiles: row 6, columns 6-8 (1-based) in tiles.png.
const DOOR_CLOSED_TILE := Vector2i(5, 5)
const DOOR_OPEN_TILE := Vector2i(6, 5)
const DOOR_DESTROYED_TILE := Vector2i(7, 5)


static func door_atlas(state: int) -> Vector2i:
	match state:
		DoorState.State.CLOSED:
			return DOOR_CLOSED_TILE
		DoorState.State.OPEN:
			return DOOR_OPEN_TILE
		DoorState.State.DESTROYED:
			return DOOR_DESTROYED_TILE
		DoorState.State.HIDDEN:
			return WALL_TILE
		_:
			return DOOR_CLOSED_TILE


static func door_has_sprite(state: int) -> bool:
	return state != DoorState.State.NONE


static func diag_wall_atlas(column: int, lit: bool) -> Vector2i:
	match column:
		2:
			return DIAG_WALL_COL2_LIT if lit else DIAG_WALL_COL2_UNLIT
		3:
			return DIAG_WALL_COL3_LIT if lit else DIAG_WALL_COL3_UNLIT
		4:
			return DIAG_WALL_COL4_LIT if lit else DIAG_WALL_COL4_UNLIT
		5:
			return DIAG_WALL_COL5_LIT if lit else DIAG_WALL_COL5_UNLIT
		_:
			return DIAG_WALL_COL2_LIT if lit else DIAG_WALL_COL2_UNLIT
const HERO_TILE := Vector2i(0, 0)

const MOVE_HOLD_INITIAL_DELAY := 1.0
const MOVE_HOLD_REPEAT_INTERVAL := 0.02
