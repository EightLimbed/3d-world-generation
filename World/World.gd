extends Node3D

var world = preload("res://World/Resources/Eden.tres")

#size of each chunk, in blocks (x,y,z)
@export var chunk_size : int = 24
#always make this odd
@export var render_distance : int = 7
@export var target_fps : float = 60
@onready var center = chunk_size*Vector3(render_distance,render_distance,render_distance)/2
@onready var reference_offset = Vector3(chunk_size,chunk_size,chunk_size)/2

#chunk coroutines handling 
var chunk = preload("res://World/Chunk.tscn")
var rendered_chunks : Dictionary
var generated : bool = true
var tagged_chunks : Array = []
@onready var chunks_per_frame : int = 0
var chunks_this_frame : int = 0
signal new_frame

@onready var noise = FastNoiseLite.new()
@onready var random = RandomNumberGenerator.new()
@onready var player = get_parent().get_child(1)
@onready var chunk_container = $ChunkContainer
@onready var label = $CanvasLayer/Label

func _ready() -> void:
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.005
	noise.seed = world.seeded
	player.set_block.connect(_set_block)
	for child in $ChunkContainer.get_children():
		child.queue_free()
	rendered_chunks.clear()

func _set_block(global_pos : Vector3, block):
	#gets chunk position and position of block within the chunk
	var chunk_pos = pos_to_chunk(global_pos)-reference_offset
	var updated_pos = global_pos-chunk_pos
	#sets block in memory to the new block
	world.chunks[chunk_pos][updated_pos.x][updated_pos.y][updated_pos.z] = block
	#finds chunks with chunk position and tags it for regeneration based on memory
	tagged_chunks.append(chunk_pos)
	#if chunk borders another chunk, tag that one regeneration that one too
	if updated_pos.x > 23:
		tagged_chunks.append(chunk_pos+Vector3(chunk_size,0,0))
	if updated_pos.x < 1:
		tagged_chunks.append(chunk_pos+Vector3(-chunk_size,0,0))
	if updated_pos.y > 23:
		tagged_chunks.append(chunk_pos+Vector3(0,chunk_size,0))
	if updated_pos.y < 1:
		tagged_chunks.append(chunk_pos+Vector3(0,-chunk_size,0))
	if updated_pos.z > 23:
		tagged_chunks.append(chunk_pos+Vector3(0,0,chunk_size))
	if updated_pos.z < 1:
		tagged_chunks.append(chunk_pos+Vector3(0,0,-chunk_size))

func get_block_noise(pos: Vector3) -> int:
	var hills = noise.get_noise_2dv(Vector2(pos.x, pos.z)) * 20
	hills *= abs(hills)
	hills += abs(hills) / 1.5
	var caves_top = noise.get_noise_2dv(Vector2(pos.x, pos.z) * 4) * 30
	var caves = noise.get_noise_3dv(pos * 5) * 10
	if not (caves > 3.5 - min(abs(pos.y / 25), 3) and pos.y < hills + caves_top - 6):
		# stone
		if hills >= pos.y:
			return 2
		# grass
		elif hills >= pos.y - 1:
			return 1
	return 0

#noise parameters
func get_block(local_pos: Vector3, chunk_pos : Vector3) -> int:
	# handle neighboring chunks
	if local_pos.x < 0 or local_pos.x >= chunk_size or local_pos.y < 0 or local_pos.y >= chunk_size or local_pos.z < 0 or local_pos.z >= chunk_size:
		#wtf was i doing here
		if local_pos.x < 0:
			chunk_pos.x -= chunk_size
			local_pos.x += chunk_size
		elif local_pos.x >= chunk_size:
			chunk_pos.x += chunk_size
			local_pos.x -= chunk_size
		if local_pos.y < 0:
			chunk_pos.y -= chunk_size
			local_pos.y += chunk_size
		elif local_pos.y >= chunk_size:
			chunk_pos.y += chunk_size
			local_pos.y -= chunk_size
		if local_pos.z < 0:
			chunk_pos.z -= chunk_size
			local_pos.z += chunk_size
		elif local_pos.z >= chunk_size:
			chunk_pos.z += chunk_size
			local_pos.z -= chunk_size
	#gets block if it can
	if world.chunks.has(chunk_pos):
		return world.chunks[chunk_pos][int(local_pos.x)][int(local_pos.y)][int(local_pos.z)]
	#gets procedural generation if nothing can be referenced
	return get_block_noise(local_pos+chunk_pos)

func _process(delta: float) -> void:
	if not tagged_chunks.is_empty():
		print(tagged_chunks)
		for child in chunk_container.get_children():
			if tagged_chunks.has(child.position):
				child.regenerate()
		tagged_chunks.clear()
	#if new chunks have been generated, remove unneeded ones
	if chunks_this_frame > 0:
		#lowers chunks per frame whenever fps drops below target
		if delta > 1/target_fps and chunks_per_frame > 0:
			chunks_per_frame -= 1
		elif delta < 1/target_fps and chunks_per_frame < render_distance**3:
			chunks_per_frame += 1
		remove_chunks(player.position)
	#reset allowed chunks
	chunks_this_frame = 0
	#lets chunk generation know it can continue
	new_frame.emit()
	#if old operation is done, starts new one
	if generated:
		create_chunks(player.position)
	#display useful information
	label.text = "total chunks: " + str(chunk_container.get_child_count()) + "\nfps: " + str(Engine.get_frames_per_second())+ "\ncoordinates: " + str(round(player.position))+ "\nchunk: " + str(pos_to_chunk(player.position)-reference_offset)+ "\nchunks per frame: " + str(chunks_per_frame+1)

func pos_to_chunk(pos) -> Vector3:
	return round(pos/chunk_size)*chunk_size

func remove_chunks(pos : Vector3):
	var updated_pos = pos_to_chunk(pos)
	#clears chunks
	for child in chunk_container.get_children():
		if longest_distance(pos_to_chunk(child.position)-updated_pos)/chunk_size > render_distance-1:
			rendered_chunks.erase(child.position)
			child.call_deferred("queue_free")

func create_chunks(pos : Vector3):
	#fills render distance with chunks
	generated = false
	for x in range(render_distance):
		for y in range(render_distance):
			for z in range(render_distance):
				#centers position around targeted area
				var updated_pos = Vector3(x,y,z)*chunk_size-center+pos_to_chunk(pos)
				#creates chunk at position if chunk not already rendered
				if updated_pos not in rendered_chunks:
					chunks_this_frame += 1
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
	instance.generate()

func longest_distance(vec3 : Vector3):
	var longest = abs(vec3.x)
	if abs(vec3.y) > longest:
		longest = abs(vec3.y)
	if abs(vec3.z) > longest:
		longest = abs(vec3.z)
	return longest

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		print("Saved")
		ResourceSaver.save(world, "res://World/Resources/Eden.tres")
