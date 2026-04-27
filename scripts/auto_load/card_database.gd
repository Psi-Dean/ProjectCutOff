extends Node

# 基础卡池（从资源目录加载）。
var basic_cards_deck: Array[CardData] = []

func _ready() -> void:
	load_card_resources()

# 从资源目录加载所有卡牌资源到基础卡池。
func load_card_resources() -> void:
	var cards_path = "res://resources/cards/"
	var files = DirAccess.get_files_at(cards_path)
	files.sort()
	for file_name in files:
		if file_name.ends_with(".tres"):
			var card_res_path = cards_path.path_join(file_name)
			var data = load(card_res_path)
			if data is CardData:
				basic_cards_deck.append(data)
