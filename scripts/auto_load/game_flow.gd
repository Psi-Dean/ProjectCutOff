extends Node

# 常量：游戏开始场景
const GAME_START_SCENE = "res://scenes/game_start_menu.tscn"
# 常量：游戏主场景
const GAME_PLAY_SCENE = "res://scenes/game_play_scene.tscn"
# 常量：游戏结束场景
const GAME_OVER_SCENE = "res://scenes/game_over_menu.tscn"
# 常量：玩家卡牌构筑场景
const GAME_DECK_BUILD_SCENE = "res://scenes/game_deck_build.tscn"

# 游戏结束结果标志
var game_result: String = ""

func switch_to_game_start_menu() -> void:
	get_tree().change_scene_to_file(GAME_START_SCENE)

func switch_to_game_play_scene() -> void:
	get_tree().change_scene_to_file(GAME_PLAY_SCENE)

func switch_to_game_over_menu(result: String) -> void:
	game_result = result
	get_tree().change_scene_to_file(GAME_OVER_SCENE)

func switch_to_game_deck_build_scene() -> void:
	get_tree().change_scene_to_file(GAME_DECK_BUILD_SCENE)
