extends SceneTree

const COLUMNS := 21
const ROWS := 13
const WALL_TILE := Vector2i(1, 0)
const TILE_SET := preload("res://assets/tiles/collision/collision_tileset.tres")
const EDITOR_BACKGROUND := preload("res://assets/tiles/refugio_entrada/refugio_entrada_background_48.png")

func _is_opening(cell: Vector2i) -> bool:
	# Tres puertas hacia el norte (x 4–6, 10–12 y 16–18) y la entrada de
	# clientes en el borde izquierdo. Solo define movimiento; no transiciones.
	return (
		cell.y <= 1 and (cell.x in range(4, 7) or cell.x in range(10, 13) or cell.x in range(16, 19))
		or cell.x == 0 and cell.y in range(8, 11)
	)

func _is_wall(cell: Vector2i) -> bool:
	if _is_opening(cell):
		return false
	return cell.x == 0 or cell.x == COLUMNS - 1 or cell.y <= 1 or cell.y == ROWS - 1

func _init() -> void:
	var collisions := TileMapLayer.new()
	collisions.name = "CollisionTiles"
	collisions.tile_set = TILE_SET
	var preview := Sprite2D.new()
	preview.name = "EditorBackground"
	preview.texture = EDITOR_BACKGROUND
	preview.centered = false
	preview.z_index = -10
	collisions.add_child(preview)
	preview.owner = collisions
	for y in range(ROWS):
		for x in range(COLUMNS):
			var cell := Vector2i(x, y)
			if _is_wall(cell):
				collisions.set_cell(cell, 0, WALL_TILE)
	var packed := PackedScene.new()
	var result := packed.pack(collisions)
	if result != OK:
		push_error("No se pudo crear la capa de colisiones de shelter_entrada.")
		quit(1)
		return
	var saved := ResourceSaver.save(packed, "res://rooms/shelter_entrada/shelter_entrada_collisions.tscn")
	if saved != OK:
		push_error("No se pudo guardar la capa de colisiones de shelter_entrada.")
		quit(1)
		return
	quit()
