extends Node

signal note_on ( note_id, note, velocity, track )
signal note_off ( note_id, track )

func _note_id(channel, event): 
	return str(channel.get_instance_id()) + str(event.note)

func _on_midi_event(channel: MidiPlayerAddon.GodotMIDIPlayerChannelStatus, event: SMF.MIDIEvent):
	match event.type:
		SMF.MIDIEventType.note_on:
				var note_id = _note_id(channel, event)
				print(channel.track_name, " - note: ", event.note)
				if event.velocity == 0:
					emit_signal("note_off", note_id)
				else:
					emit_signal("note_on", note_id, event.note, event.velocity, channel.number)
		SMF.MIDIEventType.note_off:
			var note_id = _note_id(channel, event)
			emit_signal("note_off", note_id, channel.number)
		_:
			#for key in SMF.MIDIEventType.keys():
				#if SMF.MIDIEventType[key] == event.type:
					#print(key)
					return
