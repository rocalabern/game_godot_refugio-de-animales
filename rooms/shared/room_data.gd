class_name RoomData
extends Resource

## Datos editables de una habitación: suelo y contenido colocado.
## Las puertas son instancias Doorway visibles en la escena de la sala.
@export var room_id := ""
@export var grid_data: RoomGridData
@export var placements: Array[PlacedObjectData] = []
