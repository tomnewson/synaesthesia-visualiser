extends Node

signal note_on ( note_id, note, velocity, track )
signal note_off ( note_id )

func _on_midi_event(channel: MidiPlayerAddon.GodotMIDIPlayerChannelStatus, event: SMF.MIDIEvent):
	if event.type == SMF.MIDIEventType.note_off or event.type == SMF.MIDIEventType.note_on:
		var note_id = str(channel.get_instance_id()) + str(event.note)
		match event.type:
			SMF.MIDIEventType.note_on:
				print(channel.number, " - ", channel.track_name)
				if event.velocity == 0:
					self.emit_signal("note_off", note_id)
				
				self.emit_signal("note_on", note_id, event.note, event.velocity, channel.number)
			SMF.MIDIEventType.note_off:
				self.emit_signal("note_off", note_id)
