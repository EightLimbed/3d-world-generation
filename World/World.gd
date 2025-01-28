extends Node3D

var world : World

#size of each chunk, in blocks (x,y,z)
const chunk_size : int = 24
#always make this odd
@export var render_distance : Vector3 = Vector3i(5,3,5)
@export var target_fps : float = 60
@onready var center = chunk_size*render_distance/2
@onready var reference_offset = Vector3(chunk_size,chunk_size,chunk_size)/2

#chunk coroutines handling 
var chunk = preload("res://World/Chunk.tscn")
var rendered_chunks : Dictionary
var generated : bool = true
var tagged_chunks : Dictionary
@onready var chunks_per_frame : int = round(render_distance.x*render_distance.y)
var chunks_this_frame : int = 0
signal new_frame
var structures : Dictionary
var tree : Dictionary = {Vector3(0, 0, 0): 5, Vector3(0, 1, 0): 5, Vector3(0, 2, 0): 5, Vector3(0, 3, 0): 5, Vector3(1, 3, 0): 6, Vector3(0, 3, -1): 6, Vector3(1, 3, -1): 6, Vector3(-1, 3, -1): 6, Vector3(-1, 3, 0): 6, Vector3(-1, 3, 1): 6, Vector3(0, 3, 1): 6, Vector3(1, 3, 1): 6, Vector3(-1, 4, 0): 6, Vector3(0, 4, 0): 6, Vector3(1, 4, 0): 6, Vector3(0, 4, 1): 6, Vector3(0, 4, -1): 6 }

@onready var noise = FastNoiseLite.new()
@onready var random = RandomNumberGenerator.new()
@onready var player = get_parent().get_child(1)
@onready var chunk_container = $ChunkContainer

func _ready() -> void:
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.005
	noise.seed = world.seeded
	player.set_block.connect(set_block)
	for child in $ChunkContainer.get_children():
		child.queue_free()
	rendered_chunks.clear()
	structures.clear()

func get_block_noise(pos: Vector3) -> int:
	#gets noise
	if structures.has(pos):
		var block = structures[pos]
		structures.erase(pos)
		return block
	var hills = noise.get_noise_2d(pos.x, pos.z) * 20
	hills *= abs(hills)
	hills += abs(hills) / 1.5
	var caves_top = noise.get_noise_2d(pos.x * 4, pos.z * 4) * 30
	var caves = noise.get_noise_3dv(pos * 5) * 10
	if not (caves > 3.5 - min(abs(pos.y / 25), 3) and pos.y < hills + caves_top - 6):
		# stone
		if hills >= pos.y:
			return 2
		# grass
		elif hills >= pos.y - 1:
			return 1
	return 0

func generate_structures(chunk_pos):
	random.seed = hash(chunk_pos)
	#trees
	for i in random.randi_range(0,10):
		var tree_pos = Vector2(random.randi_range(1,chunk_size-2),random.randi_range(1,chunk_size-2))+Vector2(chunk_pos.x,chunk_pos.z)
		var hills = noise.get_noise_2dv(tree_pos) * 20
		hills *= abs(hills)
		hills += abs(hills) / 1.5
		if round(hills+0.5)+5-chunk_size < chunk_pos.y and round(hills+0.5) > chunk_pos.y:
			apply_structure(tree, Vector3(tree_pos.x, round(hills+0.5), tree_pos.y))

func apply_structure(structure : Dictionary, pos):
	for key in structure.keys():
		structures[key+pos] = structure[key]

func set_block(global_pos : Vector3, block):
	#gets chunk position and position of block within the chunk
	var chunk_pos = pos_to_chunk(global_pos)-reference_offset
	var updated_pos = global_pos-chunk_pos
	#sets block in memory to the new block, or adds it to structure queue
	if chunk_pos in world.chunks and (round(player.position) != floor(global_pos) and round(player.position+Vector3(0,1,0)) != floor(global_pos)):
		world.chunks[chunk_pos][get_flat_index(floor(updated_pos))] = block
		#finds chunks with chunk position and tags it for regeneration based on memory
		tagged_chunks[chunk_pos] = true
	else:
		structures[global_pos] = block

func regenerate_chunks():
	if not tagged_chunks.is_empty():
		for child in chunk_container.get_children():
			if child.position in tagged_chunks:
				child.regenerate()
		tagged_chunks.clear()

func _process(delta: float) -> void:
	#if new chunks have been generated, remove unneeded ones
	if chunks_this_frame > 0:
		#lowers chunks per frame whenever fps drops below target
		if delta > 1/target_fps and chunks_per_frame > 0:
			chunks_per_frame -= 1
		elif delta < 1/target_fps and chunks_per_frame < render_distance.x*render_distance.y*render_distance.z:
			chunks_per_frame += 1
		remove_chunks(player.position)
	#reset allowed chunks
	chunks_this_frame = 0
	regenerate_chunks()
	#lets chunk generation know it can continue
	new_frame.emit()
	#if old operation is done, starts new one
	if generated:
		create_chunks(player.position)

func pos_to_chunk(pos) -> Vector3:
	return round(pos/chunk_size)*chunk_size

func get_flat_index(pos: Vector3):
	return pos.z + chunk_size * (pos.y + chunk_size * pos.x);

func remove_chunks(pos: Vector3):
	var updated_pos = pos_to_chunk(pos)
	var to_remove = []
	for child in chunk_container.get_children():
		if longest_distance(pos_to_chunk(child.position)-updated_pos)/chunk_size > longest_distance(render_distance)-1:
			to_remove.append(child)
	for child in to_remove:
		rendered_chunks.erase(child.position)
		child.call_deferred("queue_free")

func create_chunks(pos : Vector3):
	#fills render distance with chunks
	generated = false
	for x in range(render_distance.x):
		for y in range(render_distance.y):
			for z in range(render_distance.z):
				#centers position around targeted area
				var updated_pos = Vector3(x,y,z)*chunk_size-center+pos_to_chunk(pos)
				#creates chunk at position if chunk not already rendered
				if updated_pos not in rendered_chunks:
					create_chunk(updated_pos)
				if chunks_this_frame >= chunks_per_frame:
					await new_frame
	generated = true

func create_chunk(pos : Vector3):
	var instance = chunk.instantiate()
	instance.position = pos
	instance.parent = self
	rendered_chunks[instance.position] = true
	chunk_container.add_child(instance)
	generate_structures(instance.position)
	instance.generate()
	if instance.blocks.size() > 10:
		chunks_this_frame += 1

func longest_distance(vec3 : Vector3):
	return max(abs(vec3.x), abs(vec3.y), abs(vec3.z))
