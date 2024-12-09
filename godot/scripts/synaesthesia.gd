extends Node3D

var track_paths = [] # int to path scene
@onready var path_scene = preload("res://scenes/blob.tscn")
@export var num_tracks: int = 9

const MIN_NOTE = 21
const MAX_NOTE = 108
const MIN_VELOCITY = 0
const MAX_VELOCITY = 127

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range (num_tracks + 1):
		var track_instance = path_scene.instantiate()
		track_paths.append(track_instance)
		add_child(track_instance)

# Function to apply sigmoid remap with variable input and output ranges
func sigmoid_remap(value: float, 
	input_min: float, input_max: float, 
	output_min: float, output_max: float, 
	k: float = 2) -> float:
	# Normalize input to [0,1]
	var normalized_value = (value - input_min) / (input_max - input_min)

	# Center normalized_value around 0.5 so that:
	#   normalized_value = 0.5 --> sigmoid(0) = 0.5
	# This makes the midpoint of the input range map to the midpoint of the output range.
	var centered = normalized_value - 0.5

	# Apply the sigmoid function:
	# You can adjust the scale factor (like 10.0) if you want to "stretch" the middle region.
	# Removing the extra scale factor is also an option; then just use `exp(-k * centered)`.
	var sigmoid_value = 1.0 / (1.0 + exp(-k * centered * 10.0))

	# Map the sigmoid result to the output range
	return output_min + (sigmoid_value * (output_max - output_min))


func _on_midi_receiver_note_on(note_id, note, velocity, track) -> void:
	# high pitch - small, high up, stringy, opaque, bright, smooth
	# low pitch - big, low down, wide, transparent, dark, rough
	# loud - near
	# quiet - far
	var x = remap(track, 0, num_tracks, -10, 10) - 2
	var y = sigmoid_remap(note, MIN_NOTE, MAX_NOTE, -3, 5)
	var z = sigmoid_remap(velocity, MIN_VELOCITY, MAX_VELOCITY, -10, -7)
	var hue = sigmoid_remap(note, MIN_NOTE, MAX_NOTE, 0, 1, 0.5)
	var brightness = sigmoid_remap(note, MIN_NOTE, MAX_NOTE, 0.5, 1, 0.5)
	var opacity = sigmoid_remap(note, MIN_NOTE, MAX_NOTE, 0.5, 1)
	var roughness = sigmoid_remap(note, MIN_NOTE, MAX_NOTE, 1, 0)
	
	track_paths[track].add_note(note_id, Vector3(x,y,z), hue, brightness, opacity, roughness)

func _on_midi_receiver_note_off(note_id, track) -> void:
	track_paths[track].remove_note(note_id)
