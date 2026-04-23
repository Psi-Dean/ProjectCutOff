extends Node

const GAME_START_SCENE = "res://scenes/game_start_menu.tscn"
const GAME_PLAY_SCENE = "res://scenes/game_play_scene.tscn"
const GAME_OVER_SCENE = "res://scenes/game_over_menu.tscn"

var game_result: String = ""
func switch_to_game_start_menu() -> void:
	get_tree().change_scene_to_file(GAME_START_SCENE)

func switch_to_game_play_scene() -> void:
	get_tree().change_scene_to_file(GAME_PLAY_SCENE)

func switch_to_game_over_menu(result: String) -> void:
	game_result = result
	get_tree().change_scene_to_file(GAME_OVER_SCENE)
