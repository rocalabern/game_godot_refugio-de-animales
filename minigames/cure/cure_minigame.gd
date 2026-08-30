class_name CureMinigame
extends CanvasLayer

signal closed

@export var config: CureMinigameConfig

var random := RandomNumberGenerator.new()
var medical_items: Array[Texture2D] = []
var distractor_items: Array[Texture2D] = []
var round_targets: Array[Texture2D] = []
var current_target: Texture2D
var round_index := 0
var lives := 0
var successes := 0
var accepting_input := false

@onready var close_button: Button = $Root/CloseButton
@onready var hearts_label: Label = $Root/HeartsLabel
@onready var round_label: Label = $Root/RoundLabel
@onready var feedback_label: Label = $Root/FeedbackLabel
@onready var board: Control = $Root/BoardPanel/BoardMargin/Board
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
	get_tree().paused = true
	if config == null:
		_show_config_error()
		return
	medical_items = config.imagenes_medicina.duplicate()
	distractor_items = config.imagenes_distractoras.duplicate()
	# En el editor se conserva el descubrimiento por carpeta para facilitar
	# añadir recursos durante desarrollo. El APK usa las referencias explícitas.
	if medical_items.is_empty() and Engine.is_editor_hint():
		medical_items = _load_png_textures(config.carpeta_medicina)
	if distractor_items.is_empty() and Engine.is_editor_hint():
		distractor_items = _load_png_textures(config.carpeta_distractores)
	if medical_items.size() < config.partidas_seguidas or distractor_items.is_empty():
		_show_catalog_error()
		return
	# En la primera instancia, los Container todavía pueden no haber resuelto
	# su tamaño durante _ready(). No se generan posiciones hasta tener tablero.
	if not await _wait_for_board_layout():
		_show_layout_error()
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
	lives = config.vidas
	successes = 0
	end_panel.hide()
	round_targets = medical_items.duplicate()
	_shuffle(round_targets)
	round_targets.resize(config.partidas_seguidas)
	_update_hearts()
	_start_round()


func _start_round() -> void:
	# Salvaguarda también reinicios/cambios de tamaño futuros. Con un tablero
	# inválido, todos los límites aleatorios serían cero y se apilarían en (0, 0).
	if not await _wait_for_board_layout():
		_show_layout_error()
		return
	_clear_board()
	feedback_label.text = "Encuentra el objeto veterinario"
	feedback_label.add_theme_color_override("font_color", Color("385a69"))
	round_label.text = "RONDA %d / %d" % [round_index + 1, config.partidas_seguidas]
	current_target = round_targets[round_index]
	target_texture.texture = current_target
	var entries: Array[Dictionary] = [{"texture": current_target, "target": true}]
	# Incluye todo el catálogo cotidiano al menos una vez; completa con repetidos.
	for texture in distractor_items:
		entries.append({"texture": texture, "target": false})
	for _index in range(maxi(config.objetos_en_pantalla - entries.size(), 0)):
		entries.append({"texture": distractor_items[random.randi_range(0, distractor_items.size() - 1)], "target": false})
	_shuffle(entries)
	var occupied_rects: Array[Rect2] = []
	for entry in entries:
		var item_position := _find_scattered_position(occupied_rects)
		occupied_rects.append(Rect2(item_position, config.tamano_objeto))
		board.add_child(_create_item_button(entry.texture, entry.target, item_position))
	accepting_input = true


func _create_item_button(texture: Texture2D, is_target: bool, item_position: Vector2) -> TextureButton:
	var button := TextureButton.new()
	button.position = item_position
	button.size = config.tamano_objeto
	button.texture_normal = texture
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	button.texture_click_mask = _create_click_mask(texture)
	button.tooltip_text = "Objeto"
	var minimum_rotation := minf(config.rotacion_minima_grados, config.rotacion_maxima_grados)
	var maximum_rotation := maxf(config.rotacion_minima_grados, config.rotacion_maxima_grados)
	button.rotation = deg_to_rad(random.randf_range(minimum_rotation, maximum_rotation))
	button.scale = Vector2.ONE * random.randf_range(minf(config.escala_minima, config.escala_maxima), maxf(config.escala_minima, config.escala_maxima))
	button.pivot_offset = config.tamano_objeto * 0.5
	button.z_index = random.randi_range(0, config.profundidad_maxima)
	button.pressed.connect(_on_item_pressed.bind(is_target, button))
	return button


func _find_scattered_position(occupied_rects: Array[Rect2]) -> Vector2:
	var available := Vector2(maxf(board.size.x - config.tamano_objeto.x, 0.0), maxf(board.size.y - config.tamano_objeto.y, 0.0))
	var best_position := Vector2(random.randf_range(0.0, available.x), random.randf_range(0.0, available.y))
	var best_overlap := INF
	for _attempt in range(config.intentos_colocacion):
		var candidate_position := Vector2(random.randf_range(0.0, available.x), random.randf_range(0.0, available.y))
		var candidate_rect := Rect2(candidate_position, config.tamano_objeto)
		var overlap := 0.0
		for occupied in occupied_rects:
			var intersection := candidate_rect.intersection(occupied)
			overlap += intersection.size.x * intersection.size.y
		if overlap < best_overlap:
			best_overlap = overlap
			best_position = candidate_position
			if is_zero_approx(overlap):
				break
	return best_position


func _wait_for_board_layout() -> bool:
	for _frame in range(config.frames_espera_layout):
		if board.size.x >= config.tamano_objeto.x and board.size.y >= config.tamano_objeto.y:
			return true
		await get_tree().process_frame
		if not is_inside_tree():
			return false
	return board.size.x >= config.tamano_objeto.x and board.size.y >= config.tamano_objeto.y


func _create_click_mask(texture: Texture2D) -> BitMap:
	var click_mask := BitMap.new()
	var image := texture.get_image()
	if image != null:
		click_mask.create_from_image_alpha(image, config.umbral_click_alpha)
	return click_mask


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
	await get_tree().create_timer(config.espera_resultado, true, false, true).timeout
	round_index += 1
	if round_index >= config.partidas_seguidas:
		_finish_session()
	else:
		_start_round()


func _finish_session() -> void:
	_clear_board()
	target_texture.texture = null
	round_label.text = "SESIÓN COMPLETADA"
	feedback_label.text = ""
	end_title.text = "¡Consulta terminada!"
	end_summary.text = "Encontraste %d de %d objetos\nTe quedan %d corazones" % [successes, config.partidas_seguidas, lives]
	end_panel.show()
	replay_button.grab_focus()


func _update_hearts() -> void:
	hearts_label.text = ("♥ ".repeat(lives) + "♡ ".repeat(config.vidas - lives)).strip_edges()


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
	feedback_label.text = "Añade al menos %d PNG médicos y 1 distractor." % config.partidas_seguidas
	feedback_label.add_theme_color_override("font_color", Color("d43f49"))


func _show_config_error() -> void:
	accepting_input = false
	round_label.text = "CONFIGURACIÓN NO ASIGNADA"
	feedback_label.text = "Asigna un recurso CureMinigameConfig."
	feedback_label.add_theme_color_override("font_color", Color("d43f49"))


func _show_layout_error() -> void:
	accepting_input = false
	round_label.text = "NO SE PUDO PREPARAR LA MESA"
	feedback_label.text = "Vuelve a abrir el minijuego."
	feedback_label.add_theme_color_override("font_color", Color("d43f49"))
	push_error("El tablero de Curar no obtuvo un tamaño válido: %s" % board.size)


func close() -> void:
	if not is_inside_tree():
		return
	get_tree().paused = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
