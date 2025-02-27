extends MeshInstance3D

var parent : Node

var a_mesh = ArrayMesh.new()

var blocks : PackedInt32Array = []

func generate():
	$Area3D/CollisionShape3D.shape.size = Vector3(parent.chunk_size, parent.chunk_size, parent.chunk_size)*2
	$Area3D/CollisionShape3D.position = Vector3(parent.chunk_size, parent.chunk_size, parent.chunk_size)/2
	generate_chunk()
	create_mesh()

func regenerate():
	blocks = parent.world.chunks[position]
	create_mesh()
	var trimesh_collisions = a_mesh.create_trimesh_shape()
	$StaticBody3D/CollisionShape3D.shape = trimesh_collisions

func create_mesh():
	#creates_variable
	mesh = ArrayMesh.new()
	a_mesh = ArrayMesh.new()
	#gets values from C# script
	var packed_mesh = get_node("/root/MeshGenerator").CreateMesh(blocks, parent.chunk_size)
	if not packed_mesh.is_empty():
		#applies to mesh
		var array = []
		array.resize(Mesh.ARRAY_MAX)
		array[Mesh.ARRAY_VERTEX] = packed_mesh[0]#PackedVector3Array(packed_mesh[0])
		array[Mesh.ARRAY_INDEX] = packed_mesh[1]#PackedInt32Array(packed_mesh[1])
		array[Mesh.ARRAY_TEX_UV] = packed_mesh[2] #PackedVector2Array(packed_mesh[2])
		a_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,array)
		mesh = a_mesh

func _on_area_3d_body_entered(_body: Node3D) -> void:
	var trimesh_collisions = a_mesh.create_trimesh_shape()
	$StaticBody3D/CollisionShape3D.shape = trimesh_collisions
	$Area3D.set_deferred("monitoring", false)

func generate_chunk():
	if not check_generated():
		for x in range(parent.chunk_size):
			for y in range(parent.chunk_size):
				for z in range(parent.chunk_size):
					blocks.append(parent.get_block_noise(Vector3(x,y,z)+position))
		parent.world.chunks[position] = blocks

func check_generated():
	if parent.world.chunks.has(position):
		blocks = parent.world.chunks[position]
		return true
	return false