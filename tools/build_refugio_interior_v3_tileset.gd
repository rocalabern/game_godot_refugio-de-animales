extends SceneTree

const ATLAS_PATH := "res://assets/tiles/refugio_interior_v3/refugio_interior_v3_atlas_48.png"
const OUTPUT_PATH := "res://assets/tiles/refugio_interior_v3/refugio_interior_v3_tileset.tres"
const PREVIEW_PATH := "res://rooms/tests/refugio_interior_v3_preview.tscn"
const TILE_SIZE := Vector2i(48, 48)

func _init() -> void:
	var tile_set := TileSet.new()
	tile_set.tile_size = TILE_SIZE
	tile_set.add_physics_layer()
	tile_set.add_terrain_set()
	tile_set.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_CORNERS_AND_SIDES)
	tile_set.add_terrain(0)
	tile_set.set_terrain_name(0, 0, "Floor")
	tile_set.set_terrain_color(0, 0, Color("f6e3b8"))
	tile_set.add_terrain(0)
	tile_set.set_terrain_name(0, 1, "Wall")
	tile_set.set_terrain_color(0, 1, Color("80512d"))

	var atlas_source := TileSetAtlasSource.new()
	atlas_source.texture = load(ATLAS_PATH)
	atlas_source.texture_region_size = TILE_SIZE

	for atlas_y in range(6):
		for atlas_x in range(6):
			var coords := Vector2i(atlas_x, atlas_y)
			atlas_source.create_tile(coords)
	tile_set.add_source(atlas_source, 0)

	for atlas_y in range(6):
		for atlas_x in range(6):
			var coords := Vector2i(atlas_x, atlas_y)
			var tile_data := atlas_source.get_tile_data(coords, 0)
			if atlas_y == 0:
				_configure_terrain(tile_data, 0, [0, 1, 2, 3, 4, 5, 6, 7])
			elif atlas_y < 5:
				_configure_terrain(tile_data, 1, _wall_peering_bits(coords))
				tile_data.set_collision_polygons_count(0, 1)
				tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([
					Vector2.ZERO, Vector2(TILE_SIZE.x, 0), Vector2(TILE_SIZE), Vector2(0, TILE_SIZE.y)
				]))
			elif atlas_x >= 4:
				# Las dos transiciones de puerta lateral siguen siendo pared sólida.
				_configure_terrain(tile_data, 1, [0, 1, 2, 3, 4, 5, 6, 7])
				tile_data.set_collision_polygons_count(0, 1)
				tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([
					Vector2.ZERO, Vector2(TILE_SIZE.x, 0), Vector2(TILE_SIZE), Vector2(0, TILE_SIZE.y)
				]))

	var error := ResourceSaver.save(tile_set, OUTPUT_PATH)
	if error != OK:
		push_error("Could not save v3 TileSet: %s" % error)
		quit(error)
		return
	_build_preview(tile_set)
	quit()

func _configure_terrain(tile_data: TileData, terrain: int, connected_bits: Array) -> void:
	tile_data.set_terrain_set(0)
	tile_data.set_terrain(terrain)
	for peering_bit in range(8):
		if tile_data.is_valid_terrain_peering_bit(peering_bit):
			tile_data.set_terrain_peering_bit(peering_bit, terrain if peering_bit in connected_bits else -1)

func _wall_peering_bits(coords: Vector2i) -> Array:
	# Índices: derecha, abajo-derecha, abajo, abajo-izquierda, izquierda,
	# arriba-izquierda, arriba y arriba-derecha. Coinciden con el orden de Godot.
	var patterns := {
		Vector2i(0, 1): [0, 1, 2],
		Vector2i(1, 1): [0, 1, 2, 3, 4],
		Vector2i(2, 1): [0, 1, 2, 3, 4],
		Vector2i(3, 1): [0, 1, 2, 3, 4],
		Vector2i(4, 1): [0, 1, 2, 3, 4],
		Vector2i(5, 1): [2, 3, 4],
		Vector2i(0, 2): [0, 6, 7],
		Vector2i(1, 2): [0, 4, 5, 6, 7],
		Vector2i(2, 2): [0, 4, 5, 6, 7],
		Vector2i(3, 2): [0, 4, 5, 6, 7],
		Vector2i(4, 2): [0, 4, 5, 6, 7],
		Vector2i(5, 2): [4, 5, 6],
		Vector2i(0, 3): [0, 1, 2],
		Vector2i(1, 3): [0, 1, 2, 6, 7],
		Vector2i(2, 3): [0, 6, 7],
		Vector2i(3, 3): [2, 3, 4],
		Vector2i(4, 3): [2, 3, 4, 5, 6],
		Vector2i(5, 3): [4, 5, 6],
		Vector2i(0, 4): [0, 1, 2],
		Vector2i(1, 4): [2, 3, 4],
		Vector2i(2, 4): [0, 6, 7],
		Vector2i(3, 4): [4, 5, 6],
		Vector2i(4, 4): [0, 1, 2, 3, 4],
		Vector2i(5, 4): [0, 1, 2, 3, 4, 5, 6, 7],
	}
	return patterns.get(coords, [])

func _build_preview(tile_set: TileSet) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://rooms/tests"))
	var preview_tile_set := load(OUTPUT_PATH) as TileSet
	if preview_tile_set == null:
		push_error("Could not reload v3 TileSet for preview.")
		return
	var root := Node2D.new()
	root.name = "RefugioInteriorV3Preview"
	var floor := TileMapLayer.new()
	floor.name = "FloorTiles"
	floor.tile_set = preview_tile_set
	root.add_child(floor)
	floor.owner = root
	for cell_y in range(13):
		for cell_x in range(21):
			floor.set_cell(Vector2i(cell_x, cell_y), 0, Vector2i(cell_x % 6, 0))

	var walls := TileMapLayer.new()
	walls.name = "WallTiles"
	walls.tile_set = preview_tile_set
	root.add_child(walls)
	walls.owner = root
	for cell_x in range(21):
		if cell_x in [9, 10]:
			continue
		var horizontal_piece_x := 0 if cell_x == 0 else 5 if cell_x == 20 else 1 + (cell_x % 4)
		walls.set_cell(Vector2i(cell_x, 0), 0, Vector2i(horizontal_piece_x, 1))
		walls.set_cell(Vector2i(cell_x, 1), 0, Vector2i(horizontal_piece_x, 2))
	for door_x in range(2):
		walls.set_cell(Vector2i(9 + door_x, 0), 0, Vector2i(door_x, 5))
		walls.set_cell(Vector2i(9 + door_x, 1), 0, Vector2i(door_x + 2, 5))
	for cell_y in range(2, 13):
		var left_piece_x := 0 if cell_y == 2 else 2 if cell_y == 12 else 1
		var right_piece_x := 3 if cell_y == 2 else 5 if cell_y == 12 else 4
		walls.set_cell(Vector2i(0, cell_y), 0, Vector2i(left_piece_x, 3))
		walls.set_cell(Vector2i(20, cell_y), 0, Vector2i(right_piece_x, 3))

	var packed_scene := PackedScene.new()
	var pack_error := packed_scene.pack(root)
	if pack_error != OK:
		push_error("Could not pack v3 preview scene: %s" % pack_error)
		return
	var save_error := ResourceSaver.save(packed_scene, PREVIEW_PATH)
	if save_error != OK:
		push_error("Could not save v3 preview scene: %s" % save_error)
