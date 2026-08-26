extends Node2D

const SPEED := 320.0
const PLAYER_SIZE := 64.0

@export_file("*.png") var background_path := "res://assets/room_background.png"
@export_file("*.png") var collision_mask_path := "res://assets/room_collision.png"
@export var show_collision_mask := false
@export var spawn_position := Vector2(860, 540)

var player_position := Vector2(860, 540)
var target_position := player_position
var collision_mask: Image

@onready var background: Sprite2D = $Background
@onready var collision_mask_preview: Sprite2D = $CollisionMaskPreview


func _ready() -> void:
	load_room_images()
	player_position = find_nearest_walkable_position(spawn_position)
	target_position = player_position
	queue_redraw()


func load_room_images() -> void:
	if FileAccess.file_exists(background_path):
		background.texture = load(background_path)
		background.position = get_viewport_rect().size / 2.0

	if FileAccess.file_exists(collision_mask_path):
		collision_mask = Image.load_from_file(collision_mask_path)
		collision_mask_preview.texture = load(collision_mask_path)
		collision_mask_preview.position = get_viewport_rect().size / 2.0
		collision_mask_preview.visible = show_collision_mask


func _process(delta: float) -> void:
	if player_position.distance_to(target_position) > 1.0:
		move_toward_target(SPEED * delta)
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		target_position = event.position
		target_position.x = clamp(target_position.x, PLAYER_SIZE / 2.0, get_viewport_rect().size.x - PLAYER_SIZE / 2.0)
		target_position.y = clamp(target_position.y, PLAYER_SIZE / 2.0, get_viewport_rect().size.y - PLAYER_SIZE / 2.0)


func move_toward_target(max_distance: float) -> void:
	var remaining_motion: Vector2 = player_position.direction_to(target_position) * minf(max_distance, player_position.distance_to(target_position))
	var horizontal_candidate := player_position + Vector2(remaining_motion.x, 0.0)
	if not collides_with_mask(horizontal_candidate):
		player_position.x = horizontal_candidate.x

	var vertical_candidate := player_position + Vector2(0.0, remaining_motion.y)
	if not collides_with_mask(vertical_candidate):
		player_position.y = vertical_candidate.y


func collides_with_mask(candidate_position: Vector2) -> bool:
	if collision_mask == null:
		return false

	var viewport_size := get_viewport_rect().size
	var half_size := PLAYER_SIZE / 2.0
	var image_scale := Vector2(
		float(collision_mask.get_width()) / viewport_size.x,
		float(collision_mask.get_height()) / viewport_size.y
	)
	for offset_x in range(-int(half_size), int(half_size) + 1, 4):
		for offset_y in range(-int(half_size), int(half_size) + 1, 4):
			var sample_point := candidate_position + Vector2(offset_x, offset_y)
			var image_point := Vector2i(sample_point * image_scale)
			if image_point.x < 0 or image_point.y < 0 or image_point.x >= collision_mask.get_width() or image_point.y >= collision_mask.get_height():
				return true
			if collision_mask.get_pixelv(image_point).get_luminance() < 0.1:
				return true
	return false


func find_nearest_walkable_position(preferred_position: Vector2) -> Vector2:
	var viewport_size := get_viewport_rect().size
	var half_size := PLAYER_SIZE / 2.0
	var safe_position := Vector2(
		clamp(preferred_position.x, half_size, viewport_size.x - half_size),
		clamp(preferred_position.y, half_size, viewport_size.y - half_size)
	)
	if not collides_with_mask(safe_position):
		return safe_position

	for radius in range(8, 600, 8):
		for sample in range(32):
			var candidate: Vector2 = safe_position + Vector2.from_angle(TAU * sample / 32.0) * radius
			candidate.x = clamp(candidate.x, half_size, viewport_size.x - half_size)
			candidate.y = clamp(candidate.y, half_size, viewport_size.y - half_size)
			if not collides_with_mask(candidate):
				return candidate

	return safe_position


func _draw() -> void:
	if background.texture == null:
		draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color("294657"))
	var square := Rect2(player_position - Vector2.ONE * PLAYER_SIZE / 2.0, Vector2.ONE * PLAYER_SIZE)
	draw_rect(square, Color("4fc3f7"))
	draw_rect(square, Color("ffffff"), false, 3.0)
