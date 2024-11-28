extends Node3D

var track_paths = [] # int to path scene
@onready var path_scene = preload("res://scenes/blob.tscn")
@export var num_tracks: int = 8

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

func _on_midi_receiver_note_on(note_id, note, velocity, track) -> void:
	# high pitch - small, high up, stringy
	# low pitch - big, low down, wide
	# loud - near
	# quiet - far
	var x = remap(track, 0, num_tracks, -5, 5)
	var y = remap(note, MIN_NOTE, MAX_NOTE, -5, 5)
	var z = remap(velocity, MIN_VELOCITY, MAX_VELOCITY, -10, -5)
	
	track_paths[track].add_note(note_id, Vector3(x,y,z))

func _on_midi_receiver_note_off(note_id, track) -> void:
	track_paths[track].remove_note(note_id)
