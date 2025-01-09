extends Node3D

@onready var midi_player = $ArlezMidiPlayer
@onready var environment: Environment = $WorldEnvironment.environment
@onready var overlay: MeshInstance3D = $Overlay3D

const MAX_VELOCITY = 1000.0

const bg_transition_speed = 0.5
const dist_transition_speed = 0.8
var active_notes = []
var target_bg_color: Color
var no_notes_played: bool
var target_dist_intensity: float

enum Note {ID, TRACK, PITCH, VELOCITY}

func _ready() -> void:
	midi_player.play()
	environment.background_color = Color.BLACK
	target_bg_color = Color.BLACK
	target_dist_intensity = 0
	no_notes_played = true
	
func _process(delta):
	var current_bg_colour = environment.background_color
	var new_hue = lerp(current_bg_colour.h, target_bg_color.h, bg_transition_speed * delta)
	var new_sat = lerp(current_bg_colour.s, target_bg_color.s, bg_transition_speed * delta)
	var new_val = lerp(current_bg_colour.s, target_bg_color.v, bg_transition_speed * delta)
	
	environment.background_color = Color.from_hsv(new_hue, new_sat, new_val)
	
	var overlay_material: ShaderMaterial = overlay.mesh.surface_get_material(0)
	var current_dist_int = overlay_material.get_shader_parameter("distortion_intensity")
	var new_dist_int = lerp(current_dist_int, target_dist_intensity, dist_transition_speed * delta)
	overlay_material.set_shader_parameter("distortion_intensity", new_dist_int)

func sigmoid(value: float, steepness: float, midpoint: float) -> float:
	return 1.0 / (1.0 + exp(-steepness * (value - midpoint)))
	
func find_target_bg_color(avg_pitch: float, sum_velocity: float) -> Color:
	var hue = sigmoid(avg_pitch, 0.2, 50)
	var sat = remap(sum_velocity, 0, MAX_VELOCITY, 0.2, 0.6)
	var brightness = remap(sum_velocity, 0, MAX_VELOCITY, 0.4, 0.8)
	
	return Color.from_hsv(hue, sat, brightness)
	

func update_active_notes():
	if active_notes.is_empty():
		target_dist_intensity = 0
		return
	
	var sum_pitch = 0
	var sum_velocity = 0
	for n in active_notes:
		sum_pitch += n[Note.PITCH]
		sum_velocity += n[Note.VELOCITY]
	
	var avg_pitch = sum_pitch / len(active_notes)
	var clamped_sv = clamp(sum_velocity, 0, MAX_VELOCITY)
	
	target_bg_color = find_target_bg_color(avg_pitch, clamped_sv)
	if no_notes_played:
		environment.background_color = target_bg_color
		no_notes_played = false
		
	target_dist_intensity = clamped_sv / MAX_VELOCITY

func _on_midi_receiver_note_on(note_id, note, velocity, track) -> void:
	active_notes.append([note_id, track, note, velocity])
	update_active_notes()
	

func _on_midi_receiver_note_off(note_id, track) -> void:
	for n in active_notes:
		if n[Note.ID] == note_id:
			active_notes.erase(n)
			break
	update_active_notes()
