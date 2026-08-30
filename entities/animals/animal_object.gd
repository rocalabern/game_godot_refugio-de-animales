class_name AnimalObject
extends PlaceableObject

## Plantilla de datos común para todos los animales del refugio.
## Las especies concretas amplían comportamiento, pero la ficha se alimenta de
## estos datos sin necesitar conocer la clase Cat, Dog o Bird.
@export_category("Identidad")
@export var breed_definition: AnimalBreedDefinition
@export var pet_name := ""

var tipo := "Cat"
var raza := ""
var edad := 0
var nombre := "Animal"

@export_category("Necesidades")
@export_range(0.0, 100.0, 1.0) var salud := 100.0
@export_range(0.0, 100.0, 1.0) var hambre := 0.0
@export_range(0.0, 100.0, 1.0) var higiene := 100.0
@export_range(0.0, 100.0, 1.0) var felicidad := 80.0
@export_range(0.0, 100.0, 1.0) var energia := 100.0

@export_category("Características")
@export_range(0.0, 100.0, 1.0) var caracteristica_activo := 50.0
@export_range(0.0, 100.0, 1.0) var caracteristica_sociable := 50.0
@export_range(0.0, 100.0, 1.0) var caracteristica_dependiente := 50.0
@export_range(0.0, 100.0, 1.0) var caracteristica_adistramiento := 50.0


func feed() -> void:
	hambre = maxf(0.0, hambre - 25.0)
	felicidad = minf(100.0, felicidad + 5.0)


func play() -> void:
	felicidad = minf(100.0, felicidad + 15.0)


func clean() -> void:
	higiene = minf(100.0, higiene + 25.0)


func receive_care(amount := 15.0) -> void:
	# Acariciar es una acción afectiva: no sustituye comer, limpiar o descansar.
	felicidad = minf(100.0, felicidad + amount)


func apply_breed_definition() -> void:
	if breed_definition == null:
		push_warning("El animal '%s' no tiene AnimalBreedDefinition." % name)
		return
	tipo = breed_definition.animal_type
	raza = breed_definition.display_name
	nombre = breed_definition.display_name
	edad = breed_definition.default_age


func initialize_runtime_state(random: RandomNumberGenerator) -> void:
	# Cada animal recibe sus valores una única vez al entrar por primera vez en
	# la partida. Después se conserva su ficha de estado en GameController.
	salud = random.randi_range(0, 100)
	hambre = random.randi_range(0, 100)
	higiene = random.randi_range(0, 100)
	energia = random.randi_range(0, 100)
	felicidad = 15.0
	caracteristica_activo = random.randi_range(0, 100)
	caracteristica_sociable = random.randi_range(0, 100)
	caracteristica_dependiente = random.randi_range(0, 100)
	caracteristica_adistramiento = random.randi_range(0, 100)
	if pet_name.is_empty() and breed_definition != null:
		pet_name = breed_definition.pick_random_name(random)


func get_runtime_state() -> Dictionary:
	return {
		"pet_name": pet_name,
		"salud": salud,
		"hambre": hambre,
		"higiene": higiene,
		"energia": energia,
		"felicidad": felicidad,
		"caracteristica_activo": caracteristica_activo,
		"caracteristica_sociable": caracteristica_sociable,
		"caracteristica_dependiente": caracteristica_dependiente,
		"caracteristica_adistramiento": caracteristica_adistramiento,
	}


func apply_runtime_state(state: Dictionary) -> void:
	pet_name = String(state.get("pet_name", pet_name))
	salud = float(state.get("salud", salud))
	hambre = float(state.get("hambre", hambre))
	higiene = float(state.get("higiene", higiene))
	energia = float(state.get("energia", energia))
	felicidad = float(state.get("felicidad", felicidad))
	caracteristica_activo = float(state.get("caracteristica_activo", caracteristica_activo))
	caracteristica_sociable = float(state.get("caracteristica_sociable", caracteristica_sociable))
	caracteristica_dependiente = float(state.get("caracteristica_dependiente", caracteristica_dependiente))
	caracteristica_adistramiento = float(state.get("caracteristica_adistramiento", caracteristica_adistramiento))


func get_personality_description() -> String:
	return "Este %s es %s %s %s %s." % [
		get_tipo_en_espanol(),
		get_active_label(),
		get_sociable_label(),
		get_dependiente_label(),
		get_adistramiento_label(),
	]


func get_tipo_en_espanol() -> String:
	return get_tipo_display_name().to_lower()


func get_tipo_display_name() -> String:
	match tipo:
		"Cat": return "Gato"
		"Dog": return "Perro"
		"Bird": return "Ave"
		_: return tipo


func get_active_label() -> String:
	if caracteristica_activo < 20.0:
		return "muy tranquilo, "
	if caracteristica_activo <= 40.0:
		return "tranquilo, "
	if caracteristica_activo < 60.0:
		return ""
	if caracteristica_activo <= 80.0:
		return "nervioso, "
	return "muy nervioso, "


func get_sociable_label() -> String:
	if caracteristica_sociable < 20.0:
		return "muy poco empático, "
	if caracteristica_sociable <= 40.0:
		return "poco empático, "
	if caracteristica_sociable < 60.0:
		return ""
	if caracteristica_sociable <= 80.0:
		return "empático, "
	return "muy empático, "


func get_dependiente_label() -> String:
	if caracteristica_dependiente < 20.0:
		return "muy independiente, "
	if caracteristica_dependiente <= 40.0:
		return "independiente, "
	if caracteristica_dependiente < 60.0:
		return ""
	if caracteristica_dependiente <= 80.0:
		return "cariñoso, "
	return "muy cariñoso, "


func get_adistramiento_label() -> String:
	if caracteristica_adistramiento < 20.0:
		return "muy rebelde"
	if caracteristica_adistramiento <= 40.0:
		return "rebelde"
	if caracteristica_adistramiento < 60.0:
		return "en aprendizaje"
	if caracteristica_adistramiento <= 80.0:
		return "obediente"
	return "adiestrado"
