@tool
class_name ShelterRoom
extends Node2D

const CAT_SIAMESE_SCENE := preload("res://entities/animals/cat_siames.tscn")
const CAT_TEST_CELL := Vector2i(5, 8)

signal transition_reached(destination_room: String)

@export var room_id := "shelter_entrada"
@export var table_cell := Vector2i(9, 5)
@export var rug_cell := Vector2i(2, 8)
@export var rug_size := Vector2i(4, 2)
@export var transition_columns := PackedInt32Array([16, 17, 18, 19])
@export var grid_data: RoomGridData = RoomGridData.new():
	set(value):
		if grid_data != null and grid_data.changed.is_connected(_on_grid_data_changed):
			grid_data.changed.disconnect(_on_grid_data_changed)
		grid_data = value
		if grid_data != null:
			grid_data.changed.connect(_on_grid_data_changed)
		queue_redraw()

var cell_size := Vector2(48, 48)
var room_columns := 20
var room_rows := 12
var room_top_row := 1
var show_grid := true
var navigation_region: NavigationRegion2D
var world_y_sort: Node2D
var transition_armed := false


func _ready() -> void:
	if grid_data != null and not grid_data.changed.is_connected(_on_grid_data_changed):
		grid_data.changed.connect(_on_grid_data_changed)
	if Engine.is_editor_hint():
		# Al abrir una sala, fuerza el suelo/grid aunque no se haya editado aún.
		call_deferred("_refresh_editor_preview")


func _refresh_editor_preview() -> void:
	queue_redraw()


func _on_grid_data_changed() -> void:
	queue_redraw()


func configure(new_cell_size: Vector2, new_room_columns: int, new_room_rows: int, new_room_top_row: int, new_show_grid: bool) -> void:
	cell_size = new_cell_size
	room_columns = new_room_columns
	room_rows = new_room_rows
	room_top_row = new_room_top_row
	show_grid = new_show_grid
	if not Engine.is_editor_hint():
		build_runtime_world()
	queue_redraw()


func create_player(new_cell_size: Vector2, spawn_position: Vector2) -> PlayerController:
	var new_player := PlayerController.new()
	new_player.name = "Player_BlueSquare_1x2"
	new_player.cell_size = new_cell_size
	new_player.position = spawn_position
	new_player.collision_layer = 1
	new_player.collision_mask = 1

	var agent := NavigationAgent2D.new()
	agent.name = "NavigationAgent2D"
	agent.path_desired_distance = 4.0
	agent.target_desired_distance = 4.0
	new_player.add_child(agent)
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	new_player.add_child(collision)
	world_y_sort.add_child(new_player)
	return new_player


func cell_to_navigation_position(cell: Vector2i) -> Vector2:
	return Vector2((cell.x + 0.5) * cell_size.x, (cell.y + 0.5) * cell_size.y)


func get_navigation_destination(requested_cell: Vector2i) -> Vector2:
	# La transición existe solo donde se ha dejado una apertura en la pared.
	if requested_cell.y == room_top_row:
		if is_transition_request(requested_cell):
			var transition_cell := Vector2i(requested_cell.x, room_top_row + 1)
			if is_walkable_for_player(transition_cell):
				return cell_to_navigation_position(transition_cell)
		return Vector2.INF

	var clamped := Vector2i(clampi(requested_cell.x, 0, room_columns - 1), clampi(requested_cell.y, room_top_row + 1, room_top_row + room_rows - 1))
	if not is_walkable_for_player(clamped):
		return Vector2.INF
	return cell_to_navigation_position(clamped)


func is_transition_request(cell: Vector2i) -> bool:
	return room_id == "shelter_entrada" and cell.y == room_top_row and transition_columns.has(cell.x)


func set_transition_armed(armed: bool) -> void:
	transition_armed = armed


func get_transition_column_for_position(world_position: Vector2) -> int:
	return clampi(floori(world_position.x / cell_size.x), 0, room_columns - 1)


func check_transition_at_player_base(base_position: Vector2) -> void:
	if not transition_armed or room_id != "shelter_entrada":
		return
	var base_cell := Vector2i(floori(base_position.x / cell_size.x), floori(base_position.y / cell_size.y))
	# El origen de PlayerController es su base: solo esa fila decide la puerta.
	if base_cell.y == room_top_row + 1 and transition_columns.has(base_cell.x):
		transition_armed = false
		transition_reached.emit("shelter_dogs")


