extends Control



func _on_button_pressed() -> void:
	Global.is_gameover = false
	Global.is_gamewon = false
	get_tree().reload_current_scene()

