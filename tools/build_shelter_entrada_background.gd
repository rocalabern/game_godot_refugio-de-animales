extends SceneTree

const SOURCE := "res://assets/rooms/shelter_entrada/shelter_entrada_background_v3.png"
const OUTPUT := "res://assets/rooms/shelter_entrada/shelter_entrada_background_48.png"
const ROOM_SIZE := Vector2i(21 * 48, 13 * 48)

func _init() -> void:
	var image := Image.load_from_file(SOURCE)
	if image == null:
		push_error("No se pudo cargar el fondo de shelter_entrada.")
		quit(1)
		return
	image.resize(ROOM_SIZE.x, ROOM_SIZE.y, Image.INTERPOLATE_LANCZOS)
	var result := image.save_png(OUTPUT)
	if result != OK:
		push_error("No se pudo guardar el fondo ajustado de shelter_entrada.")
		quit(1)
		return
	print(OUTPUT)
	quit()
