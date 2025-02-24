
"""
This module defines a visualizer for single-track MIDI files.

It uses the BaseVisualizer class to handle MIDI loading, setup, and the main loop.
The SingleTrackVisualizer class extends BaseVisualizer to create and display notes
from a single MIDI track. The SingleTrackNote class represents a note with properties
such as position and size, specifically tailored for the single-track visualization.
"""
from visualiser import BaseVisualizer, Note

# Constants
WIDTH = 1920
HEIGHT = 1080
CIRCLE_SCALE = 10
MIDI_PATH = "../godot/midi/la_campanella.mid"

class SingleTrackNote(Note):
    """Represents a musical note in the single track visualization."""

    def __init__(self, msg, elapsed_time):
        super().__init__(msg, elapsed_time, scale=CIRCLE_SCALE)
        self.x = self.note_to_axis(self.note, WIDTH, self.size)
        self.y = HEIGHT / 2

class SingleTrackVisualizer(BaseVisualizer):
    """Visualizer for a single track MIDI file."""

    def create_note(self, msg, elapsed_time):
        """Create a Note object."""
        return SingleTrackNote(msg, elapsed_time)

if __name__ == '__main__':
    visualizer = SingleTrackVisualizer(MIDI_PATH)
    visualizer.load_midi()
    visualizer.setup()
    visualizer.main_loop()
