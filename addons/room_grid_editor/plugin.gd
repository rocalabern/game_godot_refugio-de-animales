@tool
extends EditorPlugin

var paint_button: Button
var edited_room: ShelterRoom
var panel: VBoxContainer


func _enter_tree() -> void:
	panel = VBoxContainer.new()
	panel.name = "Colisiones de sala"
	var help := Label.new()
	help.text = "Selecciona la habitación y activa el pincel.\nClic = bloquear/desbloquear casilla.\nRojo = bloqueo base."
	panel.add_child(help)

	paint_button = CheckButton.new()
	paint_button.text = "Pintar colisiones"
	paint_button.toggle_mode = true
	paint_button.tooltip_text = "Activa el pincel: clic en una casilla para bloquearla o desbloquearla."
	panel.add_child(paint_button)
	add_control_to_bottom_panel(panel, "Colisiones de sala")
	add_tool_menu_item("Alternar pincel de colisiones", _toggle_paint_mode)


func _exit_tree() -> void:
	remove_tool_menu_item("Alternar pincel de colisiones")
	if panel != null:
		remove_control_from_bottom_panel(panel)
		panel.queue_free()


func _toggle_paint_mode() -> void:
	paint_button.button_pressed = not paint_button.button_pressed


func _handles(object: Object) -> bool:
	return object is ShelterRoom


func _edit(object: Object) -> void:
	edited_room = object as ShelterRoom
	update_overlays()


func _make_visible(visible: bool) -> void:
	if not visible:
		edited_room = null


func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if edited_room == null or paint_button == null or not paint_button.button_pressed:
		return false
	if not event is InputEventMouseButton:
		return false
	var mouse_event: InputEventMouseButton = event
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return false

	# El propio CanvasItem conoce la cámara, el pan y el zoom del lienzo que lo
	# contiene. Usar su ratón global evita mezclar coordenadas del panel y ventana.
	var local_position: Vector2 = edited_room.to_local(edited_room.get_global_mouse_position())
	var cell_size := edited_room.cell_size
	var column := floori(local_position.x / cell_size.x)
	var row := floori(local_position.y / cell_size.y) - edited_room.room_top_row
	if column < 0 or column >= edited_room.room_columns or row < 0 or row >= edited_room.room_rows:
		return false

	if edited_room.grid_data == null:
		edited_room.grid_data = RoomGridData.new()
	edited_room.grid_data.columns = edited_room.room_columns
	edited_room.grid_data.rows = edited_room.room_rows
	var was_blocked := edited_room.grid_data.is_blocked(column, row)
	var undo_redo := get_undo_redo()
	undo_redo.create_action("Alternar colisión base")
	undo_redo.add_do_method(edited_room.grid_data, "set_blocked", column, row, not was_blocked)
	undo_redo.add_do_method(edited_room, "queue_redraw")
	undo_redo.add_undo_method(edited_room.grid_data, "set_blocked", column, row, was_blocked)
	undo_redo.add_undo_method(edited_room, "queue_redraw")
	undo_redo.commit_action()
	update_overlays()
	return true
