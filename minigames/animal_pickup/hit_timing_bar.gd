class_name HitTimingBar
extends Control

## Barra visual reutilizable para eventos de precisión temporal.
@export_range(0.0, 1.0) var target_start := 0.42:
	set(value):
		target_start = value
		queue_redraw()
@export_range(0.0, 1.0) var target_end := 0.58:
	set(value):
		target_end = value
		queue_redraw()
@export_range(0.0, 1.0) var marker_position := 1.0:
	set(value):
		marker_position = clampf(value, 0.0, 1.0)
		queue_redraw()

const TRACK_MARGIN := 7.0
const MARKER_WIDTH := 7.0


func is_marker_inside_target() -> bool:
	return marker_position >= target_start and marker_position <= target_end


func _draw() -> void:
	var track := Rect2(Vector2(2.0, TRACK_MARGIN), Vector2(size.x - 4.0, size.y - TRACK_MARGIN * 2.0))
	var shadow := track.grow(4.0)
	draw_rect(shadow, Color(0.03, 0.055, 0.045, 0.62), true)
	draw_rect(track, Color(0.18, 0.23, 0.20, 0.96), true)
	draw_rect(track, Color(0.78, 0.68, 0.48, 0.78), false, 3.0)

	var target_x := track.position.x + track.size.x * target_start
	var target_width := track.size.x * (target_end - target_start)
	var target := Rect2(Vector2(target_x, track.position.y), Vector2(target_width, track.size.y))
	draw_rect(target.grow(3.0), Color(0.38, 0.80, 0.42, 0.20), true)
	draw_rect(target, Color(0.30, 0.68, 0.36, 0.96), true)
	draw_line(Vector2(target.position.x, target.position.y), Vector2(target.position.x, target.end.y), Color(0.67, 0.94, 0.60), 2.0)
	draw_line(Vector2(target.end.x, target.position.y), Vector2(target.end.x, target.end.y), Color(0.20, 0.48, 0.25), 2.0)

	var marker_x := track.position.x + track.size.x * marker_position
	var marker := Rect2(Vector2(marker_x - MARKER_WIDTH * 0.5, track.position.y - 5.0), Vector2(MARKER_WIDTH, track.size.y + 10.0))
	draw_rect(marker.grow(2.0), Color(0.08, 0.10, 0.08, 0.72), true)
	draw_rect(marker, Color(1.0, 0.91, 0.58, 1.0), true)
	draw_line(Vector2(marker.position.x + 1.5, marker.position.y + 1.0), Vector2(marker.position.x + 1.5, marker.end.y - 1.0), Color(1.0, 0.98, 0.84), 2.0)
