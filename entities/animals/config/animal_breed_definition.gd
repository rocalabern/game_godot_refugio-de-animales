class_name AnimalBreedDefinition
extends Resource

## Fuente de verdad de una subraza: identidad, creatividad, geometría y nombres.
@export_category("Identidad")
@export_enum("Cat", "Dog", "Bird") var animal_type := "Cat"
@export var breed_id: StringName
@export var display_name := ""
@export_range(0, 100, 1) var default_age := 0

@export_category("Nombres")
@export var name_pool: AnimalNamePool

@export_category("Presentación y ocupación")
@export_range(1, 4, 1) var visual_columns := 1
@export_range(1, 4, 1) var base_columns := 1
@export var visual_texture: Texture2D


func pick_random_name(random: RandomNumberGenerator) -> String:
	if name_pool == null:
		push_warning("La subraza '%s' no tiene catálogo de nombres." % breed_id)
		return ""
	return name_pool.pick_random_name(random)


func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if breed_id.is_empty():
		errors.append("La definición no tiene breed_id.")
	if display_name.strip_edges().is_empty():
		errors.append("La subraza '%s' no tiene nombre visible." % breed_id)
	if name_pool == null:
		errors.append("La subraza '%s' no tiene catálogo de nombres." % breed_id)
	else:
		errors.append_array(name_pool.get_validation_errors())
	if base_columns > visual_columns:
		errors.append("La base de '%s' no puede ser más ancha que su visual." % breed_id)
	if visual_texture == null:
		errors.append("La subraza '%s' no tiene textura." % breed_id)
	return errors
