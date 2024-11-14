# for breaking and placing blocks, keep every rendered chunks blocks, and if you change something in it, make it override that chunks blocks, and keep that chunks blocks, so instead of regenerating it, just apply changes. discard other chunks blocks 
extends Node3D
var chunk_size : int = 16
var render_distance : int = 2
var chunk = preload("res://World/Chunk.tscn")
var rendered_chunks : Array[Vector3]

@onready var noise = FastNoiseLite.new()
@onready var random = RandomNumberGenerator.new()
@onready var player = get_parent().get_child(1)
@onready var chunk_container = $ChunkContainer
@onready var label = $CanvasLayer/Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
		noise.noise_type = FastNoiseLite.TYPE_PERLIN
		noise.frequency = 0.01
		noise.seed = random.randi()
		for child in $ChunkContainer.get_children():
			child.queue_free()
		generate_world(pos_to_chunk(player.global_position))

func _process(_delta: float) -> void:
	label.text = "total chunks:" + str(chunk_container.get_child_count())
	generate_world(pos_to_chunk(player.global_position))

func pos_to_chunk(pos):
	return round(pos/chunk_size)

func generate_world(pos : Vector3):
	var keep = []
	for x in range(render_distance):
		for y in range(render_distance):
			for z in range(render_distance):
				var updated_pos = ((pos+Vector3(x,y,z)-Vector3(render_distance,render_distance,render_distance)/2)*chunk_size)
				if not rendered_chunks.has(updated_pos):
					create_chunk(updated_pos)
				keep.append(updated_pos)
	for child in chunk_container.get_children():
		if not keep.has(child.chunk_pos):
			rendered_chunks.erase(child.chunk_pos)
			child.queue_free()

func create_chunk(pos : Vector3):
	var instance = chunk.instantiate()
	instance.position = pos
	chunk_container.add_child(instance)
	instance.chunk_pos = pos
	instance.generate()
	rendered_chunks.append(pos)
