extends Node3D

@onready var midi_player = $ArlezMidiPlayer
@onready var environment: Environment = $WorldEnvironment.environment
@onready var overlay: MeshInstance3D = $ScreenReader
@onready var waves: MeshInstance3D = $Waves
@onready var light: SpotLight3D = $SpotLight3D
@onready var strings: MeshInstance3D = $Strings
@onready var top_waves: MeshInstance3D = $TopWaves

const MAX_VELOCITY = 1000.0
const MAX_VELOCITIES = {
	Globals.InstrumentCategory.GUITAR: 300.0,
	Globals.InstrumentCategory.PIPE: 100.0,
	Globals.InstrumentCategory.PERCUSSIVE: 100.0,
	Globals.InstrumentCategory.BASS: 100.0, # TEMP
}

const INSTRUMENT_MAP = {
	"waves": Globals.InstrumentCategory.PIPE,
	"strings": Globals.InstrumentCategory.GUITAR,
	"light": Globals.InstrumentCategory.PERCUSSIVE,
	"top_waves": Globals.InstrumentCategory.BASS,
}

const BASE_WAVES_INTENSITY = 0.1
const BASE_LIGHT_POSITION = Vector3(0, 1.5, 1.0)
const BASE_LIGHT_ENERGY = 1.0

const BG_TRANSITION_SPEED = 0.5
const WAVES_TRANSITION_SPEED = 2.0
const STRINGS_TRANSITION_SPEED = 2.0
const LIGHT_TRANSITION_SPEED = 2.3

const MAX_PITCH = 127.0

var active_notes = []
var target_bg_color: Color
var no_notes_played: bool

var target_waves_intensity: float
var target_waves_color: Color

var target_top_waves_intensity: float
var target_top_waves_color: Color

var target_strings_width: float
var target_strings_color: Color

var target_light_position: Vector3
var target_light_energy: float

enum Note {ID, TRACK, PITCH, VELOCITY, INSTRUMENT}
enum Instrument {PITCH, VELOCITY, COUNT}

func lerp_between_colors(current_color: Color, target_color, transition_speed) -> Color:
	# TODO: FEAT better color transition
	var new_hue = lerp(current_color.h, target_color.h, transition_speed)
	var new_sat = lerp(current_color.s, target_color.s, transition_speed)
	var new_val = lerp(current_color.s, target_color.v, transition_speed)
	var new_alpha = lerp(current_color.a, target_color.a, transition_speed)

	return Color.from_hsv(new_hue, new_sat, new_val, new_alpha)

func reset_waves():
	var material = waves.mesh.material
	material.set_shader_parameter("amplitude", BASE_WAVES_INTENSITY)
	material.set_shader_parameter("add_color", Color.TRANSPARENT)
	material.set_shader_parameter("alpha", 0.0)

	target_waves_color = Color.TRANSPARENT
	target_waves_intensity = BASE_WAVES_INTENSITY

func reset_top_waves():
	var material = top_waves.mesh.material
	material.set_shader_parameter("amplitude", BASE_WAVES_INTENSITY)
	material.set_shader_parameter("add_color", Color.TRANSPARENT)
	material.set_shader_parameter("alpha", 0.0)

	target_top_waves_color = Color.TRANSPARENT
	target_top_waves_intensity = BASE_WAVES_INTENSITY

func reset_strings():
	strings.mesh.material.set_shader_parameter("lineColor", Color.TRANSPARENT)
	target_strings_width = 0.0
	target_strings_color = Color.TRANSPARENT

func reset_light():
	light.transform.origin = BASE_LIGHT_POSITION
	target_light_position = BASE_LIGHT_POSITION
	light.light_energy = BASE_LIGHT_ENERGY
	target_light_energy = BASE_LIGHT_ENERGY

func _ready() -> void:
	midi_player.play()
	no_notes_played = true

	environment.background_color = Color.BLACK
	target_bg_color = Color.BLACK

	reset_waves()
	reset_strings()
	reset_light()
	reset_top_waves()

func _process(delta):
	# TODO: FIX lerp to properly transition according to delta
	update_background(delta)
	update_waves_mat(delta)
	update_strings_mat(delta)
	update_light(delta)
	update_top_waves(delta)

