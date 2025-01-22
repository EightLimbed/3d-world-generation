extends CharacterBody3D

const SPEED = 10.0
const JUMP_VELOCITY = 4.5

var gravity: int = 9
@onready var neck := $Neck
@onready var camera := $Neck/Camera
@onready var collision = $CollisionShape3D
@onready var raycast = $Neck/Camera/RayCast3D
@onready var block_outline = $BlockOutline
signal set_block(hit_chunk : Node, global_pos : Vector3, block)

func _unhandled_input(event: InputEvent) -> void:
	#camera and mouse mode
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			neck.rotate_y(-event.relative.x * 0.01)
			camera.rotate_x(-event.relative.y * 0.01)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _physics_process(delta: float) -> void:
	#raycast for block editing
	if raycast.is_colliding():
		var norm = raycast.get_collision_normal()
		var pos = raycast.get_collision_point() - norm*0.5
		var bx = floor(pos.x+0.5)
		var by = floor(pos.y+0.5)
		var bz = floor(pos.z+0.5)
		var bpos = Vector3(bx, by, bz) - self.position
		block_outline.position = bpos
		block_outline.visible = true
		if Input.is_action_just_pressed("Break"):
			set_block.emit(pos+Vector3(0.5,0.5,0.5), 0)
		if Input.is_action_just_pressed("Use"):
			set_block.emit(pos+norm+Vector3(0.5,0.5,0.5), 4)
	else:
		block_outline.visible = false
	#movement
	if not is_on_floor():
		velocity.y -= gravity * delta
	if Input.is_action_just_pressed("ui_accept"):
		velocity.y = JUMP_VELOCITY
	var input_dir := Input.get_vector("Left", "Right", "Forward", "Back")
	var direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	move_and_slide()
