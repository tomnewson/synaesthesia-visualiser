extends Node3D

@onready var midi_player = $ArlezMidiPlayer

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
