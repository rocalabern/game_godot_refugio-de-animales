@tool
class_name RoomGridData
extends Resource

## Datos de colisión base editables desde Godot. 0 = caminable, 1 = bloqueada.
@export var columns := 20:
	set(value):
		columns = maxi(1, value)
		ensure_size()
		emit_changed()
@export var rows := 12:
	set(value):
		rows = maxi(1, value)
		ensure_size()
		emit_changed()
@export var cells := PackedByteArray()


func _init() -> void:
	ensure_size()


func ensure_size() -> void:
	var required_size := columns * rows
	if cells.size() == required_size:
		return
	var resized := PackedByteArray()
	resized.resize(required_size)
	for index in range(mini(cells.size(), required_size)):
		resized[index] = cells[index]
	cells = resized


func is_blocked(column: int, row: int) -> bool:
	if column < 0 or column >= columns or row < 0 or row >= rows:
		return true
	return cells[row * columns + column] == 1


func set_blocked(column: int, row: int, blocked: bool) -> void:
	if column < 0 or column >= columns or row < 0 or row >= rows:
		return
	ensure_size()
	cells[row * columns + column] = 1 if blocked else 0
	emit_changed()
