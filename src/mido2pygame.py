import mido
import pygame
import sys

# Initialize pygame
pygame.init()

# Constants
WIDTH = 1920
HEIGHT = 1080
MIN_NOTE = 21   # A0 (first note on a standard 88-key piano)
MAX_NOTE = 108  # C8 (last note on a standard 88-key piano)
CIRCLE_SCALE = 0.5
FILE_NAME = "5th-Symphony-Part-1"

# Create the display surface
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption('MIDI Visualiser')

# Clock for controlling frame rate
clock = pygame.time.Clock()

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
    hue = remap(note, MIN_NOTE, MAX_NOTE, 0, 360)
    # Convert hue to RGB (pygame uses RGB)
    color = pygame.Color(0)
    color.hsva = (int(hue % 360), 100, 100, 100)  # Hue, Saturation, Value, Alpha
    return (color.r, color.g, color.b)

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
        self.x = remap(self.note, MIN_NOTE, MAX_NOTE, 0, WIDTH)
        self.y = HEIGHT / (num_tracks + 1) * (msg.channel + 1)
        self.size = remap(msg.velocity, 0, 127, 10, 50) * CIRCLE_SCALE
        self.color = note_to_color(self.note)
        self.opacity = 255  # Pygame uses 0-255 for alpha

    def note_off(self):
        """Handle the note-off event."""
        self.end_time = elapsed_time
        self.active = False

    def update(self):
        """Update the note's position and state."""
        if self.active:
            self.y -= 2  # Move upwards
        else:
            self.size = max(0, self.size - CIRCLE_SCALE)  # Shrink after note ends
            self.opacity = max(0, self.opacity - 10)  # Fade out
            if self.size <= 0 or self.opacity <= 0:
                self.finished = True

    def draw(self, surface):
        """Draw the note on the given surface."""
        if self.size <= 0 or self.opacity <= 0:
            return  # Skip drawing if the note is invisible
        s_size = int(self.size * 2)
        s = pygame.Surface((s_size, s_size), pygame.SRCALPHA)
        # Ensure color components are integers between 0 and 255
        color = (
            int(self.color[0]),
            int(self.color[1]),
            int(self.color[2]),
            int(self.opacity)
        )
        pygame.draw.circle(s, color, (s_size // 2, s_size // 2), int(self.size))
        surface.blit(s, (int(self.x - self.size), int(self.y - self.size)))

# Main function
def main():
    global start_time, elapsed_time, next_event_index, active_notes

    # Start time in milliseconds
    start_time = pygame.time.get_ticks()

    # Initialize pygame mixer and play the audio file
    pygame.mixer.music.load(f'wav/{FILE_NAME}.wav')  # Ensure this WAV file exists
    pygame.mixer.music.play()

    running = True
    while running:
        clock.tick(60)  # Limit to 60 FPS
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
            if msg.type == 'note_on' and msg.velocity > 0:
                active_notes.append(Note(msg))
            elif msg.type == 'note_off' or (msg.type == 'note_on' and msg.velocity == 0):
                for note in active_notes:
                    if note.note == msg.note and note.active:
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
    sys.exit()

if __name__ == '__main__':
    main()
