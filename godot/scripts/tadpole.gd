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
# Current scale factor
var current_scale: float

var isDying: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_scale = initial_scale
	scale = Vector3(initial_scale, initial_scale, initial_scale)
	isDying = false
	position.y = y_offset

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Move the tadpole to the right
	position.x += speed * delta
	position.y = y_offset + sin(position.x * 2) * 0.1 * amplitude

	# rotate_x(speed * rotation_factor * delta)

	# Shrink the tadpole
	if isDying:
		current_scale -= shrink_rate * delta
		if current_scale <= 0:
			# Remove the tadpole when it's too small
			queue_free()
			return

	# Apply the new scale
	scale = Vector3(current_scale, current_scale, current_scale)

	# Check if tadpole is outside camera view
	var camera = get_viewport().get_camera_3d()
	if camera and is_outside_camera_view(camera):
		# Teleport back to left side
		# teleport_to_left_side(camera)
		queue_free()

func kill() -> void:
	isDying = true

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
