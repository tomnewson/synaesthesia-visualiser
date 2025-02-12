extends Node3D

@onready var midi_player = $ArlezMidiPlayer
@onready var collapsing_cube = $CollapseCube
@onready var waves = $Waves

var active_notes = []
var no_notes_played = true

var target_cube_speed: float # 0->1
var cube_speed: float = 0.0 # 0->1
var target_cube_color: Color
var collapse_direction = 1.0
const CUBE_ROTATION_SPEED = 0.1
const CUBE_TRANSITION_SPEED = 2.0

var target_waves_intensity: float
var target_waves_color: Color
var target_waves_alpha: float
const BASE_WAVES_INTENSITY = 0.05
const WAVES_TRANSITION_SPEED = 2.0

#const MAX_VELOCITY = 450.0
const MAX_VELOCITY = 200.0
var selected_visualisation

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
	
	selected_visualisation = waves
	
	collapsing_cube.mesh.material.set_shader_parameter("albedo", Color.TRANSPARENT)
	collapsing_cube.mesh.material.set_shader_parameter("progress", 0.0)
	target_cube_color = Color.TRANSPARENT
	
	waves.mesh.material.set_shader_parameter("amplitude", BASE_WAVES_INTENSITY)
	waves.mesh.material.set_shader_parameter("add_color", Color.TRANSPARENT)
	waves.mesh.material.set_shader_parameter("alpha", 0.0)
	
	
func _process(delta):
	match selected_visualisation:
		collapsing_cube:
			update_cube(delta)
		waves:
			update_waves(delta)
	
func lerp_shader(mat: ShaderMaterial, param: String, target, speed: float, isColor: int = false):
	var current = mat.get_shader_parameter(param)
	mat.set_shader_parameter(
		param,
		lerp_between_colors(current, target, speed) if isColor else lerp(current, target, speed)
	)
	
func update_cube(delta):
	var cube_mat: ShaderMaterial = $CollapseCube.mesh.material
	var current_prog = cube_mat.get_shader_parameter("progress")
	cube_speed = lerp(cube_speed, target_cube_speed, CUBE_TRANSITION_SPEED * delta)
	
	var new_prog = current_prog + (0.1 * target_cube_speed * delta * collapse_direction)
	if new_prog >= 0.8 and collapse_direction == 1 or new_prog <= 0 and collapse_direction == -1:
		collapse_direction = -collapse_direction
	cube_mat.set_shader_parameter("progress", new_prog)

	print(target_cube_speed, target_cube_color)
	cube_mat.set_shader_parameter("albedo", target_cube_color)
	collapsing_cube.rotate_x(CUBE_ROTATION_SPEED * delta)
	collapsing_cube.rotate_y(CUBE_ROTATION_SPEED * delta)
	
func update_waves(delta):
	var waves_mat: ShaderMaterial = waves.mesh.surface_get_material(0)
	lerp_shader(
		waves_mat,
		"amplitude",
		target_waves_intensity,
		WAVES_TRANSITION_SPEED * delta,
	)
	lerp_shader(
		waves_mat,
		"add_color",
		target_waves_color,
		WAVES_TRANSITION_SPEED * delta,
		true
	)
	lerp_shader(
		waves_mat,
		"alpha",
		target_waves_alpha,
		WAVES_TRANSITION_SPEED * delta,
	)
	
	
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
		set_waves_targets(0,0,0, MAX_VELOCITY)
		set_cube_targets(0,0,0,MAX_VELOCITY)
		return
		
	var instrument_stats = {"total": [0,0,0]}
	# clear instruments
	for i in Globals.InstrumentCategory.values():
		instrument_stats[i] = [0,0,0]
		
	for n in active_notes:
		var pitch = n[Note.PITCH]
		var velocity = n[Note.VELOCITY]
		var instrument = n[Note.INSTRUMENT]
		
		instrument_stats["total"][PITCH] += pitch
		instrument_stats["total"][VELOCITY] += velocity
		instrument_stats["total"][COUNT] += 1
		
		#print("current total velocity: ", instrument_stats["total"][VELOCITY])
	
	var avg_pitch = instrument_stats["total"][PITCH] / len(active_notes)
	var clamped_sv = clamp(instrument_stats["total"][VELOCITY], 0, MAX_VELOCITY)
	
	
	var instrument = instrument_stats["total"]
	match selected_visualisation:
		collapsing_cube:
			set_cube_targets(
				instrument[PITCH],
				instrument[VELOCITY],
				instrument[COUNT],
				MAX_VELOCITY, # manually change
			)
		waves:
			set_waves_targets(
				instrument[PITCH],
				instrument[VELOCITY],
				instrument[COUNT],
				MAX_VELOCITY, # manually change
			)
	
func set_cube_targets(sum_pitch, sum_velocity, count, max_velocity):
	sum_velocity = clamp(sum_velocity, 0.0, max_velocity)
	target_cube_speed = sum_velocity / max_velocity
	if count:
		var avg_pitch = sum_pitch / count
		target_cube_color = color_from_notes(avg_pitch, sum_velocity, max_velocity, 0.3, 0.8, 0.3, 0.6)
	target_cube_color.a = 1.0
	
func set_waves_targets(sum_pitch, velocity, count, max_velocity):
	target_waves_intensity = BASE_WAVES_INTENSITY + (clamp(velocity, 0, max_velocity) / max_velocity) / 3.0
	target_waves_alpha = clamp(velocity, 0.0, max_velocity) / max_velocity
	if count:
		var avg_waves_pitch = sum_pitch / count
		target_waves_color = color_from_notes(avg_waves_pitch, velocity, max_velocity, 0.3, 0.9, 0.6, 0.8)

func _on_midi_receiver_note_on(note_id, note, velocity, track, instrument) -> void:
	active_notes.append([note_id, track, note, velocity, instrument])
	update_active_notes()

func _on_midi_receiver_note_off(note_id, track) -> void:
	for n in active_notes:
		if n[Note.ID] == note_id:
			active_notes.erase(n)
			break
	update_active_notes()
