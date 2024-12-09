extends Node3D

var notes = [] # active notes using the following enum
enum { KEY, POSITION, HUE, BRIGHTNESS, OPACITY, ROUGHNESS, SPHERE }

@export var sphere_radius = 0.2

@onready var material = StandardMaterial3D.new()
@onready var mesh_instance = MeshInstance3D.new()

@onready var path = $Path3D
@onready var path_polygon = $Path3D/CSGPolygon3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	path.curve = Curve3D.new()
	path_polygon.material = material
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material
	
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
			#for n in notes:
				#path.curve.add_point(n[POSITION])
			self.render_snake()
			
var vertex_count: int = 0
var radius: float = 0.5
var radial_segments: int = 12     # Number of vertices around the circumference
var dome_segments: int = 6        # Vertical subdivisions for the dome
var cylinder_segments: int = 8    # Segments along each straight section of the tube
func render_snake():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	vertex_count = 0
	self.add_dome(st, notes[0][POSITION], get_direction(notes[0][POSITION], notes[1][POSITION]), radius, dome_segments, false)
	
	for i in range(notes.size() - 1):
		var start = notes[i][POSITION]
		var end = notes[i+1][POSITION]
		self.add_cylinder_segment(st, start, end, radius, radial_segments, cylinder_segments)
	
	var last = notes.size() - 1
	self.add_dome(st, notes[last][POSITION], self.get_direction(notes[last-1][POSITION], notes[last][POSITION]), radius, dome_segments, true)
	
	var mesh = st.commit()
	mesh_instance.mesh = mesh
	add_child(mesh_instance)
	

func add_dome(st: SurfaceTool, center: Vector3, direction: Vector3, r: float, segments_v: int, facing_forward: bool):
	var base_index = vertex_count
	var up = direction if facing_forward else -direction
	var o_basis = self.get_orientation_basis(up)
	
	for i in range(segments_v+1):
		var phi = (PI/2.0) * float(i)/float(segments_v)
		for j in range(radial_segments+1):
			var theta = 2.0 * PI * float(j)/float(radial_segments)
			var x = r * sin(phi)*cos(theta)
			var y = r * cos(phi)
			var z = r * sin(phi)*sin(theta)
			var local_pos = Vector3(x, y, z)
			var world_pos = center + o_basis * local_pos
			st.add_vertex(world_pos)
			vertex_count += 1
			
	var stride = radial_segments + 1
	for i in range(segments_v):
		for j in range(radial_segments):
			var i1 = base_index + i * stride + j
			var i2 = i1 + stride
			st.add_index(i1)
			st.add_index(i2)
			st.add_index(i1+1)
			st.add_index(i1+1)
			st.add_index(i2)
			st.add_index(i2+1)

func get_direction(from: Vector3, to: Vector3) -> Vector3:
	return (to - from).normalized()

func add_cylinder_segment(st: SurfaceTool, start: Vector3, end: Vector3, r: float, radial_segs: int, height_segs: int):
	var base_index = vertex_count
	var dir = (end - start).normalized()
	var o_basis = get_orientation_basis(dir)

	# Add vertices
	for i in range(height_segs+1):
		var t = float(i)/float(height_segs)
		var pos_along = start.lerp(end, t)
		for j in range(radial_segs+1):
			var angle = 2.0 * PI * float(j)/float(radial_segs)
			var x = r * cos(angle)
			var y = 0.0
			var z = r * sin(angle)
			var local_pos = Vector3(x, y, z)
			var world_pos = pos_along + o_basis * local_pos
			st.add_vertex(world_pos)
			vertex_count += 1

	# Add indices
	var stride = radial_segs + 1
	for i in range(height_segs):
		for j in range(radial_segs):
			var i1 = base_index + i * stride + j
			var i2 = i1 + stride
			st.add_index(i1)
			st.add_index(i2)
			st.add_index(i1+1)
			st.add_index(i1+1)
			st.add_index(i2)
			st.add_index(i2+1)

func get_orientation_basis(dir: Vector3) -> Basis:
	# Construct a coordinate system with 'dir' as Y-axis
	var up = Vector3(0,1,0)
	if abs(dir.dot(up)) > 0.9:
		up = Vector3(1,0,0)
	var x = up.cross(dir).normalized()
	var y = dir
	var z = x.cross(y).normalized()
	return Basis(x, y, z)		

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
