class_name AnimalObject
extends PlaceableObject

## Plantilla de datos común para todos los animales del refugio.
## Las especies concretas amplían comportamiento, pero la ficha se alimenta de
## estos datos sin necesitar conocer la clase Cat, Dog, Rabbit u Owl.
@export_category("Identidad")
@export_enum("Cat", "Dog", "Rabbit", "Owl") var tipo := "Cat"
@export_enum("Siames") var raza := "Siames"
@export_range(0, 100, 1) var edad: int = 0
@export var nombre := "Animal"
@export var pet_name := ""

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
	# La primera acción de cuidado es deliberadamente simple: mejora todas las
	# necesidades visibles y deja espacio para que cada especie la especialice.
	salud = minf(100.0, salud + amount)
	hambre = minf(100.0, hambre + amount)
	higiene = minf(100.0, higiene + amount)
	energia = minf(100.0, energia + amount)
	felicidad = minf(100.0, felicidad + amount)


func get_personality_description() -> String:
	return "Este %s es %s, %s, %s y %s." % [
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
		"Rabbit": return "Conejo"
		"Owl": return "Buho"
		_: return tipo


func get_active_label() -> String:
	if caracteristica_activo < 20.0:
		return "muy tranquilo"
	if caracteristica_activo <= 40.0:
		return "tranquilo"
	if caracteristica_activo < 60.0:
		return "equilibrado"
	if caracteristica_activo <= 80.0:
		return "nervioso"
	return "muy nervioso"


func get_sociable_label() -> String:
	if caracteristica_sociable < 20.0:
		return "muy poco empático"
	if caracteristica_sociable <= 40.0:
		return "poco empático"
	if caracteristica_sociable < 60.0:
		return "equilibrado"
	if caracteristica_sociable <= 80.0:
		return "empático"
	return "muy empático"


func get_dependiente_label() -> String:
	if caracteristica_dependiente < 20.0:
		return "muy independiente"
	if caracteristica_dependiente <= 40.0:
		return "independiente"
	if caracteristica_dependiente < 60.0:
		return "equilibrado"
	if caracteristica_dependiente <= 80.0:
		return "cariñoso"
	return "muy cariñoso"


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
