extends Node

signal note_on ( note_id, note, velocity, track )
signal note_off ( note_id )

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_midi_event(_channel: MidiPlayerAddon.GodotMIDIPlayerChannelStatus, event: SMF.MIDIEvent):
	if event.type == SMF.MIDIEventType.note_off or event.type == SMF.MIDIEventType.note_on:
		var note_id =  str(event.note)
		match event.type:
			SMF.MIDIEventType.note_on:
				if event.velocity == 0:
					self.emit_signal("note_off", note_id)
				
				self.emit_signal("note_on", note_id, event.note, event.velocity, 1)
			SMF.MIDIEventType.note_off:
				self.emit_signal("note_off", note_id)


func _on_start() -> void:
	pass
