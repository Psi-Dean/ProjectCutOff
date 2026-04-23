extends Control
@onready var game_over_label: Label = $GameOverLabel

func _ready() -> void:
	game_over_label.text = "游戏胜利！" if GameFlow.game_result == "win" else "游戏失败！"

func _on_restart_button_pressed() -> void:
	GameFlow.switch_to_game_play_scene()


func _on_back_button_pressed() -> void:
	GameFlow.switch_to_game_start_menu()
