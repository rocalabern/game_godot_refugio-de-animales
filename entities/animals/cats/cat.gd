class_name Cat
extends AnimalObject

signal selected(cat: Cat)

## Lógica específica común para todos los gatos del refugio.
@export var cell_size := Vector2(48, 48):
	set(value):
		cell_size = value
		_update_footprint()

@onready var visual: Sprite2D = $Visual
@onready var interaction_area: Area2D = $InteractionArea
@onready var collision_shape: CollisionShape2D = $InteractionArea/CollisionShape2D
@onready var body_collision_shape: CollisionShape2D = $CatBody/CollisionShape2D


func _ready() -> void:
	provides_own_physics_body = true
	footprint = Vector2i(1, 2)
	is_interactable = true
	_update_footprint()


func configure_grid_size(new_cell_size: Vector2) -> void:
	cell_size = new_cell_size


func get_navigation_blocking_cells() -> Array[Vector2i]:
	# El gato se dibuja en 1x2, pero solo sus patas/base ocupan una casilla.
	return [Vector2i.ZERO] if blocks_navigation else []


func get_visual_cells() -> Array[Vector2i]:
	return [Vector2i(0, -1), Vector2i.ZERO]


func _update_footprint() -> void:
	if not is_instance_valid(visual) or not is_instance_valid(collision_shape) or not is_instance_valid(body_collision_shape):
		return
	# Sprite de 1 columna x 2 filas, con el origen en las patas/base.
	if visual.texture != null:
		var target_size := Vector2(cell_size.x, cell_size.y * 2.0)
		visual.scale = target_size / visual.texture.get_size()
		visual.centered = false
		# El PNG tiene transparencia alrededor. Se alinea el borde inferior del
		# dibujo real a la base del gato, no el borde inferior del lienzo PNG.
		var used_rect := visual.texture.get_image().get_used_rect()
		var opaque_bottom := (used_rect.position.y + used_rect.size.y) * visual.scale.y
		visual.position = Vector2(-target_size.x * 0.5, cell_size.y * 0.5 - opaque_bottom)

	# Solo la fila inferior es interactuable, como en el personaje.
	var shape := RectangleShape2D.new()
	# El gato usa una única casilla física completa en las patas/base. El PNG y
	# su transparencia no participan nunca en el cálculo de colisiones.
	shape.size = cell_size
	collision_shape.shape = shape
	body_collision_shape.shape = shape


func _on_interaction_area_input_event(_viewport: Node, event: InputEvent, _shape_index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		selected.emit(self)
	elif event is InputEventScreenTouch and event.pressed:
		selected.emit(self)
