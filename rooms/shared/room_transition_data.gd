class_name RoomTransitionData
extends Resource

@export var id := ""
@export var trigger_cells: Array[Vector2i] = []
@export var destination_scene: PackedScene
@export var destination_spawn_cell := Vector2i.ZERO
@export var requires_click := true
