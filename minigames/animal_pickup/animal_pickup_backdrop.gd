class_name AnimalPickupBackdrop
extends Resource

## Fondo seleccionable y zona clicable del animal en coordenadas normalizadas.
@export_enum("forest", "city") var environment: String = "forest"
@export var texture: Texture2D
@export var animal_hit_rect := Rect2(0.4, 0.3, 0.2, 0.2)
