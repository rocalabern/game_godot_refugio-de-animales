class_name PlayerController
extends CharacterBody2D

signal navigation_finished

@export var speed := 320.0
var cell_size := Vector2(48, 48):
	set(value):
		cell_size = value
		queue_redraw()
		_update_collision()
var navigating := false

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("player")
	_update_collision()
	queue_redraw()


func move_to(world_position: Vector2) -> void:
	navigation_agent.target_position = world_position
	navigating = true


func stop() -> void:
	navigating = false
	velocity = Vector2.ZERO


func _physics_process(_delta: float) -> void:
	if not navigating:
		return
	if navigation_agent.is_navigation_finished():
		stop()
		navigation_finished.emit()
		return

	var next_position := navigation_agent.get_next_path_position()
	velocity = global_position.direction_to(next_position) * speed
	navigation_agent.velocity = velocity
	move_and_slide()


func _update_collision() -> void:
	if not is_instance_valid(collision_shape):
		return
	var shape := RectangleShape2D.new()
	# El dibujo ocupa dos filas, pero solo la fila inferior es física.
	# La base física es exactamente una casilla completa. La parte superior del
	# dibujo puede superponerse visualmente, pero el personaje no puede entrar en
	# la casilla base de otro ocupante ni colarse por las esquinas.
	shape.size = cell_size
	collision_shape.shape = shape
	collision_shape.position = Vector2.ZERO


func _draw() -> void:
	# El origen permanece en los pies para que Y-Sort pueda comparar al jugador.
	var body := Rect2(Vector2(-cell_size.x * 0.5, -cell_size.y * 1.5), Vector2(cell_size.x, cell_size.y * 2.0))
	draw_rect(body, Color("36b7eb"))
	draw_rect(body, Color.WHITE, false, 3.0)
	draw_circle(Vector2(0, -cell_size.y * 1.15), cell_size.x * 0.12, Color("103a56"))
