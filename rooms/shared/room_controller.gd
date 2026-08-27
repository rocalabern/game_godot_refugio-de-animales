@tool
class_name ShelterRoom
extends Node2D

const PLAYER_SCENE := preload("res://entities/player/player.tscn")
const EDITOR_CELL_SIZE := Vector2(48, 48)

signal doorway_requested(doorway: Doorway, player: PlayerController)
signal animal_interaction_requested(animal: AnimalObject)

@export var room_data: RoomData

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
var edit_mode := false


func _ready() -> void:
	_connect_doorways()
	if Engine.is_editor_hint():
		call_deferred("queue_redraw")


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


func set_edit_mode(is_active: bool) -> void:
	edit_mode = is_active
	for object in room_objects:
		object.set_edit_mode(is_active)


func get_table_at_position(world_position: Vector2) -> Table:
	for object in room_objects:
		if not object is Table:
			continue
		var table := object as Table
		var table_rect := Rect2(
			table.global_position + Vector2(-cell_size.x, -cell_size.y * 2.0),
			cell_size * 2.0
		)
		if table_rect.has_point(world_position):
			return table
	return null


func get_table_base_cell_from_position(table: Table) -> Vector2i:
	var base_center := table.global_position - table.get_cell_anchor_offset() * cell_size
	return Vector2i(
		roundi(base_center.x / cell_size.x - 0.5),
		roundi(base_center.y / cell_size.y - 0.5)
	)


func move_table_to_cell(table: Table, target_cell: Vector2i) -> bool:
	if not can_place_object_at(table, target_cell):
		return false
	table.base_cell = target_cell
	table.position = cell_to_navigation_position(target_cell) + table.get_cell_anchor_offset() * cell_size
	for placement in room_data.placements:
		if placement.id == table.name:
			placement.base_cell = target_cell
			break
	rebuild_runtime_navigation()
	return true


func apply_table_position_overrides(overrides: Dictionary) -> void:
	for object in room_objects:
		if not object is Table or not overrides.has(object.name):
			continue
		var table := object as Table
		var target_cell := overrides[object.name] as Vector2i
		move_table_to_cell(table, target_cell)


func reset_table_position(table: Table) -> void:
	table.position = cell_to_navigation_position(table.base_cell) + table.get_cell_anchor_offset() * cell_size


func can_place_object_at(object: PlaceableObject, target_cell: Vector2i) -> bool:
	var static_blocked := get_static_blocked_cells()
	for local_cell in object.get_navigation_blocking_cells():
		var cell := target_cell + local_cell
		if cell.x < 0 or cell.x >= room_columns or cell.y <= room_top_row or cell.y >= room_top_row + room_rows:
			return false
		if static_blocked.has(cell):
			return false
		for other in room_objects:
			if other == object:
				continue
			for other_local_cell in other.get_navigation_blocking_cells():
				if other.base_cell + other_local_cell == cell:
					return false
	return true


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
	occupancy.rebuild(get_static_blocked_cells(), room_objects)
	create_navigation_region()
	create_generated_collisions()


func get_static_blocked_cells() -> Dictionary:
	var blocked: Dictionary = {}
	# Las salas con fondo ilustrado completo usan una capa lógica e invisible
	# llamada CollisionTiles. Las salas antiguas conservan su TileMap visible
	# hasta que se migren, por lo que mantenemos ese comportamiento como respaldo.
	var collision_layers := find_children("CollisionTiles", "TileMapLayer", false, false)
	if collision_layers.is_empty():
		collision_layers = find_children("*", "TileMapLayer", false, false)
	for layer in collision_layers:
		var tile_layer := layer as TileMapLayer
		if tile_layer == null:
			continue
		for cell in tile_layer.get_used_cells():
			var tile_data := tile_layer.get_cell_tile_data(cell)
			if tile_data != null and tile_has_physics(tile_data):
				blocked[cell] = true
	return blocked


func tile_has_physics(tile_data: TileData) -> bool:
	# El TileSet inicial usa una capa física. Las paredes llevan al menos un
	# polígono y los suelos ninguno: el comportamiento pertenece al tile.
	return tile_data.get_collision_polygons_count(0) > 0


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
		object.interacted.connect(_on_runtime_object_interacted.bind(object))
		room_objects.append(object)
		if object.uses_y_sort:
			world_y_sort.add_child(object)
		else:
			runtime_world.add_child(object)


func _on_runtime_object_interacted(_actor: Node2D, object: PlaceableObject) -> void:
	if object is AnimalObject:
		animal_interaction_requested.emit(object as AnimalObject)


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


func rebuild_runtime_navigation() -> void:
	occupancy.rebuild(get_static_blocked_cells(), room_objects)
	if is_instance_valid(navigation_region):
		navigation_region.free()
	var old_collision_root := runtime_world.get_node_or_null("RoomGeneratedCollisions")
	if old_collision_root != null:
		old_collision_root.free()
	create_navigation_region()
	create_generated_collisions()


func _draw() -> void:
	var room_rect := Rect2(Vector2(0, room_top_row * cell_size.y), Vector2(room_columns * cell_size.x, room_rows * cell_size.y))
	if show_grid:
		var grid_color := Color(0.25, 0.20, 0.16, 0.22)
		for x in range(room_columns + 1):
			draw_line(Vector2(x * cell_size.x, room_rect.position.y), Vector2(x * cell_size.x, room_rect.end.y), grid_color, 1.0)
		for y in range(room_rows + 1):
			draw_line(Vector2(0, (room_top_row + y) * cell_size.y), Vector2(room_rect.end.x, (room_top_row + y) * cell_size.y), grid_color, 1.0)


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
