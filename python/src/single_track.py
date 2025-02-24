"""Provides a visualizer for MIDI music, focusing on a single track representation.

The module includes classes for handling notes and the overall visualization,
allowing for a dynamic and colorful representation of MIDI data. It uses Pygame
for rendering and provides a way to map MIDI notes to visual elements like
position, size, and color.

Classes:
    SingleTrackNote: Represents a single note with properties like position, size,
                     color, and methods for updating and drawing the note.
    SingleTrackVisualizer: Manages the visualization of a single track MIDI file,
                           including loading the MIDI file, creating notes, and
                           running the main visualization loop.

Functions:
    remap: Linearly maps a value from one range to another.
    note_to_axis: Maps a MIDI note number to an axis position on the screen.
    note_to_color: Maps a MIDI note number to a color.
"""
import math
import pygame
from visualiser import BaseVisualizer, Note

# Constants
WIDTH = 1920
HEIGHT = 1080
MIN_NOTE = 21  # A0
MAX_NOTE = 108  # C8
CIRCLE_SCALE = 10
MIDI_PATH = "../godot/midi/la_campanella.mid"

class SingleTrackNote(Note):
    """Represents a musical note in the single track visualization."""

    def __init__(self, msg, elapsed_time):
        super().__init__(msg, elapsed_time, scale=CIRCLE_SCALE)
        self.x = self.note_to_axis(self.note, WIDTH, self.size)
        self.y = HEIGHT / 2
        self.color = self.note_to_color(self.note)

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
        pygame.draw.circle(shape_surface, self.color, (shape_size // 2, shape_size // 2), int(self.size))
        surface.blit(shape_surface, (int(self.x - self.size), int(self.y - self.size)), special_flags=pygame.BLEND_ADD)


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
