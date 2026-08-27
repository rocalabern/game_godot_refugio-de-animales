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

@onready var room_container: Node2D = $RoomContainer
@onready var animal_profile: CanvasLayer = $AnimalProfile


func _ready() -> void:
	cell_size = Vector2(get_viewport_rect().size.x / screen_columns, get_viewport_rect().size.y / (room_rows + menu_rows))
	room_top_row = menu_rows
	if initial_room != null:
		load_room(initial_room, &"", initial_spawn_cell)
	queue_redraw()


func load_room(room_scene: PackedScene, spawn_id: StringName, fallback_cell: Vector2i) -> void:
	if current_room != null and player != null:
		current_room.detach_player(player)
	for child in room_container.get_children():
		child.queue_free()
	current_room = room_scene.instantiate() as ShelterRoom
	room_container.add_child(current_room)
	current_room.configure(cell_size, room_columns, room_rows, room_top_row, show_grid)
	current_room.doorway_requested.connect(_on_doorway_requested)
	current_room.animal_interaction_requested.connect(_on_animal_interaction_requested)
	var spawn_position := current_room.get_spawn_position(spawn_id, fallback_cell) if not spawn_id.is_empty() else current_room.cell_to_navigation_position(fallback_cell)
	if player == null:
		player = current_room.create_player(spawn_position)
	else:
		current_room.attach_player(player, spawn_position)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		move_player_to(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		move_player_to(event.position)


func move_player_to(screen_position: Vector2) -> void:
	if current_room == null or player == null:
		return
	var requested_cell := current_room.get_requested_cell(screen_position)
	if requested_cell.y < room_top_row:
		return
	if interaction_controller.request_at_cell(current_room, player, requested_cell):
		return
	var destination := current_room.get_navigation_destination(requested_cell)
	if destination != Vector2.INF:
		player.move_to(destination)


func _on_doorway_requested(doorway: Doorway, doorway_player: PlayerController) -> void:
	if doorway_player != player or doorway.destination_scene_path.is_empty():
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
	if animal_profile != null:
		animal_profile.call(&"open_for", animal)


func _draw() -> void:
	if cell_size == Vector2.ZERO:
		return
	draw_rect(Rect2(Vector2.ZERO, Vector2(get_viewport_rect().size.x, cell_size.y)), Color("25435c"))
	var room_name := current_room.get_room_id().to_upper() if current_room != null else ""
	draw_string(ThemeDB.fallback_font, Vector2(16, cell_size.y * 0.62), "REFUGIO · %s   |   Menús" % room_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
