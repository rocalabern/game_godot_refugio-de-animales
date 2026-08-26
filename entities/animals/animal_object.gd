class_name AnimalObject
extends PlaceableObject

## Necesidades comunes a gatos, perros y aves. Cada especie puede ampliar
## esta clase sin que las habitaciones conozcan su implementación concreta.
@export var display_name := "Animal"
@export_range(0.0, 100.0) var health := 100.0
@export_range(0.0, 100.0) var hunger := 0.0
@export_range(0.0, 100.0) var energy := 80.0
@export_range(0.0, 100.0) var happiness := 80.0


func feed() -> void:
	hunger = maxf(0.0, hunger - 25.0)
	happiness = minf(100.0, happiness + 5.0)


func play() -> void:
	energy = maxf(0.0, energy - 12.0)
	happiness = minf(100.0, happiness + 15.0)


func rest() -> void:
	energy = minf(100.0, energy + 25.0)
