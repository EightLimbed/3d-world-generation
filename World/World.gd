extends Node3D

var world = preload("res://World/Resources/Eden.tres")

@export var chunk_size : int = 16
@export var render_distance : int = 3
@export var render_distance_far : int = 9
var chunk = preload("res://World/Chunk.tscn")
var rendered_chunks : Array[Vector3]

@onready var noise = FastNoiseLite.new()
@onready var random = RandomNumberGenerator.new()
@onready var player = get_parent().get_child(1)
@onready var chunk_container = $ChunkContainer
@onready var label = $CanvasLayer/Label

func _ready() -> void:
		noise.noise_type = FastNoiseLite.TYPE_PERLIN
		noise.frequency = 0.01
		noise.seed = world.seeded
		for child in $ChunkContainer.get_children():
			child.queue_free() 

func _process(_delta: float) -> void:
	label.text = "total chunks: " + str(chunk_container.get_child_count()) + "\nfps: " + str(Engine.get_frames_per_second())
	generate_world(pos_to_chunk(player.global_position))

func pos_to_chunk(pos):
	return round(pos/chunk_size)

func generate_world(pos : Vector3):
	var inner = []
	var outer = []
	for x in range(render_distance_far):
		for y in range(render_distance_far):
			for z in range(render_distance_far):
				#change center distance to work
				var center_distance = Vector3(render_distance_far,render_distance_far,render_distance_far)/2
				var updated_pos = (pos+Vector3(x,y,z)-center_distance)*chunk_size
				if not middle_of(Vector3(x,y,z), render_distance, render_distance_far):
					if not rendered_chunks.has(updated_pos):
						create_chunk(updated_pos, 2)
					outer.append(updated_pos)
				else:
					if not rendered_chunks.has(updated_pos):
						create_chunk(updated_pos, 1)
					inner.append(updated_pos)
	for child in chunk_container.get_children():
		if not outer.has(child.position) and child.layer == 2:
			rendered_chunks.erase(child.position)
			child.queue_free()
		elif not inner.has(child.position) and child.layer == 1:
			rendered_chunks.erase(child.position)
			child.queue_free()

func create_chunk(pos : Vector3, layer : int):
	var instance = chunk.instantiate()
	instance.layer = layer
	instance.position = pos
	chunk_container.add_child(instance)
	instance.generate()
	rendered_chunks.append(pos)

func middle_of(vec : Vector3, inner_size, outer_size):
	var distance1 = (outer_size-inner_size)/2
	var distance2 = outer_size-distance1
	if vec.x >= distance1 and vec.x < distance2 and vec.y >= distance1 and vec.y < distance2 and vec.z >= distance1 and vec.z < distance2:
		return true

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		print("saved")
		#ResourceSaver.save(world, "res://World/Resources/Eden.tres")
