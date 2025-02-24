import math
import threading
import pygame
import mido
import librosa
from chord_extractor.extractors import Chordino

# Constants (These can be overridden in subclasses)
WIDTH = 1920
HEIGHT = 1080
FRAMERATE = 60
MIN_NOTE = 21  # A0
MAX_NOTE = 108  # C8
NOTE_TYPES = {'note_on', 'note_off', 'program_change'}

class BaseVisualizer:
    """Base class for MIDI visualizers."""

    def __init__(self, midi_path):
        pygame.init()
        self.screen = pygame.display.set_mode((WIDTH, HEIGHT))
        pygame.display.set_caption("MIDI Visualization")
        self.clock = pygame.time.Clock()
        pygame.font.init()
        self.font = pygame.font.SysFont('Arial', 50)
        self.midi_path = midi_path
        self.note_events = []
        self.active_notes = []
        self.next_event_index = 0
        self.start_time = None
        self.offset = 0
        self.game_state = "loading"  # can be "loading", "ready", or "playing"
        self.audio_onset_time = 0
        self.conversion_file_path = None
        self.loading_thread = None
        self.num_channels = 1
        self.max_channel = 0

    def load_midi(self):
        """Load the MIDI file and extract note events."""
        mid = mido.MidiFile(self.midi_path)
        current_time = 0
        for track in mid.tracks:
            print(track.name)
        for msg in mid:
            current_time += msg.time
            if msg.type not in NOTE_TYPES:
                continue
            if msg.type == 'note_on' and msg.velocity == 0:
                msg = mido.Message('note_off', note=msg.note, channel=msg.channel)
            self.note_events.append({'time': current_time, 'message': msg})
            if hasattr(msg, 'channel'):
                self.max_channel = max(self.max_channel, msg.channel)

        self.num_channels = self.max_channel + 1
        print(f"Number of channels: {self.num_channels}")

    def setup(self):
        """Initialize pygame, the display, and audio playback."""
        self.screen.fill((0, 0, 0))
        self.loading_thread = threading.Thread(target=self.background_load)
        self.loading_thread.start()

    def background_load(self):
        """Load resources in background."""
        chordino = Chordino(roll_on=1)

        print("Converting midi to wav...")
        self.conversion_file_path = chordino.preprocess(self.midi_path)

        print("Calculating wav/midi offset...")
        y, sr = librosa.load(self.conversion_file_path)
        onset_env = librosa.onset.onset_strength(y=y, sr=sr)
        onset_frames = librosa.onset.onset_detect(onset_envelope=onset_env, sr=sr)
        self.audio_onset_time = librosa.frames_to_time(onset_frames[0], sr=sr) if len(onset_frames) > 0 else 0

        midi_onset_time = next((event['time'] for event in self.note_events if event['message'].type == 'note_on'), 0) if self.note_events else 0
        self.offset = self.audio_onset_time - midi_onset_time
        print(f"wav/midi offset: {self.offset:.3f}s")

        pygame.mixer.init()
        pygame.mixer.music.load(self.conversion_file_path)
        self.game_state = "ready"  # Switch to ready state when loading is complete

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

            if self.game_state == "loading":
                # Display loading message
                text_surface = self.font.render('Loading...', True, (255, 255, 255))
                text_rect = text_surface.get_rect(center=(WIDTH // 2, HEIGHT // 2))
                self.screen.blit(text_surface, text_rect)
            elif self.game_state == "ready":
                text_surface = self.font.render('Ready, press ENTER to play', True, (255, 255, 255))
                text_rect = text_surface.get_rect(center=(WIDTH // 2, HEIGHT // 2))
                self.screen.blit(text_surface, text_rect)
            elif self.game_state == "playing":
                elapsed_time = (pygame.time.get_ticks() - self.start_time) / 1000.0

                while self.next_event_index < len(self.note_events) and \
                        self.note_events[self.next_event_index]['time'] + self.offset <= elapsed_time:
                    event = self.note_events[self.next_event_index]
                    msg = event['message']
                    if msg.type == 'note_on':
                        self.active_notes.append(self.create_note(msg, elapsed_time))
                    elif msg.type == 'note_off':
                        for note in self.active_notes:
                            if hasattr(note, 'note') and note.note == msg.note and hasattr(note, 'channel') and note.channel == msg.channel and note.active:
                                note.note_off(elapsed_time)
                                break
                            elif hasattr(note, 'note') and note.note == msg.note and note.active:
                                note.note_off(elapsed_time)
                                break
                    self.next_event_index += 1

                for note in self.active_notes[:]:
                    note.update(elapsed_time)
                    note.draw(self.screen)
                    if note.finished:
                        self.active_notes.remove(note)

            pygame.display.flip()
            self.clock.tick(FRAMERATE)

        pygame.quit()

    def create_note(self, msg, elapsed_time):
        """Factory method to create a Note object.  To be implemented by subclasses."""
        raise NotImplementedError("Subclasses must implement create_note method")

class Note:
    """Represents a musical note in the visualization."""

    def __init__(self, msg, elapsed_time, scale):
        self.note = msg.note
        self.start_time = elapsed_time
        self.end_time = None
        self.active = True
        self.finished = False
        self.size = self.sigmoid_remap(msg.note, MIN_NOTE, MAX_NOTE, scale * 50, 10)

    # --- Helper functions ---

    def remap(self, value, left_min, left_max, right_min, right_max):
        """Linearly maps a value from one range to another."""
        left_span = left_max - left_min
        right_span = right_max - right_min
        value_scaled = float(value - left_min) / float(left_span)
        return right_min + (value_scaled * right_span)

    # Function to apply sigmoid remap with variable input and output ranges
    def sigmoid_remap(self, value: float,
        input_min: float, input_max: float,
        output_min: float, output_max: float,
        k: float = 1) -> float:
        """Apply a sigmoid remap to a value with variable input and output ranges."""
        normalized_value = (value - input_min) / (input_max - input_min)

        centered = normalized_value - 0.5
        sigmoid_value = 1.0 / (1.0 +   math.exp(-k * centered * 10.0))

        return output_min + (sigmoid_value * (output_max - output_min))


    def note_to_axis(self, note, max_val, note_size, ascending=True):
        """Map MIDI note number to an axis position on the screen."""
        if ascending:
            return self.sigmoid_remap(note, MIN_NOTE, MAX_NOTE, 0, max_val - note_size)
        return self.sigmoid_remap(note, MIN_NOTE, MAX_NOTE, max_val - note_size, 0)


    def note_to_color(self, note):
        """Map a MIDI note number to a color.

        Converts an HSB (with hue in [0,360]) color to an RGB tuple.
        """
        hue = self.sigmoid_remap(note, MIN_NOTE, MAX_NOTE, 0, 360)
        color = pygame.Color(0)
        hue = self.shift(hue, 140, 360)
        color.hsva = (hue, 100, 100, 100)  # Hue, Saturation, Value, Alpha
        return color

    def note_off(self, elapsed_time):
        """Handles the note-off event."""
        self.end_time = elapsed_time
        self.active = False

    def shift(self, val, shift, shift_max):
        """Shifts the value by some degrees, wrapping around at max."""
        return (val + shift) % shift_max

    def update(self, elapsed_time):
        """Update the note's position and size."""
        raise NotImplementedError("Subclasses must implement update method")

    def draw(self, surface):
        """Draw the note on the surface."""
        raise NotImplementedError("Subclasses must implement draw method")
