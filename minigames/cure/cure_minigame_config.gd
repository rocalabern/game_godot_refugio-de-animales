class_name CureMinigameConfig
extends Resource

## Parámetros editables del minijuego de búsqueda veterinaria.

@export_category("Partida")
@export_range(1, 20, 1) var partidas_seguidas := 3
@export_range(1, 20, 1) var vidas := 3
@export_range(2, 100, 1) var objetos_en_pantalla := 48
@export_range(0.1, 5.0, 0.05) var espera_resultado := 1.15

@export_category("Distribución")
@export var tamano_objeto := Vector2(82, 68)
@export_range(1, 500, 1) var intentos_colocacion := 70
@export_range(-180.0, 180.0, 1.0) var rotacion_minima_grados := -16.0
@export_range(-180.0, 180.0, 1.0) var rotacion_maxima_grados := 16.0
@export_range(0.1, 3.0, 0.01) var escala_minima := 0.82
@export_range(0.1, 3.0, 0.01) var escala_maxima := 1.08
@export_range(0, 100, 1) var profundidad_maxima := 20

@export_category("Interacción")
@export_range(0.0, 1.0, 0.01) var umbral_click_alpha := 0.18
@export_range(1, 30, 1) var frames_espera_layout := 4

@export_category("Catálogos")
@export_dir var carpeta_medicina := "res://assets/minigames/cure/medical"
@export_dir var carpeta_distractores := "res://assets/minigames/cure/distractors"
@export var imagenes_medicina: Array[Texture2D] = []
@export var imagenes_distractoras: Array[Texture2D] = []
