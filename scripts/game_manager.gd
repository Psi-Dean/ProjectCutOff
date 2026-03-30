extends Node
@onready var price_label: Label = $"../UI/PriceLabel"
@onready var test_button: Button = $"../UI/TestButton"
var CardsData = preload("res://scripts/cards_data.gd")
var current_price:float = 100.00
var is_gameover:bool = false


var basic_cards_deck = CardsData.BASIC_CARDS
var cards_limited = 6
var player_cards = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(cards_limited):
		var random_cards = randi_range(0, basic_cards_deck.size() - 1)
		player_cards.append(basic_cards_deck[random_cards])
	update_price_display()
	update_play_state()

func _on_test_button_pressed() -> void:
	play_card()
	update_price_display()
	check_game_result()
	update_play_state()
	
func update_price_display():
	price_label.text = \
	"%s%s" % [
		"当前价格：",
		"%.2f" % current_price
	]
func check_game_result():
	if (current_price == 0.00):
		print("游戏胜利!")
		is_gameover = true


# 预留函数，用于传入玩家选择卡牌的数组下标
func select_card():
	var card_index
	card_index = 0
	return card_index

func update_play_state():
	if (is_gameover):
		test_button.disabled = true
	elif (player_cards.size() == 0):
		test_button.disabled = true

func play_card():
	if (is_gameover):
		return
	# 测试用，固定选择数组中第一张卡牌
	if (player_cards.size() != 0):
		var current_card = player_cards[0]
		print("当前剩余卡牌:", player_cards.size())
		print("当前使用卡牌：", current_card["name"])
		var random_price = randf_range(current_card["min_cut_value"], current_card["max_cut_value"])
		print("本次砍价：", random_price)
		current_price -= random_price
		player_cards.remove_at(0)
	if (current_price < 0.00):
		current_price = 0.00
