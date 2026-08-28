class_name AnimalPickupBackdropCatalog
extends Resource

## Catálogo de fondos agrupados por entorno.
@export var forest_backdrops: Array[AnimalPickupBackdrop] = []
@export var city_backdrops: Array[AnimalPickupBackdrop] = []


func get_random_backdrop(random: RandomNumberGenerator, environment: String) -> AnimalPickupBackdrop:
	var candidates := forest_backdrops if environment == "forest" else city_backdrops
	if candidates.is_empty():
		return null
	return candidates[random.randi_range(0, candidates.size() - 1)]
