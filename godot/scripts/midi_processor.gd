extends Node3D

@onready var midi_player = $ArlezMidiPlayer
@onready var environment: Environment = $WorldEnvironment.environment
@onready var overlay: MeshInstance3D = $ScreenReader
@onready var waves: MeshInstance3D = $Waves

const MAX_VELOCITY = 1000.0
const MAX_GUITAR_VELOCITY = 200.0
const MAX_STRINGS_VELOCITY = 100.0
const MAX_PIPE_VELOCITY = 100.0

const bg_transition_speed = 0.5
const dist_transition_speed = 0.8
const WAVES_TRANSITION_SPEED = 2.0
const BASE_WAVES_INTENSITY = 0.05

var active_notes = []
var target_bg_color: Color
var no_notes_played: bool
var target_dist_intensity: float

var target_waves_intensity: float
var target_waves_color: Color
var target_waves_alpha: float

var target_strings_speed: float
var target_strings_width: float
var target_strings_color: Color

var target_tess_speed: float
var target_tess_color: Color

var target_tadpole_amplitude: float # 0 to 1 - managed in Process
var target_tadpole_frequency: float # 0 to 1 - managed in Process
var target_tadpole_color: Color
#var target_tadpole_speed: float

var target_cube_speed: float # 0->1
var cube_speed: float = 0.0 # 0->1
var target_cube_color: Color
const CUBE_ROTATION_SPEED = 0.1;

enum Note {ID, TRACK, PITCH, VELOCITY, INSTRUMENT}

func lerp_between_colors(current_color: Color, target_color, transition_speed) -> Color:
	# TODO: FEAT better color transition
	var new_hue = lerp(current_color.h, target_color.h, transition_speed)
	var new_sat = lerp(current_color.s, target_color.s, transition_speed)
	var new_val = lerp(current_color.s, target_color.v, transition_speed)
	var new_alpha = lerp(current_color.a, target_color.a, transition_speed)
	
	return Color.from_hsv(new_hue, new_sat, new_val, new_alpha)

func reset_material(material: ShaderMaterial, base_intensity, base_color, base_transparency):
	material.set_shader_parameter("amplitude", BASE_WAVES_INTENSITY)
	material.set_shader_parameter("add_color", Color.TRANSPARENT)
	material.set_shader_parameter("alpha", 0.0)

func _ready() -> void:
	midi_player.play()
	no_notes_played = true
	
	environment.background_color = Color.BLACK
	target_bg_color = Color.BLACK
	
	target_dist_intensity = 0
	
	reset_material(waves.mesh.surface_get_material(0), BASE_WAVES_INTENSITY, Color.TRANSPARENT, 0.0)
	target_waves_color = Color.TRANSPARENT
	target_waves_intensity = BASE_WAVES_INTENSITY
	target_waves_alpha = 0;
	
	$Strings.mesh.material.set_shader_parameter("lineColor", Color.TRANSPARENT)
	target_strings_speed = 0.0
	target_strings_width = 0.0
	target_strings_color = Color.TRANSPARENT
	
	$Tesseract.color = Color.WHITE
	target_tess_speed = 0.0
	target_tess_color = Color.TRANSPARENT
	
	$Tadpole.mesh.material.set_shader_parameter("color", Color.TRANSPARENT)
	target_tadpole_color = Color.TRANSPARENT
	
	$CollapseCube.mesh.material.set_shader_parameter("albedo", Color.BLACK)
	$CollapseCube.mesh.material.set_shader_parameter("progress", 0.0)
	target_cube_color = Color.BLACK
	
func _process(delta):
	#if no_notes_played and target_bg_color != Color.BLACK:
		#environment.background_color = target_bg_color
		#no_notes_played = false
		
	# TODO: FIX lerp to properly transition according to delta
	
	update_background(delta)
	update_overlay_mat(delta)
	update_waves_mat(delta)
	update_strings_mat(delta)
	update_tadpole(delta)
	update_tesseract(delta)
	update_cube(delta)
	
func lerp_shader(mat: ShaderMaterial, param: String, target, speed: float, isColor: int = false):
	var current = mat.get_shader_parameter(param)
	mat.set_shader_parameter(
		param,
		lerp_between_colors(current, target, speed) if isColor else lerp(current, target, speed)
	)
	
func update_cube(delta):
	var cube_mat: ShaderMaterial = $CollapseCube.mesh.material
	var current_prog = cube_mat.get_shader_parameter("progress")
	cube_speed = lerp(cube_speed, target_cube_speed, WAVES_TRANSITION_SPEED * delta)
	var new_prog = current_prog + (0.02 * cube_speed)
	if new_prog >= 0.8:
		new_prog = 0.0
	cube_mat.set_shader_parameter("progress", new_prog)

	lerp_shader(
		cube_mat,
		"albedo",
		target_cube_color,
		WAVES_TRANSITION_SPEED * delta,
		true,
	)
	$CollapseCube.rotate_x(CUBE_ROTATION_SPEED * delta)
	$CollapseCube.rotate_y(CUBE_ROTATION_SPEED * delta)
	
