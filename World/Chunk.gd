extends MeshInstance3D


enum BlockTypes {Air, Dirt}

var chunk_pos : Vector3
@onready var parent = get_parent().get_parent()

var a_mesh = ArrayMesh.new()
var vertices = PackedVector3Array()
var indices = PackedInt32Array()
var uvs = PackedVector2Array()

var face_count
#groups texture atlas is split into
var tex_div = 0.5

var blocks = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func generate():
	generate_chunk()
	create_mesh()

func delete():
	queue_free()

#noise parameters
func get_block(pos : Vector3):
	var cn = (parent.noise.get_noise_3dv(pos+position))*10
	if cn > 0:
		return BlockTypes.Air
	else:
		return BlockTypes.Dirt

func generate_chunk():
	blocks = []
	blocks.resize(parent.chunk_size)
	for x in range(parent.chunk_size):
		blocks[x] = []
		for y in range(parent.chunk_size):
			blocks[x].append([])
			for z in range(parent.chunk_size):
				blocks[x][y].append(get_block(Vector3(x,y,z)))

func create_mesh():
	mesh = ArrayMesh.new()
	a_mesh = ArrayMesh.new()
	vertices = PackedVector3Array()
	indices = PackedInt32Array()
	uvs = PackedVector2Array()
	face_count = 0
	generate_mesh_singular()
	#smooth_mesh()
	if face_count > 0:
		var array = []
		array.resize(Mesh.ARRAY_MAX)
		array[Mesh.ARRAY_VERTEX] = vertices
		array[Mesh.ARRAY_INDEX] = indices
		array[Mesh.ARRAY_TEX_UV] = uvs
		a_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,array)
	mesh = a_mesh
	var trimesh_collisions = a_mesh.create_trimesh_shape()
	var collisions : CollisionShape3D = $StaticBody3D/CollisionShape3D
	collisions.shape = trimesh_collisions

func generate_mesh_singular():
	for x in range(parent.chunk_size):
		for y in range(parent.chunk_size):
			for z in range(parent.chunk_size):
				if (blocks[x][y][z] == BlockTypes.Dirt):
					create_block(Vector3(x, y, z))

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
	elif pos.x >= parent.chunk_size or pos.y >= parent.chunk_size or pos.z >= parent.chunk_size:
		return true
	elif blocks[pos.x][pos.y][pos.z] == BlockTypes.Air:
		return true
	else:
		return false

func smooth_mesh():
	for i in vertices.size()-1:
		vertices[i] = ((vertices[i+1]+vertices[i-1])+8*vertices[i])/10
