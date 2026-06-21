class_name GameConstants
extends RefCounted

const TILE_SIZE := 32
const DEFAULT_VISIBLE_TILES := 32
const SCROLL_MARGIN_TILES := 4

const TILES_TEXTURE_PATH := "res://assets/tiles.png"
const MONSTERS_TEXTURE_PATH := "res://assets/monsters.png"
const MONSTER_SPRITE_COLUMNS := 14
const MONSTER_SPRITE_ROWS := 5
const HERO_SPRITE_FRAME := 0
const KOBOLD_SPRITE_FRAME := 2
const KOBOLD_MAX_HP := 10

const MONSTER_ASLEEP_NOTICE_BASE := 0.5
const MONSTER_ASLEEP_NOTICE_DISTANCE_PENALTY := 0.08
const MONSTER_ASLEEP_NOTICE_MIN := 0.05
const MONSTER_UNLIT_SIGHT_RANGE := 2

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

const STEP_TIME_COST := 5
const ATTACK_TIME_COST := 5
const SEARCH_TIME_COST := 10
const ACTION_TIME_COST_MIN := 1
const GAME_TICK_SECONDS := 1.0
const MESSAGE_LOG_MAX_LINES := 50
const MESSAGE_LOG_CONTENT_HEIGHT_MULTIPLIER := 2

const EXAMINE_POPUP_PADDING := 4
const EXAMINE_POPUP_CURSOR_GAP := 4
const EXAMINE_POPUP_EDGE_MARGIN := 2
const EXAMINE_POPUP_BORDER_WIDTH := 1
## Mouse hotspot to cursor image top-left, for popup placement.
const EXAMINE_POPUP_CURSOR_TOP_LEFT_OFFSET := Vector2(0, 0)
## Approximate cursor size used when flipping popup below or beside the cursor.
const EXAMINE_POPUP_CURSOR_SIZE := Vector2(16, 16)
const DEFAULT_GAME_MODE := GameMode.Mode.SINGLE_PLAYER
## const DEFAULT_GAME_MODE := GameMode.Mode.MULTI_PLAYER
const DEFAULT_DIFFICULTY := Difficulty.Level.INTERMEDIATE
const DEFAULT_EXPERIENCE := 0
## Cap for XP required to reach the next level (keeps formula results within safe int range).
const MAX_EXPERIENCE_TO_LEVEL_UP := 999_999_999_999

const DEFAULT_HP := 10
const DEFAULT_HP_MAX := 10
const DEFAULT_LEVEL := 1
const DEFAULT_DRAINED_HIT_POINTS := 0

## Max-HP formula (integer division): (C*(4*L-1) + 7*L + HP_MAX_BASE) / (2*L + HP_MAX_DEN_BASE) - drained.
## Tuned to approximate reference values across level and constitution.
const HP_MAX_BASE := 10
const HP_MAX_LEVEL_TERM := 7
const HP_MAX_DEN_BASE := 13

## Max-mana formula: ceil((level - 1) * (int - ref) / level_div) + ceil((int - ref) / int_div).
const MANA_INTELLIGENCE_REFERENCE := 15
const MANA_LEVEL_DIVISOR := 7
const MANA_INT_DIVISOR := 10

## Carry weight: base + str * per_str + (str / divisor)^2 * quadratic_scale (integer division).
const CARRY_WEIGHT_BASE := 11500
const CARRY_WEIGHT_PER_STRENGTH := 250
const CARRY_WEIGHT_STRENGTH_DIVISOR := 10
const CARRY_WEIGHT_QUADRATIC_SCALE := 500

const MOVEMENT_SPEED_LIGHT_LOAD := 200
const MOVEMENT_SPEED_FULL_LOAD := 100
const MOVEMENT_SPEED_MIN := 1
const DEFAULT_CURRENT_CARRY_WEIGHT := 0
const DEFAULT_MANA := 5
const DEFAULT_MANA_MAX := 5
const DEFAULT_STRENGTH := 10
const DEFAULT_STRENGTH_MAX := 10
const DEFAULT_CONSTITUTION := 10
const DEFAULT_CONSTITUTION_MAX := 10
const DEFAULT_DEXTERITY := 10
const DEFAULT_DEXTERITY_MAX := 10
const DEFAULT_INTELLIGENCE := 10
const DEFAULT_INTELLIGENCE_MAX := 10

const HERO_DEFAULT_STRENGTH := 45
const HERO_DEFAULT_DEXTERITY := 45
const HERO_DEFAULT_CONSTITUTION := 45
const HERO_DEFAULT_INTELLIGENCE := 45

const DEFAULT_SPEED := 100
const DEFAULT_ARMOR := 0

## Melee attack power scales linearly with strength (before armor and variance).
## Tuned: strength 10 -> ~3 avg damage vs unarmored; strength 70 -> ~10 avg.
const ATTACK_STRENGTH_REFERENCE := 10
const ATTACK_HIGH_STRENGTH_REFERENCE := 70
const ATTACK_DAMAGE_AT_REFERENCE := 3
const ATTACK_DAMAGE_AT_HIGH_STRENGTH := 10


static func format_game_time(seconds: int) -> String:
	var days := seconds / 86400
	var hours := (seconds % 86400) / 3600
	var minutes := (seconds % 3600) / 60
	var secs := seconds % 60
	return "%dd,%02d:%02d:%02d" % [days, hours, minutes, secs]
