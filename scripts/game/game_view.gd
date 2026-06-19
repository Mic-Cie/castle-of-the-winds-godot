class_name GameView
extends Control

const _DiagonalWallResolver = preload("res://scripts/level/diagonal_wall_resolver.gd")
const ExaminePopup = preload("res://scripts/ui/examine_popup.gd")

@onready var _viewport_container: SubViewportContainer = %ViewportContainer
@onready var _sub_viewport: SubViewport = %SubViewport
@onready var _world_root: Node2D = %WorldRoot
@onready var _tile_map: TileMapLayer = %TileMap
@onready var _door_map: TileMapLayer = %DoorMap
@onready var _fog_map: TileMapLayer = %FogMap
@onready var _entities_root: Node2D = %Entities
@onready var _h_scroll: HScrollBar = %HScroll
@onready var _v_scroll: VScrollBar = %VScroll

var world: GameWorld
var scroll_controller := ScrollController.new()
var _entity_sprites: Dictionary = {}
var _local_player_entity_id: int = -1
var _local_player_id: int = 0
var _examine_popup: ExaminePopup

## Set to false to silence map click debug output.
const DEBUG_CLICK_MAP := true


func _get_minimum_size() -> Vector2:
	return Vector2.ZERO


func _ready() -> void:
	resized.connect(_on_resized)
	_h_scroll.value_changed.connect(_on_h_scroll_changed)
	_v_scroll.value_changed.connect(_on_v_scroll_changed)
	scroll_controller.scroll_changed.connect(_on_scroll_changed)
	_examine_popup = ExaminePopup.new()
	_examine_popup.z_index = 100
	add_child(_examine_popup)
	_setup_world()
	_on_resized()


func connect_viewport_input(callable: Callable) -> void:
	_viewport_container.gui_input.connect(callable)


func accept_viewport_input() -> void:
	_viewport_container.accept_event()


func viewport_local_to_map_pixel(local_pos: Vector2) -> Vector2:
	var scroll := scroll_controller.scroll_offset
	return local_pos + Vector2(scroll) * GameConstants.TILE_SIZE


func viewport_local_to_map_grid(local_pos: Vector2) -> Vector2i:
	var map_pixel := viewport_local_to_map_pixel(local_pos)
	return Vector2i(
		int(floor(map_pixel.x / GameConstants.TILE_SIZE)),
		int(floor(map_pixel.y / GameConstants.TILE_SIZE)),
	)


func get_viewport_local_mouse_map_pixel() -> Vector2:
	var global_mouse := get_global_mouse_position()
	var local := _viewport_container.get_global_transform_with_canvas().affine_inverse() * global_mouse
	return viewport_local_to_map_pixel(local)


func map_pixel_to_viewport_local(map_pixel: Vector2) -> Vector2:
	var scroll := scroll_controller.scroll_offset
	return map_pixel - Vector2(scroll) * GameConstants.TILE_SIZE


func warp_mouse_to_map_pixel(map_pixel: Vector2) -> void:
	var viewport_local := map_pixel_to_viewport_local(map_pixel)
	var global_pos := _viewport_container.get_global_transform_with_canvas() * viewport_local
	get_viewport().warp_mouse(global_pos)


func show_examine_popup(viewport_local: Vector2, text: String) -> void:
	var pointer := _viewport_local_to_game_view_local(viewport_local)
	var cursor_top_left := pointer - GameConstants.EXAMINE_POPUP_CURSOR_TOP_LEFT_OFFSET
	_examine_popup.present(cursor_top_left, text, get_play_area_rect())


func hide_examine_popup() -> void:
	_examine_popup.hide_popup()


func get_play_area_rect() -> Rect2:
	var viewport_global := _viewport_container.get_global_rect()
	var origin := get_global_transform_with_canvas().affine_inverse() * viewport_global.position
	return Rect2(origin, viewport_global.size)


func _viewport_local_to_game_view_local(viewport_local: Vector2) -> Vector2:
	var global_pos := _viewport_container.get_global_transform_with_canvas() * viewport_local
	return get_global_transform_with_canvas().affine_inverse() * global_pos


func get_local_player_entity_id() -> int:
	return _local_player_entity_id


