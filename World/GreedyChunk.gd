#testing with performance things, seems to run slower

extends MeshInstance3D

enum BlockTypes { Air, Dirt }

var layer: int
@onready var parent = get_parent().get_parent()

var a_mesh = ArrayMesh.new()
var vertices = PackedVector3Array()
var indices = PackedInt32Array()
var uvs = PackedVector2Array()

var tex_div = 0.5  # Texture atlas subdivision factor
var blocks = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func generate():
	generate_chunk()
	create_mesh()

# Noise-based block generation
func get_block(pos: Vector3) -> int:
	var cn = (parent.noise.get_noise_3dv(pos + position)) * 10
	return BlockTypes.Air if cn > 0 else BlockTypes.Dirt

# Generate the chunk voxel data
func generate_chunk():
	if not chunk_generated():
		blocks = []
		blocks.resize(parent.chunk_size)
		for x in range(parent.chunk_size):
			blocks[x] = []
			for y in range(parent.chunk_size):
				blocks[x].append([])
				for z in range(parent.chunk_size):
					blocks[x][y].append(get_block(Vector3(x, y, z)))
		parent.world.chunk_positions.append(position)
		parent.world.chunks.append(blocks)

# Check if the chunk is already generated
func chunk_generated() -> bool:
	for i in range(parent.world.chunk_positions.size()):
		if parent.world.chunk_positions[i] == position:
			blocks = parent.world.chunks[i]
			return true
	return false

# Create the mesh with greedy meshing
func create_mesh():
	a_mesh = ArrayMesh.new()
	vertices = PackedVector3Array()
	indices = PackedInt32Array()
	uvs = PackedVector2Array()

	generate_greedy_mesh()

	if vertices.size() > 0:
		var array = []
		array.resize(Mesh.ARRAY_MAX)
		array[Mesh.ARRAY_VERTEX] = vertices
		array[Mesh.ARRAY_INDEX] = indices
		array[Mesh.ARRAY_TEX_UV] = uvs
		a_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, array)

	mesh = a_mesh

	if layer == 1:
		var trimesh_collisions = a_mesh.create_trimesh_shape()
		var collisions: CollisionShape3D = $StaticBody3D/CollisionShape3D
		collisions.shape = trimesh_collisions

# Generate the mesh using greedy meshing
func generate_greedy_mesh():
	for axis in range(3):  # Iterate over X, Y, Z axes
		var u = (axis + 1) % 3
		var v = (axis + 2) % 3

		var mask = []

		# Iterate over slices along the axis
		for d in range(parent.chunk_size + 1):
			mask.resize(parent.chunk_size * parent.chunk_size)

			# Build the mask for this slice
			for x in range(parent.chunk_size):
				for y in range(parent.chunk_size):
					var a = Vector3()
					var b = Vector3()

					a[axis] = d
					b[axis] = d - 1
					a[u] = x
					b[u] = x
					a[v] = y
					b[v] = y

					var voxel_a = get_voxel(a)
					var voxel_b = get_voxel(b)

					# Determine if this face is visible
					if voxel_a != voxel_b and (voxel_a != BlockTypes.Air or voxel_b != BlockTypes.Air):
						mask[x + y * parent.chunk_size] = voxel_a if voxel_a != BlockTypes.Air else voxel_b
					else:
						mask[x + y * parent.chunk_size] = 0

			# Perform greedy meshing on the mask
			for y in range(parent.chunk_size):
				for x in range(parent.chunk_size):
					var index = x + y * parent.chunk_size
					if mask[index] != 0:
						var x_start = x
						var y_start = y
						var width = 1
						var height = 1

						# Expand the quad along X
						while x + width < parent.chunk_size and mask[index + width] == mask[index]:
							width += 1

						# Expand the quad along Y
						var valid_quad = true
						while y + height < parent.chunk_size:
							for x_check in range(width):
								if mask[index + x_check + height * parent.chunk_size] != mask[index]:
									valid_quad = false
									break
							if not valid_quad:
								break
							height += 1

						# Generate the quad
						var pos = Vector3()
						pos[axis] = d
						pos[u] = x_start
						pos[v] = y_start

						var size = Vector3()
						size[axis] = 1
						size[u] = width
						size[v] = height

						append_quad(pos, size, axis)

						# Clear the mask for the generated quad
						for y_clear in range(height):
							for x_clear in range(width):
								mask[index + x_clear + y_clear * parent.chunk_size] = 0

#append a quad to the mesh
func append_quad(pos: Vector3, size: Vector3, normal_axis: int):
	var offset = vertices.size()

	# Determine quad vertices based on the axis
	if normal_axis == 0:  # X-axis
		vertices.append(pos)
		vertices.append(pos + Vector3(0, size.y, 0))
		vertices.append(pos + Vector3(0, size.y, size.z))
		vertices.append(pos + Vector3(0, 0, size.z))
	elif normal_axis == 1:  # Y-axis
		vertices.append(pos)
		vertices.append(pos + Vector3(size.x, 0, 0))
		vertices.append(pos + Vector3(size.x, 0, size.z))
		vertices.append(pos + Vector3(0, 0, size.z))
	elif normal_axis == 2:  # Z-axis
		vertices.append(pos)
		vertices.append(pos + Vector3(size.x, 0, 0))
		vertices.append(pos + Vector3(size.x, size.y, 0))
		vertices.append(pos + Vector3(0, size.y, 0))

	# Define quad indices
	indices.append(offset + 0)
	indices.append(offset + 1)
	indices.append(offset + 2)
	indices.append(offset + 0)
	indices.append(offset + 2)
	indices.append(offset + 3)

	# Define quad UVs
	add_uv(0, 0)

# Add UV mapping for a quad
func add_uv(x: int, y: int):
	uvs.append(Vector2(tex_div * x, tex_div * y))
	uvs.append(Vector2(tex_div * x + tex_div, tex_div * y))
	uvs.append(Vector2(tex_div * x + tex_div, tex_div * y + tex_div))
	uvs.append(Vector2(tex_div * x, tex_div * y + tex_div))

# Retrieve a voxel at a given position
func get_voxel(pos: Vector3) -> int:
	if pos.x < 0 or pos.y < 0 or pos.z < 0 or pos.x >= parent.chunk_size or pos.y >= parent.chunk_size or pos.z >= parent.chunk_size:
		return BlockTypes.Air
	return blocks[int(pos.x)][int(pos.y)][int(pos.z)]
