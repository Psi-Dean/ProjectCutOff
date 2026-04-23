extends Control

func _on_start_button_pressed() -> void:
	GameFlow.switch_to_game_play_scene()


func _on_quit_button_pressed() -> void:
	get_tree().quit()
