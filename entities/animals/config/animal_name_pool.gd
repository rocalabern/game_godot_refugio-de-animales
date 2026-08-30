class_name AnimalNamePool
extends Resource

## Catálogo reutilizable de nombres. Varias subrazas pueden compartirlo sin
## duplicar listas y cambiar a otro catálogo cuando necesiten diferenciarse.
@export var pool_id: StringName
@export var names: PackedStringArray = []


func pick_random_name(random: RandomNumberGenerator) -> String:
	if names.is_empty():
		push_warning("El catálogo de nombres '%s' está vacío." % pool_id)
		return ""
	return String(names[random.randi_range(0, names.size() - 1)]).strip_edges()


func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if pool_id.is_empty():
		errors.append("El catálogo de nombres no tiene pool_id.")
	if names.is_empty():
		errors.append("El catálogo '%s' no contiene nombres." % pool_id)
	for candidate in names:
		if String(candidate).strip_edges().is_empty():
			errors.append("El catálogo '%s' contiene un nombre vacío." % pool_id)
			break
	return errors
