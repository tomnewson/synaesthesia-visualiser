@tool
extends MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var viewport = $"../WavesViewport"

	# Explicitly wait for viewport to render
	await get_tree().process_frame
	var overlay_material: ShaderMaterial = self.mesh.surface_get_material(0)
	overlay_material.set_shader_parameter("waves_buffer", viewport.get_texture())

	# Ensure texture filtering
	#viewport.get_texture().flags = Texture2D.FLAG_FILTER


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
