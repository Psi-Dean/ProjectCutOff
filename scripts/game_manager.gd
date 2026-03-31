extends Node
@onready var price_label: Label = $"../UI/PriceLabel"
@onready var test_button: Button = $"../UI/TestButton"
@onready var hand_area: Control = $"../UI/HandArea"
var CardsData = preload("res://scripts/cards_data.gd")
var current_price:float = 100.00
var is_gameover:bool = false
var card_buttons:Array = []

var basic_cards_deck = CardsData.BASIC_CARDS
var cards_limited:int = 6
var player_cards:Array = []
var select_card_index:int = -1

func _ready() -> void:
	draw_some_cards()
	update_cards_display()
	update_price_display()
	update_play_state()

func _on_test_button_pressed() -> void:
	if(!play_card()):
		return
	check_game_result()
	update_cards_display()
	update_price_display()
	update_play_state()
	
func update_price_display():
	price_label.text = \
	"%s%s" % [
		"商品价格：",
		"%.2f" % current_price
	]
func check_game_result():
	if (current_price <= 0.00):
		print("游戏胜利!")
		is_gameover = true


 # 预留函数，用于传入玩家选择卡牌的数组下标
func select_card(index):
	print("选择卡牌：",player_cards[index])
	select_card_index = index
	update_cards_display()
	
func update_play_state():
	if (is_gameover):
		test_button.disabled = true
	elif (player_cards.size() == 0):
		test_button.disabled = true
	else:
		test_button.disabled = false

func play_card():
	var _is_play
	if (is_gameover):
		_is_play = false
		return _is_play
	if ( select_card_index < 0 or select_card_index >= player_cards.size()):
		_is_play = false
		return _is_play
	
	var current_card = player_cards[select_card_index]
	print("当前剩余卡牌:", player_cards.size() - 1)
	print("当前使用卡牌：", current_card["name"])
	var random_price = randf_range(current_card["min_cut_value"], current_card["max_cut_value"])
	print("本次砍价：", random_price)
	current_price -= random_price
	player_cards.remove_at(select_card_index)
	select_card_index = -1
	if (current_price < 0.00):
		current_price = 0.00
	_is_play = true
	return _is_play

func update_cards_display():
	# 1.清空手牌显示
	for child in hand_area.get_children():
		child.queue_free()
	# 2.遍历玩家手牌
	for i in range(player_cards.size()):
		var _card = player_cards[i]
		# 3.创建按钮
		var btn = Button.new()
		if (i == select_card_index):
			btn.text = \
			"%s%s" % [
				">",
				_card["name"]
			]
		else:
			btn.text = _card["name"]
		btn.custom_minimum_size = Vector2(140, 200)
		# 4.绑定按钮与卡牌索引
		btn.set_meta("card_index", i)
		btn.connect("pressed",Callable(self,"select_card").bind(i))
		# 5.加入UI
		hand_area.add_child(btn)
		
func draw_some_cards():
	for i in range(cards_limited):
		var random_cards = randi_range(0, basic_cards_deck.size() - 1)
		player_cards.append(basic_cards_deck[random_cards])



func _on_test_button_2_pressed() -> void:
	draw_some_cards()
	update_cards_display()
	update_play_state()
