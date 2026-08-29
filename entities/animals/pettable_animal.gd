class_name PettableAnimal
extends AnimalObject

## Comportamiento visual, físico e interactivo compartido por las especies que
## pueden acariciarse. Cat, Dog y Bird solo declaran su identidad de especie.
signal selected(animal: PettableAnimal)
signal care_requested(animal: PettableAnimal)

const CARE_DISTANCE_IN_CELLS := 2.0
const CARE_SHAKE_DURATION := 3.0
const CARE_SHAKE_OFFSET := 3.0

## Ancho visible y físico medido en casillas. La altura visible se calcula a
## partir del aspect ratio de la zona opaca de la textura.
@export_range(1, 4, 1) var visual_columns := 1:
	set(value):
		visual_columns = maxi(1, value)
		_update_footprint()
@export_range(1, 4, 1) var base_columns := 1:
	set(value):
		base_columns = maxi(1, value)
		_update_footprint()
@export var cell_size := Vector2(48, 48):
	set(value):
		cell_size = value
		_update_footprint()

@onready var visual: Sprite2D = $Visual
@onready var interaction_area: Area2D = $InteractionArea
@onready var collision_shape: CollisionShape2D = $InteractionArea/CollisionShape2D
@onready var body_collision_shape: CollisionShape2D = $Body/CollisionShape2D
@onready var hand_action: Area2D = $HandAction
@onready var hand_icon: Sprite2D = $HandAction/Icon
@onready var hand_collision_shape: CollisionShape2D = $HandAction/CollisionShape2D

var visual_rest_position := Vector2.ZERO
var visual_rows := 1
var visual_top_y := -48.0
var care_in_progress := false
var is_in_edit_mode := false


func _ready() -> void:
	provides_own_physics_body = true
	is_interactable = true
	_update_footprint()
	interaction_area.input_event.connect(_on_interaction_area_input_event)
	hand_action.input_event.connect(_on_hand_action_input_event)
	set_hand_visible(false)


func configure_grid_size(new_cell_size: Vector2) -> void:
	cell_size = new_cell_size


func get_cell_anchor_offset() -> Vector2:
	# base_cell es la casilla inferior izquierda; el nodo se centra sobre toda
	# la base para que sprite y colisión sean simétricos.
	return Vector2((base_columns - 1) * 0.5, 0.0)


func get_navigation_blocking_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if blocks_navigation:
		for x in range(base_columns):
			cells.append(Vector2i(x, 0))
	return cells


func get_visual_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(-(visual_rows - 1), 1):
		for x in range(visual_columns):
			cells.append(Vector2i(x, y))
	return cells


func get_interaction_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = [Vector2i(-1, 0), Vector2i(base_columns, 0)]
	for x in range(base_columns):
		cells.append(Vector2i(x, -1))
		cells.append(Vector2i(x, 1))
	return cells


func _update_footprint() -> void:
	if not is_instance_valid(visual) or not is_instance_valid(collision_shape) or not is_instance_valid(body_collision_shape) or not is_instance_valid(hand_action):
		return
	if visual.texture != null:
		var image := visual.texture.get_image()
		var used_rect := image.get_used_rect()
		var opaque_size := Vector2(used_rect.size)
		if opaque_size.x <= 0.0 or opaque_size.y <= 0.0:
			return
		# Solo el ancho configurado determina la escala. X e Y usan el mismo
		# factor, por lo que la ilustración nunca se deforma.
		var target_width := visual_columns * cell_size.x
		var scale_factor := target_width / opaque_size.x
		visual.scale = Vector2.ONE * scale_factor
		visual.centered = false
		var opaque_width := opaque_size.x * scale_factor
		var opaque_height := opaque_size.y * scale_factor
		visual_rows = maxi(1, ceili(opaque_height / cell_size.y))
		footprint = Vector2i(visual_columns, visual_rows)
		var opaque_left := used_rect.position.x * scale_factor
		var opaque_bottom := (used_rect.position.y + used_rect.size.y) * scale_factor
		visual.position = Vector2(-opaque_width * 0.5 - opaque_left, cell_size.y * 0.5 - opaque_bottom)
		visual_rest_position = visual.position
		visual_top_y = cell_size.y * 0.5 - opaque_height
	else:
		visual_rows = 1
		footprint = Vector2i(visual_columns, visual_rows)

	var shape := RectangleShape2D.new()
	shape.size = Vector2(cell_size.x * base_columns, cell_size.y)
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
	hand_action.position = Vector2(0.0, visual_top_y - cell_size.y * 0.35)
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
