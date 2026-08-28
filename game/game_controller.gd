class_name GameController
extends Node2D

const ANIMAL_PICKUP_MINIGAME := preload("res://minigames/animal_pickup/animal_pickup_minigame.tscn")
const WORLD_MAP := preload("res://map/map_scene.tscn")
const SHELTER_ENTRANCE := preload("res://rooms/shelter_entrada/shelter_entrada.tscn")
const RESCUED_DOG_SCENES: Array[PackedScene] = [
	preload("res://entities/animals/dogs/beagle.tscn"),
	preload("res://entities/animals/dogs/german_sheperd.tscn"),
	preload("res://entities/animals/dogs/huskie.tscn"),
	preload("res://entities/animals/dogs/poodle.tscn"),
]
const DOG_NAMES: Array[String] = [
	"Luna", "Toby", "Nala", "Max", "Kira", "Bruno", "Milo", "Coco",
	"Lola", "Rocky", "Bimba", "Leo", "Duna", "Simba", "Noa", "Otto",
]
const RESCUED_DOG_CELLS: Array[Vector2i] = [
	Vector2i(7, 9), Vector2i(8, 9), Vector2i(9, 9), Vector2i(11, 9),
	Vector2i(12, 9), Vector2i(13, 9), Vector2i(14, 9), Vector2i(15, 9),
	Vector2i(16, 9), Vector2i(17, 9), Vector2i(7, 11), Vector2i(9, 11),
]

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
var animal_states: Dictionary = {}
var random := RandomNumberGenerator.new()
var animal_pickup_minigame: AnimalPickupMinigame
var world_map: WorldMap
var map_source_doorway: Doorway
var rescued_dogs: Array[Dictionary] = []
var next_rescued_dog_id := 1

@onready var room_container: Node2D = $RoomContainer
@onready var animal_profile: CanvasLayer = $AnimalProfile
@onready var menu_toggle: Button = $MenuUI/MenuToggle
@onready var menu_panel: PanelContainer = $MenuUI/MenuPanel
@onready var edit_button: Button = $MenuUI/MenuPanel/Margin/Content/EditButton
@onready var pickup_button: Button = $MenuUI/MenuPanel/Margin/Content/PickupButton
@onready var map_button: Button = $MenuUI/MenuPanel/Margin/Content/MapButton


func _ready() -> void:
	random.randomize()
	menu_toggle.pressed.connect(toggle_menu)
	edit_button.pressed.connect(start_edit_mode)
	pickup_button.pressed.connect(open_animal_pickup_minigame)
	map_button.pressed.connect(open_world_map)
	set_menu_open(false)
	cell_size = Vector2(get_viewport_rect().size.x / screen_columns, get_viewport_rect().size.y / (room_rows + menu_rows))
	room_top_row = menu_rows
	if initial_room != null:
		load_room(initial_room, &"", initial_spawn_cell)


func load_room(room_scene: PackedScene, spawn_id: StringName, fallback_cell: Vector2i) -> void:
	if current_room != null and player != null:
		current_room.store_animal_states(animal_states)
		current_room.detach_player(player)
	for child in room_container.get_children():
		child.queue_free()
	current_room = room_scene.instantiate() as ShelterRoom
	room_container.add_child(current_room)
	current_room.configure(cell_size, room_columns, room_rows, room_top_row, show_grid)
	current_room.apply_table_position_overrides(room_table_positions.get(current_room.get_room_id(), {}))
	current_room.initialize_or_restore_animal_states(animal_states, random)
	_restore_rescued_dogs_in_current_room()
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


func open_animal_pickup_minigame(environment := "") -> void:
	if animal_pickup_minigame != null:
		return
	set_menu_open(false)
	if player != null:
		player.stop()
	animal_pickup_minigame = ANIMAL_PICKUP_MINIGAME.instantiate() as AnimalPickupMinigame
	animal_pickup_minigame.requested_environment = environment
	animal_pickup_minigame.closed.connect(_on_animal_pickup_minigame_closed)
	add_child(animal_pickup_minigame)


func _on_animal_pickup_minigame_closed(successful_session: bool) -> void:
	if animal_pickup_minigame == null:
		return
	animal_pickup_minigame.queue_free()
	animal_pickup_minigame = null
	if successful_session:
		_register_rescued_dog()
	if world_map != null:
		if successful_session:
			world_map.close(true)
		else:
			get_tree().paused = true
	elif successful_session:
		_restore_rescued_dogs_in_current_room()


func open_world_map() -> void:
	if world_map != null:
		return
	set_menu_open(false)
	if player != null:
		player.stop()
	world_map = WORLD_MAP.instantiate() as WorldMap
	world_map.closed.connect(_on_world_map_closed)
	world_map.animal_pickup_requested.connect(open_animal_pickup_minigame)
	add_child(world_map)


func _on_world_map_closed(return_to_shelter: bool) -> void:
	if world_map == null:
		return
	world_map.queue_free()
	world_map = null
	if return_to_shelter:
		load_room(SHELTER_ENTRANCE, &"from_map", initial_spawn_cell)
	elif map_source_doorway != null and is_instance_valid(map_source_doorway):
		map_source_doorway.reset_transition()
		player.position = current_room.get_spawn_position(&"from_map", initial_spawn_cell)
	map_source_doorway = null


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
	if edit_mode or doorway_player != player:
		return
	if doorway.opens_world_map:
		map_source_doorway = doorway
		open_world_map()
		return
	if doorway.destination_scene_path.is_empty():
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


func _register_rescued_dog() -> void:
	var used_cells: Dictionary = {}
	for dog_data in rescued_dogs:
		used_cells[dog_data.get("base_cell", Vector2i.ZERO)] = true
	var selected_cell := RESCUED_DOG_CELLS[rescued_dogs.size() % RESCUED_DOG_CELLS.size()]
	for candidate in RESCUED_DOG_CELLS:
		if not used_cells.has(candidate):
			selected_cell = candidate
			break
	var dog_id := "RescuedDog_%03d" % next_rescued_dog_id
	next_rescued_dog_id += 1
	rescued_dogs.append({
		"id": dog_id,
		"scene": RESCUED_DOG_SCENES[random.randi_range(0, RESCUED_DOG_SCENES.size() - 1)],
		"pet_name": DOG_NAMES[random.randi_range(0, DOG_NAMES.size() - 1)],
		"base_cell": selected_cell,
	})


func _restore_rescued_dogs_in_current_room() -> void:
	if current_room == null or current_room.get_room_id() != "shelter_entrada":
		return
	for dog_data in rescued_dogs:
		var dog_scene := dog_data.get("scene") as PackedScene
		var dog_id := String(dog_data.get("id", "RescuedDog"))
		if current_room.find_child(dog_id, true, false) != null:
			continue
		var preferred_cell := dog_data.get("base_cell", Vector2i.ZERO) as Vector2i
		var dog := current_room.add_runtime_animal(dog_scene, dog_id, preferred_cell)
		if dog == null:
			push_warning("No se pudo colocar al perro rescatado '%s' en %s." % [dog_id, preferred_cell])
			continue
		dog.pet_name = String(dog_data.get("pet_name", ""))
		var state_key := current_room.get_animal_state_key(dog)
		if animal_states.has(state_key):
			dog.apply_runtime_state(animal_states[state_key] as Dictionary)
		else:
			dog.initialize_runtime_state(random)
			animal_states[state_key] = dog.get_runtime_state()
