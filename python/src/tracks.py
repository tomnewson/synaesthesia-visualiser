import mido
import pygame
import math
import argparse
from chord_extractor.extractors import Chordino

pygame.init()

WIDTH = 1920
HEIGHT = 1080
MIN_NOTE = 21   # A0 (first note on a standard 88-key piano)
MAX_NOTE = 108  # C8 (last note on a standard 88-key piano)
DEFAULT_FILE = "messiaen_diptyque_part_I_(winitzki)"
FRAMERATE = 60
NOTE_TYPES = {'note_on', 'note_off'}

# SYNAESTHETIC MAPPINGS
# height increases with pitch
# brightness increases with pitch
# size decreases with pitch

# what should change with time? - atm size increases with time
# split tracks left to right
# fade/shrink out notes after they end

def remap(value, left_min, left_max, right_min, right_max):
    """Re-maps a number from one range to another."""
    # Avoid division by zero
    if left_max - left_min == 0:
        return right_min
    # Figure out how 'wide' each range is
    left_span = left_max - left_min
    right_span = right_max - right_min

    # Convert the left range into a 0-1 range (float)
    value_scaled = float(value - left_min) / float(left_span)

    # Convert the 0-1 range into a value in the right range
    return right_min + (value_scaled * right_span)

def note_to_color(note):
    """Map MIDI note number to an RGB color."""
    hue = remap(note, MAX_NOTE, MIN_NOTE, 0, 360)
    value = remap(note, MIN_NOTE, MAX_NOTE, 50, 100)

    color = pygame.Color(0)
    color.hsva = (hue, 100, value, 100)  # Hue, Saturation, Value, Alpha
    return color

class Note:
    """Represents a musical note in the visualization."""
    def __init__(self, msg, track):
        self.note = msg.note
        self.channel = msg.channel
        self.active = True
        self.finished = False
        self.x = remap(track or 0, 0, num_tracks-1, WIDTH * 0.1, WIDTH * 0.9)
        self.y = remap(self.note, MIN_NOTE, MAX_NOTE, HEIGHT, 0)
        self.size = remap(self.note, MIN_NOTE, MAX_NOTE, 50, 5)
        self.color = note_to_color(self.note)

    def note_off(self):
        self.active = False

    def update(self):
        if self.active:
            self.size += math.log10(self.size) * 0.2
            return

        self.size = max(0, self.size - 1)  # Shrink after note ends
        self.color.a = max(0, self.color.a - 10)  # Fade out
        if self.size <= 0 or self.color.a <= 0:
            self.finished = True

    def draw(self, surface):
        if self.size <= 0 or self.color.a <= 0:
            return  # Skip drawing if the note is invisible

        # Draw a shape (circle) with an alpha value
        # size is the radius of the circle
        shape_size = int(self.size * 2)
        shape_surface = pygame.Surface((shape_size, shape_size), pygame.SRCALPHA)
        pygame.draw.circle(shape_surface, self.color, (shape_size // 2, shape_size // 2), int(self.size))

        # Copy the shape onto the main surface
        surface.blit(shape_surface, (int(self.x - self.size), int(self.y - self.size)))

def generate_note_events(events: list, tracks: list):
    print(f"Extracting notes into {num_tracks} tracks...")
    current_time = 0
    note_events = []
    mid_length = len(events)

    for mid_i, mid_msg in enumerate(events):
        current_time += mid_msg.time
        if mid_msg.type not in NOTE_TYPES:
            continue

        print(f"Processing message {mid_i}/{mid_length}", end='     \r')

        # find matching event in tracks
        found = False
        for track_i in range(num_tracks):
            track = tracks[track_i]
            if mid_msg in track:
                note_events.append({'time': current_time, 'track': track_i, 'message': mid_msg})
                track.remove(mid_msg)
                found = True
                break

        if not found:
            # note events do not always belong to a track, but we can't just ignore them!
            # i think this only applies to note_off events
            note_events.append({'time': current_time, 'track': None, 'message': mid_msg})
    print()
    return note_events

parser = argparse.ArgumentParser()
parser.add_argument("--midi", type=str, default=DEFAULT_FILE, help="MIDI filename to load (without extension)")
args = parser.parse_args()
midi_file = f'../midi/{args.midi}.mid'

# Setup Chordino with one of several parameters that can be passed
chordino = Chordino(roll_on=1)

print("Preprocessing midi file...")
conversion_file_path = chordino.preprocess(midi_file)

# Load MIDI file and extract messages as note events
mid = mido.MidiFile(midi_file)
num_tracks = len(mid.tracks)

for i, track in enumerate(mid.tracks):
    print(f"Track {i}: {track.name} ({len(track)} messages)")

note_events = generate_note_events(list(mid), mid.tracks)

# Create the display surface
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption('MIDI Visualiser')

# Clock for controlling frame rate
clock = pygame.time.Clock()

active_notes = []
next_event_index = 0
start_time = None
elapsed_time = 0

def main():
    global start_time, elapsed_time, next_event_index, active_notes

    # Start time in milliseconds
    start_time = pygame.time.get_ticks()

    # Initialize pygame mixer and play the audio file
    pygame.mixer.music.load(conversion_file_path)
    pygame.mixer.music.play()

    running = True
    while running:
        clock.tick(FRAMERATE)
        elapsed_time = (pygame.time.get_ticks() - start_time) / 1000.0  # Convert to seconds

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
                break

        # Clear the screen
        screen.fill((0, 0, 0))

        # Process MIDI events in sync with the playback
        while next_event_index < len(note_events) and note_events[next_event_index]['time'] <= elapsed_time:
            event = note_events[next_event_index]
            msg = event['message']
            track = event['track']
            if msg.type == 'note_on' and msg.velocity > 0:
                active_notes.append(Note(msg, track))
            elif msg.type == 'note_off' or (msg.type == 'note_on' and msg.velocity == 0):
                for note in active_notes:
                    if note.note == msg.note and note.active and note.channel == msg.channel:
                        note.note_off()
                        break
            next_event_index += 1

        # Update and draw active notes
        for note in active_notes[:]:
            note.update()
            note.draw(screen)
            if note.finished:
                active_notes.remove(note)

        # Update the display
        pygame.display.flip()

        print(f"active notes: {len(active_notes)}", end='  \r')

    pygame.quit()

if __name__ == '__main__':
    main()
