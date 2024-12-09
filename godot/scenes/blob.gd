extends Node3D

var notes = [] # active notes using the following enum
enum { KEY, POSITION, HUE, BRIGHTNESS, OPACITY, ROUGHNESS, SPHERE }

@export var sphere_radius = 0.2

var material = StandardMaterial3D.new()

@onready var path = $Path3D
@onready var path_polygon = $Path3D/CSGPolygon3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	path.curve = Curve3D.new()
	path_polygon.material = material
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
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
	
func _render_sphere(pos):
	var sphere = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	
	# render sphere per note
	sphere_mesh.material = material
	sphere_mesh.radius = sphere_radius
	sphere_mesh.height = sphere_radius * 2
	sphere.mesh = sphere_mesh
	sphere.translate(pos)
	
	return sphere
	
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
			self.add_child(notes[0][SPHERE])
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
			self._render_sphere(pos),
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
