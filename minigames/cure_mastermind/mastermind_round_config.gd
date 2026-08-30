class_name MastermindRoundConfig
extends Resource

## Dificultad de una partida individual de Cura v2.

@export_range(3, 6, 1) var posiciones := 3
@export_range(2, 6, 1) var cantidad_colores := 3
@export_range(1, 20, 1) var intentos_maximos := 8
@export var permitir_colores_repetidos := true
