class_name AnimalPickupMinigame
extends CanvasLayer

## Minijuego independiente de recogida de animales.
## Evalúa un clic cuando el marcador móvil atraviesa la zona válida.
signal closed
signal attempt_finished(success: bool)

@export var config: AnimalPickupConfig
@export var backdrops: AnimalPickupBackdropCatalog

var started := false
var accepting_attempt := true
var successful_attempts := 0
var result_time_remaining := 0.0
var close_when_result_time_finishes := false
var movement_direction := -1.0
var random := RandomNumberGenerator.new()
var current_environment: String
var current_backdrop: AnimalPickupBackdrop

@onready var close_button: Button = $Root/CloseButton
@onready var root: Control = $Root
@onready var background: TextureRect = $Root/Background
@onready var start_hint: Label = $Root/StartHint
@onready var bottom_hud: PanelContainer = $Root/BottomHud
@onready var hit_bar: HitTimingBar = $Root/BottomHud/Margin/Content/HitBar
@onready var feedback_label: Label = $Root/BottomHud/Margin/Content/FeedbackLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	random.randomize()
	select_random_backdrop()
	close_button.pressed.connect(close)
	root.gui_input.connect(_on_root_gui_input)
	randomize_target_width()
	bottom_hud.hide()
	get_tree().paused = true
	close_button.grab_focus()


func select_random_backdrop() -> void:
	current_environment = "forest" if random.randi_range(0, 1) == 0 else "city"
	current_backdrop = backdrops.get_random_backdrop(random, current_environment)
	if current_backdrop == null:
		push_error("No hay fondos configurados para el entorno '%s'." % current_environment)
		return
	background.texture = current_backdrop.texture


func _process(delta: float) -> void:
	if not started:
		return
	if accepting_attempt:
		move_marker(delta)
		return
	result_time_remaining -= delta
	if result_time_remaining <= 0.0:
		if close_when_result_time_finishes:
			close()
		else:
			start_next_attempt()


func start_minigame() -> void:
	started = true
	start_hint.hide()
	bottom_hud.show()
	hit_bar.marker_position = config.initial_marker_position
	movement_direction = -1.0


func randomize_target_width() -> void:
	var minimum_width := minf(config.target_width_min, config.target_width_max)
	var maximum_width := maxf(config.target_width_min, config.target_width_max)
	var target_width := random.randf_range(minimum_width, maximum_width)
	var half_width := target_width * 0.5
	var target_center := random.randf_range(half_width, 1.0 - half_width)
	hit_bar.target_start = target_center - half_width
	hit_bar.target_end = target_center + half_width


func move_marker(delta: float) -> void:
	var next_position := hit_bar.marker_position + movement_direction * config.bar_speed * delta
	if next_position <= 0.0:
		next_position = -next_position
		movement_direction = 1.0
	elif next_position >= 1.0:
		next_position = 2.0 - next_position
		movement_direction = -1.0
	hit_bar.marker_position = clampf(next_position, 0.0, 1.0)


func evaluate_attempt() -> void:
	if not accepting_attempt:
		return
	accepting_attempt = false
	var success := hit_bar.is_marker_inside_target()
	if success:
		successful_attempts += 1
	feedback_label.text = "¡Perfecto!" if success else "Casi..."
	feedback_label.add_theme_color_override("font_color", Color("8ee58d") if success else Color("ffd27a"))
	attempt_finished.emit(success)
	if not success:
		close()
		return
	if successful_attempts >= maxi(config.n_replays_hit_timing_bar, 1):
		close_when_result_time_finishes = true
		result_time_remaining = config.completion_close_delay
		return
	result_time_remaining = config.result_display_time


func start_next_attempt() -> void:
	close_when_result_time_finishes = false
	feedback_label.text = "Pulsa en cualquier lugar"
	feedback_label.add_theme_color_override("font_color", Color("fff0c2"))
	accepting_attempt = true


func _on_root_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if started:
			evaluate_attempt()
		elif is_animal_clicked(event.position):
			start_minigame()
		root.accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		if started:
			evaluate_attempt()
		elif is_animal_clicked(event.position):
			start_minigame()
		root.accept_event()


func is_animal_clicked(root_position: Vector2) -> bool:
	if current_backdrop == null or background.texture == null:
		return false
	var texture_size := background.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return false
	var scale_factor := minf(background.size.x / texture_size.x, background.size.y / texture_size.y)
	var displayed_size := texture_size * scale_factor
	var content_rect := Rect2((background.size - displayed_size) * 0.5, displayed_size)
	var canvas_position: Vector2 = root.get_global_transform_with_canvas() * root_position
	var background_position: Vector2 = background.get_global_transform_with_canvas().affine_inverse() * canvas_position
	if not content_rect.has_point(background_position):
		return false
	var normalized_position: Vector2 = (background_position - content_rect.position) / content_rect.size
	return current_backdrop.animal_hit_rect.has_point(normalized_position)


func close() -> void:
	if not is_inside_tree():
		return
	get_tree().paused = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
