class_name EncounterMarker
extends Control

signal selected

var elapsed := 0.0


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	gui_input.connect(_on_gui_input)


func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var pulse := (sin(elapsed * 7.0) + 1.0) * 0.5
	draw_circle(center, 25.0 + pulse * 5.0, Color(0.88, 0.18, 0.24, 0.18))
	draw_circle(center, 21.0, Color(0.91, 0.20, 0.25, 0.92))
	draw_arc(center, 28.0 + pulse * 4.0, 0.0, TAU, 40, Color(1.0, 0.75, 0.55, 0.9), 3.0, true)
	draw_circle(center, 7.0, Color("fff1ce"))


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		selected.emit()
		accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		selected.emit()
		accept_event()

