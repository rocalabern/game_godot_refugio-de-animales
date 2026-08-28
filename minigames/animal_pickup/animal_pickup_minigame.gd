class_name AnimalPickupMinigame
extends CanvasLayer

## Minijuego independiente de recogida de animales.
## Evalúa un clic cuando el marcador móvil atraviesa la zona válida.
signal closed
signal attempt_finished(success: bool)

@export var config: AnimalPickupConfig

var started := false
var accepting_attempt := true
var successful_attempts := 0
var result_time_remaining := 0.0
var movement_direction := -1.0
var random := RandomNumberGenerator.new()

@onready var close_button: Button = $Root/CloseButton
@onready var root: Control = $Root
@onready var start_hint: Label = $Root/StartHint
@onready var bottom_hud: PanelContainer = $Root/BottomHud
@onready var hit_bar: HitTimingBar = $Root/BottomHud/Margin/Content/HitBar
@onready var feedback_label: Label = $Root/BottomHud/Margin/Content/FeedbackLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	random.randomize()
	close_button.pressed.connect(close)
	root.gui_input.connect(_on_root_gui_input)
	randomize_target_width()
	bottom_hud.hide()
	get_tree().paused = true
	close_button.grab_focus()


func _process(delta: float) -> void:
	if not started:
		return
	if accepting_attempt:
		move_marker(delta)
		return
	result_time_remaining -= delta
	if result_time_remaining <= 0.0:
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
	if not success or successful_attempts >= maxi(config.n_replays_hit_timing_bar, 1):
		close()
		return
	result_time_remaining = config.result_display_time


func start_next_attempt() -> void:
	feedback_label.text = "Pulsa en cualquier lugar"
	feedback_label.add_theme_color_override("font_color", Color("fff0c2"))
	accepting_attempt = true


func _on_root_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if started:
			evaluate_attempt()
		else:
			start_minigame()
		root.accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		if started:
			evaluate_attempt()
		else:
			start_minigame()
		root.accept_event()


func close() -> void:
	if not is_inside_tree():
		return
	get_tree().paused = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
