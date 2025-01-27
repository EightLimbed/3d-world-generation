extends CanvasLayer

@export var menu : PackedScene
@onready var world = get_tree().root.get_node("Game/World")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


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
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		$Settings.visible = true
	if event.is_action_pressed("Information"):
		if $Information.visible:
			$Information.visible = false
		else:
			$Information.visible = true

func save():
	world.save()

func _on_xz_slider_value_changed(value: float) -> void:
	world.render_distance.x = value+1
	world.render_distance.z = value+1
	world.center = world.chunk_size*world.render_distance/2
	$Settings/Subtitle.text = "Render Distance X,Z: "+str(value+1)

func _on_y_slider_value_changed(value: float) -> void:
	world.render_distance.y = value+1
	world.center = world.chunk_size*world.render_distance/2
	$Settings/Subtitle2.text = "Render Distance Y: "+str(value+1)

func _on_fps_slider_value_changed(value: float) -> void:
	world.target_fps = value
	$Settings/Subtitle3.text = "Target FPS: "+str(value)

func _on_save_button_pressed() -> void:
	save()

func _on_exit_button_pressed() -> void:
	save()
	get_tree().root.change_scene_to_file("res://Menu.tscn")
