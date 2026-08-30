class_name CureMinigame
extends CanvasLayer

signal closed

const MEDICAL_DIRECTORY := "res://assets/minigames/cure/medical"
const DISTRACTOR_DIRECTORY := "res://assets/minigames/cure/distractors"
const ROUND_COUNT := 3
const STARTING_LIVES := 3
const BOARD_ITEM_COUNT := 28

var random := RandomNumberGenerator.new()
var medical_items: Array[Texture2D] = []
var distractor_items: Array[Texture2D] = []
var round_targets: Array[Texture2D] = []
var current_target: Texture2D
var round_index := 0
var lives := STARTING_LIVES
var successes := 0
var accepting_input := false

@onready var close_button: Button = $Root/CloseButton
@onready var hearts_label: Label = $Root/HeartsLabel
@onready var round_label: Label = $Root/RoundLabel
@onready var feedback_label: Label = $Root/FeedbackLabel
@onready var board: GridContainer = $Root/BoardPanel/BoardMargin/Board
@onready var target_texture: TextureRect = $Root/TargetFrame/TargetMargin/TargetTexture
@onready var end_panel: PanelContainer = $Root/EndPanel
@onready var end_title: Label = $Root/EndPanel/EndMargin/EndContent/Title
@onready var end_summary: Label = $Root/EndPanel/EndMargin/EndContent/Summary
@onready var replay_button: Button = $Root/EndPanel/EndMargin/EndContent/Buttons/ReplayButton
@onready var back_button: Button = $Root/EndPanel/EndMargin/EndContent/Buttons/BackButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	random.randomize()
	close_button.pressed.connect(close)
	replay_button.pressed.connect(start_session)
	back_button.pressed.connect(close)
	medical_items = _load_png_textures(MEDICAL_DIRECTORY)
	distractor_items = _load_png_textures(DISTRACTOR_DIRECTORY)
	get_tree().paused = true
	if medical_items.size() < ROUND_COUNT or distractor_items.is_empty():
		_show_catalog_error()
		return
	start_session()
	close_button.grab_focus()


func _load_png_textures(directory_path: String) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	var directory := DirAccess.open(directory_path)
	if directory == null:
		push_error("No se pudo abrir el catálogo de Curar: %s" % directory_path)
		return textures
	var file_names := PackedStringArray()
	for file_name in directory.get_files():
		if file_name.to_lower().ends_with(".png"):
			file_names.append(file_name)
	file_names.sort()
	for file_name in file_names:
		var texture := load(directory_path.path_join(file_name)) as Texture2D
		if texture != null:
			textures.append(texture)
	return textures


func start_session() -> void:
	accepting_input = false
	round_index = 0
	lives = STARTING_LIVES
	successes = 0
	end_panel.hide()
	round_targets = medical_items.duplicate()
	_shuffle(round_targets)
	round_targets.resize(ROUND_COUNT)
	_update_hearts()
	_start_round()


func _start_round() -> void:
	_clear_board()
	feedback_label.text = "Encuentra el objeto veterinario"
	feedback_label.add_theme_color_override("font_color", Color("385a69"))
	round_label.text = "RONDA %d / %d" % [round_index + 1, ROUND_COUNT]
	current_target = round_targets[round_index]
	target_texture.texture = current_target
	var entries: Array[Dictionary] = [{"texture": current_target, "target": true}]
	# Incluye todo el catálogo cotidiano al menos una vez; completa con repetidos.
	for texture in distractor_items:
		entries.append({"texture": texture, "target": false})
	for index in range(maxi(BOARD_ITEM_COUNT - entries.size(), 0)):
		entries.append({"texture": distractor_items[random.randi_range(0, distractor_items.size() - 1)], "target": false})
	_shuffle(entries)
	for entry in entries:
		board.add_child(_create_item_button(entry.texture, entry.target))
	accepting_input = true


func _create_item_button(texture: Texture2D, is_target: bool) -> TextureButton:
	var button := TextureButton.new()
	button.custom_minimum_size = Vector2(94, 78)
	button.texture_normal = texture
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	button.tooltip_text = "Objeto"
	button.rotation = random.randf_range(-0.12, 0.12)
	button.scale = Vector2.ONE * random.randf_range(0.84, 1.0)
	button.pivot_offset = button.custom_minimum_size * 0.5
	button.pressed.connect(_on_item_pressed.bind(is_target, button))
	return button


func _on_item_pressed(is_target: bool, selected_button: TextureButton) -> void:
	if not accepting_input:
		return
	accepting_input = false
	selected_button.modulate = Color("b9ffbe") if is_target else Color("ffadad")
	if is_target:
		successes += 1
		feedback_label.text = "¡Lo encontraste!"
		feedback_label.add_theme_color_override("font_color", Color("238a4b"))
	else:
		lives = maxi(lives - 1, 0)
		_update_hearts()
		feedback_label.text = "¡Este no es!"
		feedback_label.add_theme_color_override("font_color", Color("d43f49"))
	await get_tree().create_timer(1.15, true, false, true).timeout
	round_index += 1
	if round_index >= ROUND_COUNT:
		_finish_session()
	else:
		_start_round()


func _finish_session() -> void:
	_clear_board()
	target_texture.texture = null
	round_label.text = "SESIÓN COMPLETADA"
	feedback_label.text = ""
	end_title.text = "¡Consulta terminada!"
	end_summary.text = "Encontraste %d de %d objetos\nTe quedan %d corazones" % [successes, ROUND_COUNT, lives]
	end_panel.show()
	replay_button.grab_focus()


func _update_hearts() -> void:
	hearts_label.text = ("♥ ".repeat(lives) + "♡ ".repeat(STARTING_LIVES - lives)).strip_edges()


func _clear_board() -> void:
	for child in board.get_children():
		board.remove_child(child)
		child.queue_free()


func _shuffle(values: Array) -> void:
	for index in range(values.size() - 1, 0, -1):
		var other := random.randi_range(0, index)
		var temporary = values[index]
		values[index] = values[other]
		values[other] = temporary


func _show_catalog_error() -> void:
	round_label.text = "NO HAY SUFICIENTES OBJETOS"
	feedback_label.text = "Añade al menos 3 PNG médicos y 1 distractor."
	feedback_label.add_theme_color_override("font_color", Color("d43f49"))


func close() -> void:
	if not is_inside_tree():
		return
	get_tree().paused = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
