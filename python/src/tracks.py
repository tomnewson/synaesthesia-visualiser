"""
This module defines a TracksVisualizer class that extends BaseVisualizer to
visualize MIDI data by representing each note as a circle, with the position
and color of the circle determined by the note's pitch and channel.

The module also includes helper functions for remapping values between ranges
and converting MIDI note numbers to colors.

Classes:
    TracksNote: Represents a musical note with properties for position, size,
        color, and channel, extending the base Note class.
    TracksVisualizer: A visualizer that separates notes by track, extending
        the BaseVisualizer class.

Functions:
    remap: Linearly maps a value from one range to another.
    note_to_axis: Maps a MIDI note number to an axis position on the screen.
    note_to_color: Maps a MIDI note number to a color (RGB tuple).

Constants:
    WIDTH: The width of the screen.
    HEIGHT: The height of the screen.
    MIN_NOTE: The lowest MIDI note number (A0).
    MAX_NOTE: The highest MIDI note number (C8).
    DEFAULT_FILE: The default MIDI file path.
    FRAMERATE: The frame rate of the visualization.
    NOTE_TYPES: A set of MIDI message types to process.
    CIRCLE_SCALE: A scaling factor for the size of the circles.
    MIDI_PATH: The path to the MIDI file to visualize.
    GM_INSTRUMENTS: A list of General MIDI instrument names.
"""
import math
import pygame
from visualiser import BaseVisualizer, Note # Import BaseVisualizer

# Constants
WIDTH = 1920
HEIGHT = 1080
MIN_NOTE = 21  # A0 (first note on a standard 88-key piano)
MAX_NOTE = 108  # C8 (last note on a standard 88-key piano)
DEFAULT_FILE = "../godot/midi/5th-Symphony-Part-1.mid"
FRAMERATE = 60
NOTE_TYPES = {'note_on', 'note_off', 'program_change'}
CIRCLE_SCALE = 10
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


# --- Helper functions ---

def remap(value, left_min, left_max, right_min, right_max):
    """Linearly maps a value from one range to another."""
    left_span = left_max - left_min
    right_span = right_max - right_min
    value_scaled = float(value - left_min) / float(left_span)
    return right_min + (value_scaled * right_span)


def note_to_axis(note, max_val):
    """Map MIDI note number to an axis position on the screen."""
    return remap(note, MIN_NOTE, MAX_NOTE, 0, max_val)


def note_to_color(note):
    """Map a MIDI note number to a color.

    Converts an HSB (with hue in [0,360]) color to an RGB tuple.
    """
    hue = remap(note, MIN_NOTE, MAX_NOTE, 0, 360)
    color = pygame.Color(0)
    color.hsva = (hue, 100, 100, 100)  # Hue, Saturation, Value, Alpha
    return color

class TracksNote(Note):
    """Represents a musical note in the tracks visualization."""

    def __init__(self, msg, elapsed_time, num_channels):
        super().__init__(msg, elapsed_time)
        self.channel = msg.channel
        self.x = WIDTH // 2 if num_channels <= 1 else remap(msg.channel or 0, 0, num_channels - 1, WIDTH * 0.1, WIDTH * 0.9)
        self.y = remap(self.note, MIN_NOTE, MAX_NOTE, HEIGHT, 0)
        self.size = remap(self.note, MIN_NOTE, MAX_NOTE, 50, 5) * CIRCLE_SCALE
        self.color = note_to_color(self.note)

    def update(self, elapsed_time):
        """Update the note's position and size."""
        if self.active:
            self.size += math.log10(self.size) * 0.2
        else:
            time_since_end = elapsed_time - self.end_time
            self.size = max(0, self.size - (time_since_end * CIRCLE_SCALE * 5))
            self.color.a = max(0, 255 - int(time_since_end * 50))

            if self.size <= 0 or self.color.a <= 0:
                self.finished = True

    def draw(self, surface):
        """Draw the note on the surface."""
        if self.size <= 0 or self.color.a <= 0:
            return

        shape_size = int(self.size * 2)
        shape_surface = pygame.Surface((shape_size, shape_size), pygame.SRCALPHA)
        pygame.draw.circle(
            shape_surface,
            self.color,
            (shape_size // 2, shape_size // 2),
            int(self.size),
        )
        surface.blit(shape_surface, (int(self.x - self.size), int(self.y - self.size)),
                     special_flags=pygame.BLEND_ADD)


class TracksVisualizer(BaseVisualizer):
    """Visualizer that separates notes by track."""

    def create_note(self, msg, elapsed_time):
        return TracksNote(msg, elapsed_time, self.num_channels)

if __name__ == '__main__':
    visualizer = TracksVisualizer(MIDI_PATH)
    visualizer.load_midi()
    visualizer.setup()
    visualizer.main_loop()
