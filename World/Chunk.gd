extends MeshInstance3D

var parent : Node

var a_mesh = ArrayMesh.new()
var vertices = PackedVector3Array()
var indices = PackedInt32Array()
var uvs = PackedVector2Array()
var face_count : int = 0
#groups texture atlas is split into
var tex_div = Vector2(1.0/7.0,1.0/6.0)
#list of transparent blocks, index is block id, boolean is whether or not it is transparent (air is always at the end)
const transparent : Array = [true, false, false, false, false, false, true, true]

var blocks = []

func generate():
	generate_chunk()
	create_mesh()

func regenerate():
	blocks = parent.world.chunks[position]
	create_mesh()

func generate_chunk():
	if not check_generated():
		parent.generate_structures(position)
		blocks = []
		blocks.resize(parent.chunk_size)
		for x in range(parent.chunk_size):
			blocks[x] = []
			for y in range(parent.chunk_size):
				blocks[x].append([])
				for z in range(parent.chunk_size):
					blocks[x][y].append(parent.get_block_noise(Vector3(x,y,z)+position))
		#add structures, like trees
		parent.world.chunks[position] = blocks

func check_generated():
	if parent.world.chunks.has(position):
		blocks = parent.world.chunks[position]
		return true
	return false

func create_mesh():
	mesh = ArrayMesh.new()
	a_mesh = ArrayMesh.new()
	vertices.clear()
	indices.clear()
	uvs.clear()
	face_count = 0
	#generates blocks and faces
	for x in range(parent.chunk_size):
		for y in range(parent.chunk_size):
			for z in range(parent.chunk_size):
				var block = blocks[x][y][z]
				if block != 0:
					create_block(Vector3(x, y, z), 1, block)
	#uses blocks to create mesh
	if face_count > 0:
		var array = []
		array.resize(Mesh.ARRAY_MAX)
		array[Mesh.ARRAY_VERTEX] = vertices
		array[Mesh.ARRAY_INDEX] = indices
		array[Mesh.ARRAY_TEX_UV] = uvs
		a_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,array)
		mesh = a_mesh
		var trimesh_collisions = a_mesh.create_trimesh_shape()
		$StaticBody3D/CollisionShape3D.shape = trimesh_collisions

func create_block(pos : Vector3, size : float, type : int):
	#top
	if not_transparent(pos + Vector3(0, size, 0), type):
		vertices.append(pos + Vector3(-0.5, -0.5+size, -0.5))
		vertices.append(pos + Vector3(-0.5+size, -0.5+size, -0.5))
		vertices.append(pos + Vector3(-0.5+size, -0.5+size,  -0.5+size))
		vertices.append(pos + Vector3(-0.5, -0.5+size, -0.5+size))
		update_indices()
		add_uv(type-1,0)

	#bottom
	if not_transparent(pos + Vector3(0, -size, 0), type):
		vertices.append(pos + Vector3(-0.5, -0.5, -0.5+size))
		vertices.append(pos + Vector3(-0.5+size, -0.5, -0.5+size))
		vertices.append(pos + Vector3(-0.5+size, -0.5, -0.5))
		vertices.append(pos + Vector3(-0.5, -0.5, -0.5))
		update_indices()
		add_uv(type-1,1)

	#left
	if not_transparent(pos + Vector3(size, 0, 0), type):
		vertices.append(pos + Vector3(-0.5+size, -0.5+size, -0.5+size))
		vertices.append(pos + Vector3(-0.5+size, -0.5+size, -0.5))
		vertices.append(pos + Vector3(-0.5+size, -0.5,-0.5))
		vertices.append(pos + Vector3(-0.5+size, -0.5, -0.5+size))
		update_indices()
		add_uv(type-1,2)

	#right
	if not_transparent(pos + Vector3(-size, 0, 0), type):
		vertices.append(pos + Vector3(-0.5, -0.5+size, -0.5))
		vertices.append(pos + Vector3(-0.5, -0.5+size, -0.5+size))
		vertices.append(pos + Vector3(-0.5, -0.5, -0.5+size))
		vertices.append(pos + Vector3(-0.5, -0.5, -0.5))
		update_indices()
		add_uv(type-1,3)

	#front
	if not_transparent(pos + Vector3(0, 0, size), type):
		vertices.append(pos + Vector3(-0.5, -0.5+size, -0.5+size))
		vertices.append(pos + Vector3(-0.5+size, -0.5+size, -0.5+size))
		vertices.append(pos + Vector3(-0.5+size, -0.5, -0.5+size))
		vertices.append(pos + Vector3(-0.5, -0.5, -0.5+size))
		update_indices()
		add_uv(type-1,4)

	#back
	if not_transparent(pos + Vector3(0, 0, -size), type):
		vertices.append(pos + Vector3(-0.5+size, -0.5+size, -0.5))
		vertices.append(pos + Vector3(-0.5, -0.5+size, -0.5))
		vertices.append(pos + Vector3(-0.5, -0.5, -0.5))
		vertices.append(pos + Vector3(-0.5+size, -0.5, -0.5))
		update_indices()
		add_uv(type-1,5)

func add_uv(x, y):
	uvs.append(Vector2(tex_div.x * x, tex_div.y * y))
	uvs.append(Vector2(tex_div.x * x + tex_div.x, tex_div.y * y))
	uvs.append(Vector2(tex_div.x * x + tex_div.x, tex_div.y * y + tex_div.y))
	uvs.append(Vector2(tex_div.x * x, tex_div.y * y + tex_div.y))

func update_indices():
	indices.append(face_count * 4 + 0)
	indices.append(face_count * 4 + 1)
	indices.append(face_count * 4 + 2)
	indices.append(face_count * 4 + 0)
	indices.append(face_count * 4 + 2)
	indices.append(face_count * 4 + 3)
	face_count += 1

func not_transparent(pos, type):
	var block = 0
	if pos.x < 0 or pos.y < 0 or pos.z < 0 or pos.x >= parent.chunk_size or pos.y >= parent.chunk_size or pos.z >= parent.chunk_size:
		block = parent.get_block(pos,position)
	else:
		block = blocks[pos.x][pos.y][pos.z]
	if type == block:
		return false
	elif transparent[block]:
		return true
	else:
		return false
