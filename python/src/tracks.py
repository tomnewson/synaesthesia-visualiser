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
DEFAULT_FILE = "../godot/midi/5th-Symphony-Part-1.mid"
FRAMERATE = 60
NOTE_TYPES = {'note_on', 'note_off', 'program_change'}

GM_INSTRUMENTS = [
    "Acoustic Grand Piano", "Bright Acoustic Piano", "Electric Grand Piano", "Honky-tonk Piano",
    "Electric Piano 1", "Electric Piano 2", "Harpsichord", "Clavinet",
    "Celesta", "Glockenspiel", "Music Box", "Vibraphone",
    "Marimba", "Xylophone", "Tubular Bells", "Dulcimer",
    "Drawbar Organ", "Percussive Organ", "Rock Organ", "Church Organ",
    "Reed Organ", "Accordion", "Harmonica", "Tango Accordion",
    "Acoustic Guitar (nylon)", "Acoustic Guitar (steel)", "Electric Guitar (jazz)", "Electric Guitar (clean)",
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
    def __init__(self, msg):
        self.note = msg.note
        self.channel = msg.channel
        self.active = True
        self.finished = False
        self.x = remap(msg.channel or 0, 0, num_channels-1, WIDTH * 0.1, WIDTH * 0.9)
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

def generate_note_events(events: list):
    current_time = 0
    note_events = []
    max_channel = 0

    for mid_msg in events:
        current_time += mid_msg.time
        if mid_msg.type not in NOTE_TYPES:
            continue

        if mid_msg.type == 'note_on' and mid_msg.velocity == 0:
            mid_msg = mido.Message('note_off', note=mid_msg.note, channel=mid_msg.channel)

        note_events.append({'time': current_time, 'message': mid_msg})
        max_channel = max(max_channel, mid_msg.channel)

    print()
    return note_events, max_channel

parser = argparse.ArgumentParser()
parser.add_argument("--midi", type=str, default=DEFAULT_FILE, help="MIDI path")
args = parser.parse_args()
midi_file = args.midi

# Setup Chordino with one of several parameters that can be passed
chordino = Chordino(roll_on=1)

print("Preprocessing midi file...")
conversion_file_path = chordino.preprocess(midi_file)

# Load MIDI file and extract messages as note events
mid = mido.MidiFile(midi_file)

for i, track in enumerate(mid.tracks):
    print(f"Track {i}: {track.name} ({len(track)} messages)")

note_events, max_channel = generate_note_events(list(mid))
num_channels = max_channel + 1

print(f"Number of channels: {num_channels}")

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
            if msg.type == 'program_change':
                print(f"Channel {msg.channel}, instrument: {GM_INSTRUMENTS[msg.program]}")

            if msg.type == 'note_off' or (msg.type == 'note_on' and msg.velocity == 0):
                for note in active_notes:
                    if note.note == msg.note and note.active and note.channel == msg.channel:
                        note.note_off()
                        break
            elif msg.type == 'note_on':
                active_notes.append(Note(msg))
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
