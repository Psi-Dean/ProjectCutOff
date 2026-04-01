extends Node
@onready var price_label: Label = $"../UI/PriceLabel"
@onready var play_card_button: Button = $"../UI/PlayCardButton"
@onready var draw_card_button: Button = $"../UI/DrawCardButton"
@onready var hand_area: Control = $"../UI/HandArea"
@onready var random_cut_value: Label = $"../UI/RandomCutValue"
@onready var play_times: Label = $"../UI/PlayTimes"
@onready var next_round_button: Button = $"../UI/NextRoundButton"
@onready var skip_button: Button = $"../UI/SkipButton"
@onready var player_money: Label = $"../UI/PlayerMoney"
@onready var pay_panel: Panel = $"../UI/PayPanel"


const CardsData = preload("res://scripts/cards_data.gd")
var current_price:float = 100.00
var current_money:float = 50.00
var is_gameover:bool = false
var card_buttons:Array = []

var basic_cards_deck = CardsData.BASIC_CARDS
var setup_cards_limit:int = 6
var round_cards_limit:int = 3
var player_cards:Array = []
var selected_card_index:int = -1
var final_cut_value:float = 0.00
var current_select_card = null
var roll_times:int = 15
var move_limit:int = 3
var move_count:int = 0
var is_end_turn:bool = false
var is_payable:bool = false

func _ready() -> void:
	setup_cards()
	check_end_turn()
	update_cards_display()
	update_price_display()
	update_play_times()
	update_play_state()

func _on_play_card_button_pressed() -> void:
	if(!play_card()):
		return
	check_game_result()
	check_player_money()
	check_end_turn()
	#start_next_round()
	update_cards_display()
	update_play_times()
	update_play_state()
	await update_random_value()
	#update_value_display()
	update_price_display()
	
func update_price_display():
	price_label.text = \
	"%s%s" % [
		"商品价格：",
		"%.2f" % current_price
	]
	player_money.text = "%s%.2f" % ["现金：", current_money]

func update_play_times():
	play_times.text = \
	"%s%d%s" % [
		"已出牌：",
		move_count,
		"张"
	]
	
func check_game_result():
	if (current_price <= 0.00):
		print("游戏胜利!")
		is_gameover = true


 # 预留函数，用于传入玩家选择卡牌的数组下标
func select_card(index):
	if (index < 0 or index >= player_cards.size()):
		return
	if (index == selected_card_index):
		selected_card_index = -1
	else:
		selected_card_index = index
	update_cards_display()
	update_play_state()
	
func update_play_state():
	if (is_gameover):
		play_card_button.disabled = true
	elif (is_end_turn):
		play_card_button.disabled = true
	elif (player_cards.size() == 0):
		play_card_button.disabled = true
	elif (selected_card_index < 0 or selected_card_index >= player_cards.size()):
		play_card_button.disabled = true
	else:
		play_card_button.disabled = false
	if (!is_gameover and is_end_turn):
		next_round_button.visible = true
	else:
		next_round_button.visible = false
	if(!is_gameover and !is_end_turn):
		skip_button.disabled = false
	else:
		skip_button.disabled = true
	if(is_payable):
		pay_panel.visible = true
	else:
		pay_panel.visible = false

func play_card():
	if (is_gameover):
		print("游戏已结束！")
		return false
	if ( selected_card_index < 0 or selected_card_index >= player_cards.size()):
		print("请选择正确卡牌！")
		return false
	if (is_end_turn):
		print("当前回合已结束！")
		return false
	
	current_select_card = player_cards[selected_card_index]
	print("当前使用卡牌：", current_select_card["name"])
	var random_value = randf_range(current_select_card["min_cut_value"], current_select_card["max_cut_value"])
	final_cut_value = random_value
	print("随机砍价：", random_value)
	print("最终砍价：", final_cut_value)
	current_price -= final_cut_value
	player_cards.remove_at(selected_card_index)
	print("当前剩余卡牌:", player_cards.size())
	selected_card_index = -1
	move_count += 1
	random_cut_value.visible = true
	if (current_price < 0.00):
		current_price = 0.00
	return true
	
func update_cards_display():
	# 1.清空手牌显示
	for child in hand_area.get_children():
		child.queue_free()
	# 2.遍历玩家手牌
	for i in range(player_cards.size()):
		var _card = player_cards[i]
		# 3.创建按钮
		var btn = Button.new()
		if (i == selected_card_index):
			btn.self_modulate = Color.LIGHT_GREEN
		else:
			btn.self_modulate = Color.WHITE
		btn.text = _card["name"]
		btn.custom_minimum_size = Vector2(140, 200)
		# 4.绑定按钮与卡牌索引
		btn.set_meta("card_index", i)
		btn.connect("pressed",Callable(self,"select_card").bind(i))
		# 5.加入UI
		hand_area.add_child(btn)
# 用于测试抽卡

func update_random_value():
	random_cut_value.text = \
	"%s%s" % [
		"本次砍价：",
		"%.2f" % 0.00
	]
	await get_tree().create_timer(0.09).timeout
	for i in range(roll_times):
		var rand = randf_range(current_select_card["min_cut_value"], current_select_card["max_cut_value"])
		random_cut_value.text = \
		"%s%s" %[
			"本次砍价：",
			"%.2f" % rand
		]
		await get_tree().create_timer(0.05).timeout
	random_cut_value.text = \
		"%s%s" %[
			"本次砍价：",
			"%.2f" % final_cut_value
		]
	
func check_end_turn():
	if (move_count >= move_limit):
		is_end_turn = true
		print("回合已结束！")
	else:
		is_end_turn = false
		print("已出牌：", move_count)
		
func start_next_round():
	if(is_end_turn):
		move_count = 0
		selected_card_index = -1
		is_end_turn = false
		next_round_cards()
		print("开始下一回合")

# 抽卡按钮，用于测试逻辑
func _on_draw_card_button_pressed() -> void:
	next_round_cards()
	update_cards_display()
	update_play_state()


func setup_cards():
	for i in range(setup_cards_limit):
		var random_cards = randi_range(0, basic_cards_deck.size() - 1)
		player_cards.append(basic_cards_deck[random_cards])

func next_round_cards():
	for i in range(round_cards_limit):
		var random_cards = randi_range(0, basic_cards_deck.size() - 1)
		player_cards.append(basic_cards_deck[random_cards])

func check_player_money():
	# 判断是否游戏结束、回合结束、现金是否满足
	if (!is_gameover and !is_end_turn):
		if(current_price > current_money):
			is_payable = false
		else:
			is_payable = true

func _on_next_round_pressed() -> void:
	start_next_round()
	update_cards_display()
	update_play_state()
	update_play_times()
	update_price_display()


func _on_skip_button_pressed() -> void:
	if(!is_gameover and !is_end_turn):
		is_end_turn = true
		update_play_state()



func _on_pay_confirm_pressed() -> void:
	current_money -= current_price
	update_cards_display()
	update_play_state()
	update_play_times()
	update_price_display()

func _on_pay_deny_pressed() -> void:
	pay_panel.visible = false
