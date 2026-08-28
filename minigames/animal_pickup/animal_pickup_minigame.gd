class_name AnimalPickupMinigame
extends CanvasLayer

## Minijuego independiente de recogida de animales.
## Por ahora presenta su escenario y permite regresar a la partida conservada.
signal closed

@onready var close_button: Button = $Root/CloseButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	close_button.pressed.connect(close)
	get_tree().paused = true
	close_button.grab_focus()


func close() -> void:
	if not is_inside_tree():
		return
	get_tree().paused = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
