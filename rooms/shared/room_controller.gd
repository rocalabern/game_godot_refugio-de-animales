@tool
class_name ShelterRoom
extends Node2D

const PLAYER_SCENE := preload("res://entities/player/player.tscn")
const EDITOR_CELL_SIZE := Vector2(48, 48)

signal doorway_requested(doorway: Doorway, player: PlayerController)

@export var room_data: RoomData:
	set(value):
		room_data = value
		_connect_grid_data()
		queue_redraw()
@export_range(1, 4, 1) var wall_height_cells := 2:
	set(value):
		wall_height_cells = value
		queue_redraw()

# Propiedad de compatibilidad con el editor de colisiones. La fuente de verdad
# es RoomData, no una variable separada de la escena.
var grid_data: RoomGridData:
	get:
		return room_data.grid_data if room_data != null else null
	set(value):
		if room_data == null:
			room_data = RoomData.new()
		room_data.grid_data = value
		_connect_grid_data()
		queue_redraw()

var cell_size := Vector2(48, 48)
var room_columns := 20
var room_rows := 12
var room_top_row := 1
var show_grid := true
var navigation_region: NavigationRegion2D
var world_y_sort: Node2D
var runtime_world: Node2D
var occupancy := RoomOccupancy.new()
var room_objects: Array[PlaceableObject] = []


func _ready() -> void:
	_connect_grid_data()
	_connect_doorways()
	if Engine.is_editor_hint():
		call_deferred("queue_redraw")


func _connect_grid_data() -> void:
	if grid_data != null and not grid_data.changed.is_connected(_on_grid_data_changed):
		grid_data.changed.connect(_on_grid_data_changed)


func _on_grid_data_changed() -> void:
	queue_redraw()
	if not Engine.is_editor_hint():
		build_runtime_world()


func configure(new_cell_size: Vector2, new_room_columns: int, new_room_rows: int, new_room_top_row: int, new_show_grid: bool) -> void:
	cell_size = new_cell_size
	room_columns = new_room_columns
	room_rows = new_room_rows
	room_top_row = new_room_top_row
	show_grid = new_show_grid
	configure_spawn_points()
	configure_doorways()
	if not Engine.is_editor_hint():
		build_runtime_world()
	queue_redraw()


func create_player(spawn_position: Vector2) -> PlayerController:
	var new_player := PLAYER_SCENE.instantiate() as PlayerController
	new_player.name = "Player_BlueSquare_1x2"
	new_player.cell_size = cell_size
	new_player.position = spawn_position
	world_y_sort.add_child(new_player)
	return new_player


func attach_player(existing_player: PlayerController, spawn_position: Vector2) -> void:
	existing_player.stop()
	existing_player.cell_size = cell_size
	existing_player.position = spawn_position
	world_y_sort.add_child(existing_player)


func detach_player(existing_player: PlayerController) -> void:
	if existing_player.get_parent() != null:
		existing_player.get_parent().remove_child(existing_player)


func get_room_id() -> String:
	return room_data.room_id if room_data != null else ""


func cell_to_navigation_position(cell: Vector2i) -> Vector2:
	return Vector2((cell.x + 0.5) * cell_size.x, (cell.y + 0.5) * cell_size.y)


func get_requested_cell(screen_position: Vector2) -> Vector2i:
	return Vector2i(floori(screen_position.x / cell_size.x), floori(screen_position.y / cell_size.y))


func get_navigation_destination(requested_cell: Vector2i) -> Vector2:
	if requested_cell.y <= room_top_row:
		# Permite clicar la pared/puerta visible: el destino real es la primera
		# casilla navegable cubierta por su Area2D.
		for doorway in find_children("*", "Doorway", true, false):
			if requested_cell.x >= doorway.grid_cell.x and requested_cell.x < doorway.grid_cell.x + doorway.grid_size.x:
				var doorway_cell := Vector2i(requested_cell.x, doorway.grid_cell.y)
				if is_walkable_for_player(doorway_cell):
					return cell_to_navigation_position(doorway_cell)
		return Vector2.INF
	var clamped := Vector2i(clampi(requested_cell.x, 0, room_columns - 1), clampi(requested_cell.y, room_top_row + 1, room_top_row + room_rows - 1))
	return cell_to_navigation_position(clamped) if is_walkable_for_player(clamped) else Vector2.INF


func get_spawn_position(spawn_id: StringName, fallback_cell: Vector2i) -> Vector2:
	var marker := find_child(String(spawn_id), true, false) as Marker2D
	if marker != null:
		return marker.position
	push_warning("No existe el Marker2D de aparición '%s' en '%s'." % [spawn_id, get_room_id()])
	return cell_to_navigation_position(fallback_cell)


