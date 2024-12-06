# for breaking and placing blocks, keep every rendered chunks blocks, and if you change something in it, make it override that chunks blocks, and keep that chunks blocks, so instead of regenerating it, just apply changes. discard other chunks blocks 
extends Node3D
var chunk_size : int = 4
var render_distance : int = 2
var render_distance_far : int = 8
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
				var updated_pos = ((pos+Vector3(x,y,z)-Vector3(render_distance_far,render_distance_far,render_distance_far)/2))
				var distance = vector_dist(Vector3(x,y,z))
				if distance > render_distance:
					if not rendered_chunks.has(updated_pos):
						create_chunk(updated_pos, false)
					outer.append(updated_pos)
				else:
					if not rendered_chunks.has(updated_pos):
						create_chunk(updated_pos, true)
					inner.append(updated_pos)
	for child in chunk_container.get_children():
		if not outer.has(child.chunk_pos) and not child.inner:
			rendered_chunks.erase(child.chunk_pos)
			child.queue_free()
		elif not inner.has(child.chunk_pos) and child.inner:
			rendered_chunks.erase(child.chunk_pos)
			child.queue_free()

func create_chunk(pos : Vector3, inner):
	var instance = chunk.instantiate()
	instance.inner = inner
	if inner:
		instance.block_subdivisions = 1
	else:
		instance.block_subdivisions = 2
	instance.position = pos*chunk_size
	chunk_container.add_child(instance)
	instance.chunk_pos = pos
	instance.generate()
	rendered_chunks.append(pos)

func vector_dist(vec : Vector3):
	var dist = vec.x
	if vec.y > dist:
		dist = vec.y
	if vec.z > dist:
		dist = vec.z
	return abs(dist)