func _setup_world() -> void:
	var generator := LevelGeneratorFactory.create("fixed")
	var game_map := generator.generate()

	world = GameWorld.new(game_map)
	world.entity_added.connect(_on_entity_added)
	world.entity_moved.connect(_on_entity_moved)
	world.visibility_changed.connect(_on_visibility_changed)
	world.door_changed.connect(_on_door_changed)

	_build_tileset()
	_build_door_tileset()
	_build_fog_tileset()
	_draw_map(game_map)
	_draw_doors(game_map)

	scroll_controller.setup(Vector2i(game_map.width, game_map.height))

	var spawn := _find_spawn_position(game_map)
	var player := world.add_player(_local_player_id, spawn)
	_local_player_entity_id = player.entity_id
	_refresh_fog(player.vision, game_map)

	scroll_controller.set_scroll_offset(
		_center_scroll_on(player.grid_position, game_map.width, game_map.height)
	)


func _build_tileset() -> void:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(GameConstants.TILE_SIZE, GameConstants.TILE_SIZE)

	var atlas := TileSetAtlasSource.new()
	atlas.texture = load(GameConstants.TILES_TEXTURE_PATH)
	atlas.texture_region_size = Vector2i(GameConstants.TILE_SIZE, GameConstants.TILE_SIZE)

	atlas.create_tile(GameConstants.WALL_TILE)
	atlas.create_tile(GameConstants.FLOOR_TILE)
	atlas.create_tile(GameConstants.LIGHT_TILE)
	atlas.create_tile(GameConstants.DIAG_WALL_COL2_UNLIT)
	atlas.create_tile(GameConstants.DIAG_WALL_COL3_UNLIT)
	atlas.create_tile(GameConstants.DIAG_WALL_COL4_UNLIT)
	atlas.create_tile(GameConstants.DIAG_WALL_COL5_UNLIT)
	atlas.create_tile(GameConstants.DIAG_WALL_COL2_LIT)
	atlas.create_tile(GameConstants.DIAG_WALL_COL3_LIT)
	atlas.create_tile(GameConstants.DIAG_WALL_COL4_LIT)
	atlas.create_tile(GameConstants.DIAG_WALL_COL5_LIT)

	tile_set.add_source(atlas, 0)
	_tile_map.tile_set = tile_set
	_tile_map.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _build_door_tileset() -> void:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(GameConstants.TILE_SIZE, GameConstants.TILE_SIZE)

	var atlas := TileSetAtlasSource.new()
	atlas.texture = load(GameConstants.TILES_TEXTURE_PATH)
	atlas.texture_region_size = Vector2i(GameConstants.TILE_SIZE, GameConstants.TILE_SIZE)

	atlas.create_tile(GameConstants.DOOR_CLOSED_TILE)
	atlas.create_tile(GameConstants.DOOR_OPEN_TILE)
	atlas.create_tile(GameConstants.DOOR_DESTROYED_TILE)
	atlas.create_tile(GameConstants.WALL_TILE)

	tile_set.add_source(atlas, 0)
	_door_map.tile_set = tile_set
	_door_map.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _build_fog_tileset() -> void:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(GameConstants.TILE_SIZE, GameConstants.TILE_SIZE)

	var image := Image.create(GameConstants.TILE_SIZE, GameConstants.TILE_SIZE, false, Image.FORMAT_RGB8)
	image.fill(Color.WHITE)
	var texture := ImageTexture.create_from_image(image)

	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(GameConstants.TILE_SIZE, GameConstants.TILE_SIZE)
	atlas.create_tile(Vector2i.ZERO)

	tile_set.add_source(atlas, 0)
	_fog_map.tile_set = tile_set
	_fog_map.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _draw_map(game_map: GameMap) -> void:
	_tile_map.clear()
	for y in range(game_map.height):
		for x in range(game_map.width):
			var pos := Vector2i(x, y)
			var wall_variant := _DiagonalWallResolver.resolve(pos, game_map)
			if wall_variant.use_special:
				_tile_map.set_cell(pos, 0, wall_variant.atlas, wall_variant.alternative)
			else:
				_tile_map.set_cell(pos, 0, _atlas_coords_for_tile(game_map.get_tile(pos)))


func _draw_doors(game_map: GameMap) -> void:
	_door_map.clear()
	for y in range(game_map.height):
		for x in range(game_map.width):
			var pos := Vector2i(x, y)
			_refresh_door_cell(pos, game_map.get_door_state(pos))


func _refresh_door_cell(pos: Vector2i, state: int) -> void:
	if not GameConstants.door_has_sprite(state):
		_door_map.erase_cell(pos)
	else:
		_door_map.set_cell(pos, 0, GameConstants.door_atlas(state))


func _atlas_coords_for_tile(tile_type: int) -> Vector2i:
	match tile_type:
		TileType.Type.LIT_FLOOR:
			return GameConstants.LIGHT_TILE
		TileType.Type.FLOOR:
			return GameConstants.FLOOR_TILE
		_:
			return GameConstants.WALL_TILE


