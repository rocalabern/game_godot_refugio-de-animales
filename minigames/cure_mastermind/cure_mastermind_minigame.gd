class_name CureMastermindMinigame
extends CanvasLayer

signal closed

@export var config: MastermindConfig

var random := RandomNumberGenerator.new()
var round_index := 0
var attempts := 0
var solved_rounds := 0
var secret: Array[int] = []
var current_guess: Array[int] = []
var accepting_input := false

@onready var close_button: Button = $Root/CloseButton
@onready var round_label: Label = $Root/RoundLabel
@onready var config_label: Label = $Root/MainArea/ControlPanel/ControlMargin/Controls/ConfigLabel
@onready var current_guess_container: HBoxContainer = $Root/MainArea/ControlPanel/ControlMargin/Controls/CurrentGuess
@onready var palette: GridContainer = $Root/MainArea/ControlPanel/ControlMargin/Controls/Palette
@onready var clear_button: Button = $Root/MainArea/ControlPanel/ControlMargin/Controls/Buttons/ClearButton
@onready var check_button: Button = $Root/MainArea/ControlPanel/ControlMargin/Controls/Buttons/CheckButton
@onready var feedback_label: Label = $Root/MainArea/ControlPanel/ControlMargin/Controls/FeedbackLabel
@onready var history: VBoxContainer = $Root/MainArea/HistoryPanel/HistoryMargin/HistoryContent/HistoryScroll/History
@onready var history_scroll: ScrollContainer = $Root/MainArea/HistoryPanel/HistoryMargin/HistoryContent/HistoryScroll
@onready var gold_legend: TextureRect = $Root/MainArea/ControlPanel/ControlMargin/Controls/GoldLegend/Icon
@onready var silver_legend: TextureRect = $Root/MainArea/ControlPanel/ControlMargin/Controls/SilverLegend/Icon
@onready var end_panel: PanelContainer = $Root/EndPanel
@onready var end_summary: Label = $Root/EndPanel/Margin/Content/Summary
@onready var replay_button: Button = $Root/EndPanel/Margin/Content/Buttons/ReplayButton
@onready var back_button: Button = $Root/EndPanel/Margin/Content/Buttons/BackButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	random.randomize()
	close_button.pressed.connect(close)
	clear_button.pressed.connect(_clear_guess)
	check_button.pressed.connect(_check_guess)
	replay_button.pressed.connect(start_session)
	back_button.pressed.connect(close)
	get_tree().paused = true
	if not _is_config_valid():
		_show_config_error()
		return
	gold_legend.texture = config.hueso_dorado
	silver_legend.texture = config.hueso_plateado
	start_session()
	close_button.grab_focus()


func _is_config_valid() -> bool:
	if config == null or config.partidas.is_empty() or config.capsulas.size() < 6:
		return false
	if config.hueso_dorado == null or config.hueso_plateado == null:
		return false
	for round_config in config.partidas:
		if round_config == null:
			return false
		if round_config.posiciones < 3 or round_config.posiciones > 6:
			return false
		if round_config.cantidad_colores < 2 or round_config.cantidad_colores > 6:
			return false
		if not round_config.permitir_colores_repetidos and round_config.posiciones > round_config.cantidad_colores:
			return false
	return true


func start_session() -> void:
	end_panel.hide()
	round_index = 0
	solved_rounds = 0
	_start_round()


func _start_round() -> void:
	accepting_input = false
	attempts = 0
	var round_config := _get_round_config()
	secret = _generate_secret(round_config)
	current_guess.clear()
	current_guess.resize(round_config.posiciones)
	current_guess.fill(-1)
	_clear_children(history)
	_rebuild_guess_slots()
	_rebuild_palette()
	round_label.text = "PARTIDA %d / %d" % [round_index + 1, config.partidas.size()]
	config_label.text = "%d posiciones · %d colores · %d intentos" % [round_config.posiciones, round_config.cantidad_colores, round_config.intentos_maximos]
	feedback_label.text = "Prepara una combinación"
	feedback_label.add_theme_color_override("font_color", Color("3b6263"))
	accepting_input = true
	_update_buttons()


func _get_round_config() -> MastermindRoundConfig:
	return config.partidas[round_index]


func _generate_secret(round_config: MastermindRoundConfig) -> Array[int]:
	var result: Array[int] = []
	if round_config.permitir_colores_repetidos:
		for _position in range(round_config.posiciones):
			result.append(random.randi_range(0, round_config.cantidad_colores - 1))
		return result
	var available_colors: Array[int] = []
	for color_index in range(round_config.cantidad_colores):
		available_colors.append(color_index)
	_shuffle(available_colors)
	for position in range(round_config.posiciones):
		result.append(available_colors[position])
	return result


func _rebuild_guess_slots() -> void:
	_clear_children(current_guess_container)
	for position in range(current_guess.size()):
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(52, 48)
		slot.expand_icon = true
		slot.text = "?" if current_guess[position] < 0 else ""
		slot.icon = null if current_guess[position] < 0 else config.capsulas[current_guess[position]]
		slot.add_theme_font_size_override("font_size", 22)
		slot.add_theme_color_override("font_color", Color("6d8580"))
		slot.add_theme_stylebox_override("normal", _make_slot_style())
		slot.add_theme_stylebox_override("hover", _make_slot_style(Color("d5e9df")))
		slot.tooltip_text = "Vaciar posición" if current_guess[position] >= 0 else "Posición vacía"
		slot.pressed.connect(_remove_guess_at.bind(position))
		current_guess_container.add_child(slot)


