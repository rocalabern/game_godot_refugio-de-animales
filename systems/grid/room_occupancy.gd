class_name RoomOccupancy
extends RefCounted

## Fuente única de verdad para navegación y colisiones de una habitación.
var blocked_cells: Dictionary = {}
var own_physics_cells: Dictionary = {}


func rebuild(grid_data: RoomGridData, room_columns: int, room_rows: int, top_row: int, objects: Array[PlaceableObject]) -> void:
	blocked_cells.clear()
	own_physics_cells.clear()
	if grid_data != null:
		grid_data.ensure_size()
		for x in range(mini(room_columns, grid_data.columns)):
			for y in range(mini(room_rows, grid_data.rows)):
				if grid_data.is_blocked(x, y):
					blocked_cells[Vector2i(x, top_row + y)] = true
	for object in objects:
		for local_cell in object.get_navigation_blocking_cells():
			var room_cell := object.base_cell + local_cell
			blocked_cells[room_cell] = true
			if object.provides_own_physics_body:
				own_physics_cells[room_cell] = true


func is_blocked(cell: Vector2i) -> bool:
	return blocked_cells.has(cell)


func needs_generated_physics(cell: Vector2i) -> bool:
	return blocked_cells.has(cell) and not own_physics_cells.has(cell)
