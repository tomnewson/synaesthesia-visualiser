extends Node3D

@onready var midi_player = $ArlezMidiPlayer
@onready var environment: Environment = $WorldEnvironment.environment
@onready var overlay: MeshInstance3D = $ScreenReader
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
var target_pipe_alpha: float

var target_strings_speed: float

enum Note {ID, TRACK, PITCH, VELOCITY, INSTRUMENT}

func lerp_between_colors(current_color: Color, target_color, transition_speed) -> Color:
	# TODO: FEAT better color transition
	var new_hue = lerp(current_color.h, target_color.h, transition_speed)
	var new_sat = lerp(current_color.s, target_color.s, transition_speed)
	var new_val = lerp(current_color.s, target_color.v, transition_speed)
	
	return Color.from_hsv(new_hue, new_sat, new_val)

func reset_material(material: ShaderMaterial, base_intensity, base_color, base_transparency):
	material.set_shader_parameter("amplitude", BASE_WAVES_INTENSITY)
	material.set_shader_parameter("add_color", Color.TRANSPARENT)
	material.set_shader_parameter("alpha", 0.0)

func _ready() -> void:
	midi_player.play()
	no_notes_played = true
	
	environment.background_color = Color.BLACK
	target_bg_color = Color.BLACK
	
	target_dist_intensity = 0
	
	reset_material(waves.mesh.surface_get_material(0), BASE_WAVES_INTENSITY, Color.TRANSPARENT, 0.0)
	target_pipe_color = Color.TRANSPARENT
	target_pipe_intensity = BASE_WAVES_INTENSITY
	target_pipe_alpha = 0;
	
	target_strings_speed = 0.0
	
func _process(delta):
	#if no_notes_played and target_bg_color != Color.BLACK:
		#environment.background_color = target_bg_color
		#no_notes_played = false
		
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
	var current_pipe_alpha = waves_mat.get_shader_parameter("alpha")
	var new_pipe_alpha = lerp(current_pipe_alpha, target_pipe_alpha, WAVES_TRANSITION_SPEED * delta)
	waves_mat.set_shader_parameter("alpha", new_pipe_alpha)
	
	var strings_mat: ShaderMaterial = $Overlay/Strings.material
	var current_strings_speed = strings_mat.get_shader_parameter("overallSpeed")
	var new_strings_speed = lerp(current_strings_speed, target_strings_speed, WAVES_TRANSITION_SPEED * delta)
	strings_mat.set_shader_parameter("overallSpeed", new_strings_speed)
	

func sigmoid(value: float, steepness: float, midpoint: float) -> float:
	return 1.0 / (1.0 + exp(-steepness * (value - midpoint)))
	
func color_from_notes(avg_pitch: float, sum_velocity: float, max_velocity: float, min_saturation: float, max_saturation: float, min_brightness: float, max_brightness: float) -> Color:
	var hue = sigmoid(avg_pitch, 0.2, 50)
	
	sum_velocity = clamp(sum_velocity, 0, max_velocity)
	var sat = remap(sum_velocity, 0, max_velocity, min_saturation, max_saturation)
	var brightness = remap(sum_velocity, 0, max_velocity, min_brightness, max_brightness)
	
	return Color.from_hsv(hue, sat, brightness)
	
enum {
	PITCH,
	VELOCITY,
	COUNT,
}

func update_active_notes():
	if active_notes.is_empty():
		target_dist_intensity = 0
		#target_bg_color = Color.BLACK
		set_pipe_targets(0,0,0)
		return
		
	var instrument_stats = {"total": [0,0]}
	# clear instruments
	for i in Globals.InstrumentCategory.values():
		instrument_stats[i] = [0,0,0]
		
	for n in active_notes:
		var pitch = n[Note.PITCH]
		var velocity = n[Note.VELOCITY]
		var instrument = n[Note.INSTRUMENT]
		
		instrument_stats["total"][PITCH] += pitch
		instrument_stats["total"][VELOCITY] += velocity
		
		instrument_stats[instrument][PITCH] += pitch
		instrument_stats[instrument][VELOCITY] += velocity
		instrument_stats[instrument][COUNT] += 1
	
	var avg_pitch = instrument_stats["total"][PITCH] / len(active_notes)
	var clamped_sv = clamp(instrument_stats["total"][VELOCITY], 0, MAX_VELOCITY)
	
	# background
	target_bg_color = color_from_notes(avg_pitch, clamped_sv, MAX_VELOCITY, 0.2, 0.6, 0.4, 0.8)
	
	# distortion
	target_dist_intensity = clamped_sv / MAX_VELOCITY
	
	# waves - pipe
	set_pipe_targets(
		instrument_stats[Globals.InstrumentCategory.PIPE][PITCH],
		instrument_stats[Globals.InstrumentCategory.PIPE][VELOCITY],
		instrument_stats[Globals.InstrumentCategory.PIPE][COUNT],
	)
	
	# strings
	var strings = $Overlay/Strings
	target_strings_speed = 0.05 + (clamp(instrument_stats[Globals.InstrumentCategory.STRINGS][VELOCITY], 0, 100.0) / 100.0) / 4.0

func set_pipe_targets(sum_pitch, velocity, count):
	target_pipe_intensity = BASE_WAVES_INTENSITY + (clamp(velocity, 0, 100) / 100.0) / 3.0
	target_pipe_alpha = clamp(velocity, 0, 100) / 100
	if !count:
		#target_pipe_color = Color.TRANSPARENT
		pass
	else:
		var avg_pipe_pitch = sum_pitch / count
		target_pipe_color = color_from_notes(avg_pipe_pitch, velocity, 300, 0.3, 0.9, 0.6, 0.8)

func _on_midi_receiver_note_on(note_id, note, velocity, track, instrument) -> void:
	active_notes.append([note_id, track, note, velocity, instrument])
	update_active_notes()
	

func _on_midi_receiver_note_off(note_id, track) -> void:
	for n in active_notes:
		if n[Note.ID] == note_id:
			active_notes.erase(n)
			break
	update_active_notes()
