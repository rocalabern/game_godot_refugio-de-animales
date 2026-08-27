class_name PlaceableObject
extends Node2D

## Contrato común para muebles, animales y otros elementos de una habitación.
## `base_cell` es la casilla donde se apoya el origen del nodo en el suelo.
signal interacted(actor: Node2D)

@export var base_cell := Vector2i.ZERO
@export var footprint := Vector2i.ONE
@export var blocks_navigation := true
@export var is_interactable := false
@export var uses_y_sort := true
@export var provides_own_physics_body := false


func configure_grid_size(_new_cell_size: Vector2) -> void:
	# Las subclases visuales redefinen este método si necesitan ajustar sprites.
	pass


func set_edit_mode(_is_active: bool) -> void:
	# Las subclases que tengan acciones propias pueden desactivarlas en edición.
	pass


func get_cell_anchor_offset() -> Vector2:
	# Desplazamiento desde el centro de base. Solo lo cambian objetos cuyo origen
	# no está en su punto de apoyo, como una alfombra anclada por su esquina.
	return Vector2.ZERO


func get_visual_cells() -> Array[Vector2i]:
	return get_occupied_cells()


func get_occupied_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(footprint.y):
		for x in range(footprint.x):
			cells.append(Vector2i(x, y))
	return cells


func get_navigation_blocking_cells() -> Array[Vector2i]:
	if not blocks_navigation:
		return []
	return get_occupied_cells()


func get_interaction_cells() -> Array[Vector2i]:
	return [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]


func interact(actor: Node2D) -> void:
	interacted.emit(actor)
