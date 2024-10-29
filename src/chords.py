from chord_extractor.extractors import Chordino
import argparse
import pygame
import mido

WIDTH = 1920
HEIGHT = 1080
MIN_NOTE = 21   # A0 (first note on a standard 88-key piano)
MAX_NOTE = 108  # C8 (last note on a standard 88-key piano)
NOTE_TYPES = {'note_on', 'note_off'}
DEFAULT_MIDI_FILE = "midi/messiaen_diptyque_part_I_(winitzki).mid"
FRAMERATE = 60

def remap(value, left_min, left_max, right_min, right_max):
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
    hue = remap(note, MIN_NOTE, MAX_NOTE, 0, 360)
    # Convert hue to RGB (pygame uses RGB)
    color = pygame.Color(0)
    color.hsva = (int(hue % 360), 100, 100, 100)  # Hue, Saturation, Value, Alpha
    return (color.r, color.g, color.b)

def is_note_on(msg):
    return msg.type == 'note_on' and msg.velocity > 0

def is_note_off(msg):
    return msg.type == 'note_off' or (msg.type == 'note_on' and msg.velocity == 0)

class Note:
    def __init__(self, msg, track):
        self.note = msg.note
        self.track = track
        self.start_time = elapsed_time
        self.active = True
        self.x = remap(self.note, MIN_NOTE, MAX_NOTE, 0, WIDTH)
        self.y = remap(track, 0, num_tracks, 0, HEIGHT)
        self.size = remap(msg.velocity, 0, 127, 10, 50)
        self.color = note_to_color(self.note)
        self.opacity = 255

    def note_off(self):
        self.active = False

    def draw(self, screen):
        if self.active == False:
            return
        pygame.draw.circle(screen, self.color, (int(self.x), int(self.y)), int(self.size))

parser = argparse.ArgumentParser()
parser.add_argument("--midi_path", type=str, default=DEFAULT_MIDI_FILE, help="Path to the MIDI file to extract chords from")
args = parser.parse_args()

# Setup Chordino with one of several parameters that can be passed
chordino = Chordino(roll_on=1)

print("Preprocessing midi file...")
conversion_file_path = chordino.preprocess(args.midi_path)

# Run extraction
# print("Extracting chords...")
# chords = chordino.extract(conversion_file_path)

mid = mido.MidiFile(args.midi_path) # parse midi file
num_tracks = len(mid.tracks)
note_events = []

# time is relative to the note before it
# in the context of the entire midi file
# not per track
# so how can i get an accurate time for each note, whilst splitting them by track?

print(f"Extracting notes into {num_tracks} tracks...")
current_time = 0
mid_length = len(list(mid))
for mid_i, mid_msg in enumerate(mid):
    current_time += mid_msg.time
    if mid_msg.type not in NOTE_TYPES:
        continue

    print(f"processing message {mid_i}/{mid_length}", end='     \r')

    for track_i in range(num_tracks):
        for track_msg_i, track_msg in enumerate(mid.tracks[track_i]):
            if mid_msg == track_msg:
                note_events.append({'time': current_time, 'track': track_i, 'message': mid_msg})
                mid.tracks[track_i].pop(track_msg_i)
                break

print("Initialising pygame...")
pygame.init()

screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption('MIDI Visualiser')

pygame.mixer.music.load(conversion_file_path)
pygame.mixer.music.play()

clock = pygame.time.Clock()
start_time = pygame.time.get_ticks() # in ms
elapsed_time = 0
active_notes = []
next_event_index = 0

running = True
while running:
    clock.tick(FRAMERATE)
    elapsed_time = (pygame.time.get_ticks() - start_time) / 1000 # convert to seconds
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False
            break

    screen.fill((0, 0, 0))

    # Process MIDI events in sync with the playback
    while next_event_index < len(note_events) and note_events[next_event_index]['time'] <= elapsed_time:
        event = note_events[next_event_index]
        msg = event['message']
        track = event['track']
        if is_note_on(msg):
            active_notes.append(Note(msg, track))
        else:
            for note in active_notes:
                if note.active and note.note == msg.note:
                    note.note_off()
                    break
        next_event_index += 1

    # Update and draw active notes
    for note in active_notes[:]:
        note.draw(screen)
        if not note.active:
            active_notes.remove(note)

    pygame.display.flip()
    print(f"active notes: {len(active_notes)}", end='  \r')

pygame.quit()

