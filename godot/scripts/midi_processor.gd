extends Node3D

@onready var midi_player = $ArlezMidiPlayer
@export var note_scene: PackedScene
@export var num_tracks: int = 3

const MIN_NOTE = 21
const MAX_NOTE = 108
const MIN_VELOCITY = 0
const MAX_VELOCITY = 127

var active_notes = {}

# METHODS TO PLAY MIDI
# 1. arlez + asp
# 2. arlez + inbuilt asp
# 3. g0retz + asp

# 1. doesn't work if there's a delay between the app starting and the music starting
# 2. works but im not sure about track visualisation
# 3. uses MidiResource so has to reload files, has same issues as 2 but even worse :(

func _ready():
	midi_player.play()

func _on_midi_receiver_note_off(note_id) -> void:
	remove_child(active_notes[note_id])
	active_notes.erase(note_id)

func _on_midi_receiver_note_on(note_id, note, velocity, track) -> void:
	# high pitch - small, high up, stringy
	# low pitch - big, low down, wide
	# loud - near
	# quiet - far
	var note_instance = note_scene.instantiate()
	var x = remap(track, 0, num_tracks, -5, 5)
	var y = remap(note, MIN_NOTE, MAX_NOTE, -5, 10)
	var z = remap(velocity, MIN_VELOCITY, MAX_VELOCITY, -5, 5)
	var new_scale = remap(MAX_NOTE - note, MIN_NOTE, MAX_NOTE, 0.2, 2)
	
	note_instance.scale = Vector3(new_scale, new_scale, new_scale)
	note_instance.transform.origin = Vector3(x,y,z)
	
	add_child(note_instance)
	active_notes[note_id] = note_instance
