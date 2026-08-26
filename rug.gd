class_name Rug
extends Node2D

var cell_size := Vector2(48, 48):
	set(value):
		cell_size = value
		queue_redraw()
var grid_cell := Vector2i(2, 8):
	set(value):
		grid_cell = value
		queue_redraw()
var grid_size := Vector2i(4, 2):
	set(value):
		grid_size = value
		queue_redraw()


func _ready() -> void:
	z_index = -1
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2(grid_cell) * cell_size + Vector2(5, 5), Vector2(grid_size) * cell_size - Vector2(10, 10))
	draw_rect(rect, Color("bd5967"))
	draw_rect(rect, Color("7a3341"), false, 3.0)
