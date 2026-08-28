class_name WorldMap
extends CanvasLayer

signal closed(return_to_shelter: bool)
signal animal_pickup_requested(environment: String)

@export var config: MapConfig

var random := RandomNumberGenerator.new()
var destination := Vector2.ZERO
var encounter_time_remaining := 0.0
var encounter_lifetime_remaining := 0.0
var moving := false

@onready var root: Control = $Root
@onready var map_image: TextureRect = $Root/MapImage
@onready var player: MapPlayer = $Root/MapPlayer
@onready var encounter_marker: EncounterMarker = $Root/EncounterMarker
@onready var close_button: Button = $Root/CloseButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	random.randomize()
	root.gui_input.connect(_on_root_gui_input)
	root.resized.connect(_layout_map)
	close_button.pressed.connect(close)
	encounter_marker.selected.connect(_on_encounter_selected)
	get_tree().paused = true
	encounter_marker.hide()
	_layout_map()
	player.position = _normalized_to_screen(config.shelter_door_position) - player.size * 0.5
	destination = player.position
	_schedule_next_encounter(true)
	close_button.grab_focus()


func _process(delta: float) -> void:
	_update_player(delta)
	_update_encounter(delta)


func _layout_map() -> void:
	if map_image.texture == null or root.size.x <= 0.0 or root.size.y <= 0.0:
		return
	var available := root.size - Vector2(config.map_margin * 2.0, config.map_margin * 2.0)
	var texture_size := map_image.texture.get_size()
	var scale_factor := minf(available.x / texture_size.x, available.y / texture_size.y)
	map_image.size = texture_size * scale_factor
	map_image.position = (root.size - map_image.size) * 0.5
	_clamp_player_and_destination()


func _update_player(delta: float) -> void:
	if not moving:
		return
	var offset := destination - player.position
	if offset.length() <= config.player_speed * delta:
		player.position = destination
		moving = false
		return
	var motion := offset.normalized() * config.player_speed * delta
	player.set_facing_from_motion(motion)
	player.position += motion


func _update_encounter(delta: float) -> void:
	if _is_player_near_shelter():
		if encounter_marker.visible:
			encounter_marker.hide()
		_schedule_next_encounter(false)
		return
	if encounter_marker.visible:
		encounter_lifetime_remaining -= delta
		if encounter_lifetime_remaining <= 0.0:
			encounter_marker.hide()
			_schedule_next_encounter(false)
		return
	encounter_time_remaining -= delta
	if encounter_time_remaining <= 0.0:
		_show_encounter()


func _set_destination(pointer_position: Vector2) -> void:
	var player_half := player.size * 0.5
	var allowed := Rect2(map_image.position + player_half, map_image.size - player.size)
	var clamped_center := pointer_position.clamp(allowed.position, allowed.end)
	destination = clamped_center - player_half
	moving = true


func _clamp_player_and_destination() -> void:
	if not is_instance_valid(player):
		return
	var maximum := map_image.position + map_image.size - player.size
	player.position = player.position.clamp(map_image.position, maximum)
	destination = destination.clamp(map_image.position, maximum)


func _show_encounter() -> void:
	var angle := random.randf_range(0.0, TAU)
	var distance := random.randf_range(config.encounter_distance_min, config.encounter_distance_max)
	var desired_center := player.position + player.size * 0.5 + Vector2.from_angle(angle) * distance
	var half_size := encounter_marker.size * 0.5
	var allowed := Rect2(map_image.position + half_size, map_image.size - encounter_marker.size)
	var clamped_center := desired_center.clamp(allowed.position, allowed.end)
	encounter_marker.position = clamped_center - half_size
	encounter_lifetime_remaining = random.randf_range(config.encounter_duration_min, config.encounter_duration_max)
	encounter_marker.show()


func _schedule_next_encounter(first: bool) -> void:
	if first:
		encounter_time_remaining = random.randf_range(config.first_encounter_delay_min, config.first_encounter_delay_max)
	else:
		encounter_time_remaining = random.randf_range(config.encounter_interval_min, config.encounter_interval_max)


func _on_encounter_selected() -> void:
	encounter_marker.hide()
	moving = false
	# Hasta que las localizaciones del mapa tengan tipo propio, el encuentro
	# escoge uno de los dos catálogos visuales ya existentes.
	var environment := "forest" if random.randi_range(0, 1) == 0 else "city"
	animal_pickup_requested.emit(environment)
	_schedule_next_encounter(false)


func _on_root_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _is_shelter_clicked(event.position):
			close(true)
			root.accept_event()
			return
		_set_destination(event.position)
		root.accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		if _is_shelter_clicked(event.position):
			close(true)
			root.accept_event()
			return
		_set_destination(event.position)
		root.accept_event()


func _normalized_to_screen(normalized_position: Vector2) -> Vector2:
	return map_image.position + normalized_position * map_image.size


func _is_player_near_shelter() -> bool:
	var player_center := player.position + player.size * 0.5
	return player_center.distance_to(_normalized_to_screen(config.shelter_door_position)) <= config.shelter_safe_radius


func _is_shelter_clicked(pointer_position: Vector2) -> bool:
	if not Rect2(map_image.position, map_image.size).has_point(pointer_position):
		return false
	var normalized_position := (pointer_position - map_image.position) / map_image.size
	return config.shelter_hit_rect.has_point(normalized_position)


func close(return_to_shelter := false) -> void:
	if not is_inside_tree():
		return
	get_tree().paused = false
	closed.emit(return_to_shelter)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close(false)
		get_viewport().set_input_as_handled()
