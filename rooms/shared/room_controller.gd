@tool
class_name ShelterRoom
extends Node2D

const PLAYER_SCENE := preload("res://entities/player/player.tscn")

signal transition_reached(transition: RoomTransitionData)

@export var room_data: RoomData:
	set(value):
		room_data = value
		_connect_grid_data()
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
var transition_armed: RoomTransitionData
var occupancy := RoomOccupancy.new()
var room_objects: Array[PlaceableObject] = []


func _ready() -> void:
	_connect_grid_data()
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


func get_room_id() -> String:
	return room_data.room_id if room_data != null else ""


func cell_to_navigation_position(cell: Vector2i) -> Vector2:
	return Vector2((cell.x + 0.5) * cell_size.x, (cell.y + 0.5) * cell_size.y)


func get_requested_cell(screen_position: Vector2) -> Vector2i:
	return Vector2i(floori(screen_position.x / cell_size.x), floori(screen_position.y / cell_size.y))


func get_navigation_destination(requested_cell: Vector2i) -> Vector2:
	var transition := get_transition_at_cell(requested_cell)
	if transition != null:
		if transition.requires_click:
			transition_armed = transition
		var entry_cell := Vector2i(requested_cell.x, room_top_row + 1)
		return cell_to_navigation_position(entry_cell) if is_walkable_for_player(entry_cell) else Vector2.INF
	if requested_cell.y <= room_top_row:
		return Vector2.INF
	var clamped := Vector2i(clampi(requested_cell.x, 0, room_columns - 1), clampi(requested_cell.y, room_top_row + 1, room_top_row + room_rows - 1))
	return cell_to_navigation_position(clamped) if is_walkable_for_player(clamped) else Vector2.INF


func get_transition_at_cell(cell: Vector2i) -> RoomTransitionData:
	if room_data == null:
		return null
	for transition in room_data.transitions:
		if transition.trigger_cells.has(cell):
			return transition
	return null


func clear_armed_transition() -> void:
	transition_armed = null


func check_transition_at_player_base(base_position: Vector2) -> void:
	if transition_armed == null:
		return
	var base_cell := Vector2i(floori(base_position.x / cell_size.x), floori(base_position.y / cell_size.y))
	for trigger_cell in transition_armed.trigger_cells:
		if base_cell == Vector2i(trigger_cell.x, room_top_row + 1):
			var reached := transition_armed
			transition_armed = null
			transition_reached.emit(reached)
			return


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
	for child in get_children():
		child.queue_free()
	room_objects.clear()
	world_y_sort = Node2D.new()
	world_y_sort.name = "WorldYSort"
	world_y_sort.y_sort_enabled = true
	add_child(world_y_sort)
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
			add_child(object)


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
	add_child(navigation_region)


func create_generated_collisions() -> void:
	var collision_root := Node2D.new()
	collision_root.name = "RoomGeneratedCollisions"
	add_child(collision_root)
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
	draw_rect(Rect2(room_rect.position, Vector2(room_rect.size.x, cell_size.y)), Color("c58e70"))
	var destination_label := ""
	if room_data != null and not room_data.transitions.is_empty():
		destination_label = "PARED DE FONDO → SALA CONECTADA"
	draw_string(ThemeDB.fallback_font, room_rect.position + Vector2(16, cell_size.y * 0.62), destination_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("2b1a16"))
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
