@tool
extends CSGPolygon3D

@onready var radius = self.get_parent().get_parent().sphere_radius

var angles = [
	0,
	PI / 4,
	PI / 2,
	(3 * PI) / 4,
	PI,
	(5 * PI) / 4,
	(3 * PI) / 2,
	(7 * PI) / 4
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# generate circle
	# x = r * cos (theta)
	# y = r * sin (theta)
	var poly = PackedVector2Array()
	for angle in angles:
		poly.append(Vector2(radius * sin(angle), radius * cos(angle)))
	self.polygon = poly
