import math
import sys
import mido
import pygame
import random
import colorsys

# Constants
WIDTH = 1920
HEIGHT = 1080
MIN_NOTE = 21    # A0
MAX_NOTE = 108   # C8
CIRCLE_SCALE = 1
FILE_NAME = "mario_raceway"

# --- Helper functions ---

def remap(value, left_min, left_max, right_min, right_max):
    """Linearly maps a value from one range to another."""
    # Figure out how 'wide' each range is
    left_span = left_max - left_min
    right_span = right_max - right_min

    # Convert the left range into a 0-1 range (float)
    value_scaled = float(value - left_min) / float(left_span)

    # Convert the 0-1 range into a value in the right range.
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


# --- MIDI Loading ---

# Load the MIDI file and extract note events (both note_on and note_off)
mid = mido.MidiFile(f'../midi/{FILE_NAME}.mid')
note_events = []
current_time = 0

# (Print track names for debugging)
for track in mid.tracks:
    print(track.name)

# Iterate over all messages in the MIDI file to get cumulative times
for msg in mid:
    current_time += msg.time
    # Convert note_on with velocity 0 to note_off
    if msg.type == 'note_on' and msg.velocity == 0:
        msg.type = 'note_off'
    if msg.type in ['note_on', 'note_off']:
        note_events.append({'time': current_time, 'message': msg})


# --- Visualization Variables ---

active_notes = []     # List of Note objects currently being drawn/updated
next_event_index = 0  # Index to the next note event to process
start_time = None     # Will be set when playback begins
elapsed_time = 0      # Seconds since playback started

# --- Note Class ---

class Note:
    """Represents a musical note in the visualization."""
    def __init__(self, msg):
        self.note = msg.note
        self.velocity = msg.velocity
        # Record when the note started (in seconds)
        self.start_time = elapsed_time
        self.end_time = None
        self.active = True
        self.finished = False

        # Compute the x-position (mapped from note value)
        self.x = note_to_axis(self.note, WIDTH)
        # For now, y is fixed to the middle of the screen
        self.y = HEIGHT / 2
        # Size is mapped from velocity (0-127) to a size between 10 and 50*CIRCLE_SCALE
        self.size = remap(self.velocity, 0, 127, 10, 50 * CIRCLE_SCALE)
        self.color = note_to_color(self.note)

    def note_off(self):
        """Handles the note-off event."""
        self.end_time = elapsed_time
        self.active = False

    def update(self):
        """Update the note's position and size."""
        if self.active:
            # Move the note upward while active.
            self.y -= 2
            self.size += math.log10(self.size) * 0.2
        else:
            # Once the note is off, let it shrink.
            self.size -= CIRCLE_SCALE
            self.size = max(0, self.size - 1)  # Shrink after note ends
            self.color.a = max(0, self.color.a - 10)  # Fade out

            if self.size <= 0 or  self.color.a <= 0:
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


# --- Setup and Main Loop ---

def setup():
    """Initialize pygame, the display, and start audio playback."""
    global screen, clock, start_time
    pygame.init()
    screen = pygame.display.set_mode((WIDTH, HEIGHT))
    pygame.display.set_caption("MIDI Visualization")
    clock = pygame.time.Clock()

    # Fill background with black
    screen.fill((0, 0, 0))

    # Initialize pygame mixer and load/play the WAV file
    pygame.mixer.init()
    pygame.mixer.music.load(f'wav/{FILE_NAME}.wav')  # Ensure this WAV file exists!
    pygame.mixer.music.play()

    # Record the starting time (in milliseconds)
    start_time = pygame.time.get_ticks()

def main():
    global elapsed_time, next_event_index, active_notes
    setup()
    running = True
    while running:
        # --- Event Handling ---
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False

        # --- Drawing / Updating ---
        # Clear the screen (background black)
        screen.fill((0, 0, 0))

        # Compute elapsed time in seconds since playback started
        elapsed_time = (pygame.time.get_ticks() - start_time) / 1000.0

        # Process any MIDI events that are scheduled up to the current time.
        while next_event_index < len(note_events) and note_events[next_event_index]['time'] <= elapsed_time:
            event_dict = note_events[next_event_index]
            msg = event_dict['message']
            if msg.type == 'note_on':
                active_notes.append(Note(msg))
            elif msg.type == 'note_off':
                # Find the matching active note and mark it as off.
                for note in active_notes:
                    if note.note == msg.note and note.active:
                        note.note_off()
                        break
            next_event_index += 1

        # Update and draw each active note.
        for note in active_notes[:]:
            note.update()
            note.draw(screen)
            if note.finished:
                active_notes.remove(note)

        pygame.display.flip()
        clock.tick(60)  # Aim for 60 frames per second

    pygame.quit()
    sys.exit()

if __name__ == '__main__':
    main()
