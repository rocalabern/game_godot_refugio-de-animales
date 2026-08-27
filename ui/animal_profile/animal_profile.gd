class_name AnimalProfile
extends CanvasLayer

## Ficha modal reutilizable para cualquier AnimalObject.
## Se mantiene dentro de la escena principal y pausa el árbol mientras está abierta.
signal closed

var current_animal: AnimalObject

@onready var card: PanelContainer = $ProfileRoot/Card
@onready var close_button: Button = $ProfileRoot/Card/Margin/Content/Header/CloseButton
@onready var name_label: Label = $ProfileRoot/Card/Margin/Content/Header/Info/NameLabel
@onready var type_label: Label = $ProfileRoot/Card/Margin/Content/Body/Details/IdentityRow/TypeLabel
@onready var breed_label: Label = $ProfileRoot/Card/Margin/Content/Body/Details/IdentityRow/BreedLabel
@onready var age_label: Label = $ProfileRoot/Card/Margin/Content/Body/Details/AgeLabel
@onready var description_label: Label = $ProfileRoot/Card/Margin/Content/Header/Info/Description
@onready var portrait: TextureRect = $ProfileRoot/Card/Margin/Content/Body/PortraitFrame/Portrait
@onready var health_bar: ProgressBar = $ProfileRoot/Card/Margin/Content/Body/Details/HealthBar
@onready var hunger_bar: ProgressBar = $ProfileRoot/Card/Margin/Content/Body/Details/HungerBar
@onready var hygiene_bar: ProgressBar = $ProfileRoot/Card/Margin/Content/Body/Details/HygieneBar
@onready var energy_bar: ProgressBar = $ProfileRoot/Card/Margin/Content/Body/Details/EnergyBar


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	close_button.pressed.connect(close)
	$ProfileRoot.hide()


func open_for(animal: AnimalObject) -> void:
	current_animal = animal
	name_label.text = animal.pet_name if not animal.pet_name.is_empty() else animal.nombre
	type_label.text = "Tipo: %s" % animal.get_tipo_display_name()
	breed_label.text = "Raza: %s" % animal.raza
	age_label.text = "Edad: %d años" % animal.edad
	description_label.text = animal.get_personality_description()
	set_stat(health_bar, animal.salud)
	set_stat(hunger_bar, animal.hambre)
	set_stat(hygiene_bar, animal.higiene)
	set_stat(energy_bar, animal.energia)
	set_portrait(animal)
	$ProfileRoot.show()
	get_tree().paused = true
	close_button.grab_focus()


func close() -> void:
	if not $ProfileRoot.visible:
		return
	$ProfileRoot.hide()
	current_animal = null
	get_tree().paused = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if $ProfileRoot.visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func set_stat(bar: ProgressBar, value: float) -> void:
	bar.value = value
	bar.tooltip_text = "%d / 100" % roundi(value)
	bar.add_theme_stylebox_override("fill", create_stat_fill(value))


func create_stat_fill(value: float) -> StyleBoxFlat:
	var fill := StyleBoxFlat.new()
	if value < 25.0:
		fill.bg_color = Color("c84a4a")
	elif value < 60.0:
		fill.bg_color = Color("d7a631")
	else:
		fill.bg_color = Color("4d9e6e")
	fill.corner_radius_top_left = 8
	fill.corner_radius_top_right = 8
	fill.corner_radius_bottom_right = 8
	fill.corner_radius_bottom_left = 8
	return fill


func set_portrait(animal: AnimalObject) -> void:
	var visual := animal.get_node_or_null("Visual") as Sprite2D
	portrait.texture = visual.texture if visual != null else null
