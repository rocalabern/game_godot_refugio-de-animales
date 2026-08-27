class_name Cat
extends AnimalObject

signal selected(cat: Cat)
signal care_requested(cat: Cat)

const CARE_DISTANCE_IN_CELLS := 2.0
const CARE_SHAKE_DURATION := 3.0
const CARE_SHAKE_OFFSET := 3.0

## Lógica específica común para todos los gatos del refugio.
@export var cell_size := Vector2(48, 48):
	set(value):
		cell_size = value
		_update_footprint()

@onready var visual: Sprite2D = $Visual
@onready var interaction_area: Area2D = $InteractionArea
@onready var collision_shape: CollisionShape2D = $InteractionArea/CollisionShape2D
@onready var body_collision_shape: CollisionShape2D = $CatBody/CollisionShape2D
@onready var hand_action: Area2D = $HandAction
@onready var hand_icon: Sprite2D = $HandAction/Icon
@onready var hand_collision_shape: CollisionShape2D = $HandAction/CollisionShape2D

var visual_rest_position := Vector2.ZERO
var care_in_progress := false
var is_in_edit_mode := false


func _ready() -> void:
	provides_own_physics_body = true
	footprint = Vector2i(1, 2)
	is_interactable = true
	_update_footprint()
	hand_action.input_event.connect(_on_hand_action_input_event)
	set_hand_visible(false)


func configure_grid_size(new_cell_size: Vector2) -> void:
	cell_size = new_cell_size


func get_navigation_blocking_cells() -> Array[Vector2i]:
	# El gato se dibuja en 1x2, pero solo sus patas/base ocupan una casilla.
	return [Vector2i.ZERO] if blocks_navigation else []


func get_visual_cells() -> Array[Vector2i]:
	return [Vector2i(0, -1), Vector2i.ZERO]


func _update_footprint() -> void:
	if not is_instance_valid(visual) or not is_instance_valid(collision_shape) or not is_instance_valid(body_collision_shape) or not is_instance_valid(hand_action):
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
		visual_rest_position = visual.position

	# Solo la fila inferior es interactuable, como en el personaje.
	var shape := RectangleShape2D.new()
	# El gato usa una única casilla física completa en las patas/base. El PNG y
	# su transparencia no participan nunca en el cálculo de colisiones.
	shape.size = cell_size
	collision_shape.shape = shape
	body_collision_shape.shape = shape
	configure_hand_action()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or care_in_progress or is_in_edit_mode:
		return
	set_hand_visible(is_player_nearby())


func configure_hand_action() -> void:
	if hand_icon.texture == null:
		return
	var hand_size := cell_size * 0.5
	var source_size := hand_icon.texture.get_size()
	var scale_factor := minf(hand_size.x / source_size.x, hand_size.y / source_size.y)
	hand_icon.scale = Vector2.ONE * scale_factor
	hand_action.position = Vector2(0.0, -cell_size.y * 2.1)
	var hand_shape := RectangleShape2D.new()
	hand_shape.size = source_size * scale_factor
	hand_collision_shape.shape = hand_shape


func is_player_nearby() -> bool:
	var player := get_tree().get_first_node_in_group("player") as PlayerController
	return player != null and global_position.distance_to(player.global_position) <= cell_size.x * CARE_DISTANCE_IN_CELLS


func set_hand_visible(is_visible: bool) -> void:
	if not is_instance_valid(hand_action):
		return
	hand_action.visible = is_visible
	hand_action.input_pickable = is_visible


func set_edit_mode(is_active: bool) -> void:
	is_in_edit_mode = is_active
	interaction_area.input_pickable = not is_active
	if is_active:
		set_hand_visible(false)


func _on_hand_action_input_event(_viewport: Node, event: InputEvent, _shape_index: int) -> void:
	if is_in_edit_mode or care_in_progress or not hand_action.visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_viewport().set_input_as_handled()
		start_care_action()
	elif event is InputEventScreenTouch and event.pressed:
		get_viewport().set_input_as_handled()
		start_care_action()


func start_care_action() -> void:
	care_in_progress = true
	set_hand_visible(false)
	receive_care()
	care_requested.emit(self)
	var shake := create_tween()
	shake.set_loops(roundi(CARE_SHAKE_DURATION / 0.12))
	shake.tween_property(visual, "position:x", visual_rest_position.x + CARE_SHAKE_OFFSET, 0.06)
	shake.tween_property(visual, "position:x", visual_rest_position.x - CARE_SHAKE_OFFSET, 0.06)
	shake.finished.connect(_finish_care_action)


func _finish_care_action() -> void:
	visual.position = visual_rest_position
	care_in_progress = false


func _on_interaction_area_input_event(_viewport: Node, event: InputEvent, _shape_index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		selected.emit(self)
	elif event is InputEventScreenTouch and event.pressed:
		selected.emit(self)