func update_tadpole(delta):
	var tadpole_mat: ShaderMaterial = $Tadpole.mesh.material
	lerp_shader(
		tadpole_mat,
		"minAmplitude",
		0.05 + target_tadpole_amplitude / 10,
		WAVES_TRANSITION_SPEED * delta,
	)
	lerp_shader(
		tadpole_mat,
		"maxAmplitude",
		0.20 + target_tadpole_amplitude / 5,
		WAVES_TRANSITION_SPEED * delta,
	)
		
	lerp_shader(
		tadpole_mat,
		"minFrequency",
		1.0 + target_tadpole_frequency * (2.0),
		WAVES_TRANSITION_SPEED * delta,
	)
	lerp_shader(
		tadpole_mat,
		"maxFrequency",
		6.5 + target_tadpole_frequency * (3.0),
		WAVES_TRANSITION_SPEED * delta,
	)
	lerp_shader(
		tadpole_mat,
		"color",
		target_tadpole_color,
		WAVES_TRANSITION_SPEED * 0.5 * delta,
		true,
	)
	
func update_tesseract(delta):
	$Tesseract.speed = lerp($Tesseract.speed, target_tess_speed, WAVES_TRANSITION_SPEED * delta)
	#$Tesseract.scale = lerp($Tesseract.scale, Vector3(target_guitar_speed,target_guitar_speed,target_guitar_speed), WAVES_TRANSITION_SPEED * delta)
	#$Tesseract.rotate_z(0.01)
	$Tesseract.color = lerp_between_colors($Tesseract.color, target_tess_color, WAVES_TRANSITION_SPEED * delta)
	#print(target_strings_width)
	
func update_background(delta):
	var current_bg_colour = environment.background_color
	environment.background_color = lerp_between_colors(current_bg_colour, target_bg_color, bg_transition_speed * delta)
	
func update_overlay_mat(delta):
	var overlay_material: ShaderMaterial = overlay.mesh.surface_get_material(0)
	var current_dist_int = overlay_material.get_shader_parameter("distortion_intensity")
	var new_dist_int = lerp(current_dist_int, target_dist_intensity, dist_transition_speed * delta)
	overlay_material.set_shader_parameter("distortion_intensity", new_dist_int)
	
func update_waves_mat(delta):
	var waves_mat: ShaderMaterial = waves.mesh.surface_get_material(0)
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
	lerp_shader(
		waves_mat,
		"alpha",
		target_waves_alpha,
		WAVES_TRANSITION_SPEED * delta,
	)
	
func update_strings_mat(delta):
	var strings_mat: ShaderMaterial = $Strings.mesh.material
	#lerp_shader(
		#strings_mat,
		#"overallSpeed",
		#target_strings_speed,
		#WAVES_TRANSITION_SPEED * delta,
	#)
	lerp_shader(
		strings_mat,
		"width",
		target_strings_width,
		WAVES_TRANSITION_SPEED * delta,
	)
	lerp_shader(
		strings_mat,
		"lineColor",
		target_strings_color,
		WAVES_TRANSITION_SPEED * delta,
		true,
	)
	
func sigmoid(value: float, steepness: float, midpoint: float) -> float:
	return 1.0 / (1.0 + exp(-steepness * (value - midpoint)))
	
func color_from_notes(avg_pitch: float, sum_velocity: float, max_velocity: float, min_saturation: float, max_saturation: float, min_brightness: float, max_brightness: float) -> Color:
	var hue = sigmoid(avg_pitch, 0.2, 50)
	
	sum_velocity = clamp(sum_velocity, 0, max_velocity)
	var sat = remap(sum_velocity, 0, max_velocity, min_saturation, max_saturation)
	var brightness = remap(sum_velocity, 0, max_velocity, min_brightness, max_brightness)
	
	return Color.from_hsv(hue, sat, brightness)
	
enum {
	PITCH,
	VELOCITY,
	COUNT,
}

