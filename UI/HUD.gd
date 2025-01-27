extends CanvasLayer

@onready var world = get_tree().root.get_node("Game/World")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if $Information.visible:
		$Information.text = "seed: " + str(world.world.seeded) + "\ntotal chunks: " + str(world.chunk_container.get_child_count()) + "\nfps: " + str(Engine.get_frames_per_second())+ "\ncoordinates: " + str(round(world.player.position))+ "\nchunk: " + str(world.pos_to_chunk(world.player.position)-world.reference_offset)+ "\nchunks per frame: " + str(world.chunks_per_frame+1)

func _unhandled_input(event: InputEvent) -> void:
	#camera and mouse mode
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		$Settings.visible = false
	elif event.is_action_pressed("ui_cancel"):
		if $Settings.visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			$Hotbar.visible = true
			$Settings.visible = false
			get_tree().paused = false
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			$Hotbar.visible = false
			$Settings.visible = true
			get_tree().paused = true
	if event.is_action_pressed("Information"):
		if $Information.visible:
			$Information.visible = false
		else:
			$Information.visible = true
	#hotbar
	if event.is_action_pressed("ScrollUp"):
		if world.player.block > 1:
			world.player.block -= 1
		else:
			world.player.block = 7
		$Hotbar/Indicator.position.x = 49*(world.player.block-1)
	if event.is_action_pressed("ScrollDown"):
		if world.player.block < 7:
			world.player.block += 1
		else:
			world.player.block = 1
		$Hotbar/Indicator.position.x = 49*(world.player.block-1)
	if event.is_action_pressed("1"):
		world.player.block = 1
		$Hotbar/Indicator.position.x = 49*(world.player.block-1)
	if event.is_action_pressed("2"):
		world.player.block = 2
		$Hotbar/Indicator.position.x = 49*(world.player.block-1)
	if event.is_action_pressed("3"):
		world.player.block = 3
		$Hotbar/Indicator.position.x = 49*(world.player.block-1)
	if event.is_action_pressed("4"):
		world.player.block = 4
		$Hotbar/Indicator.position.x = 49*(world.player.block-1)
	if event.is_action_pressed("5"):
		world.player.block = 5
		$Hotbar/Indicator.position.x = 49*(world.player.block-1)
	if event.is_action_pressed("6"):
		world.player.block = 6
		$Hotbar/Indicator.position.x = 49*(world.player.block-1)
	if event.is_action_pressed("7"):
		world.player.block = 7
		$Hotbar/Indicator.position.x = 49*(world.player.block-1)

func _on_xz_slider_value_changed(value: float) -> void:
	world.render_distance.x = value+1
	world.render_distance.z = value+1
	world.center = world.chunk_size*world.render_distance/2
	$Settings/Subtitle.text = "Render Distance X and Z: "+str(value+1)

func _on_y_slider_value_changed(value: float) -> void:
	world.render_distance.y = value+1
	world.center = world.chunk_size*world.render_distance/2
	$Settings/Subtitle2.text = "Render Distance Y: "+str(value+1)

func _on_fps_slider_value_changed(value: float) -> void:
	world.target_fps = value
	$Settings/Subtitle3.text = "Target FPS: "+str(value)

func _on_save_button_pressed() -> void:
	$FileDialog.popup()

func _on_exit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://UI/Menu.tscn")
	get_tree().root.get_node("Game").queue_free()

func _on_flight_button_pressed() -> void:
	if world.player.flight:
		$Settings/Control3/FlightButton.text = "Flight: Off"
		world.player.flight = false
	else:
		$Settings/Control3/FlightButton.text = "Flight: On"
		world.player.flight = true

func _on_file_dialog_file_selected(path: String) -> void:
	ResourceSaver.save(world.world, path)
