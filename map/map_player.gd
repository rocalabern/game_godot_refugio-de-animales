class_name MapPlayer
extends Control

const FRONT_TEXTURE := preload("res://assets/characters/main_character_map_front.png")
const BACK_TEXTURE := preload("res://assets/characters/main_character_map_back.png")
const VISUAL_HEIGHT := 58.0

var facing_left := false
var looking_back := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func set_facing_from_motion(motion: Vector2) -> void:
	if motion.is_zero_approx():
		return
	var next_looking_back := motion.y < 0.0 and absf(motion.y) >= absf(motion.x)
	var next_facing_left := facing_left
	if not next_looking_back:
		if not is_zero_approx(motion.x):
			next_facing_left = motion.x < 0.0
		elif motion.y > 0.0:
			next_facing_left = false
	if next_facing_left != facing_left or next_looking_back != looking_back:
		facing_left = next_facing_left
		looking_back = next_looking_back
		queue_redraw()


func _draw() -> void:
	var texture: Texture2D = BACK_TEXTURE if looking_back else FRONT_TEXTURE
	var texture_size := texture.get_size()
	var visual_width := VISUAL_HEIGHT * texture_size.x / texture_size.y
	var body := Rect2(
		Vector2((size.x - visual_width) * 0.5, size.y - VISUAL_HEIGHT),
		Vector2(visual_width, VISUAL_HEIGHT)
	)
	# La espalda es simétrica. Solo se refleja horizontalmente el sprite frontal.
	if facing_left and not looking_back:
		draw_set_transform(Vector2(size.x, 0.0), 0.0, Vector2(-1.0, 1.0))
	draw_texture_rect(texture, body, false)
