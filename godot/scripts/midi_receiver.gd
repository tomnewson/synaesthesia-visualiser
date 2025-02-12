extends Node

signal note_on ( note_id, note, velocity, track )
signal note_off ( note_id, track )

# Map of common program numbers to instrument categories
const PROGRAM_CATEGORY_MAP = {
	# Pianos
	0: Globals.InstrumentCategory.PIANO,    # Acoustic Grand Piano
	1: Globals.InstrumentCategory.PIANO,    # Bright Acoustic Piano
	2: Globals.InstrumentCategory.PIANO,    # Electric Grand Piano
	
	# Guitars
	24: Globals.InstrumentCategory.GUITAR,  # Acoustic Guitar (Nylon)
	25: Globals.InstrumentCategory.GUITAR,  # Acoustic Guitar (Steel)
	26: Globals.InstrumentCategory.GUITAR,  # Electric Guitar (Jazz)
	
	# Basses
	32: Globals.InstrumentCategory.BASS,    # Acoustic Bass
	33: Globals.InstrumentCategory.BASS,    # Electric Bass (Finger)
	34: Globals.InstrumentCategory.BASS,    # Electric Bass (Pick)
	
	# Strings
	40: Globals.InstrumentCategory.STRINGS, # Violin
	41: Globals.InstrumentCategory.STRINGS, # Viola
	42: Globals.InstrumentCategory.STRINGS, # Cello
	
	# Wind instruments
	73: Globals.InstrumentCategory.PIPE,    # Flute
	74: Globals.InstrumentCategory.PIPE,    # Recorder
	75: Globals.InstrumentCategory.PIPE,    # Pan Flute
	
	# Brass
	56: Globals.InstrumentCategory.BRASS,   # Trumpet
	57: Globals.InstrumentCategory.BRASS,   # Trombone
	58: Globals.InstrumentCategory.BRASS,   # Tuba
	
	# Synth
	80: Globals.InstrumentCategory.SYNTH,   # Square Wave
	81: Globals.InstrumentCategory.SYNTH    # Saw Wave
}

var channel_instrument_map = {}

# Returns the instrument category for a given program number
func get_instrument_category(program_number: int) -> int:
	return PROGRAM_CATEGORY_MAP.get(program_number, Globals.InstrumentCategory.UNKNOWN)

func _note_id(channel, event): 
	return str(channel.get_instance_id()) + str(event.note)

func _on_arlez_midi_player_midi_event(channel: MidiPlayerAddon.GodotMIDIPlayerChannelStatus, event: Variant) -> void:
	match event.type:
		SMF.MIDIEventType.program_change:
			var category = get_instrument_category(event.number)
			print("PROGRAM CHANGE, %s -> %s" % [channel.instrument_name, Globals.InstrumentCategory.keys()[category]])
			channel_instrument_map[channel.number] = category
		SMF.MIDIEventType.note_on:
				var note_id = _note_id(channel, event)
				var instrument = channel_instrument_map[channel.number]
				print(channel.instrument_name, " - note: ", event.note, " velocity: ", event.velocity)
				if event.velocity == 0:
					emit_signal("note_off", note_id)
				else:
					emit_signal("note_on", note_id, event.note, event.velocity, channel.number, instrument)
		SMF.MIDIEventType.note_off:
			var note_id = _note_id(channel, event)
			emit_signal("note_off", note_id, channel.number)
		_:
			return
