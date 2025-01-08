extends Node3D

@onready var midi_player = $ArlezMidiPlayer
@onready var environment: Environment = $WorldEnvironment.environment

const MAX_VELOCITY = 1000

var active_notes = []
var target_bg_color = Color.BLACK
var bg_transition_speed = 0.5
var no_notes_played = true

enum Note {ID, TRACK, PITCH, VELOCITY}

func _ready() -> void:
	midi_player.play()
	environment.background_color = Color.BLACK
	
func _process(delta):
	var current_bg_colour = environment.background_color
	var new_hue = lerp(current_bg_colour.h, target_bg_color.h, bg_transition_speed * delta)
	var new_sat = lerp(current_bg_colour.s, target_bg_color.s, bg_transition_speed * delta)
	var new_val = lerp(current_bg_colour.s, target_bg_color.v, bg_transition_speed * delta)
	
	environment.background_color = Color.from_hsv(new_hue, new_sat, new_val)

func sigmoid(value: float, steepness: float, midpoint: float) -> float:
	return 1.0 / (1.0 + exp(-steepness * (value - midpoint)))

func update_background_color():
	if active_notes.is_empty():
		return
	
	var sum_pitch = 0
	var sum_velocity = 0
	for n in active_notes:
		sum_pitch += n[Note.PITCH]
		sum_velocity += n[Note.VELOCITY]
	
	var avg_pitch = sum_pitch / len(active_notes)
	var clamped_sv = clamp(sum_velocity, 0, MAX_VELOCITY)
	
	var hue = sigmoid(avg_pitch, 0.2, 50)
	var sat = remap(clamped_sv, 0, MAX_VELOCITY, 0.2, 0.6)
	var brightness = remap(clamped_sv, 0, MAX_VELOCITY, 0.4, 0.8)
	
	var new_color = Color.from_hsv(hue, sat, brightness)
	
	target_bg_color = new_color
	if no_notes_played:
		environment.background_color = new_color
		no_notes_played = false

func _on_midi_receiver_note_on(note_id, note, velocity, track) -> void:
	active_notes.append([note_id, track, note, velocity])
	update_background_color()
	

func _on_midi_receiver_note_off(note_id, track) -> void:
	for n in active_notes:
		if n[Note.ID] == note_id:
			active_notes.erase(n)
			break
	update_background_color()
	