func is_walkable_for_player(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.x >= room_columns or cell.y <= room_top_row or cell.y >= room_top_row + room_rows:
		return false
	var cells := get_blocked_cells()
	# El personaje se ve en dos filas, pero solo su fila inferior tiene hit box.
	# Por tanto, la navegación solo reserva una casilla por personaje.
	return not cells.has(cell)


func get_blocked_cells() -> Dictionary:
	var result := {}
	if grid_data != null:
		grid_data.ensure_size()
		for x in range(mini(room_columns, grid_data.columns)):
			for y in range(mini(room_rows, grid_data.rows)):
				if grid_data.is_blocked(x, y):
					result[Vector2i(x, room_top_row + y)] = true
	# Muebles: colisiones dinámicas que se combinan con las del fondo.
	for x in range(table_cell.x, table_cell.x + 2):
		for y in range(table_cell.y, table_cell.y + 2):
			result[Vector2i(x, y)] = true
	if room_id == "shelter_entrada":
		# El gato es un bloqueo dinámico: se incluye al hornear la navegación.
		result[CAT_TEST_CELL] = true
	return result


func build_runtime_world() -> void:
	for child in get_children():
		child.queue_free()
	var blocked := get_blocked_cells()
	create_navigation_region(blocked)
	create_base_collisions(blocked)
	create_rug()
	create_table_collision_and_visual()
	create_entrance_cat()
	create_transition_zone()


func create_navigation_region(blocked: Dictionary) -> void:
	navigation_region = NavigationRegion2D.new()
	navigation_region.name = "NavigationRegion2D"
	var navigation_polygon := NavigationPolygon.new()
	var vertices := PackedVector2Array()
	for x in range(room_columns):
		for y in range(room_top_row + 1, room_top_row + room_rows):
			var cell := Vector2i(x, y)
			if not is_walkable_for_player(cell):
				continue
			var start := vertices.size()
			var top_left := Vector2(x * cell_size.x, y * cell_size.y)
			vertices.append_array(PackedVector2Array([top_left, top_left + Vector2(cell_size.x, 0), top_left + cell_size, top_left + Vector2(0, cell_size.y)]))
			navigation_polygon.add_polygon(PackedInt32Array([start, start + 1, start + 2, start + 3]))
	navigation_polygon.vertices = vertices
	navigation_region.navigation_polygon = navigation_polygon
	add_child(navigation_region)


func create_base_collisions(blocked: Dictionary) -> void:
	var collision_root := Node2D.new()
	collision_root.name = "BaseRoomCollisions"
	add_child(collision_root)
	for cell in blocked:
		# Cat tiene su propio StaticBody2D; aquí solo se crean las otras colisiones.
		if room_id == "shelter_entrada" and cell == CAT_TEST_CELL:
			continue
		var body := StaticBody2D.new()
		body.position = cell_to_navigation_position(cell)
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = cell_size
		shape.shape = rectangle
		body.add_child(shape)
		collision_root.add_child(body)


func create_rug() -> void:
	var new_rug := Rug.new()
	new_rug.name = "Rug_Configurable"
	new_rug.cell_size = cell_size
	new_rug.grid_cell = rug_cell
	new_rug.grid_size = rug_size
	add_child(new_rug)


func create_table_collision_and_visual() -> void:
	world_y_sort = Node2D.new()
	world_y_sort.name = "WorldYSort"
	world_y_sort.y_sort_enabled = true
	add_child(world_y_sort)
	var table := WorldObject.new()
	table.name = "Table_2x2_YSort"
	table.kind = WorldObject.Kind.TABLE
	table.cell_size = cell_size
	table.position = Vector2((table_cell.x + 1) * cell_size.x, (table_cell.y + 2) * cell_size.y)
	world_y_sort.add_child(table)


func create_entrance_cat() -> void:
	if room_id != "shelter_entrada":
		return
	var cat := CAT_SIAMESE_SCENE.instantiate() as Cat
	cat.name = "CatSiames_Test"
	cat.configure_grid_size(cell_size)
	# Casilla de base del gato: no bloquea la navegación en esta prueba.
	cat.position = cell_to_navigation_position(CAT_TEST_CELL)
	cat.add_to_group("interactuables")
	world_y_sort.add_child(cat)


func create_transition_zone() -> void:
	if room_id != "shelter_entrada" or transition_columns.is_empty():
		return
	var start_column := transition_columns[0]
	var end_column := transition_columns[transition_columns.size() - 1]
	var zone := Area2D.new()
	zone.name = "TransitionToDogs"
	zone.position = Vector2((start_column + end_column + 1) * cell_size.x * 0.5, (room_top_row + 1.5) * cell_size.y)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2((end_column - start_column + 1) * cell_size.x, cell_size.y)
	collision.shape = shape
	zone.add_child(collision)
	add_child(zone)


func _draw() -> void:
	var room_rect := Rect2(Vector2(0, room_top_row * cell_size.y), Vector2(room_columns * cell_size.x, room_rows * cell_size.y))
	var floor_color := Color("f6dfb7") if room_id == "shelter_entrada" else Color("d9e9cf")
	draw_rect(room_rect, floor_color)
	draw_rect(room_rect, Color("5a4135"), false, 7.0)
	draw_rect(Rect2(room_rect.position, Vector2(room_rect.size.x, cell_size.y)), Color("c58e70"))
	draw_string(ThemeDB.fallback_font, room_rect.position + Vector2(16, cell_size.y * 0.62), "PARED DE FONDO → %s" % ("SHELTER DOGS" if room_id == "shelter_entrada" else ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("2b1a16"))
	if show_grid:
		var grid_color := Color(0.25, 0.20, 0.16, 0.22)
		for x in range(room_columns + 1):
			draw_line(Vector2(x * cell_size.x, room_rect.position.y), Vector2(x * cell_size.x, room_rect.end.y), grid_color, 1.0)
		for y in range(room_rows + 1):
			draw_line(Vector2(0, (room_top_row + y) * cell_size.y), Vector2(room_rect.end.x, (room_top_row + y) * cell_size.y), grid_color, 1.0)
	if Engine.is_editor_hint() and grid_data != null:
		grid_data.ensure_size()
		for x in range(mini(room_columns, grid_data.columns)):
			for y in range(mini(room_rows, grid_data.rows)):
				if grid_data.is_blocked(x, y):
					draw_rect(Rect2(Vector2(x * cell_size.x, (room_top_row + y) * cell_size.y), cell_size).grow(-3.0), Color(0.82, 0.16, 0.18, 0.55))
