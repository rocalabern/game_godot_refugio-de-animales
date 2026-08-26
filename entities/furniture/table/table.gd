class_name Table
extends PlaceableObject

var cell_size := Vector2(48, 48):
	set(value):
		cell_size = value
		queue_redraw()


func _ready() -> void:
	footprint = Vector2i(2, 2)
	queue_redraw()


func configure_grid_size(new_cell_size: Vector2) -> void:
	cell_size = new_cell_size


func get_cell_anchor_offset() -> Vector2:
	# La casilla base de mesa es su apoyo inferior derecho. El dibujo se ancla a
	# la intersección inferior derecha del bloque 2x2, no al centro de esa casilla.
	return Vector2(-0.5, 0.5)


func get_occupied_cells() -> Array[Vector2i]:
	# El origen de la mesa está en su base inferior derecha para Y-Sort.
	return [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i.ZERO]


func _draw() -> void:
	var top := Rect2(Vector2(-cell_size.x, -cell_size.y * 2.0), Vector2(cell_size.x * 2.0, cell_size.y * 2.0))
	draw_rect(top, Color("93633e"))
	draw_rect(top, Color("49301f"), false, 5.0)
	draw_line(Vector2(-cell_size.x * 0.70, -cell_size.y * 0.18), Vector2(-cell_size.x * 0.70, 0), Color("49301f"), 5.0)
	draw_line(Vector2(cell_size.x * 0.70, -cell_size.y * 0.18), Vector2(cell_size.x * 0.70, 0), Color("49301f"), 5.0)
