class_name RoomData
extends Resource

## Datos editables de una habitación: identidad y contenido colocado.
## El suelo, paredes y sus colisiones viven en los TileMapLayer de la escena.
## Las puertas son instancias Doorway visibles en la escena de la sala.
@export var room_id := ""
@export var placements: Array[PlacedObjectData] = []
