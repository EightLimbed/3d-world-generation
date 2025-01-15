extends Node3D

var world = preload("res://World/Resources/Eden.tres")

#size of each chunk, in blocks (x,y,z)
@export var chunk_size : int = 24
#each concentric border will go through index of this by 1, each time increasing the size of each block, to render less
@export var lod_steps : Array[float] = []
#size of what is in view, in chunks (x,y,z), needs to be odd to avoid artifacts
@export var render_distance : int = 8
var chunk = preload("res://World/Chunk.tscn")
var rendered_chunks : Array[Vector3]

@onready var noise = FastNoiseLite.new()
@onready var random = RandomNumberGenerator.new()
@onready var player = get_parent().get_child(1)
@onready var chunk_container = $ChunkContainer
@onready var label = $CanvasLayer/Label

func _ready() -> void:
		noise.noise_type = FastNoiseLite.TYPE_PERLIN
		noise.frequency = 0.005
		noise.seed = world.seeded
		for child in $ChunkContainer.get_children():
			child.queue_free() 

func get_block1(pos : Vector3):
	var block = 6
	if pos.y <= 0:
		block = 0
	return block

#noise parameters
func get_block(pos : Vector3):
	var hills = noise.get_noise_2dv(Vector2(pos.x,pos.z))*20
	hills*=abs(hills)
	hills+=abs(hills)/1.5
	var caves_top = noise.get_noise_2dv(Vector2(pos.x,pos.z)*Vector2(4,4))*30
	var caves = noise.get_noise_3dv(pos*Vector3(4,4,4))*10
	var block : int = 6
	#stone
	if hills >= pos.y:
		block = 1
	#grass
	elif hills >= pos.y-1:
		block = 0
	#caves
	if caves > 4-min(abs(pos.y/15), 3) and pos.y < hills+caves_top-6:
		block = 6
	return block

func _process(_delta: float) -> void:
	label.text = "total chunks: " + str(chunk_container.get_child_count()) + "\nfps: " + str(Engine.get_frames_per_second())+ "\ncoordinates: " + str(round(player.position))+ "\nchunk: " + str(pos_to_chunk(player.position))
	generate_world(player.position)

func pos_to_chunk(pos):
	return round(pos/chunk_size)

func generate_world(pos : Vector3):
	#constructs each concentric layer in render distance
	var lod_layers = []
	for i in range(round(render_distance/2.0)):
		lod_layers.append([])
	#fills render distance with chunks
	for x in range(render_distance):
		for y in range(render_distance):
			for z in range(render_distance):
				#centers position around targeted area
				var center = Vector3(render_distance,render_distance,render_distance)/2
				var centered_pos = Vector3(x,y,z)-center
				var updated_pos = (pos_to_chunk(pos)+centered_pos)*chunk_size
				#finds distance of chunk from center, which is also its layer
				var center_distance = round(longest_distance(centered_pos+Vector3(0.5,0.5,0.5)))
				#creates chunk at position, and uses its layer as the index in the LOD chart
				if not rendered_chunks.has(updated_pos):
					create_chunk(updated_pos, center_distance)
				#adds chunk position to layer
				lod_layers[center_distance-2].append(updated_pos)
	#clears chunks
	for child in chunk_container.get_children():
		#checks each child to see if its layer has its position. if it doesnt, the child is deleted
		if not lod_layers[child.layer-2].has(child.position):
			rendered_chunks.erase(child.position)
			child.queue_free()

func create_chunk(pos : Vector3, layer : int):
	var instance = chunk.instantiate()
	instance.layer = layer
	instance.position = pos
	chunk_container.add_child(instance)
	instance.generate()
	rendered_chunks.append(pos)

func longest_distance(vec3 : Vector3):
	var longest = abs(vec3.x)
	if abs(vec3.y) > longest:
		longest = abs(vec3.y)
	if abs(vec3.z) > longest:
		longest = abs(vec3.z)
	return longest

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		print("saved")
		#ResourceSaver.save(world, "res://World/Resources/Eden.tres")
