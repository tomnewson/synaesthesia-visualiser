@tool
extends MeshInstance3D

@onready var texture = preload("res://icon.svg")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var mesh_data = []
	# probably inoptimal but allows us to not care about resizing depending on number of vertices
	mesh_data.resize(ArrayMesh.ARRAY_MAX)
	# the base of a mesh array, says where vertices are
	mesh_data[ArrayMesh.ARRAY_VERTEX] = PackedVector3Array([
		Vector3(0,0,0), # bottom right corner
		Vector3(1,0,0), # bottom left corner
		Vector3(1,1,0), # top left corner
		Vector3(0,1,0), # top right corner
	])
	# by default the mesh array (with primitive triangles) will take triplet of vector3s as an individual trangle
	# we can use an array index to share indices between triangles
	# this will also mean share UVs and normals between faces
	mesh_data[ArrayMesh.ARRAY_INDEX] = PackedInt32Array([
		0,1,2, # triangle 1
		0,2,3, # triangle 2
	])
	# normals can be added for each vertices telling light how to interact
	# normals point in direction the face is facing
	# if a vertex is part of multiple faces (thanks to array indices), its normal is the average of the face directions
	mesh_data[ArrayMesh.ARRAY_NORMAL] = PackedVector3Array([
		Vector3(0,0,-1), # the face is pointing in the negative z direction
		Vector3(0,0,-1),
		Vector3(0,0,-1),
		Vector3(0,0,-1),
	])
	# UVs point to vectors on a texture, (0,0) top left (1,1) bottom right
	mesh_data[ArrayMesh.ARRAY_TEX_UV] = PackedVector2Array([
		Vector2(1,1), # the first vertex in our array is in the bottom right
		Vector2(0,1),
		Vector2(0,0),
		Vector2(1,0), # the last is in the top right
	])
	mesh = ArrayMesh.new()
	# generate mesh out of triangles
	mesh.add_surface_from_arrays(
		Mesh.PRIMITIVE_TRIANGLES, 
		mesh_data,
	)
	#mesh.surface_find_by_name("Surface 0").material = texture
