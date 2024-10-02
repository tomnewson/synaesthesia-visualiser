import mido

mid = mido.MidiFile('midi/mario_raceway.mid')
for i, track in enumerate(mid.tracks):
    print(f'Track {i}: {track.name}')
