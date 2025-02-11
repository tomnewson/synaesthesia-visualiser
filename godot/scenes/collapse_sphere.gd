@tool
extends MeshInstance3D

func _ready():
	# Configure the sphere mesh with desired subdivisions
	var sphere = SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 64  # Higher for smoother cube
	sphere.rings = 64

	# Retrieve mesh data
	var arr = sphere.get_mesh_arrays()
	var vertices = arr[ArrayMesh.ARRAY_VERTEX].duplicate()
	var normals = []
	normals.resize(vertices.size())

	# Process each vertex to project onto cube
	for i in vertices.size():
		var v = vertices[i]
		var dir = v.normalized()
		var max_comp = max(abs(dir.x), abs(dir.y), abs(dir.z))
		var cube_v = dir / max_comp
		vertices[i] = cube_v

		# Determine face normal based on dominant axis
		var abs_x = abs(cube_v.x)
		var abs_y = abs(cube_v.y)
		var abs_z = abs(cube_v.z)
		var max_abs = max(abs_x, abs_y, abs_z)
		var normal: Vector3
		if max_abs == abs_x:
			normal = Vector3(sign(cube_v.x), 0, 0)
		elif max_abs == abs_y:
			normal = Vector3(0, sign(cube_v.y), 0)
		else:
			normal = Vector3(0, 0, sign(cube_v.z))
		normals[i] = normal

	# Update mesh arrays
	arr[ArrayMesh.ARRAY_VERTEX] = vertices
	arr[ArrayMesh.ARRAY_NORMAL] = normals

	# Create and assign the new mesh
	var arr_mesh = ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	self.mesh = arr_mesh
	
