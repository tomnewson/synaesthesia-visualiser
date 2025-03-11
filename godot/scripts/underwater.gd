extends Node3D

@onready var midi_player = $ArlezMidiPlayer

var active_notes = []
var no_notes_played = true
var tadpoles_by_note_id = {} # Dictionary to track which tadpole belongs to which note_id

const MAX_VELOCITY = 50.0
const MAX_PITCH = 127.0
const PITCH_THIRD = 43.0
const PITCH_TWO_THIRDS = 86.0
enum Note {ID, TRACK, PITCH, VELOCITY, INSTRUMENT}

func lerp_between_colors(current_color: Color, target_color, transition_speed) -> Color:
	var new_hue = lerp(current_color.h, target_color.h, transition_speed)
	var new_sat = lerp(current_color.s, target_color.s, transition_speed)
	var new_val = lerp(current_color.s, target_color.v, transition_speed)
	var new_alpha = lerp(current_color.a, target_color.a, transition_speed)

	return Color.from_hsv(new_hue, new_sat, new_val, new_alpha)


func _ready() -> void:
	midi_player.play()
	no_notes_played = true

func _process(delta):
	pass

func lerp_shader(mat: ShaderMaterial, param: String, target, speed: float, isColor: int = false):
	var current = mat.get_shader_parameter(param)
	mat.set_shader_parameter(
		param,
		lerp_between_colors(current, target, speed) if isColor else lerp(current, target, speed)
	)

func sigmoid(value: float, steepness: float, midpoint: float) -> float:
	return 1.0 / (1.0 + exp(-steepness * (value - midpoint)))

func color_from_pitch(pitch: float):
	var hue
	if pitch < PITCH_THIRD:
		hue = remap(pitch, 0, PITCH_THIRD, 0.0, 1)
	elif pitch < PITCH_TWO_THIRDS:
		hue = remap(pitch, PITCH_THIRD, PITCH_TWO_THIRDS, 1.0, 0.0)
	else:
		hue = remap(pitch, PITCH_TWO_THIRDS, MAX_PITCH, 0.0, 1.0)

	const sat = 0.7
	var val = remap(pitch, 0, MAX_PITCH, 0.5, 1)
	return Color.from_hsv(hue, sat, val)

func calculate_y_offset(pitch: float) -> float:
	if pitch < PITCH_THIRD:
		return remap(pitch, 0, PITCH_THIRD, -2.0, -0.4)
	if pitch < PITCH_TWO_THIRDS:
		return remap(pitch, PITCH_THIRD, PITCH_TWO_THIRDS , 0, 1.0)
	return remap(pitch, PITCH_TWO_THIRDS, MAX_PITCH, 1.5, 2.0)

func _on_midi_receiver_note_on(note_id, note, velocity, track, instrument) -> void:
	# sigmoid function on note
	note = sigmoid(note, 0.2, 74) * MAX_PITCH
	print("sigmoid ", note)

	var tadpole = preload("res://scenes/tadpole.tscn").instantiate()
	tadpole.show_direction_indicator = false

	tadpole.y_offset = calculate_y_offset(note)
	tadpole.position.x = -4.5
	tadpole.position.z = remap(velocity, 0, MAX_VELOCITY, -3, -0.5) * randf_range(0.8, 1.2)

	tadpole.initial_scale = remap(note, 0, MAX_PITCH, 1.0, 0.2)
	tadpole.amplitude = remap(note, 0, MAX_PITCH, 0.1, 0.3)
	tadpole.speed = remap(note, 0, MAX_PITCH, 2.0, 5.0) * randf_range(0.8, 1.2)

	var tadpoleMesh = tadpole.mesh.duplicate(true)
	tadpoleMesh.material.set_shader_parameter("albedo", color_from_pitch(note))
	tadpoleMesh.material.set_shader_parameter("tail_length", remap(note, 0, MAX_PITCH, 6.5, 11.0))
	tadpoleMesh.material.set_shader_parameter("wave_amplitude", remap(note, 0, MAX_PITCH, 0.03, 0.08))
	tadpoleMesh.material.set_shader_parameter("wave_frequency", remap(note, 0, MAX_PITCH, 4.0, 9.0))
	tadpole.mesh = tadpoleMesh
	add_child(tadpole)

	tadpoles_by_note_id[note_id] = tadpole # Store reference to tadpole by note_id

func _on_midi_receiver_note_off(note_id, track) -> void:
	# Send kill signal to the corresponding tadpole
	if tadpoles_by_note_id.has(note_id):
		var tadpole = tadpoles_by_note_id[note_id]
		if is_instance_valid(tadpole):
			# kill tadpole if not already removed from memory
			tadpoles_by_note_id[note_id].kill()
		tadpoles_by_note_id.erase(note_id) # Remove from dictionary
