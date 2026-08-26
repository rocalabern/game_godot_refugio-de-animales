class_name InteractionController
extends RefCounted

## Unifica el clic sobre contenido: primero se camina a una casilla válida y
## después se llama a la interacción del objeto.
var pending_object: PlaceableObject


func request_at_cell(room: ShelterRoom, player: PlayerController, cell: Vector2i) -> bool:
	var object := room.get_interactable_at_cell(cell)
	if object == null:
		return false
	var destination := room.get_interaction_destination(object)
	if destination == Vector2.INF:
		return true
	pending_object = object
	# La conexión pertenece a esta orden concreta; evita acumular callbacks al
	# interactuar varias veces con distintos animales u objetos.
	player.navigation_finished.connect(_on_player_navigation_finished.bind(player), CONNECT_ONE_SHOT)
	player.move_to(destination)
	return true


func _on_player_navigation_finished(player: PlayerController) -> void:
	if is_instance_valid(pending_object):
		pending_object.interact(player)
	pending_object = null
