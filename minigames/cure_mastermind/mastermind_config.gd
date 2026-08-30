class_name MastermindConfig
extends Resource

## Configuración de la sesión completa de Mastermind veterinario.

@export_category("Partidas")
@export var partidas: Array[MastermindRoundConfig] = []
@export_range(0.2, 5.0, 0.1) var espera_entre_partidas := 1.6

@export_category("Cápsulas")
@export var capsulas: Array[Texture2D] = []

@export_category("Pistas")
@export var hueso_dorado: Texture2D
@export var hueso_plateado: Texture2D
