extends Node3D

@onready var midi_player = $ArlezMidiPlayer
@onready var environment: Environment = $WorldEnvironment.environment
@onready var overlay: MeshInstance3D = $GlobalOverlay
@onready var waves: MeshInstance3D = $Waves

const MAX_VELOCITY = 1000.0

const bg_transition_speed = 0.5
const dist_transition_speed = 0.8
const WAVES_TRANSITION_SPEED = 2.0
const BASE_WAVES_INTENSITY = 0.05

var active_notes = []
var target_bg_color: Color
var no_notes_played: bool
var target_dist_intensity: float

var target_pipe_intensity: float
var target_pipe_color: Color

enum Note {ID, TRACK, PITCH, VELOCITY, INSTRUMENT}

func lerp_between_colors(current_color: Color, target_color, transition_speed) -> Color:
	# TODO: FEAT better color transition
	var new_hue = lerp(current_color.h, target_color.h, transition_speed)
	var new_sat = lerp(current_color.s, target_color.s, transition_speed)
	var new_val = lerp(current_color.s, target_color.v, transition_speed)
	
	return Color.from_hsv(new_hue, new_sat, new_val)

func _ready() -> void:
	midi_player.play()
	environment.background_color = Color.BLACK
	target_bg_color = Color.BLACK
	target_dist_intensity = 0
	no_notes_played = true
	
	target_pipe_color = Color.TRANSPARENT
	target_pipe_intensity = BASE_WAVES_INTENSITY
	
func _process(delta):
	if no_notes_played and target_bg_color != Color.BLACK:
		environment.background_color = target_bg_color
		no_notes_played = false
		
	# TODO: FIX lerp to properly transition according to delta
	
	var current_bg_colour = environment.background_color
	environment.background_color = lerp_between_colors(current_bg_colour, target_bg_color, bg_transition_speed * delta)
	
	var overlay_material: ShaderMaterial = overlay.mesh.surface_get_material(0)
	var current_dist_int = overlay_material.get_shader_parameter("distortion_intensity")
	var new_dist_int = lerp(current_dist_int, target_dist_intensity, dist_transition_speed * delta)
	overlay_material.set_shader_parameter("distortion_intensity", new_dist_int)
	
	var waves_mat: ShaderMaterial = waves.mesh.surface_get_material(0)
	var current_pipe_int = waves_mat.get_shader_parameter("amplitude")
	var new_pipe_intensity = lerp(current_pipe_int, target_pipe_intensity, WAVES_TRANSITION_SPEED * delta)
	waves_mat.set_shader_parameter("amplitude", new_pipe_intensity)
	var current_pipe_color = waves_mat.get_shader_parameter("add_color")
	var new_pipe_color = lerp_between_colors(current_pipe_color, target_pipe_color, WAVES_TRANSITION_SPEED * delta)
	waves_mat.set_shader_parameter("add_color", new_pipe_color)
	

func sigmoid(value: float, steepness: float, midpoint: float) -> float:
	return 1.0 / (1.0 + exp(-steepness * (value - midpoint)))
	
func color_from_notes(avg_pitch: float, sum_velocity: float, max_velocity: float, min_saturation: float, max_saturation: float, min_brightness: float, max_brightness: float) -> Color:
	var hue = sigmoid(avg_pitch, 0.2, 50)
	
	sum_velocity = clamp(sum_velocity, 0, max_velocity)
	var sat = remap(sum_velocity, 0, max_velocity, min_saturation, max_saturation)
	var brightness = remap(sum_velocity, 0, max_velocity, min_brightness, max_brightness)
	
	return Color.from_hsv(hue, sat, brightness)
	

func update_active_notes():
	if active_notes.is_empty():
		target_dist_intensity = 0
		#target_bg_color = Color.BLACK
		return
	
	var sum_pitch = 0
	var sum_velocity = 0
	var pipe_pitch = 0
	var pipe_velocity = 0
	var pipe_count = 0
	for n in active_notes:
		sum_pitch += n[Note.PITCH]
		sum_velocity += n[Note.VELOCITY]
		
		match n[Note.INSTRUMENT]:
			Globals.InstrumentCategory.PIPE:
				pipe_pitch += n[Note.PITCH]
				pipe_velocity += n[Note.VELOCITY]
				pipe_count += 1
			_:
				pass
	
	var avg_pitch = sum_pitch / len(active_notes)
	var clamped_sv = clamp(sum_velocity, 0, MAX_VELOCITY)
	
	target_bg_color = color_from_notes(avg_pitch, sum_velocity, MAX_VELOCITY, 0.2, 0.6, 0.4, 0.8)
	
	target_dist_intensity = clamped_sv / MAX_VELOCITY
	
	target_pipe_intensity = BASE_WAVES_INTENSITY + (clamp(pipe_velocity, 0, 100) / 100.0) / 4.0
	if !pipe_count:
		#target_pipe_color = Color.TRANSPARENT
		pass
	else:
		target_pipe_color = color_from_notes(pipe_pitch / pipe_count, pipe_velocity, 300, 0.3, 0.9, 0.6, 1.0)
		

func _on_midi_receiver_note_on(note_id, note, velocity, track, instrument) -> void:
	active_notes.append([note_id, track, note, velocity, instrument])
	update_active_notes()
	

func _on_midi_receiver_note_off(note_id, track) -> void:
	for n in active_notes:
		if n[Note.ID] == note_id:
			active_notes.erase(n)
			break
	update_active_notes()
