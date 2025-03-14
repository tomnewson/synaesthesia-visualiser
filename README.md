# Synaesthesia Visualiser

A project for visualising synaesthesia through audio and visual representations. Created as a third year project at the University of Manchester.

## Project Overview

This project aims to visualise sound-colour / sound-shape / sound-projective synaesthesia, transforming music of increasing complexity into visual representations of increasing complexity.

The project includes both Python scripts for audio processing and a Godot-based visualization engine with different modes:

- **Python - Single Track**: Visualises simple music with simple visuals
- **Python - Tracks**: Visualises multi-track music with simple visuals
- **Godot - Underwater**: Visualises simple music with 3D graphics
- **Godot - Main**: Visualises multi-track music with 3D graphics

## Running the Python Scripts

### Dependencies

3. /godot/midi/la_campanella.mid (if not already downloaded, source location is in midi_sources.csv)
4. /godot/midi/5th-Symphony-Part-1.mid (if not already downloaded, source location is in midi_sources.csv)

### Single Track Visualiser

To run the single track visualiser:

```bash
cd /path/to/synaesthesia_visualiser
python python/src/single_track.py
```

### Multi-Track Visualiser

To run the multi-track visualiser:

```bash
cd /path/to/synaesthesia_visualiser
python python/src/tracks.py
```

## Running the Godot Project as an executable
If there are executables within the godot_executables directory:
1. Select the exe/x86_64 for your system (Windows / Linux)
2. Run it.
3. Select the visualisation of a single track MIDI file (one piano) or of a multi track file (multiple instruments)
4. Enjoy!

## Running the Godot Project within the Godot Editor

### Dependencies

1. Godot Plugin - GUT (Godot Unit Tests) (found in /godot/addons)
2. Godot Plugin - Midi Player Addon (ArlezMidiPlayer) (found in /godot/addons)
3. /godot/midi/la_campanella.mid (if not already downloaded, source location is in midi_sources.csv)
4. /godot/midi/in_a_mellow_tone_djl.mid (if not already downloaded, source location is in midi_sources.csv)
5. /godot/data/Aspirin-Stereo.sf2 (if not already downloaded, source location is in sf_sources.csv)
6. /godot/data/Timbres of Heaven (XGM) 4.00(G).sf2 (if not already downloaded, source location is in sf_sources.csv)

To run the Godot project:

1. Install Godot 4.3 if you haven't already
2. Open Godot 4.3 and select "Import"
3. Navigate to the project directory and select the project.godot file
4. Once the project is loaded, you can run either of the following scenes:

### Main Scene

- This scene visualises multi-track music with 3D graphics
- To run: Click on the "main" scene in the project explorer and press F5 (or click the "Play" button)

### Underwater Scene

- This scene visualises simple music with 3D graphics
- To run: Click on the "underwater" scene in the project explorer and press F5 (or click the "Play" button)

## Features

- Real-time audio visualization
- Multiple visualization modes
- Support for both simple and multi-track audio processing
- 3D and 2D visual representations
