@tool
extends MeshInstance3D

@export var update_mesh : bool
@export var chunk_size : int = 16

var noise
var random

enum BlockTypes {Air, Dirt}

var a_mesh = ArrayMesh.new()
var vertices = PackedVector3Array()
var indices = PackedInt32Array()
var uvs = PackedVector2Array()

var face_count
#groups texture atlas is split into
var tex_div = 0.25

var blocks = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_mesh = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if update_mesh:
		noise = FastNoiseLite.new()
		random = RandomNumberGenerator.new()
		noise.noise_type = FastNoiseLite.TYPE_PERLIN
		noise.frequency = 0.01
		noise.seed = random.randi()
		generate_chunk()
		generate_mesh()
		update_mesh = false
	pass

#noise parameters
func get_block(pos : Vector3i):
	var n = (noise.get_noise_2d(pos.x, pos.z) + 1) * chunk_size*random.randi_range(1,2)
	var cn = (noise.get_noise_3dv(pos))*10
	if n > pos.y:
		if cn > 0:
			return BlockTypes.Air
		else:
			return BlockTypes.Dirt
	else:
		return BlockTypes.Air

func generate_chunk():
	blocks = []
	blocks.resize(chunk_size)
	for x in range(chunk_size):
		blocks[x] = []
		for y in range(chunk_size):
			blocks[x].append([])
			for z in range(chunk_size):
				blocks[x][y].append(get_block(Vector3(x,y,z)))

func generate_mesh():
	mesh = ArrayMesh.new()
	a_mesh = ArrayMesh.new()
	vertices = PackedVector3Array()
	indices = PackedInt32Array()
	uvs = PackedVector2Array()
	face_count = 0
	for x in range(chunk_size):
		for y in range(chunk_size):
			for z in range(chunk_size):
				if (blocks[x][y][z] == BlockTypes.Dirt):
					create_block(Vector3(x, y, z))
	#smooth_mesh()
	if face_count > 0:
		var array = []
		array.resize(Mesh.ARRAY_MAX)
		array[Mesh.ARRAY_VERTEX] = vertices
		array[Mesh.ARRAY_INDEX] = indices
		array[Mesh.ARRAY_TEX_UV] = uvs
		a_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,array)
	mesh = a_mesh

func create_block(pos):
	if is_air(pos + Vector3(0, 1, 0)):
		vertices.append(pos + Vector3(-0.5, 0.5, -0.5))
		vertices.append(pos + Vector3( 0.5, 0.5, -0.5))
		vertices.append(pos + Vector3( 0.5, 0.5,  0.5))
		vertices.append(pos + Vector3(-0.5, 0.5,  0.5))
		update_indices()
		add_uv(0,0)

	if is_air(pos + Vector3(1, 0, 0)):
		vertices.append(pos + Vector3( 0.5, 0.5, 0.5))
		vertices.append(pos + Vector3( 0.5, 0.5, -0.5))
		vertices.append(pos + Vector3( 0.5, -0.5,-0.5))
		vertices.append(pos + Vector3( 0.5, -0.5,  0.5))
		update_indices()
		add_uv(3,0)

	if is_air(pos + Vector3(0, 0, 1)):
		vertices.append(pos + Vector3(-0.5, 0.5, 0.5))
		vertices.append(pos + Vector3( 0.5, 0.5, 0.5))
		vertices.append(pos + Vector3( 0.5, -0.5,0.5))
		vertices.append(pos + Vector3(-0.5, -0.5, 0.5))
		update_indices()
		add_uv(0,1)

	if is_air(pos + Vector3(-1, 0, 0)):
		vertices.append(pos + Vector3(-0.5, 0.5, -0.5))
		vertices.append(pos + Vector3(-0.5, 0.5,  0.5))
		vertices.append(pos + Vector3(-0.5, -0.5, 0.5))
		vertices.append(pos + Vector3(-0.5, -0.5, -0.5))
		update_indices()
		add_uv(1,1)

	if is_air(pos + Vector3(0, 0, -1)):
		vertices.append(pos + Vector3( 0.5,  0.5, -0.5))
		vertices.append(pos + Vector3(-0.5,  0.5, -0.5))
		vertices.append(pos + Vector3(-0.5, -0.5, -0.5))
		vertices.append(pos + Vector3( 0.5, -0.5, -0.5))
		update_indices()
		add_uv(2,0)

	if is_air(pos + Vector3(0, -1, 0)):
		vertices.append(pos + Vector3(-0.5, -0.5, 0.5))
		vertices.append(pos + Vector3( 0.5, -0.5, 0.5))
		vertices.append(pos + Vector3( 0.5, -0.5, -0.5))
		vertices.append(pos + Vector3(-0.5, -0.5, -0.5))
		update_indices()
		add_uv(1,0)

func add_uv(x, y):
	uvs.append(Vector2(tex_div * x, tex_div * y))
	uvs.append(Vector2(tex_div * x + tex_div, tex_div * y))
	uvs.append(Vector2(tex_div * x + tex_div, tex_div * y + tex_div))
	uvs.append(Vector2(tex_div * x, tex_div * y + tex_div))

func update_indices():
	indices.append(face_count * 4 + 0)
	indices.append(face_count * 4 + 1)
	indices.append(face_count * 4 + 2)
	indices.append(face_count * 4 + 0)
	indices.append(face_count * 4 + 2)
	indices.append(face_count * 4 + 3)
	face_count += 1

func is_air(pos):
	if pos.x < 0 or pos.y < 0 or pos.z < 0:
		return true
	elif pos.x >= chunk_size or pos.y >= chunk_size or pos.z >= chunk_size:
		return true
	elif blocks[pos.x][pos.y][pos.z] == BlockTypes.Air:
		return true
	else:
		return false

func smooth_mesh():
	for i in vertices.size()-1:
		vertices[i] = ((vertices[i+1]+vertices[i-1])+8*vertices[i])/10
