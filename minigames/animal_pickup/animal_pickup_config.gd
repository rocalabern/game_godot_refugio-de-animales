class_name AnimalPickupConfig
extends Resource

## Parámetros de balance del minijuego de recogida de animales.

@export_category("Barra")
@export_range(0.05, 2.0, 0.01) var bar_speed := 0.48
@export_range(0.01, 1.0, 0.01) var target_width_min := 0.05
@export_range(0.01, 1.0, 0.01) var target_width_max := 0.35
@export_range(0.0, 1.0, 0.01) var initial_marker_position := 1.0

@export_category("Intentos")
@export_range(1, 100, 1) var n_replays_hit_timing_bar := 3
@export_range(0.1, 3.0, 0.05) var result_display_time := 0.85
@export_range(0.5, 5.0, 0.1) var completion_close_delay := 2.0
