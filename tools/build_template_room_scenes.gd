extends SceneTree

const ROOM_SIZE := Vector2i(21, 13)
const STYLES := ["walnut_cream", "oak_sand", "chestnut_stone"]

func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://rooms/tests/template_rooms")
	for style in STYLES:
		var root := Node2D.new()
		root.name = style.capitalize() + "Template"
		var layer := TileMapLayer.new()
		layer.name = "RoomTemplateTiles"
		layer.tile_set = load("res://assets/tiles/template_rooms/%s_template_tileset.tres" % style) as TileSet
		for y in range(ROOM_SIZE.y):
			for x in range(ROOM_SIZE.x):
				layer.set_cell(Vector2i(x, y), 0, Vector2i(x, y))
		root.add_child(layer)
		layer.owner = root
		var scene := PackedScene.new()
		var packed := scene.pack(root)
		if packed != OK:
			push_error("No se pudo crear la escena de prueba para %s" % style)
			quit(1)
			return
		var output := "res://rooms/tests/template_rooms/%s_template.tscn" % style
		var saved := ResourceSaver.save(scene, output)
		if saved != OK:
			push_error("No se pudo guardar %s" % output)
			quit(1)
			return
		print(output)
	quit()