func update_active_notes():
	if active_notes.is_empty():
		target_dist_intensity = 0
		#target_bg_color = Color.BLACK
		set_waves_targets(0,0,0, MAX_PIPE_VELOCITY)
		set_strings_targets(0,0,0,MAX_GUITAR_VELOCITY)
		set_cube_targets(0,0,0,MAX_STRINGS_VELOCITY)
		return
		
	var instrument_stats = {"total": [0,0]}
	# clear instruments
	for i in Globals.InstrumentCategory.values():
		instrument_stats[i] = [0,0,0]
		
	for n in active_notes:
		var pitch = n[Note.PITCH]
		var velocity = n[Note.VELOCITY]
		var instrument = n[Note.INSTRUMENT]
		
		instrument_stats["total"][PITCH] += pitch
		instrument_stats["total"][VELOCITY] += velocity
		
		instrument_stats[instrument][PITCH] += pitch
		instrument_stats[instrument][VELOCITY] += velocity
		instrument_stats[instrument][COUNT] += 1
	
	var avg_pitch = instrument_stats["total"][PITCH] / len(active_notes)
	var clamped_sv = clamp(instrument_stats["total"][VELOCITY], 0, MAX_VELOCITY)
	
	# background
	target_bg_color = color_from_notes(avg_pitch, clamped_sv, MAX_VELOCITY, 0.2, 0.6, 0.4, 0.8)
	
	# distortion
	target_dist_intensity = clamped_sv / MAX_VELOCITY
	
	# waves - pipe
	var wave_instrument = instrument_stats[Globals.InstrumentCategory.PIPE]
	set_waves_targets(
		wave_instrument[PITCH],
		wave_instrument[VELOCITY],
		wave_instrument[COUNT],
		MAX_PIPE_VELOCITY, # manually change
	)
	
	# strings
	var strings_instrument = instrument_stats[Globals.InstrumentCategory.GUITAR]
	set_strings_targets(
		strings_instrument[PITCH],
		strings_instrument[VELOCITY],
		strings_instrument[COUNT],
		MAX_GUITAR_VELOCITY, # manually change
	)
	
	#var tadpole_instrument = instrument_stats[Globals.InstrumentCategory.STRINGS]
	#set_tadpole_targets(
		#tadpole_instrument[PITCH],
		#tadpole_instrument[VELOCITY],
		#strings_instrument[COUNT],
		#MAX_STRINGS_VELOCITY, # manually change
	#)
	
	var cube_instrument = instrument_stats[Globals.InstrumentCategory.STRINGS]
	set_cube_targets(
		cube_instrument[PITCH],
		cube_instrument[VELOCITY],
		cube_instrument[COUNT],
		MAX_STRINGS_VELOCITY, # manually change
	)
	
	# guitar
	#var guitar_velocity = clamp(instrument_stats[Globals.InstrumentCategory.GUITAR][VELOCITY], 0, MAX_GUITAR_VELOCITY)
	#target_tess_speed = 0.2 + (guitar_velocity / MAX_GUITAR_VELOCITY) * 2.0
	#var guitar_count = instrument_stats[Globals.InstrumentCategory.GUITAR][COUNT]
	#if !guitar_count:
		#target_tess_color = target_bg_color
		#target_tess_color.a = 0.0
	#else:
		#var guitar_avg_pitch = instrument_stats[Globals.InstrumentCategory.GUITAR][PITCH] / guitar_count
		#target_tess_color = color_from_notes(guitar_avg_pitch, guitar_velocity, MAX_GUITAR_VELOCITY, 0.3, 0.9, 0.6, 0.8)
		#target_tess_color.a = guitar_velocity / MAX_GUITAR_VELOCITY
		
func set_cube_targets(sum_pitch, sum_velocity, count, max_velocity):
	sum_velocity = clamp(sum_velocity, 0.0, max_velocity)
	target_cube_speed = sum_velocity / max_velocity
	if count:
		var avg_pitch = sum_pitch / count
		target_cube_color = color_from_notes(avg_pitch, sum_velocity, max_velocity, 0.3, 0.8, 0.3, 0.6)
	target_cube_color.a = 1.0
	#target_cube_color.a = 0.5 + (sum_velocity / max_velocity) / 2.0

func set_tadpole_targets(sum_pitch, sum_velocity, count, max_velocity):
	sum_velocity = clamp(sum_velocity, 0.0, max_velocity)
	target_tadpole_amplitude = sum_velocity / max_velocity
	if count:
		var avg_pitch = sum_pitch / count
		target_tadpole_color = color_from_notes(avg_pitch, sum_velocity, max_velocity, 0.3, 0.9, 0.6, 0.8)
		target_tadpole_frequency = sigmoid(avg_pitch, 0.2, 50)
	target_tadpole_color.a = 0.5 + (sum_velocity / max_velocity) / 2.0

func set_waves_targets(sum_pitch, velocity, count, max_velocity):
	target_waves_intensity = BASE_WAVES_INTENSITY + (clamp(velocity, 0, max_velocity) / max_velocity) / 3.0
	target_waves_alpha = clamp(velocity, 0.0, max_velocity) / max_velocity
	if count:
		var avg_waves_pitch = sum_pitch / count
		target_waves_color = color_from_notes(avg_waves_pitch, velocity, max_velocity, 0.3, 0.9, 0.6, 0.8)
		
func set_strings_targets(sum_pitch, sum_velocity, count, max_velocity):
	sum_velocity = clamp(sum_velocity, 0, max_velocity)
	target_strings_speed = sum_velocity / max_velocity
	if count:
		var avg_strings_pitch = sum_pitch / count
		target_strings_color = color_from_notes(avg_strings_pitch, sum_velocity, max_velocity, 0.3, 0.9, 0.6, 0.8)
		target_strings_width = 1.0 - sigmoid(avg_strings_pitch, 0.2, 50)
	target_strings_color.a = sum_velocity / max_velocity

func _on_midi_receiver_note_on(note_id, note, velocity, track, instrument) -> void:
	active_notes.append([note_id, track, note, velocity, instrument])
	update_active_notes()
	

func _on_midi_receiver_note_off(note_id, track) -> void:
	for n in active_notes:
		if n[Note.ID] == note_id:
			active_notes.erase(n)
			break
	update_active_notes()
