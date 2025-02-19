import math
import sys
import mido
import pygame
from chord_extractor.extractors import Chordino
import librosa  # Import librosa

# Constants
WIDTH = 1920
HEIGHT = 1080
MIN_NOTE = 21  # A0
MAX_NOTE = 108  # C8
CIRCLE_SCALE = 10
MIDI_PATH = "../godot/midi/la_campanella.mid"


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


class Note:
    """Represents a musical note in the visualization."""

    def __init__(self, msg, elapsed_time):
        self.note = msg.note
        self.velocity = msg.velocity
        self.start_time = elapsed_time
        self.end_time = None
        self.active = True
        self.finished = False
        self.x = note_to_axis(self.note, WIDTH)
        self.y = HEIGHT / 2
        self.size = remap(self.velocity, 0, 127, 10, 50 * CIRCLE_SCALE)
        self.color = note_to_color(self.note)

    def note_off(self, elapsed_time):
        """Handles the note-off event."""
        self.end_time = elapsed_time
        self.active = False

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


class Visualizer:
    """Encapsulates the visualization logic."""

    def __init__(self):
        pygame.init()
        self.screen = pygame.display.set_mode((WIDTH, HEIGHT))
        pygame.display.set_caption("MIDI Visualization")
        self.clock = pygame.time.Clock()
        pygame.font.init()
        self.font = pygame.font.SysFont('Arial', 50)
        self.note_events = []
        self.active_notes = []
        self.next_event_index = 0
        self.start_time = None
        self.offset = 0
        self.game_state = "ready"
        self.audio_onset_time = 0
        self.conversion_file_path = None

    def load_midi(self, midi_path):
        """Load the MIDI file and extract note events."""
        mid = mido.MidiFile(midi_path)
        current_time = 0
        for track in mid.tracks:
            print(track.name)
        for msg in mid:
            current_time += msg.time
            if msg.type == 'note_on' and msg.velocity == 0:
                msg = mido.Message('note_off', note=msg.note, channel=msg.channel)
            if msg.type in ['note_on', 'note_off']:
                self.note_events.append({'time': current_time, 'message': msg})

    def setup(self):
        """Initialize pygame, the display, and audio playback."""
        self.screen.fill((0, 0, 0))
        chordino = Chordino(roll_on=1)

        print("Converting midi to wav...")
        self.conversion_file_path = chordino.preprocess(MIDI_PATH)

        print("Calculating wav/midi offset...")
        y, sr = librosa.load(self.conversion_file_path)
        onset_env = librosa.onset.onset_strength(y=y, sr=sr)
        onset_frames = librosa.onset.onset_detect(onset_envelope=onset_env, sr=sr)
        self.audio_onset_time = librosa.frames_to_time(onset_frames[0], sr=sr) if len(onset_frames) > 0 else 0

        midi_onset_time = self.note_events[0]['time'] if self.note_events else 0
        self.offset = self.audio_onset_time - midi_onset_time
        print(f"wav/midi offset: {self.offset:3}ms")

        pygame.mixer.init()
        pygame.mixer.music.load(self.conversion_file_path)

    def main_loop(self):
        """Main loop for handling events, updating, and drawing."""
        running = True
        while running:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False
                if event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_RETURN and self.game_state == "ready":
                        self.game_state = "playing"
                        pygame.mixer.music.play()
                        self.start_time = pygame.time.get_ticks()

            self.screen.fill((0, 0, 0))

            if self.game_state == "ready":
                text_surface = self.font.render('Ready, press ENTER to play', True, (255, 255, 255))
                text_rect = text_surface.get_rect(center=(WIDTH // 2, HEIGHT // 2))
                self.screen.blit(text_surface, text_rect)
            elif self.game_state == "playing":
                elapsed_time = (pygame.time.get_ticks() - self.start_time) / 1000.0

                while self.next_event_index < len(self.note_events) and \
                        self.note_events[self.next_event_index]['time'] + self.offset <= elapsed_time:
                    event_dict = self.note_events[self.next_event_index]
                    msg = event_dict['message']
                    if msg.type == 'note_on':
                        self.active_notes.append(Note(msg, elapsed_time))
                    elif msg.type == 'note_off':
                        for note in self.active_notes:
                            if note.note == msg.note and note.active:
                                note.note_off(elapsed_time)
                                break
                    self.next_event_index += 1

                for note in self.active_notes[:]:
                    note.update(elapsed_time)
                    note.draw(self.screen)
                    if note.finished:
                        self.active_notes.remove(note)

            pygame.display.flip()
            self.clock.tick(60)

        pygame.quit()
        sys.exit()


if __name__ == '__main__':
    visualizer = Visualizer()
    visualizer.load_midi(MIDI_PATH)
    visualizer.setup()
    visualizer.main_loop()
