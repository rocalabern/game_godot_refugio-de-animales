extends Node2D

@export_category("Grid")
@export var screen_columns := 21
@export var room_columns := 20
@export var room_rows := 12
@export var menu_rows := 1
@export var show_grid := true

const ROOM_ENTRANCE := "shelter_entrada"
const ROOM_DOGS := "shelter_dogs"

var cell_size := Vector2.ZERO
var room_top_row := 1
var current_room_id := ROOM_ENTRANCE
var player: PlayerController
var current_room: ShelterRoom

@onready var room_container: Node2D = $RoomContainer


func _ready() -> void:
	cell_size = Vector2(get_viewport_rect().size.x / screen_columns, get_viewport_rect().size.y / (room_rows + menu_rows))
	room_top_row = menu_rows
	load_room(ROOM_ENTRANCE, Vector2i(9, 10))
	queue_redraw()


func load_room(room_id: String, spawn_cell: Vector2i) -> void:
	for child in room_container.get_children():
		child.queue_free()
	current_room_id = room_id
	current_room = load("res://rooms/%s.tscn" % room_id).instantiate() as ShelterRoom
	room_container.add_child(current_room)
	current_room.configure(cell_size, room_columns, room_rows, room_top_row, show_grid)
	current_room.transition_reached.connect(_on_transition_reached)
	player = current_room.create_player(cell_size, current_room.cell_to_navigation_position(spawn_cell))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		move_player_to(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		move_player_to(event.position)


func move_player_to(screen_position: Vector2) -> void:
	var requested_cell := Vector2i(floori(screen_position.x / cell_size.x), floori(screen_position.y / cell_size.y))
	if requested_cell.y < room_top_row:
		return
	# Entrar en una puerta exige haber clicado la pared/abertura, no solo pasar
	# caminando horizontalmente por encima de su Area2D.
	current_room.set_transition_armed(current_room.is_transition_request(requested_cell))
	var destination := current_room.get_navigation_destination(requested_cell)
	if destination == Vector2.INF:
		current_room.set_transition_armed(false)
		return
	player.move_to(destination)


func _on_transition_reached(destination_room: String) -> void:
	if destination_room == ROOM_DOGS and current_room_id == ROOM_ENTRANCE:
		var entrance_column := current_room.get_transition_column_for_position(player.global_position)
		load_room(ROOM_DOGS, Vector2i(entrance_column, room_top_row + 3))


func _physics_process(_delta: float) -> void:
	# La transición se evalúa con el punto de base del personaje, no con el alto
	# completo de su sprite ni con una primera superposición de rectángulos.
	if current_room != null and player != null:
		current_room.check_transition_at_player_base(player.global_position)


func _draw() -> void:
	if cell_size == Vector2.ZERO:
		return
	draw_rect(Rect2(Vector2.ZERO, Vector2(get_viewport_rect().size.x, cell_size.y)), Color("25435c"))
	draw_string(ThemeDB.fallback_font, Vector2(16, cell_size.y * 0.62), "REFUGIO · %s   |   Menús" % current_room_id.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
