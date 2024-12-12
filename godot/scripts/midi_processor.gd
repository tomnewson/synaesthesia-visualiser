extends Node3D

@onready var midi_player = $ArlezMidiPlayer

func _ready():
	midi_player.play()
