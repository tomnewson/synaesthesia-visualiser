extends Node3D

@onready var midi_player = $MidiPlayer
@onready var asp = $AudioStreamPlayer
@export var note_scene: PackedScene
# MidiData just doesn't WORK FOR SOME FILES>>>>>>>>
#var midi_data: MidiData = load("/home/tom/synaesthesia_visualiser/midi/messiaen_diptyque_part_I_(winitzki).mid")
# MidiPlayers always BREAK <>>><><> THIS IS PUSHIGN MET OTESIUGNSKJ NSEKfj.gbhdf.,skaejdjxn
var event_to_note: Dictionary = {}
const MIN_NOTE = 21
const MAX_NOTE = 108
const MIN_VELOCITY = 0
const MAX_VELOCITY = 127


#func _play():
	#var initial_delay := midi_data.tracks[0].get_offset_in_seconds()
	#match midi_data.header.format:
		#MidiData.Header.Format.SINGLE_TRACK, MidiData.Header.Format.MULTI_SONG:
			#var us_per_beat: int = 500_000
			#for event in midi_data.tracks[0].events:
				#initial_delay += midi_data.header.convert_to_seconds(us_per_beat, event.delta_time)
				#var tempo := event as MidiData.Tempo
				#var note_on := event as MidiData.NoteOn
				#if tempo != null:
					#us_per_beat = tempo.us_per_beat
				#elif note_on != null:
					## TODO: wait for inital_delay and play note_on.note
					#initial_delay = 0
		#MidiData.Header.Format.MULTI_TRACK:
			#var index = 0
			#var tempo_map: Array[Vector2i] = midi_data.tracks[0].get_tempo_map()
			#var us_per_beat := tempo_map[index].y
			#var time: int = 0
			#for event in midi_data.tracks[1].events:
				#time += event.delta_time
				#while time >= tempo_map[index].x:
					## why does this go out of bounds
					#index += 1
					##if index >= len(tempo_map): 
						##break
					#us_per_beat = tempo_map[index].y
				#initial_delay += midi_data.header.convert_to_seconds(us_per_beat, event.delta_time)
				#var note_on := event as MidiData.NoteOn
				#if note_on != null:
					## TODO: wait for inital_delay and play note_on.note
					## await .get_offset_in_seconds() (stored in initial delay for track 0)
					#initial_delay = 0
					#print(note_on)

func _ready():
	midi_player.loop = true
	midi_player.note.connect(my_note_callback)
	midi_player.link_audio_stream_player([asp])
	
	#midi_player.play()
	#_play()
	
func _process(_delta):
	# rotate notes
	
	# emergency stop
	if Input.is_action_just_pressed("ui_accept"):
		midi_player.stop() 
		
func add_note(note, velocity, track):
	# high pitch - small, high up, stringy
	# low pitch - big, low down, wide
	# loud - near
	# quiet - far
	var note_instance = note_scene.instantiate()
	var x = remap(track, 0, 13, -5, 5)
	var y = remap(note, MIN_NOTE, MAX_NOTE, -5, 5)
	var z = remap(velocity, MIN_VELOCITY, MAX_VELOCITY, -5, 5)
	var new_scale = remap(MAX_NOTE - note, MIN_NOTE, MAX_NOTE, 0.2, 2)
	
	note_instance.scale = Vector3(new_scale, new_scale, new_scale)
	note_instance.transform.origin = Vector3(x,y,z)
	event_to_note[Vector2(note, track)] = note_instance
	
	add_child(note_instance)
	return note_instance

func my_note_callback(event, track):
	# EVENT
	# note: the key number - indicating pitch
	# data: the velocity
	# channel: the channel to be outputted to
	# type: note/meta
	# subtype: on/off
	# delta: the time since previous event
	
	if (event['subtype'] == MIDI_MESSAGE_NOTE_ON): # note on
		print("ADDING")
		add_note(event['note'], event['data'], track)
		
	elif (event['subtype'] == MIDI_MESSAGE_NOTE_OFF): # note off
		print("REMOVING")
		var key = Vector2(event['note'], track)
		if event_to_note.has(key):
			remove_child(event_to_note[key])
		event_to_note.erase(key)
		
	print("[Track: " + str(track) + "] Note played: " + str(event['note']))

var active_notes = {}

func _on_arlez_midi_player_start() -> void:
	#$AudioStreamPlayer.play()
	pass


func _on_midi_receiver_note_off(note_id) -> void:
	if active_notes.has(note_id):
		remove_child(active_notes[note_id])
	else:
		print(note_id)
	active_notes.erase(note_id)


func _on_midi_receiver_note_on(note_id, note, velocity, track) -> void:
	var note_instance = add_note(note, velocity, track)
	active_notes[note_id] = note_instance
