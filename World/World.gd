@tool
extends Node3D
@export var update_mesh : bool
@export var chunk_size : int = 16
@export var world_size : int = 4
var chunk = preload("res://World/Chunk.tscn")
var stored_chunks

var noise
var random

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _process(_delta: float) -> void:
	if update_mesh:
		noise = FastNoiseLite.new()
		noise.noise_type = FastNoiseLite.TYPE_PERLIN
		noise.frequency = 0.01
		random = RandomNumberGenerator.new()
		noise.seed = random.randi()
		for child in get_children():
			child.queue_free()
		generate_world()
		update_mesh = false

func generate_world():
	for x in range(world_size):
		for y in range(world_size):
			for z in range(world_size):
				create_chunk(x*chunk_size,y*chunk_size,z*chunk_size)

func create_chunk(x,y,z):
	var instance = chunk.instantiate()
	instance.position = Vector3(x,y,z)
	add_child(instance)
	instance.generate()
