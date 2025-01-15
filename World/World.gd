extends Node3D

var world = preload("res://World/Resources/Eden.tres")

#size of each chunk, in blocks (x,y,z)
@export var chunk_size : int = 24
#each concentric border will go through index of this by 1, each time increasing the size of each block, to render less
#size of what is in view, in chunks (x,y,z), needs to be odd to avoid artifacts
@export var render_distance : int = 8
var chunk = preload("res://World/Chunk.tscn")
var rendered_chunks : Array
var rendered_chunk_positions : Array[Vector3]
var chunks_thread : Thread
@onready var random = RandomNumberGenerator.new()
@onready var player = get_parent().get_child(1)

func _ready() -> void:
		chunks_thread = Thread.new()
		chunks_thread.start(generate_world.bind(player.position))

func _process(_delta: float) -> void:
	#label.text = "total chunks: " + str(chunk_container.get_child_count()) + "\nfps: " + str(Engine.get_frames_per_second())+ "\ncoordinates: " + str(round(player.position))+ "\nchunk: " + str(pos_to_chunk(player.position))
	pass

func pos_to_chunk(pos):
	return round(pos/chunk_size)

func generate_world(pos : Vector3):
	while true:
		#fills render distance with chunks
		for x in range(render_distance):
			for y in range(render_distance):
				for z in range(render_distance):
					#centers position around targeted area
					var updated_pos = (pos_to_chunk(pos)+Vector3(x,y,z)-Vector3(render_distance,render_distance,render_distance)/2)*chunk_size
					#creates chunk at position
					if not rendered_chunk_positions.has(updated_pos):
						create_chunk(updated_pos)
		#clears chunks
		#for child in rendered_chunks:
			#if longest_distance(pos_to_chunk(child.position-pos)) > render_distance:
				#child.call_deferred("queue_free")
				#rendered_chunks.erase(child)
				#rendered_chunk_positions.erase(child.position)

func create_chunk(pos : Vector3):
	var instance = chunk.instantiate()
	instance.position = pos
	instance.parent = self
	call_deferred("add_child",instance)
	instance.generate()
	rendered_chunks.append(instance)
	rendered_chunk_positions.append(pos)

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
