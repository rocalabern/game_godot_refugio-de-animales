class_name WorldObject
extends Node2D

enum Kind { PLAYER, TABLE }
var kind := Kind.PLAYER
var cell_size := Vector2(48, 48):
	set(value):
		cell_size = value
		queue_redraw()


func _draw() -> void:
	if kind == Kind.PLAYER:
		var body := Rect2(Vector2(-cell_size.x * 0.5, -cell_size.y * 2.0), Vector2(cell_size.x, cell_size.y * 2.0))
		draw_rect(body, Color("36b7eb"))
		draw_rect(body, Color.WHITE, false, 3.0)
		draw_circle(Vector2(0, -cell_size.y * 1.62), cell_size.x * 0.12, Color("103a56"))
	else:
		var top := Rect2(Vector2(-cell_size.x, -cell_size.y * 2.0), Vector2(cell_size.x * 2.0, cell_size.y * 2.0))
		draw_rect(top, Color("93633e"))
		draw_rect(top, Color("49301f"), false, 5.0)
		draw_line(Vector2(-cell_size.x * 0.70, -cell_size.y * 0.18), Vector2(-cell_size.x * 0.70, 0), Color("49301f"), 5.0)
		draw_line(Vector2(cell_size.x * 0.70, -cell_size.y * 0.18), Vector2(cell_size.x * 0.70, 0), Color("49301f"), 5.0)