func lerp_shader(mat: ShaderMaterial, param: String, target, speed: float, isColor: int = false):
	var current = mat.get_shader_parameter(param)
	mat.set_shader_parameter(
		param,
		lerp_between_colors(current, target, speed) if isColor else lerp(current, target, speed)
	)

func update_light(delta):
	var current_pos = light.transform.origin
	light.transform.origin = lerp(current_pos, target_light_position, LIGHT_TRANSITION_SPEED * delta)
	var current_energy = light.light_energy
	light.light_energy = lerp(current_energy, target_light_energy, LIGHT_TRANSITION_SPEED * delta)

func update_background(delta):
	var current_bg_colour = environment.background_color
	environment.background_color = lerp_between_colors(current_bg_colour, target_bg_color, BG_TRANSITION_SPEED * delta)

func update_top_waves(delta):
	var material: ShaderMaterial = top_waves.mesh.material
	lerp_shader(
		material,
		"amplitude",
		target_top_waves_intensity,
		WAVES_TRANSITION_SPEED * delta,
	)
	lerp_shader(
		material,
		"add_color",
		target_top_waves_color,
		WAVES_TRANSITION_SPEED * delta,
		true
	)

func update_waves_mat(delta):
	var waves_mat: ShaderMaterial = waves.mesh.material
	lerp_shader(
		waves_mat,
		"amplitude",
		target_waves_intensity,
		WAVES_TRANSITION_SPEED * delta,
	)
	lerp_shader(
		waves_mat,
		"add_color",
		target_waves_color,
		WAVES_TRANSITION_SPEED * delta,
		true
	)

func update_strings_mat(delta):
	var strings_mat: ShaderMaterial = strings.mesh.material
	lerp_shader(
		strings_mat,
		"width",
		target_strings_width,
		STRINGS_TRANSITION_SPEED * delta,
	)
	lerp_shader(
		strings_mat,
		"lineColor",
		target_strings_color,
		STRINGS_TRANSITION_SPEED * delta,
		true,
	)

func color_from_notes(
	avg_pitch: float,
	sum_velocity: float,
	max_velocity: float,
	min_saturation: float = 0.3,
	max_saturation: float = 0.8,
	min_brightness: float = 0.6,
	max_brightness: float = 0.8,
) -> Color:
	var hue = avg_pitch / MAX_PITCH

	sum_velocity = clamp(sum_velocity, 0, max_velocity)
	var sat = remap(sum_velocity, 0, max_velocity, min_saturation, max_saturation)
	var brightness = remap(sum_velocity, 0, max_velocity, min_brightness, max_brightness)

	return Color.from_hsv(hue, sat, brightness)

func update_active_notes():
	if active_notes.is_empty():
		set_waves_targets(0, 0, 0)
		set_strings_targets(0, 0, 0)
		set_light_targets(0, 0, 0)
		return

	var instrument_stats = {"total": [0, 0]}
	# clear instruments
	for i in Globals.InstrumentCategory.values():
		instrument_stats[i] = [0, 0, 0]

	for n in active_notes:
		var pitch = n[Note.PITCH]
		var velocity = n[Note.VELOCITY]
		var instrument = n[Note.INSTRUMENT]

		instrument_stats["total"][Instrument.PITCH] += pitch
		instrument_stats["total"][Instrument.VELOCITY] += velocity

		instrument_stats[instrument][Instrument.PITCH] += pitch
		instrument_stats[instrument][Instrument.VELOCITY] += velocity
		instrument_stats[instrument][Instrument.COUNT] += 1

	var avg_pitch = instrument_stats["total"][Instrument.PITCH] / len(active_notes)
	var clamped_sv = clamp(instrument_stats["total"][Instrument.VELOCITY], 0, MAX_VELOCITY)

	# background
	target_bg_color = color_from_notes(avg_pitch, clamped_sv, MAX_VELOCITY)

	# waves
	var wave_instrument = instrument_stats[INSTRUMENT_MAP["waves"]]
	set_waves_targets(
		wave_instrument[Instrument.PITCH],
		wave_instrument[Instrument.VELOCITY],
		wave_instrument[Instrument.COUNT],
	)

	# strings
	var strings_instrument = instrument_stats[INSTRUMENT_MAP["strings"]]
	set_strings_targets(
		strings_instrument[Instrument.PITCH],
		strings_instrument[Instrument.VELOCITY],
		strings_instrument[Instrument.COUNT],
	)

	# light
	var light_instrument = instrument_stats[INSTRUMENT_MAP["light"]]
	set_light_targets(
		light_instrument[Instrument.PITCH],
		light_instrument[Instrument.VELOCITY],
		light_instrument[Instrument.COUNT],
	)

	# top waves
	var top_waves_instrument = instrument_stats[INSTRUMENT_MAP["top_waves"]]
	print("top waves velocity: ", top_waves_instrument[Instrument.VELOCITY])
	set_top_waves_targets(
		top_waves_instrument[Instrument.PITCH],
		top_waves_instrument[Instrument.VELOCITY],
		top_waves_instrument[Instrument.COUNT],
	)



