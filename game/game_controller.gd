class_name GameController
extends Node2D

@export_category("Grid")
@export var screen_columns := 21
@export var room_columns := 20
@export var room_rows := 12
@export var menu_rows := 1
@export var show_grid := true
@export var initial_room: PackedScene
@export var initial_spawn_cell := Vector2i(9, 10)

var cell_size := Vector2.ZERO
var room_top_row := 1
var player: PlayerController
var current_room: ShelterRoom
var interaction_controller := InteractionController.new()
var edit_mode := false
var dragged_table: Table
var drag_pointer_offset := Vector2.ZERO
# Estado de edición de esta partida. Las escenas se vuelven a instanciar al
# cambiar de habitación, así que no deben ser la fuente de verdad en runtime.
var room_table_positions: Dictionary = {}

@onready var room_container: Node2D = $RoomContainer
@onready var animal_profile: CanvasLayer = $AnimalProfile
@onready var menu_toggle: Button = $MenuUI/MenuToggle
@onready var menu_panel: PanelContainer = $MenuUI/MenuPanel
@onready var edit_button: Button = $MenuUI/MenuPanel/Margin/Content/EditButton


func _ready() -> void:
	menu_toggle.pressed.connect(toggle_menu)
	edit_button.pressed.connect(start_edit_mode)
	set_menu_open(false)
	cell_size = Vector2(get_viewport_rect().size.x / screen_columns, get_viewport_rect().size.y / (room_rows + menu_rows))
	room_top_row = menu_rows
	if initial_room != null:
		load_room(initial_room, &"", initial_spawn_cell)


func load_room(room_scene: PackedScene, spawn_id: StringName, fallback_cell: Vector2i) -> void:
	if current_room != null and player != null:
		current_room.detach_player(player)
	for child in room_container.get_children():
		child.queue_free()
	current_room = room_scene.instantiate() as ShelterRoom
	room_container.add_child(current_room)
	current_room.configure(cell_size, room_columns, room_rows, room_top_row, show_grid)
	current_room.apply_table_position_overrides(room_table_positions.get(current_room.get_room_id(), {}))
	current_room.doorway_requested.connect(_on_doorway_requested)
	current_room.animal_interaction_requested.connect(_on_animal_interaction_requested)
	var spawn_position := current_room.get_spawn_position(spawn_id, fallback_cell) if not spawn_id.is_empty() else current_room.cell_to_navigation_position(fallback_cell)
	if player == null:
		player = current_room.create_player(spawn_position)
	else:
		current_room.attach_player(player, spawn_position)


func _unhandled_input(event: InputEvent) -> void:
	if edit_mode:
		handle_edit_input(event)
		return
	if menu_panel.visible and event.is_action_pressed("ui_cancel"):
		set_menu_open(false)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		move_player_to(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		move_player_to(event.position)


func move_player_to(screen_position: Vector2) -> void:
	if edit_mode or current_room == null or player == null:
		return
	var requested_cell := current_room.get_requested_cell(screen_position)
	if requested_cell.y < room_top_row:
		return
	if interaction_controller.request_at_cell(current_room, player, requested_cell):
		return
	var destination := current_room.get_navigation_destination(requested_cell)
	if destination != Vector2.INF:
		player.move_to(destination)


func toggle_menu() -> void:
	if edit_mode:
		stop_edit_mode()
		return
	set_menu_open(not menu_panel.visible)


func set_menu_open(is_open: bool) -> void:
	if edit_mode:
		menu_panel.hide()
		menu_toggle.text = "×"
		menu_toggle.tooltip_text = "Cerrar edición"
		return
	menu_panel.visible = is_open
	menu_toggle.text = "×" if is_open else "☰"
	menu_toggle.tooltip_text = "Cerrar menú" if is_open else "Abrir menú"


func start_edit_mode() -> void:
	edit_mode = true
	menu_panel.hide()
	menu_toggle.text = "×"
	menu_toggle.tooltip_text = "Cerrar edición"
	if player != null:
		player.stop()
	if current_room != null:
		current_room.set_edit_mode(true)


func stop_edit_mode() -> void:
	if dragged_table != null and is_instance_valid(dragged_table) and current_room != null:
		current_room.reset_table_position(dragged_table)
	dragged_table = null
	edit_mode = false
	if current_room != null:
		current_room.set_edit_mode(false)
	set_menu_open(false)


func handle_edit_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		stop_edit_mode()
		get_viewport().set_input_as_handled()
		return
	if current_room == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_table_drag(event.position)
		else:
			finish_table_drag()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and dragged_table != null:
		dragged_table.global_position = event.position + drag_pointer_offset
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		if event.pressed:
			start_table_drag(event.position)
		else:
			finish_table_drag()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and dragged_table != null:
		dragged_table.global_position = event.position + drag_pointer_offset
		get_viewport().set_input_as_handled()


func start_table_drag(pointer_position: Vector2) -> void:
	if dragged_table != null:
		return
	var table := current_room.get_table_at_position(pointer_position)
	if table == null:
		return
	dragged_table = table
	drag_pointer_offset = table.global_position - pointer_position


func finish_table_drag() -> void:
	if dragged_table == null or not is_instance_valid(dragged_table):
		dragged_table = null
		return
	var target_cell := current_room.get_table_base_cell_from_position(dragged_table)
	if current_room.move_table_to_cell(dragged_table, target_cell):
		remember_table_position(dragged_table, target_cell)
	else:
		current_room.reset_table_position(dragged_table)
	dragged_table = null


func remember_table_position(table: Table, base_cell: Vector2i) -> void:
	var room_id := current_room.get_room_id()
	var positions := room_table_positions.get(room_id, {}) as Dictionary
	positions[table.name] = base_cell
	room_table_positions[room_id] = positions


func _on_doorway_requested(doorway: Doorway, doorway_player: PlayerController) -> void:
	if edit_mode or doorway_player != player or doorway.destination_scene_path.is_empty():
		return
	if doorway.transition_sound != null:
		$TransitionAudio.stream = doorway.transition_sound
		$TransitionAudio.play()
	var destination_scene := load(doorway.destination_scene_path) as PackedScene
	if destination_scene == null:
		push_error("No se pudo cargar el destino de la puerta: %s" % doorway.destination_scene_path)
		return
	load_room(destination_scene, doorway.destination_spawn_id, initial_spawn_cell)


func _on_animal_interaction_requested(animal: AnimalObject) -> void:
	if not edit_mode and animal_profile != null:
		animal_profile.call(&"open_for", animal)