func is_walkable_for_player(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.x >= room_columns or cell.y <= room_top_row or cell.y >= room_top_row + room_rows:
		return false
	return not occupancy.is_blocked(cell)


func get_blocked_cells() -> Dictionary:
	return occupancy.blocked_cells


func get_interactable_at_cell(cell: Vector2i) -> PlaceableObject:
	for object in room_objects:
		if not object.is_interactable:
			continue
		for local_cell in object.get_visual_cells():
			if object.base_cell + local_cell == cell:
				return object
	return null


func get_interaction_destination(object: PlaceableObject) -> Vector2:
	for local_cell in object.get_interaction_cells():
		var candidate := object.base_cell + local_cell
		if is_walkable_for_player(candidate):
			return cell_to_navigation_position(candidate)
	return Vector2.INF


func build_runtime_world() -> void:
	if runtime_world != null and is_instance_valid(runtime_world):
		runtime_world.free()
	room_objects.clear()
	runtime_world = Node2D.new()
	runtime_world.name = "RuntimeWorld"
	add_child(runtime_world)
	world_y_sort = Node2D.new()
	world_y_sort.name = "WorldYSort"
	world_y_sort.y_sort_enabled = true
	runtime_world.add_child(world_y_sort)
	instantiate_placements()
	occupancy.rebuild(grid_data, room_columns, room_rows, room_top_row, room_objects)
	create_navigation_region()
	create_generated_collisions()


func instantiate_placements() -> void:
	if room_data == null:
		return
	for placement in room_data.placements:
		if placement.scene == null:
			push_warning("La colocación '%s' no tiene escena." % placement.id)
			continue
		var object := placement.scene.instantiate() as PlaceableObject
		if object == null:
			push_error("'%s' debe heredar de PlaceableObject." % placement.id)
			continue
		object.name = placement.id if not placement.id.is_empty() else object.name
		object.base_cell = placement.base_cell
		object.configure_grid_size(cell_size)
		object.position = cell_to_navigation_position(placement.base_cell) + object.get_cell_anchor_offset() * cell_size
		room_objects.append(object)
		if object.uses_y_sort:
			world_y_sort.add_child(object)
		else:
			runtime_world.add_child(object)


func create_navigation_region() -> void:
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
	runtime_world.add_child(navigation_region)


func create_generated_collisions() -> void:
	var collision_root := Node2D.new()
	collision_root.name = "RoomGeneratedCollisions"
	runtime_world.add_child(collision_root)
	for cell in occupancy.blocked_cells:
		if not occupancy.needs_generated_physics(cell):
			continue
		var body := StaticBody2D.new()
		body.position = cell_to_navigation_position(cell)
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = cell_size
		shape.shape = rectangle
		body.add_child(shape)
		collision_root.add_child(body)


func _draw() -> void:
	var room_rect := Rect2(Vector2(0, room_top_row * cell_size.y), Vector2(room_columns * cell_size.x, room_rows * cell_size.y))
	var floor_color := Color("f6dfb7") if get_room_id() == "shelter_entrada" else Color("d9e9cf")
	draw_rect(room_rect, floor_color)
	draw_rect(room_rect, Color("5a4135"), false, 7.0)
	draw_background_wall(room_rect)
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


func draw_background_wall(room_rect: Rect2) -> void:
	var wall_rect := Rect2(room_rect.position, Vector2(room_rect.size.x, cell_size.y * wall_height_cells))
	var openings: Array[Vector2i] = []
	for doorway in find_children("*", "Doorway", true, false):
		# Esta es la pared de fondo (norte). Solo las puertas a las que se entra
		# caminando hacia arriba deben perforarla; una salida sur no abre un hueco
		# visual en esta pared.
		if doorway.allowed_entry_direction.y >= 0.0:
			continue
		var start_column := clampi(doorway.grid_cell.x, 0, room_columns)
		var end_column := clampi(doorway.grid_cell.x + doorway.grid_size.x, 0, room_columns)
		if end_column > start_column:
			openings.append(Vector2i(start_column, end_column))
	openings.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x)

	var next_column := 0
	for opening in openings:
		if opening.x > next_column:
			draw_wall_section(wall_rect, next_column, opening.x)
		next_column = maxi(next_column, opening.y)
	if next_column < room_columns:
		draw_wall_section(wall_rect, next_column, room_columns)


func draw_wall_section(wall_rect: Rect2, from_column: int, to_column: int) -> void:
	var section := Rect2(
		wall_rect.position + Vector2(from_column * cell_size.x, 0),
		Vector2((to_column - from_column) * cell_size.x, wall_rect.size.y)
	)
	draw_rect(section, Color("c58e70"))


func configure_spawn_points() -> void:
	for marker in find_children("*", "Marker2D", true, false):
		# Marker2D es la fuente de verdad: se mueve directamente en el editor.
		# Las escenas se editan con casillas de 48 px y el juego las adapta al
		# tamaño de viewport configurado, conservando la ubicación que se ve.
		marker.position *= cell_size / EDITOR_CELL_SIZE


func configure_doorways() -> void:
	for doorway in find_children("*", "Doorway", true, false):
		doorway.configure_grid_size(cell_size)


func _connect_doorways() -> void:
	for doorway in find_children("*", "Doorway", true, false):
		if not doorway.transition_requested.is_connected(_on_doorway_transition_requested):
			doorway.transition_requested.connect(_on_doorway_transition_requested)


func _on_doorway_transition_requested(doorway: Doorway, player: PlayerController) -> void:
	doorway_requested.emit(doorway, player)