func _rebuild_palette() -> void:
	_clear_children(palette)
	for color_index in range(_get_round_config().cantidad_colores):
		var button := Button.new()
		button.custom_minimum_size = Vector2(105, 54)
		button.icon = config.capsulas[color_index]
		button.expand_icon = true
		button.add_theme_stylebox_override("normal", _make_slot_style(Color("f6f0d9")))
		button.add_theme_stylebox_override("hover", _make_slot_style(Color("d5e9df")))
		button.tooltip_text = "Añadir cápsula"
		button.pressed.connect(_add_color.bind(color_index))
		palette.add_child(button)


func _add_color(color_index: int) -> void:
	if not accepting_input:
		return
	for position in range(current_guess.size()):
		if current_guess[position] < 0:
			current_guess[position] = color_index
			_rebuild_guess_slots()
			_update_buttons()
			return


func _remove_guess_at(position: int) -> void:
	if not accepting_input or current_guess[position] < 0:
		return
	current_guess[position] = -1
	_rebuild_guess_slots()
	_update_buttons()


func _clear_guess() -> void:
	if not accepting_input:
		return
	current_guess.fill(-1)
	_rebuild_guess_slots()
	_update_buttons()


func _update_buttons() -> void:
	var is_complete := not current_guess.has(-1)
	check_button.disabled = not accepting_input or not is_complete
	clear_button.disabled = not accepting_input or current_guess.count(-1) == current_guess.size()


func _check_guess() -> void:
	if not accepting_input or current_guess.has(-1):
		return
	accepting_input = false
	_update_buttons()
	attempts += 1
	var result := evaluate_guess(secret, current_guess, _get_round_config().cantidad_colores)
	_add_history_row(current_guess, result.x, result.y)
	if result.x == secret.size():
		solved_rounds += 1
		feedback_label.text = "¡Receta descubierta!"
		feedback_label.add_theme_color_override("font_color", Color("278852"))
		await get_tree().create_timer(config.espera_entre_partidas, true, false, true).timeout
		_advance_round()
		return
	if attempts >= _get_round_config().intentos_maximos:
		current_guess = secret.duplicate()
		_rebuild_guess_slots()
		feedback_label.text = "Sin intentos: esta era la receta"
		feedback_label.add_theme_color_override("font_color", Color("c54850"))
		await get_tree().create_timer(config.espera_entre_partidas, true, false, true).timeout
		_advance_round()
		return
	feedback_label.text = "%d dorados · %d plateados" % [result.x, result.y]
	feedback_label.add_theme_color_override("font_color", Color("47676b"))
	current_guess.fill(-1)
	_rebuild_guess_slots()
	accepting_input = true
	_update_buttons()


static func evaluate_guess(code: Array[int], guess: Array[int], color_count: int) -> Vector2i:
	var exact := 0
	var code_counts: Array[int] = []
	code_counts.resize(color_count)
	code_counts.fill(0)
	for position in range(code.size()):
		if code[position] == guess[position]:
			exact += 1
		else:
			code_counts[code[position]] += 1
	var misplaced := 0
	for position in range(code.size()):
		if code[position] == guess[position]:
			continue
		var color_index := guess[position]
		if color_index >= 0 and color_index < color_count and code_counts[color_index] > 0:
			misplaced += 1
			code_counts[color_index] -= 1
	return Vector2i(exact, misplaced)


func _add_history_row(guess: Array[int], exact: int, misplaced: int) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	var number_label := Label.new()
	number_label.custom_minimum_size = Vector2(24, 30)
	number_label.text = "%02d" % attempts
	number_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(number_label)
	for color_index in guess:
		row.add_child(_make_texture(config.capsulas[color_index], Vector2(38, 27)))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(4, 1)
	row.add_child(spacer)
	for _bone in range(exact):
		row.add_child(_make_texture(config.hueso_dorado, Vector2(24, 18)))
	for _bone in range(misplaced):
		row.add_child(_make_texture(config.hueso_plateado, Vector2(24, 18)))
	if exact + misplaced == 0:
		var no_match := Label.new()
		no_match.text = "—"
		no_match.add_theme_font_size_override("font_size", 20)
		row.add_child(no_match)
	history.add_child(row)
	await get_tree().process_frame
	history_scroll.scroll_vertical = int(history_scroll.get_v_scroll_bar().max_value)


func _make_texture(texture: Texture2D, minimum_size: Vector2) -> TextureRect:
	var texture_rect := TextureRect.new()
	texture_rect.custom_minimum_size = minimum_size
	texture_rect.texture = texture
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return texture_rect


func _make_slot_style(color := Color("e4ece1")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color("6e9188")
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	return style


func _advance_round() -> void:
	if not is_inside_tree():
		return
	round_index += 1
	if round_index >= config.partidas.size():
		_finish_session()
	else:
		_start_round()


func _finish_session() -> void:
	accepting_input = false
	_update_buttons()
	end_summary.text = "Resolviste %d de %d recetas" % [solved_rounds, config.partidas.size()]
	end_panel.show()
	replay_button.grab_focus()


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _shuffle(values: Array) -> void:
	for index in range(values.size() - 1, 0, -1):
		var other := random.randi_range(0, index)
		var temporary = values[index]
		values[index] = values[other]
		values[other] = temporary


func _show_config_error() -> void:
	accepting_input = false
	round_label.text = "CONFIGURACIÓN INVÁLIDA"
	feedback_label.text = "Revisa default_mastermind_config.tres"
	feedback_label.add_theme_color_override("font_color", Color("c54850"))


func close() -> void:
	if not is_inside_tree():
		return
	get_tree().paused = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
