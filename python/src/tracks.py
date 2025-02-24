"""
This module defines a TracksVisualizer class that visualizes MIDI data by separating notes by track.

It uses the pygame library for rendering and the mido library for MIDI parsing.

The visualization displays notes as circles, with the x-position determined by the MIDI channel and the y-position determined by the note pitch.

Constants:
    WIDTH (int): The width of the screen.
    HEIGHT (int): The height of the screen.
    CIRCLE_SCALE (int): The scaling factor for the note circles.
    MIDI_PATH (str): The path to the MIDI file.
    GM_INSTRUMENTS (list): A list of General MIDI instrument names.

Classes:
    TracksNote (Note): Represents a musical note in the tracks visualization.
    TracksVisualizer (BaseVisualizer): Visualizer that separates notes by track.
"""
from visualiser import BaseVisualizer, Note # Import BaseVisualizer

# Constants
WIDTH = 1920
HEIGHT = 1080
CIRCLE_SCALE = 9
MIDI_PATH = "../godot/midi/5th-Symphony-Part-1.mid"

GM_INSTRUMENTS = [
    "Acoustic Grand Piano", "Bright Acoustic Piano", "Electric Grand Piano", "Honky-tonk Piano",
    "Electric Piano 1", "Electric Piano 2", "Harpsichord", "Clavinet",
    "Celesta", "Glockenspiel", "Music Box", "Vibraphone",
    "Marimba", "Xylophone", "Tubular Bells", "Dulcimer",
    "Drawbar Organ", "Percussive Organ", "Rock Organ", "Church Organ",
    "Reed Organ", "Accordion", "Harmonica", "Tango Accordion",
    "Acoustic Guitar (nylon)", "Acoustic Guitar (steel)", "Electric Guitar (jazz)",
    "Electric Guitar (clean)",
    "Electric Guitar (muted)", "Overdriven Guitar", "Distortion Guitar", "Guitar harmonics",
    "Acoustic Bass", "Electric Bass (finger)", "Electric Bass (pick)", "Fretless Bass",
    "Slap Bass 1", "Slap Bass 2", "Synth Bass 1", "Synth Bass 2",
    "Violin", "Viola", "Cello", "Contrabass",
    "Tremolo Strings", "Pizzicato Strings", "Orchestral Harp", "Timpani",
    "String Ensemble 1", "String Ensemble 2", "SynthStrings 1", "SynthStrings 2",
    "Choir Aahs", "Voice Oohs", "Synth Voice", "Orchestra Hit",
    "Trumpet", "Trombone", "Tuba", "Muted Trumpet",
    "French Horn", "Brass Section", "SynthBrass 1", "SynthBrass 2",
    "Soprano Sax", "Alto Sax", "Tenor Sax", "Baritone Sax",
    "Oboe", "English Horn", "Bassoon", "Clarinet",
    "Piccolo", "Flute", "Recorder", "Pan Flute",
    "Blown Bottle", "Shakuhachi", "Whistle", "Ocarina",
    "Lead 1 (square)", "Lead 2 (sawtooth)", "Lead 3 (calliope)", "Lead 4 (chiff)",
    "Lead 5 (charang)", "Lead 6 (voice)", "Lead 7 (fifths)", "Lead 8 (bass + lead)",
    "Pad 1 (new age)", "Pad 2 (warm)", "Pad 3 (polysynth)", "Pad 4 (choir)",
    "Pad 5 (bowed)", "Pad 6 (metallic)", "Pad 7 (halo)", "Pad 8 (sweep)",
    "FX 1 (rain)", "FX 2 (soundtrack)", "FX 3 (crystal)", "FX 4 (atmosphere)",
    "FX 5 (brightness)", "FX 6 (goblins)", "FX 7 (echoes)", "FX 8 (sci-fi)",
    "Sitar", "Banjo", "Shamisen", "Koto",
    "Kalimba", "Bag pipe", "Fiddle", "Shanai",
    "Tinkle Bell", "Agogo", "Steel Drums", "Woodblock",
    "Taiko Drum", "Melodic Tom", "Synth Drum", "Reverse Cymbal",
    "Guitar Fret Noise", "Breath Noise", "Seashore", "Bird Tweet",
    "Telephone Ring", "Helicopter", "Applause", "Gunshot"
]

class TracksNote(Note):
    """Represents a musical note in the tracks visualization."""

    def __init__(self, msg, elapsed_time, num_channels):
        super().__init__(msg, elapsed_time, scale=CIRCLE_SCALE)
        self.channel = msg.channel
        self.x = WIDTH // 2 if num_channels <= 1 else self.remap(msg.channel or 0, 0, num_channels - 1, WIDTH * 0.1, WIDTH * 0.9)
        self.y = self.note_to_axis(self.note, HEIGHT, self.size, False)

class TracksVisualizer(BaseVisualizer):
    """Visualizer that separates notes by track."""

    def create_note(self, msg, elapsed_time):
        return TracksNote(msg, elapsed_time, self.num_channels)

if __name__ == '__main__':
    visualizer = TracksVisualizer(MIDI_PATH)
    visualizer.load_midi()
    visualizer.setup()
    visualizer.main_loop()
