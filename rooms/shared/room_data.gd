class_name RoomData
extends Resource

## Datos editables de una habitación: suelo, contenido colocado y puertas.
@export var room_id := ""
@export var grid_data: RoomGridData
@export var placements: Array[PlacedObjectData] = []
@export var transitions: Array[RoomTransitionData] = []
