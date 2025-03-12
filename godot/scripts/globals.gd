extends Node

# Maps MIDI program numbers to general instrument categories
enum InstrumentCategory {
	UNKNOWN,
	PIANO,
	CHROMATIC_PERCUSSION,
	ORGAN,
	GUITAR,
	BASS,
	STRINGS,
	ENSEMBLE,
	BRASS,
	REED,
	PIPE,
	SYNTH,
	ETHNIC,
	PERCUSSIVE,
	SOUND_EFFECTS
}

# Apply sigmoid transformation to a value - for extenuating the differences between pitch
func sigmoid(value: float, val_min: float = 0.0, val_max: float = 127.0, steepness: float = 10.0) -> float:
	var normalised_value = clamp(value, val_min, val_max) / val_max - 0.5
	var sigmoid_value = 1.0 / (1.0 + exp(-normalised_value * steepness))
	return sigmoid_value * val_max
