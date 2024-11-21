import mido
import p5
import pygame
import random

# Constants
WIDTH = 1920
HEIGHT = 1080
MIN_NOTE = 21   # A0 (first note on a standard 88-key piano)
MAX_NOTE = 108  # C8 (last note on a standard 88-key piano)
CIRCLE_SCALE = 1
FILE_NAME = "5th-Symphony-Part-1"

def note_to_color(note):
    """Map MIDI note number to a hue value for coloring."""
    hue = p5.remap(note, (MIN_NOTE, MAX_NOTE), (0, 360))
    return p5.Color(hue, 100, 100)

# Load MIDI file and extract messages as note events
mid = mido.MidiFile(f'midi/{FILE_NAME}.mid')
note_events = []
current_time = 0

for i, track in enumerate(mid.tracks):
    print(f"{i}: {track.name}")

for msg in mid:
    current_time += msg.time
    if msg.type in ['note_on', 'note_off']:
        note_events.append({'time': current_time, 'message': msg})

# Visualization variables
active_notes = []
next_event_index = 0
start_time = None
elapsed_time = 0
num_tracks = len(mid.tracks)

class Note:
    """Represents a musical note in the visualization."""
    def __init__(self, msg):
        self.note = msg.note
        self.start_time = elapsed_time
        self.end_time = None
        self.active = True
        self.finished = False
        self.x = p5.remap(self.note, (MIN_NOTE, MAX_NOTE), (0, WIDTH))
        self.y = HEIGHT / (num_tracks + 1) * (msg.channel + 1)
        self.size = p5.remap(msg.velocity, (0, 127), (10, 50))
        self.color = note_to_color(self.note)
        self.opacity = 1.0

    def note_off(self):
        """Handle the note-off event."""
        self.end_time = elapsed_time
        self.active = False

    def update(self):
        """Update the note's position and state."""
        if self.active:
            self.y -= 2  # Move upwards
        else:
            self.size -= 1  # Shrink after note ends
            self.opacity -= 0.1
            if self.size <= 0 or self.opacity <= 0:
                self.finished = True

    def draw(self):
        """Draw the note on the screen."""
        p5.fill(self.color, self.opacity)
        p5.no_stroke()
        p5.ellipse((self.x, self.y), self.size, self.size)

def setup():
    global start_time
    p5.size(WIDTH, HEIGHT)
    p5.color_mode('HSB', 360, 100, 100, 1.0)
    p5.background(0)
    # Initialize pygame mixer and play the audio file
    pygame.mixer.init()
    pygame.mixer.music.load(f'wav/{FILE_NAME}.wav')  # Ensure this WAV file exists
    pygame.mixer.music.play()
    start_time = p5.millis()

def draw():
    global start_time, elapsed_time, next_event_index, active_notes
    p5.background(0)
    elapsed_time = (p5.millis() - start_time) / 1000.0  # Convert to seconds

    # Process MIDI events in sync with the playback
    while next_event_index < len(note_events) and note_events[next_event_index]['time'] <= elapsed_time:
        event = note_events[next_event_index]
        msg = event['message']
        if msg.type == 'note_on':
            active_notes.append(Note(msg))
        elif msg.type == 'note_off':
            for note in active_notes:
                if note.note == msg.note and note.active:
                    note.note_off()
                    break
        next_event_index += 1

    # Update and draw active notes
    for note in active_notes[:]:
        note.update()
        note.draw()
        if note.finished:
            active_notes.remove(note)

    print(f"active notes: {len(active_notes)}", end='  \r')

p5.run()
