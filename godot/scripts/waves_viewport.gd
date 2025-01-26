@tool
extends SubViewport

@export var target_material: Material

func _ready():
	if Engine.is_editor_hint():
		# Force render in editor
		render_target_update_mode = SubViewport.UPDATE_ALWAYS
		size = get_viewport().size
		
		# Assign texture after 1 frame delay
		await get_tree().process_frame
		if target_material:
			var vt = ViewportTexture.new()
			vt.viewport_path = get_path()
			target_material.set_shader_parameter("waves_buffer", vt)
