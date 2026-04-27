extends Control
@onready var card_pool_container: HBoxContainer = $CardPoolContainer


# 玩家牌库数据
var player_current_build: Array[CardData] = []
# 玩家选择牌库限制数量
var player_setup_limit: int = 16

func _ready() -> void:
	setup_card_deck_build()
	
func _on_confirm_build_button_pressed() -> void:
	RunData.player_deck_build = player_current_build
	GameFlow.switch_to_game_play_scene()

func setup_card_deck_build() -> void:
	if CardDatabase.basic_cards_deck.is_empty():
		return
	for card in CardDatabase.basic_cards_deck:
		var card_button = Button.new()
		card_button.text = card.card_title
		card_button.pressed.connect(_on_card_button_pressed.bind(card))
		card_pool_container.add_child(card_button)
		
func _on_card_button_pressed(card_data:CardData):
	if player_current_build.size() >= player_setup_limit:
		return
	player_current_build.append(card_data.duplicate(true))
	print("加入卡牌：",card_data.card_title)
