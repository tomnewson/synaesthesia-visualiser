import mido, p5

WIDTH = 1920
HEIGHT = 1080
STARTING_X_POS = 0
STARTING_MSG = 0
X_INCREMENT = 10
ELLIPSE_BASE_WIDTH = 100
ELLIPSE_BASE_HEIGHT = 100

def setup():
    p5.size(WIDTH, HEIGHT)

def draw():
    global x_pos
    global notes
    global current_message

    msg = notes[current_message]
    print(msg)

    p5.background(204)
    p5.fill(msg.note % 255, 0, 0)
    p5.ellipse((x_pos, msg.velocity % HEIGHT + HEIGHT/2), ELLIPSE_BASE_WIDTH, ELLIPSE_BASE_HEIGHT + msg.time % ELLIPSE_BASE_HEIGHT)

    x_pos += X_INCREMENT
    current_message += 1

    if x_pos > WIDTH:
        x_pos = STARTING_X_POS
    if current_message >= len(notes):
        current_message = STARTING_MSG

get_note_ons = lambda track: list(filter(lambda message: message.type == 'note_on', track))

x_pos = STARTING_X_POS
mid = mido.MidiFile('midi/mario_raceway.mid')
notes = get_note_ons(mid.tracks[1])
current_message = STARTING_MSG

p5.run()
