extends Node3D

var notes = [] # active notes using the following enum
enum { KEY, POSITION, HUE, BRIGHTNESS, OPACITY, ROUGHNESS }

@export var single_note_size = 0.2
@export var rotation_speed = 90.0

var material = StandardMaterial3D.new()
var sphere_mesh = SphereMesh.new()
var box_mesh = BoxMesh.new()

@onready var path = $Path3D
@onready var path_polygon = $Path3D/CSGPolygon3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	path.curve = Curve3D.new()
	path_polygon.material = material
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sphere_mesh.material = material
	sphere_mesh.radius = single_note_size
	sphere_mesh.height = single_note_size * 2
	box_mesh.material = material
	box_mesh.size = Vector3(single_note_size, single_note_size, single_note_size)
	
func _process(delta:float):
	for child in self.get_children():
		#if child is Path3D and child.curve.point_count > 0:
			#var center = calculate_center(child.curve)
			#var rotation_angle = deg_to_rad(rotation_speed * delta)
			##var rotation_transform = Transform3D(Basis(Vector3.UP, rotation_angle), Vector3.ZERO)
##
			### Apply rotation transformation relative to the center
			##child.global_transform.origin -= center
			##child.global_transform = rotation_transform * child.global_transform
			##child.global_transform.origin += center
			#child.rotate_object
			#child.rotate_object_local(Vector3.UP, rotation_angle)
		if child is MeshInstance3D:
			child.rotate_object_local(Vector3.UP, deg_to_rad(rotation_speed * delta))
		
	
func calculate_center(curve: Curve3D):
	var min = curve.get_point_position(0)
	var max = curve.get_point_position(0)

	# Iterate through all points to calculate bounds
	for i in range(1, curve.point_count):
		var point = curve.get_point_position(0)
		min = min.min(point)
		max = max.max(point)

	# Return the center point
	return min + (max - min) * 0.5
	
func _show_markers():
	var marker = MeshInstance3D.new()
	marker.mesh = sphere_mesh
	marker.translate(Vector3(0,0,-7))
	add_child(marker)
	
func update_material():
	# Adjust material properties
	if notes.is_empty(): return
	var l = notes.size()
	var hues = 0
	var brights = 0
	var opacs = 0
	var roughs = 0
	for n in notes:
		hues += n[HUE]
		brights += n[BRIGHTNESS]
		opacs += n[OPACITY]
		roughs += n[ROUGHNESS]
		
	material.albedo_color = Color.from_hsv(
		hues / l,
		1.0,
		brights / l,
		opacs / l
	)
	material.roughness = roughs / l
	
func _insert_into_sorted_list(sorted_list, arr):
	# binary search insert sorted by y axis
	var value = arr[POSITION].y
	var left = 0
	var right = sorted_list.size() - 1

	while left <= right:
		var mid = (left + right) / 2
		if sorted_list[mid][POSITION].y == value:
			left = mid + 1
			break
		elif sorted_list[mid][POSITION].y < value:
			left = mid + 1
		else:
			right = mid - 1

	sorted_list.insert(left, arr)
	
func _render_single_note(pos):
	var mesh_instance = MeshInstance3D.new()
	
	# render sphere per note
	mesh_instance.mesh = box_mesh
	mesh_instance.translate(pos)
	
	self.add_child(mesh_instance)
	
func _render_track():
	path.curve.clear_points()
	for child in self.get_children():
		if child is MeshInstance3D:
			self.remove_child(child)
			
	match notes.size():
		0:
			return
		1:
			self.update_material()
			self._render_single_note(notes[0][POSITION])
		_:
			self.update_material()
			for n in notes:
				path.curve.add_point(n[POSITION])


func add_note(key: String, pos: Vector3, hue: float, brightness: float, opacity: float, roughness: float):
	self._insert_into_sorted_list(
		notes,
		[
			key, 
			pos,
			hue,
			brightness,
			opacity,
			roughness,
		],
	)
	self._render_track()
	
func remove_note(key: String):
	for i in notes.size():
		if notes[i][KEY] == key:
			notes.remove_at(i)
			_render_track()
			return
	return -1
