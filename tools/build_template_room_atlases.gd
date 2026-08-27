extends SceneTree

const ROOM_SIZE := Vector2i(21, 13)
const CELL_SIZE := 48
const STYLES := ["walnut_cream", "oak_sand", "chestnut_stone"]

func _init() -> void:
	for style in STYLES:
		var input_path := "res://assets/tiles/template_rooms/%s_source.png" % style
		var output_path := "res://assets/tiles/template_rooms/%s_atlas_48.png" % style
		var image := Image.load_from_file(input_path)
		if image == null:
			push_error("No se pudo cargar %s" % input_path)
			quit(1)
			return
		image.resize(ROOM_SIZE.x * CELL_SIZE, ROOM_SIZE.y * CELL_SIZE, Image.INTERPOLATE_LANCZOS)
		var result := image.save_png(output_path)
		if result != OK:
			push_error("No se pudo guardar %s" % output_path)
			quit(1)
			return
		print(output_path)
	quit()
