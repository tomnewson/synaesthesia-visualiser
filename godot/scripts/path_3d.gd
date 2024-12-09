@tool
extends Path3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_note_on(position: Vector3):
	self.curve.add_point(position)

func _on_note_off(index: int):
	self.curve.remove_point(index)
