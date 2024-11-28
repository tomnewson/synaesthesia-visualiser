extends Node3D

var notes = []

enum { KEY, POSITION, SPHERE }

@onready var path = $Path3D
@onready var curve = Curve3D.new()
@onready var material = StandardMaterial3D.new()
@onready var polygon = $Path3D/CSGPolygon3D
@export var sphere_radius = 0.2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	path.curve = curve
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	polygon.material = material
	
func insert_into_sorted_list(sorted_list, arr):
	# binary search insert
	var value = arr[POSITION].y
	var left = 0
	var right = sorted_list.size() - 1

	while left <= right:
		var mid = (left + right) / 2
		if sorted_list[mid][POSITION].y == value:
			# Insert the value next to duplicates to maintain order
			left = mid + 1
			break
		elif sorted_list[mid][POSITION].y < value:
			left = mid + 1
		else:
			right = mid - 1

	sorted_list.insert(left, arr)

func add_note(key: String, pos: Vector3):
	
	var sphere = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	var sphere_material = StandardMaterial3D.new()
	
	sphere_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sphere_material.albedo_color = Color(pos.x, pos.y, pos.z, 0.7)
	sphere_mesh.material = sphere_material
	sphere_mesh.radius = sphere_radius
	sphere_mesh.height = sphere_radius * 2
	sphere.mesh = sphere_mesh
	sphere.translate(pos)
	
	add_child(sphere)
	
	insert_into_sorted_list(notes, [key, pos, sphere])
	print(notes)
	curve.clear_points()
	for point in notes:
		curve.add_point(point[POSITION])
	
	update_colour()
	
func remove_note(key: String):
	for i in notes.size():
		if notes[i][KEY] == key:
			remove_child(notes[i][SPHERE])
			notes.remove_at(i)
			curve.remove_point(i)
			break
	update_colour()

func update_colour():
	var sum: Vector3
	for note in notes:
		sum += note[POSITION]
	var mean_positions = sum / notes.size()
		
	material.albedo_color = Color(mean_positions.x, mean_positions.y, mean_positions.z, 0.7)
