extends SceneTree

func _init() -> void:
	var source_path := "res://assets/tiles/refugio_interior_v5/refugio_interior_v5_atlas.svg"
	var map_path := "res://assets/tiles/refugio_interior_v5/refugio_interior_v5_layout_test.json"
	var output_path := "res://assets/tiles/refugio_interior_v5/refugio_interior_v5_layout_test.png"
	var map_data = JSON.parse_string(FileAccess.get_file_as_string(map_path)) as Dictionary
	if map_data.is_empty():
		push_error("No se pudo leer el mapa de prueba v5.")
		quit(1)
		return
	var texture := load(source_path) as Texture2D
	if texture == null:
		push_error("No se pudo cargar el atlas v5.")
		quit(1)
		return
	var atlas := texture.get_image()
	var cell_size: int = map_data["cell_size"]
	var image := Image.create(map_data["width"] * cell_size, map_data["height"] * cell_size, false, atlas.get_format())
	image.fill(Color(0.0, 0.0, 0.0, 0.0))
	for cell in map_data["cells"]:
		var source_rect := Rect2i(cell["atlas_x"] * cell_size, cell["atlas_y"] * cell_size, cell_size, cell_size)
		var destination := Vector2i(cell["x"] * cell_size, cell["y"] * cell_size)
		image.blit_rect(atlas, source_rect, destination)
	var saved := image.save_png(output_path)
	if saved != OK:
		push_error("No se pudo guardar la prueba v5: %s" % saved)
		quit(1)
		return
	print(output_path)
	quit()
