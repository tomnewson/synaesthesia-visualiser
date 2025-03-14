extends Control

func _on_main_button_pressed() -> void:
    # Change to the "main" scene
    get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_underwater_button_pressed() -> void:
    # Change to the "underwater" scene
    get_tree().change_scene_to_file("res://scenes/underwater.tscn")