func _refresh_fog(vision: PlayerVision, game_map: GameMap) -> void:
	_fog_map.clear()
	for y in range(game_map.height):
		for x in range(game_map.width):
			var pos := Vector2i(x, y)
			if not vision.is_uncovered(pos):
				_fog_map.set_cell(pos, 0, Vector2i.ZERO)


func _find_spawn_position(game_map: GameMap) -> Vector2i:
	for y in range(game_map.height):
		for x in range(game_map.width):
			var pos := Vector2i(x, y)
			if game_map.get_tile(pos) == TileType.Type.FLOOR or game_map.get_tile(pos) == TileType.Type.LIT_FLOOR:
				return pos
	return Vector2i(1, 1)


func _center_scroll_on(position: Vector2i, map_width: int, map_height: int) -> Vector2i:
	var visible := scroll_controller.visible_tiles
	var offset := position - visible / 2
	offset.x = clampi(offset.x, 0, maxi(map_width - visible.x, 0))
	offset.y = clampi(offset.y, 0, maxi(map_height - visible.y, 0))
	return offset


func _on_entity_added(entity: Entity) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = load(GameConstants.MONSTERS_TEXTURE_PATH)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.hframes = 14
	sprite.vframes = 5
	sprite.frame = 0
	sprite.centered = false
	sprite.position = Vector2(entity.grid_position) * GameConstants.TILE_SIZE
	_entities_root.add_child(sprite)
	_entity_sprites[entity.entity_id] = sprite


func _on_entity_moved(entity_id: int, _old_position: Vector2i, new_position: Vector2i) -> void:
	var sprite: Sprite2D = _entity_sprites.get(entity_id)
	if sprite:
		sprite.position = Vector2(new_position) * GameConstants.TILE_SIZE

	if entity_id == _local_player_entity_id:
		scroll_controller.on_entity_moved(new_position)


func _on_door_changed(pos: Vector2i) -> void:
	_refresh_door_cell(pos, world.game_map.get_door_state(pos))


func _on_visibility_changed(player_id: int, uncovered_positions: Array[Vector2i]) -> void:
	if player_id != _local_player_id:
		return

	for pos in uncovered_positions:
		_fog_map.erase_cell(pos)


func _on_resized() -> void:
	_update_viewport_size()


func _update_viewport_size() -> void:
	var scrollbar_width := int(_v_scroll.get_combined_minimum_size().x)
	var scrollbar_height := int(_h_scroll.get_combined_minimum_size().y)
	var available_width := maxi(int(size.x) - scrollbar_width, 1)
	var available_height := maxi(int(size.y) - scrollbar_height, 1)

	_viewport_container.custom_minimum_size = Vector2.ZERO
	_sub_viewport.size = Vector2i(available_width, available_height)

	var visible_tiles := Vector2i(
		ceili(available_width / float(GameConstants.TILE_SIZE)),
		ceili(available_height / float(GameConstants.TILE_SIZE)),
	)
	scroll_controller.set_visible_tiles(visible_tiles)
	_update_scrollbars()


func _update_scrollbars() -> void:
	var max_scroll := scroll_controller.get_scroll_max()
	var map_size := scroll_controller.map_size
	var visible := scroll_controller.visible_tiles

	_h_scroll.min_value = 0
	_h_scroll.max_value = map_size.x
	_h_scroll.page = visible.x
	_h_scroll.step = 1
	_h_scroll.visible = max_scroll.x > 0

	_v_scroll.min_value = 0
	_v_scroll.max_value = map_size.y
	_v_scroll.page = visible.y
	_v_scroll.step = 1
	_v_scroll.visible = max_scroll.y > 0

	_h_scroll.set_value_no_signal(scroll_controller.scroll_offset.x)
	_v_scroll.set_value_no_signal(scroll_controller.scroll_offset.y)
	_apply_scroll_to_view()


func _on_scroll_changed(offset: Vector2i) -> void:
	_h_scroll.set_value_no_signal(offset.x)
	_v_scroll.set_value_no_signal(offset.y)
	_apply_scroll_to_view()


func _on_h_scroll_changed(value: float) -> void:
	scroll_controller.set_scroll_offset(
		Vector2i(int(value), scroll_controller.scroll_offset.y)
	)


func _on_v_scroll_changed(value: float) -> void:
	scroll_controller.set_scroll_offset(
		Vector2i(scroll_controller.scroll_offset.x, int(value))
	)


func _apply_scroll_to_view() -> void:
	var offset := scroll_controller.scroll_offset
	_world_root.position = Vector2(-offset) * GameConstants.TILE_SIZE
