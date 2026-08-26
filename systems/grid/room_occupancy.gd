class_name RoomOccupancy
extends RefCounted

## Estado dinámico de ocupación de una habitación.
## Las paredes estáticas se leen de las físicas definidas en el TileSet.
var blocked_cells: Dictionary = {}
var own_physics_cells: Dictionary = {}
var generated_physics_cells: Dictionary = {}


func rebuild(static_blocked_cells: Dictionary, objects: Array[PlaceableObject]) -> void:
	blocked_cells = static_blocked_cells.duplicate()
	own_physics_cells.clear()
	generated_physics_cells.clear()
	for object in objects:
		for local_cell in object.get_navigation_blocking_cells():
			var room_cell := object.base_cell + local_cell
			blocked_cells[room_cell] = true
			if object.provides_own_physics_body:
				own_physics_cells[room_cell] = true
			else:
				generated_physics_cells[room_cell] = true


func is_blocked(cell: Vector2i) -> bool:
	return blocked_cells.has(cell)


func needs_generated_physics(cell: Vector2i) -> bool:
	return generated_physics_cells.has(cell) and not own_physics_cells.has(cell)
