extends Node3D

var world = preload("res://World/Resources/Eden.tres")

#size of each chunk, in blocks (x,y,z)
@export var chunk_size : int = 24
@export var render_distance : int = 7
@export var target_fps : float = 60
@onready var center = chunk_size*Vector3(render_distance,render_distance,render_distance)/2

#chunk coroutines handling 
var chunk = preload("res://World/Chunk.tscn")
var rendered_chunks : Array[Vector3]
var generated : bool = true
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
	var chunk_pos = pos_to_chunk(global_pos)
	var updated_pos = global_pos-chunk_pos
	print(updated_pos)
	world.chunks[chunk_pos][updated_pos.x][updated_pos.y][updated_pos.z] = block
	for child in chunk_container.get_children():
		if child.position == chunk_pos:
			child.regenerate()

#noise parameters
func get_block(pos : Vector3):
	var block : int = 0
	var chunk_pos = pos_to_chunk(pos)
	#checks if chunk being referenced is already loaded, and if it has checks for that block
	if world.chunks.has(chunk_pos):
		var updated_pos = pos-chunk_pos
		block = world.chunks[chunk_pos][updated_pos.x][updated_pos.y][updated_pos.z]
		return block
	#gets block based on noise values
	var hills = noise.get_noise_2dv(Vector2(pos.x,pos.z))*20
	hills*=abs(hills)
	hills+=abs(hills)/1.5
	var caves_top = noise.get_noise_2dv(Vector2(pos.x,pos.z)*4)*30
	var caves = noise.get_noise_3dv(pos*5)*10
	if not (caves > 3.5-min(abs(pos.y/25), 3) and pos.y < hills+caves_top-6):
		#stone
		if hills >= pos.y:
			block = 2
		#grass
		elif hills >= pos.y-1:
			block = 1
	return block

func _process(delta: float) -> void:
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
	label.text = "total chunks: " + str(chunk_container.get_child_count()) + "\nfps: " + str(Engine.get_frames_per_second())+ "\ncoordinates: " + str(round(player.position))+ "\nchunk: " + str(pos_to_chunk(player.position))+ "\nchunks per frame: " + str(chunks_per_frame+1)

func pos_to_chunk(pos):
	return round(pos/chunk_size)*chunk_size

func remove_chunks(pos : Vector3):
	#clears chunks
	for child in chunk_container.get_children():
		if longest_distance(pos_to_chunk(child.position)-pos_to_chunk(pos))/chunk_size > render_distance-1:
			rendered_chunks.erase(child.position)
			child.queue_free()

func create_chunks(pos : Vector3):
	#fills render distance with chunks
	generated = false
	for x in range(render_distance):
		for y in range(render_distance):
			for z in range(render_distance):
				#centers position around targeted area
				var updated_pos = Vector3(x,y,z)*chunk_size-center+pos_to_chunk(pos)
				#creates chunk at position if chunk not already rendered
				if not rendered_chunks.has(updated_pos):
					chunks_this_frame += 1
					create_chunk(updated_pos)
				if chunks_this_frame >= chunks_per_frame:
					await new_frame
	generated = true

func create_chunk(pos : Vector3):
	var instance = chunk.instantiate()
	instance.position = pos
	rendered_chunks.append(instance.position)
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