func set_top_waves_targets(sum_pitch, velocity, count):
	var max_velocity = MAX_VELOCITIES[INSTRUMENT_MAP["top_waves"]]
	target_top_waves_intensity = BASE_WAVES_INTENSITY + (clamp(velocity, 0, max_velocity) / max_velocity) / 3.0

	var alpha = remap(velocity, 0, max_velocity, 0.0, 0.5)
	var sat = remap(velocity, 0, max_velocity, 0.5, 0.8)
	var val = remap(velocity, 0, max_velocity, 0.6, 0.8)
	var hue
	if count:
		var avg_waves_pitch = sum_pitch / count
		hue = avg_waves_pitch / MAX_PITCH
	else:
		hue = target_top_waves_color.h

	target_top_waves_color = Color.from_hsv(hue, sat, val, alpha)

func set_light_targets(sum_pitch, velocity, count):
	var max_velocity = MAX_VELOCITIES[INSTRUMENT_MAP["light"]]
	target_light_energy = remap(velocity, 0, max_velocity, BASE_LIGHT_ENERGY, 8.0)

	if (count == 0):
		target_light_position = BASE_LIGHT_POSITION
	else:
		var target_x = remap(sum_pitch / count, 0, MAX_PITCH, -2.5, 2.5)
		target_light_position = Vector3(target_x, BASE_LIGHT_POSITION.y, BASE_LIGHT_POSITION.z)

func set_waves_targets(sum_pitch, velocity, count):
	var max_velocity = MAX_VELOCITIES[INSTRUMENT_MAP["waves"]]
	target_waves_intensity = BASE_WAVES_INTENSITY + (clamp(velocity, 0, max_velocity) / max_velocity) / 3.0

	var sat = remap(velocity, 0, max_velocity, 0.5, 0.8)
	var val = remap(velocity, 0, max_velocity, 0.6, 0.8)
	var hue
	if count:
		var avg_waves_pitch = sum_pitch / count
		hue = avg_waves_pitch / MAX_PITCH
	else:
		hue = target_waves_color.h

	target_waves_color = Color.from_hsv(hue, sat, val)

func set_strings_targets(sum_pitch, sum_velocity, count):
	var max_velocity = MAX_VELOCITIES[INSTRUMENT_MAP["strings"]]
	sum_velocity = clamp(sum_velocity, 0, max_velocity)
	target_strings_width = remap(sum_velocity, 0, max_velocity, 0.2, 0.5)

	var alpha = sum_velocity / max_velocity
	var sat = remap(sum_velocity, 0, max_velocity, 0.5, 0.8)
	var val = remap(sum_velocity, 0, max_velocity, 0.6, 0.8)
	var hue
	if count:
		var avg_pitch = sum_pitch / count
		hue = avg_pitch / MAX_PITCH
	else:
		hue = target_strings_color.h
	target_strings_color = Color.from_hsv(hue, sat, val, alpha)

func _on_midi_receiver_note_on(note_id, note, velocity, track, instrument) -> void:
	var sigmoided_note = Globals.sigmoid(note)
	active_notes.append([note_id, track, sigmoided_note, velocity, instrument])
	update_active_notes()

func _on_midi_receiver_note_off(note_id, track) -> void:
	for n in active_notes:
		if n[Note.ID] == note_id:
			active_notes.erase(n)
			break
	update_active_notes()
