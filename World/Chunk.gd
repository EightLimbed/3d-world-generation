extends MeshInstance3D

var parent : Node3D

var a_mesh = ArrayMesh.new()
var vertices = PackedVector3Array()
var indices = PackedInt32Array()
var uvs = PackedVector2Array()

var block_subdivisions : int = 1
var face_count : int = 0
#groups texture atlas is split into
var tex_div = Vector2(0.16666,0.16666)
#list of transparent blocks, index is block id, boolean is whether or not it is transparent (air is always at the end)
const transparent : Array = [false, false, false, true, false, true, true]
var noise : FastNoiseLite

var blocks = []

func get_block(pos : Vector3):
	var block = 6
	if pos.y <= 0:
		block = 0
	return block

#noise parameters
func get_block1(pos : Vector3):
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
	if caves > 3.2-min(abs(pos.y/16), 3) and pos.y < hills+caves_top-6:
		block = 6
	return block

func generate():
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.005
	noise.seed = parent.world.seeded
	generate_chunk()
	create_mesh()

func generate_chunk():
	if not chunk_generated():
		blocks = []
		blocks.resize(parent.chunk_size+2)
		for x in range(parent.chunk_size+2):
			blocks[x] = []
			for y in range(parent.chunk_size+2):
				blocks[x].append([])
				for z in range(parent.chunk_size+2):
					blocks[x][y].append(get_block(Vector3(x,y,z)+position))
		#add structures, like trees
		parent.world.chunk_positions.append(position)
		parent.world.chunks.append(blocks)

func chunk_generated():
	for i in parent.world.chunk_positions.size()-1:
		if parent.world.chunk_positions[i] == position:
			blocks = parent.world.chunks[i]
			return true
	return false

func create_mesh():
	mesh = ArrayMesh.new()
	a_mesh = ArrayMesh.new()
	vertices = PackedVector3Array()
	indices = PackedInt32Array()
	uvs = PackedVector2Array()
	face_count = 0
	generate_mesh_singular()
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
	for x in range(parent.chunk_size/block_subdivisions):
		for y in range(parent.chunk_size/block_subdivisions):
			for z in range(parent.chunk_size/block_subdivisions):
				var block = blocks[block_subdivisions*x+1][block_subdivisions*y+1][block_subdivisions*z+1]
				if block != 6:
					create_block(block_subdivisions*Vector3(x, y, z)+Vector3(1,1,1), block_subdivisions, block)

func create_block(pos : Vector3, size : float, type : int):
	#top
	if not_transparent(pos + Vector3(0, size, 0), type):
		vertices.append(pos + Vector3(-0.5, -0.5+size, -0.5))
		vertices.append(pos + Vector3(-0.5+size, -0.5+size, -0.5))
		vertices.append(pos + Vector3(-0.5+size, -0.5+size,  -0.5+size))
		vertices.append(pos + Vector3(-0.5, -0.5+size, -0.5+size))
		update_indices()
		add_uv(type,0)

	#bottom
	if not_transparent(pos + Vector3(0, -size, 0), type):
		vertices.append(pos + Vector3(-0.5, -0.5, -0.5+size))
		vertices.append(pos + Vector3(-0.5+size, -0.5, -0.5+size))
		vertices.append(pos + Vector3(-0.5+size, -0.5, -0.5))
		vertices.append(pos + Vector3(-0.5, -0.5, -0.5))
		update_indices()
		add_uv(type,1)

	#left
	if not_transparent(pos + Vector3(size, 0, 0), type):
		vertices.append(pos + Vector3(-0.5+size, -0.5+size, -0.5+size))
		vertices.append(pos + Vector3(-0.5+size, -0.5+size, -0.5))
		vertices.append(pos + Vector3(-0.5+size, -0.5,-0.5))
		vertices.append(pos + Vector3(-0.5+size, -0.5, -0.5+size))
		update_indices()
		add_uv(type,2)

	#right
	if not_transparent(pos + Vector3(-size, 0, 0), type):
		vertices.append(pos + Vector3(-0.5, -0.5+size, -0.5))
		vertices.append(pos + Vector3(-0.5, -0.5+size, -0.5+size))
		vertices.append(pos + Vector3(-0.5, -0.5, -0.5+size))
		vertices.append(pos + Vector3(-0.5, -0.5, -0.5))
		update_indices()
		add_uv(type,3)

	#front
	if not_transparent(pos + Vector3(0, 0, size), type):
		vertices.append(pos + Vector3(-0.5, -0.5+size, -0.5+size))
		vertices.append(pos + Vector3(-0.5+size, -0.5+size, -0.5+size))
		vertices.append(pos + Vector3(-0.5+size, -0.5, -0.5+size))
		vertices.append(pos + Vector3(-0.5, -0.5, -0.5+size))
		update_indices()
		add_uv(type,4)

	#back
	if not_transparent(pos + Vector3(0, 0, -size), type):
		vertices.append(pos + Vector3(-0.5+size, -0.5+size, -0.5))
		vertices.append(pos + Vector3(-0.5, -0.5+size, -0.5))
		vertices.append(pos + Vector3(-0.5, -0.5, -0.5))
		vertices.append(pos + Vector3(-0.5+size, -0.5, -0.5))
		update_indices()
		add_uv(type,5)

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

func not_transparent(new_pos, type):
	var new_value = blocks[new_pos.x][new_pos.y][new_pos.z]
	if type == new_value:
		return false
	elif transparent[new_value]:
		return true
	else:
		return false
