extends Node3D

var track_paths = [] # int to path scene
@onready var path_scene = preload("res://scenes/blob.tscn")
@onready var environment: Environment = $"../../WorldEnvironment".environment
@export var num_tracks: int = 9



# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#for i in range (num_tracks + 1):
		#var x = remap(i, 0, num_tracks, -7, 7)
		#var track_instance = path_scene.instantiate()
		#track_paths.append(track_instance)
		#track_instance.translate(Vector3(x, 0, 0))
		#add_child(track_instance)


#func _on_midi_receiver_note_on(note_id, note, velocity, track) -> void:
	## high pitch - small, high up, stringy, opaque, bright, smooth
	## low pitch - big, low down, wide, transparent, dark, rough
	## loud - near
	## quiet - far
	##var y = sigmoid_remap(note, MIN_NOTE, MAX_NOTE, -3, 5, 4)
	##var z = sigmoid_remap(velocity, MIN_VELOCITY, MAX_VELOCITY, -10, -7)
	##var hue = sigmoid_remap(note, MIN_NOTE, MAX_NOTE, 0, 1, 1)
	##var brightness = sigmoid_remap(note, MIN_NOTE, MAX_NOTE, 0.5, 1, 0.5)
	##var opacity = sigmoid_remap(note, MIN_NOTE, MAX_NOTE, 0.5, 1)
	##var roughness = sigmoid_remap(note, MIN_NOTE, MAX_NOTE, 1, 0)
	#
	##track_paths[track].add_note(note_id, Vector3(0,y,z), hue, brightness, opacity, roughness)
	#active_notes.append([note_id, track, note, velocity])
	#update_background_color()
	#
#
#func _on_midi_receiver_note_off(note_id, track) -> void:
	##track_paths[track].remove_note(note_id)
	#for n in active_notes:
		#if n[Note.ID] == note_id:
			#active_notes.erase(n)
	#update_background_color()
	#
