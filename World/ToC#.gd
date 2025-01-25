extends Node

#wether or not each block is transparent
@export var transparency : Array = [true, false, false, false, false, false, true, true]
#groups texture atlas is split into
@export var tex_div : Vector2 = Vector2(1.0/7.0,1.0/6.0)

var vertices = PackedVector3Array()
var indices = PackedInt32Array()
var uvs = PackedVector2Array()
var face_count : int = 0
var chunk_size : int
var blocks : Array = []

func create_mesh(block_list, size):
	#resets old variables
	vertices.clear()
	indices.clear()
	uvs.clear()
	face_count = 0
	#passes variables to larger scope
	blocks = block_list
	chunk_size = size
	#generates blocks with faces culled
	for x in range(chunk_size):
		for y in range(chunk_size):
			for z in range(chunk_size):
				var block = blocks[x][y][z]
				if block != 0:
					create_block(Vector3(x, y, z), block)
	#uses blocks to create mesh
	if face_count > 0:
		return [vertices, indices, uvs]
	else:
		return []

#TO C#
func create_block(pos : Vector3, type : int):
	#top
	if not_transparent(pos + Vector3(0, 1, 0), type):
		vertices.append(pos + Vector3(-0.5, 0.5, -0.5))
		vertices.append(pos + Vector3(0.5, 0.5, -0.5))
		vertices.append(pos + Vector3(0.5, 0.5,  0.5))
		vertices.append(pos + Vector3(-0.5, 0.5, 0.5))
		update_indices()
		add_uv(type-1,0)

	#bottom
	if not_transparent(pos + Vector3(0, -1, 0), type):
		vertices.append(pos + Vector3(-0.5, -0.5, 0.5))
		vertices.append(pos + Vector3(0.5, -0.5, 0.5))
		vertices.append(pos + Vector3(0.5, -0.5, -0.5))
		vertices.append(pos + Vector3(-0.5, -0.5, -0.5))
		update_indices()
		add_uv(type-1,1)

	#left
	if not_transparent(pos + Vector3(1, 0, 0), type):
		vertices.append(pos + Vector3(0.5, 0.5, 0.5))
		vertices.append(pos + Vector3(0.5, 0.5, -0.5))
		vertices.append(pos + Vector3(0.5, -0.5,-0.5))
		vertices.append(pos + Vector3(0.5, -0.5, 0.5))
		update_indices()
		add_uv(type-1,2)

	#right
	if not_transparent(pos + Vector3(-1, 0, 0), type):
		vertices.append(pos + Vector3(-0.5, 0.5, -0.5))
		vertices.append(pos + Vector3(-0.5, 0.5, 0.5))
		vertices.append(pos + Vector3(-0.5, -0.5, 0.5))
		vertices.append(pos + Vector3(-0.5, -0.5, -0.5))
		update_indices()
		add_uv(type-1,3)

	#front
	if not_transparent(pos + Vector3(0, 0, 1), type):
		vertices.append(pos + Vector3(-0.5, 0.5, 0.5))
		vertices.append(pos + Vector3(0.5, 0.5, 0.5))
		vertices.append(pos + Vector3(0.5, -0.5, 0.5))
		vertices.append(pos + Vector3(-0.5, -0.5, 0.5))
		update_indices()
		add_uv(type-1,4)

	#back
	if not_transparent(pos + Vector3(0, 0, -1), type):
		vertices.append(pos + Vector3(0.5, 0.5, -0.5))
		vertices.append(pos + Vector3(-0.5, 0.5, -0.5))
		vertices.append(pos + Vector3(-0.5, -0.5, -0.5))
		vertices.append(pos + Vector3(0.5, -0.5, -0.5))
		update_indices()
		add_uv(type-1,5)

#TO C#
func add_uv(x, y):
	uvs.append(Vector2(tex_div.x * x, tex_div.y * y))
	uvs.append(Vector2(tex_div.x * x + tex_div.x, tex_div.y * y))
	uvs.append(Vector2(tex_div.x * x + tex_div.x, tex_div.y * y + tex_div.y))
	uvs.append(Vector2(tex_div.x * x, tex_div.y * y + tex_div.y))

#TO C#
func update_indices():
	indices.append(face_count * 4 + 0)
	indices.append(face_count * 4 + 1)
	indices.append(face_count * 4 + 2)
	indices.append(face_count * 4 + 0)
	indices.append(face_count * 4 + 2)
	indices.append(face_count * 4 + 3)
	face_count += 1

#needs to be fixed
func not_transparent(pos, type):
	var block = 0
	if pos.x < 0 or pos.y < 0 or pos.z < 0 or pos.x >= chunk_size or pos.y >= chunk_size or pos.z >= chunk_size:
		block = get_parent().parent.get_block(pos,get_parent().position)
		#block = 0
	else:
		block = blocks[pos.x][pos.y][pos.z]
	if type == block:
		return false
	elif transparency[block]:
		return true
	else:
		return false
