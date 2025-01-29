@tool
extends RigidBody3D

@export var line_radius = 0.5
@export var point_radius = 0.1
@export var speed: float = 2.0
@export var color: Color = Color.WHITE:
	set(value):
		color = value
		update_colors()  # Update colors when property changes

var vertices: Array[Vector4]
var points: Array[MeshInstance3D]
var lines: Array[MeshInstance3D]
var pointShapes: Array[CollisionShape3D]
var lineShapes: Array[CollisionShape3D]
var time = 0

func _ready():
	var phys: PhysicsMaterial = PhysicsMaterial.new()
	phys.friction = 0
	phys.bounce = 3
	physics_material_override = phys

	var sphere: SphereMesh = SphereMesh.new()
	var point_mat: StandardMaterial3D = StandardMaterial3D.new()
	point_mat.albedo_color = color
	point_mat.roughness = 0.1 
	point_mat.metallic = 0.9 
	point_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	sphere.material = point_mat
	var line_mat: StandardMaterial3D = StandardMaterial3D.new()
	line_mat.albedo_color = color
	line_mat.roughness = 0.1
	line_mat.metallic = 0.9
	line_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	for i in range(16): 
		var v1 = Vector4(2*(i/8)-1, 2*(i/4%2)-1, 2*(i/2%2)-1, 2*(i%2)-1)
		vertices.append(v1)
		var point: MeshInstance3D = MeshInstance3D.new()
		point.mesh = sphere
		add_child(point)
		points.append(point)

		var collider: CollisionShape3D = CollisionShape3D.new()
		collider.shape = SphereShape3D.new()
		add_child(collider)
		pointShapes.append(collider)
		
	create_materials()
	update_colors()

	for i in range(16):
		var v1 = vertices[i]
		for j in range(i+1, 16):
			if v1.distance_to(vertices[j]) > 2: continue
			var cylinder: CylinderMesh = CylinderMesh.new()
			cylinder.material = line_mat
			cylinder.height = 1.0
			var line: MeshInstance3D = MeshInstance3D.new()
			line.mesh = cylinder
			add_child(line)
			lines.append(line)

			var collider: CollisionShape3D = CollisionShape3D.new()
			collider.shape = CylinderShape3D.new()
			collider.shape.radius = line_radius*0.5
			add_child(collider)
			lineShapes.append(collider)

func _process(_delta):
	time += speed*_delta
	var li = 0
	var radii = []
	# Point update: Compute XW rotation and do perspective projection to make 3D.
	for i in range(16):
		var base: Vector4 = vertices[i]
		var sub: Vector2 = Vector2(base.x, base.w).rotated(time)
		base.x = sub.x
		base.w = sub.y
		var point: MeshInstance3D = points[i]
		var scaling = 3.0 / (3-base.w)
		point.position = scaling * Vector3(base.x, base.y, base.z)
		radii.append(scaling*scaling*point_radius) 

	# Edge update: Set position, size and rotation of the points and cylinders.
	for i in range(16):
		var p1: MeshInstance3D = points[i]
		p1.scale = Vector3.ONE*radii[i]*2
		pointShapes[i].shape.radius = radii[i]
		pointShapes[i].position = p1.position

		for j in range(i+1, 16):
			if vertices[i].distance_to(vertices[j]) > 2: continue
			var p2: MeshInstance3D = points[j]
			var line: MeshInstance3D = lines[li]
			var collider: CollisionShape3D = lineShapes[li]

			line.position = (p2.position+p1.position)/2.0
			line.basis = Basis(Quaternion(Vector3.UP, (p2.position-p1.position).normalized()))
			collider.transform = line.transform
			line.scale.y = p1.position.distance_to(p2.position)
			collider.shape.height = line.scale.y

			var mesh: CylinderMesh = line.mesh
			mesh.bottom_radius = radii[i] * line_radius
			mesh.top_radius = radii[j] * line_radius
			li += 1
			
func create_materials():
	# Create shared materials
	var point_mat = StandardMaterial3D.new()
	point_mat.roughness = 0.1 
	point_mat.metallic = 0.9 
	point_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var line_mat = StandardMaterial3D.new()
	line_mat.roughness = 0.1
	line_mat.metallic = 0.9
	line_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	# Assign materials to meshes
	for point in points:
		if point.mesh is SphereMesh:
			point.mesh.material = point_mat.duplicate()

	for line in lines:
		if line.mesh is CylinderMesh:
			line.mesh.material = line_mat.duplicate()

func update_colors():
	# Update all point materials
	for point in points:
		if point.mesh is SphereMesh && point.mesh.material is StandardMaterial3D:
			point.mesh.material.albedo_color = color

	# Update all line materials
	for line in lines:
		if line.mesh is CylinderMesh && line.mesh.material is StandardMaterial3D:
			line.mesh.material.albedo_color = color
