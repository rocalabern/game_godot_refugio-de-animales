class_name MapConfig
extends Resource

## Parámetros editables del escenario de mapa y sus encuentros.
@export_category("Movimiento")
@export var player_speed := 260.0
@export var map_margin := 12.0
@export var shelter_door_position := Vector2(0.82, 0.21)
@export var shelter_hit_rect := Rect2(0.75, 0.045, 0.19, 0.22)
@export var shelter_safe_radius := 135.0

@export_category("Encuentros")
@export var first_encounter_delay_min := 1.5
@export var first_encounter_delay_max := 3.0
@export var encounter_interval_min := 3.0
@export var encounter_interval_max := 6.0
@export var encounter_duration_min := 2.0
@export var encounter_duration_max := 3.0
@export var encounter_distance_min := 90.0
@export var encounter_distance_max := 190.0
