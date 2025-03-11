extends MeshInstance3D

# Movement speed in units per second
@export var speed: float = 5.0
# How fast the tadpole shrinks (scale reduction per second)
@export var shrink_rate: float = 0.1
# Initial scale of the tadpole
@export var initial_scale: float = 1.0

@export var y_offset: float = 0.0
@export var amplitude: float = 1.0

@export var rotation_factor: float = 1.0
# Debug options
@export var show_direction_indicator: bool = true

# Current scale factor
var current_scale: float
var direction_indicator: MeshInstance3D
var isDying: bool
var dying_speed: float = 0.2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_scale = initial_scale
	scale = Vector3(initial_scale, initial_scale, initial_scale)
	isDying = false
	position.y = y_offset

	# Create direction indicator for debugging
	if show_direction_indicator:
		create_direction_indicator()

# Create a visual indicator showing movement direction
func create_direction_indicator() -> void:
	direction_indicator = MeshInstance3D.new()
	direction_indicator.name = "DirectionIndicator"

	direction_indicator.mesh = SphereMesh.new()
	direction_indicator.mesh.radius = 0.25
	direction_indicator.mesh.height = 0.5

	# Position it to point in direction of movement
	direction_indicator.transform.origin = Vector3(-2, 0, 0)

	# Make it red for visibility
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0, 0)
	direction_indicator.material_override = material

	add_child(direction_indicator)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Move the tadpole to the right
	position.x += speed * delta
	position.y = y_offset + sin(position.x * 2) * 0.1 * amplitude

	# Calculate movement direction
	var direction = Vector3(speed, 0.2 * amplitude * cos(position.x * 2), 0)
	direction = direction.normalized()

	# Calculate rotation angle to face movement direction
	var angle = atan2(direction.y, direction.x)

	# Apply rotation to face the direction of movement
	rotation.z = -angle

	# Shrink the tadpole
	if isDying:
		var current_transparency = self.mesh.material.get_shader_parameter("transparency")
		var new_transparency = current_transparency - dying_speed * delta
		if new_transparency < 0:
			# Remove the tadpole when it's too small
			queue_free()
			return
		self.mesh.material.set_shader_parameter("transparency", new_transparency)

	# Apply the new scale
	scale = Vector3(current_scale, current_scale, current_scale)

	# Check if tadpole is outside camera view
	if (self.position.x >= 3.0 and self.position.y > -1.5 or is_outside_camera_view(get_viewport().get_camera_3d())):
		kill(1.0)

func kill(kill_speed: float = dying_speed) -> void:
	isDying = true
	dying_speed = kill_speed

# Check if tadpole is outside the camera's view on the right
func is_outside_camera_view(camera: Camera3D) -> bool:
	var viewport_pos = camera.unproject_position(global_transform.origin)
	return viewport_pos.x > get_viewport().size.x

# Move tadpole back to the left side of the view
func teleport_to_left_side(camera: Camera3D) -> void:
	# Get current viewport position (to preserve y position)
	var viewport_pos = camera.unproject_position(global_transform.origin)

	# Create new position just off the left side of the screen
	var new_viewport_pos = Vector2(-50, viewport_pos.y)

	# Convert back to 3D world position
	var distance_to_camera = (global_transform.origin - camera.global_transform.origin).length()
	var new_position = camera.project_position(new_viewport_pos, distance_to_camera)

	# Update just the x coordinate
	global_transform.origin.x = new_position.x
