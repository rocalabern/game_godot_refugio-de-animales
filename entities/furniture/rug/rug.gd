class_name Rug
extends PlaceableObject

var cell_size := Vector2(48, 48):
	set(value):
		cell_size = value
		queue_redraw()
func _ready() -> void:
	blocks_navigation = false
	uses_y_sort = false
	z_index = -1
	queue_redraw()


func configure_grid_size(new_cell_size: Vector2) -> void:
	cell_size = new_cell_size


func get_cell_anchor_offset() -> Vector2:
	return Vector2(-0.5, -0.5)


func _draw() -> void:
	# La base de una alfombra es su esquina superior izquierda.
	var rect := Rect2(Vector2(-cell_size.x * 0.5, -cell_size.y * 0.5) + Vector2(5, 5), Vector2(footprint) * cell_size - Vector2(10, 10))
	draw_rect(rect, Color("bd5967"))
	draw_rect(rect, Color("7a3341"), false, 3.0)
