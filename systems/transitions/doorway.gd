@tool
class_name Doorway
extends Area2D

## Puerta reutilizable: una zona estándar de Godot que enlaza una sala con un
## Marker2D identificado en la escena de destino.
signal transition_requested(doorway: Doorway, body: Node2D)

@export_category("Destino")
@export_file("*.tscn") var destination_scene_path := ""
@export var destination_spawn_id: StringName
@export var transition_sound: AudioStream

@export_category("Zona en grid")
@export var grid_cell := Vector2i.ZERO:
	set(value):
		grid_cell = value
		_update_shape()
@export var grid_size := Vector2i.ONE:
	set(value):
		grid_size = Vector2i(maxi(1, value.x), maxi(1, value.y))
		_update_shape()
@export var allowed_entry_direction := Vector2.ZERO

var cell_size := Vector2(48, 48)
var _transitioning := false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	_update_shape()
	if not Engine.is_editor_hint() and not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func configure_grid_size(new_cell_size: Vector2) -> void:
	cell_size = new_cell_size
	_update_shape()


func _on_body_entered(body: Node2D) -> void:
	if _transitioning or not body is PlayerController:
		return
	if allowed_entry_direction != Vector2.ZERO:
		var movement: Vector2 = body.velocity.normalized()
		if movement.dot(allowed_entry_direction.normalized()) < 0.6:
			return
	_transitioning = true
	transition_requested.emit(self, body)


func _update_shape() -> void:
	if not is_instance_valid(collision_shape):
		return
	position = (Vector2(grid_cell) + Vector2(grid_size) * 0.5) * cell_size
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(grid_size) * cell_size
	collision_shape.shape = rectangle
