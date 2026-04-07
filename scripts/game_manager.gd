extends Node
@onready var price_label: Label = $"../UI/PriceLabel"
@onready var play_card_button: Button = $"../UI/PlayCardButton"
@onready var hand_area: Control = $"../UI/HandArea"
@onready var random_cut_value: Label = $"../UI/RandomCutValue"
@onready var play_times: Label = $"../UI/PlayTimes"
@onready var next_round_button: Button = $"../UI/NextRoundButton"
@onready var skip_button: Button = $"../UI/SkipButton"
@onready var player_money: Label = $"../UI/PlayerMoney"
@onready var pay_panel: Panel = $"../UI/PayPanel"
@onready var pay_confirm: Button = $"../UI/PayPanel/PayConfirm"
@onready var pay_text: Label = $"../UI/PayPanel/PayText"
@onready var game_over_label: Label = $"../GameOverLabel"

const CardScene = preload("res://scenes/card_template.tscn")
const CardsData = preload("res://scripts/cards_data.gd")
var play_state = GameState.PlayState.PLAYER_TURN
var current_price:float = 100.00
var current_money:float = 50.00
var goal_price:float = 40.00
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
var is_payable:bool = false
var is_paid:bool = false


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
	if (current_price <= 0.00 or is_paid):
		print("游戏胜利!")
		play_state = GameState.PlayState.GAME_OVER
		


 # 预留函数，用于传入玩家选择卡牌的数组下标
func select_card(index):
	if (play_state != GameState.PlayState.PLAYER_TURN):
		return
	if (index < 0 or index >= player_cards.size()):
		return
	if (index == selected_card_index):
		selected_card_index = -1
	else:
		selected_card_index = index
	print("选择卡牌：", selected_card_index)
	update_cards_display()
	update_play_state()
	
func update_play_state():
	#if (play_state == GameState.PlayState.GAME_OVER):
		#play_card_button.disabled = true
	#elif (play_state == GameState.PlayState.ROUND_END):
		#play_card_button.disabled = true
	#elif (!can_play_card):
		#play_card_button.disabled = true
	#elif (player_cards.size() == 0):
		#play_card_button.disabled = true
	#elif (selected_card_index < 0 or selected_card_index >= player_cards.size()):
		#play_card_button.disabled = true
	#else:
		#play_card_button.disabled = false
	# 这行判断通过引入中间变量和游戏状态的判定，收敛上面的if else
	# 定义判断打出卡牌按钮是否可按的中间变量
	var has_cards:bool = player_cards.size() > 0
	var has_valid_selection:bool = selected_card_index >= 0 and selected_card_index < player_cards.size()
	var can_play_card:bool = play_state == GameState.PlayState.PLAYER_TURN and has_cards and has_valid_selection
	var can_skip:bool = play_state == GameState.PlayState.PLAYER_TURN
	var show_next_round:bool = play_state == GameState.PlayState.ROUND_END
	var can_pay:bool = is_payable and play_state != GameState.PlayState.GAME_OVER
	play_card_button.disabled = !can_play_card
	#if(play_state == GameState.PlayState.PLAYER_TURN):
		#skip_button.disabled = false
	#else:
		#skip_button.disabled = true
	skip_button.disabled = !can_skip
	#if (play_state == GameState.PlayState.ROUND_END):
		#next_round_button.visible = true
	#else:
		#next_round_button.visible = false
	next_round_button.visible = show_next_round
	#if(is_payable && play_state == GameState.PlayState.PLAYER_TURN):
		#pay_confirm.disabled = false
	#else:
		#pay_confirm.disabled = true
	pay_confirm.disabled = !can_pay
	#if (is_paid):
		#pay_panel.visible = false
	#else:
		#pay_panel.visible = true
	pay_panel.visible = !is_paid and play_state != GameState.PlayState.GAME_OVER
	game_over_label.visible = play_state == GameState.PlayState.GAME_OVER
	update_pay_confirm_text()

func play_card():
	if (play_state == GameState.PlayState.GAME_OVER):
		print("游戏已结束！")
		return false
	if ( selected_card_index < 0 or selected_card_index >= player_cards.size()):
		print("请选择正确卡牌！")
		return false
	if (play_state == GameState.PlayState.ROUND_END):
		print("当前回合已结束！")
		return false
	
	current_select_card = player_cards[selected_card_index]
	print("当前使用卡牌：", current_select_card["name"])
	var random_value = randf_range(current_select_card["min_cut_value"], current_select_card["max_cut_value"])
	final_cut_value = random_value
	print("随机砍价：", random_value)
	print("最终砍价：", final_cut_value)
	current_price -= final_cut_value
	print("当前剩余卡牌:", player_cards.size())
	move_count += 1
	random_cut_value.visible = true
	# 1. 先拿到对应的节点
	var card_node = hand_area.get_child(selected_card_index)
	# 2. 删掉数据
	player_cards.remove_at(selected_card_index)
	# 3. 节点删除标记，延迟生效，在帧结束之后执行删除
	card_node.queue_free()
	# 4. 关键：重置选中索引并重新排列剩余卡牌
	selected_card_index = -1
	rearrange_cards() # 这样剩下的牌会平滑地滑过去填补空缺
	if (current_price < 0.00):
		current_price = 0.00
	return true
	
func update_cards_display():
	# 第一版手牌显示，通过button创建
	# 1.清空手牌显示
	#for child in hand_area.get_children():
		#child.queue_free()
	# 2.遍历玩家手牌
	#for i in range(player_cards.size()):
		#var _card = player_cards[i]
		# 3.创建按钮
		#var btn = Button.new()
		#if (i == selected_card_index):
			#btn.self_modulate = Color.LIGHT_GREEN
		#else:
			#btn.self_modulate = Color.WHITE
		#btn.text = _card["name"]
		#btn.custom_minimum_size = Vector2(140, 200)
		# 4.绑定按钮与卡牌索引
		#btn.set_meta("card_index", i)
		#btn.connect("pressed",Callable(self,"select_card").bind(i))
		# 5.加入UI
		#hand_area.add_child(btn)
	# 第二版手牌显示，使用独立场景创建卡牌，获取点击卡牌的数组下标发送信号
	# 获取当前场景中已有卡牌数量
	# 提出已加入删除标记的节点
	var all_children = hand_area.get_children()
	var current_card_nodes = []
	for child in all_children:
		if not child.is_queued_for_deletion():
			current_card_nodes.append(child)
	# 只有玩家卡牌数与场景节点数不一致时，执行清空，并重新生成
	if current_card_nodes.size() != player_cards.size():
		# 1.清空手牌显示
		for child in hand_area.get_children():
			child.queue_free()
		# 2.遍历玩家手牌
		for i in range(player_cards.size()):
			# 3.创建卡牌
			var card = CardScene.instantiate()
			var is_selected:bool = (i == selected_card_index)
			# 4.加入UI
			hand_area.add_child(card)
			# 5.接入数据
			card.setup_card(player_cards[i], i)
			card.set_card_style(is_selected)
			# 6.连接信号
			card.card_clicked.connect(self.select_card)
	else :
		# 如果手牌数量和手牌节点数量一致，只更新样式
		for i in range(current_card_nodes.size()):
			var _card = current_card_nodes[i]
			_card.setup_card(player_cards[i], i)
			_card.set_card_style(i == selected_card_index)
	rearrange_cards()
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
	if (play_state == GameState.PlayState.GAME_OVER):
		return
	if (move_count >= move_limit):
		play_state = GameState.PlayState.ROUND_END
		print("回合已结束！")
	else:
		play_state = GameState.PlayState.PLAYER_TURN
		print("已出牌：", move_count)
		
func start_next_round():
	if(play_state == GameState.PlayState.ROUND_END):
		move_count = 0
		selected_card_index = -1
		play_state = GameState.PlayState.PLAYER_TURN
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
	is_payable = false
	if(current_price <= goal_price && current_price <= current_money):
		is_payable = true
			
func _on_next_round_pressed() -> void:
	start_next_round()
	update_cards_display()
	update_play_state()
	update_play_times()
	update_price_display()


func _on_skip_button_pressed() -> void:
	selected_card_index = -1
	if(play_state == GameState.PlayState.PLAYER_TURN):
		play_state = GameState.PlayState.ROUND_END
		update_play_state()
		update_cards_display()

func update_pay_confirm_text():
	if(is_payable):
		pay_confirm.text = "%s" % ["购买"]
	else:
		pay_confirm.text = "%s" % ["当前金额未达标"]
		
func _on_pay_confirm_pressed() -> void:
	selected_card_index = -1
	current_money -= current_price
	is_paid = true
	check_game_result()
	update_cards_display()
	update_play_state()
	update_play_times()
	update_price_display()

func rearrange_cards():
	var all_children = hand_area.get_children()
	var _cards = []
	for child in all_children:
		if not child.is_queued_for_deletion():
			_cards.append(child)
	var _count = _cards.size()
	if _count == 0:
		return
	var _area_width = hand_area.size.x
	var _card_width = 142
	var _spacing = _card_width
	
	# 计算起始偏移，让手牌整体居中
	var _total_content_width = min(_area_width, _count * _card_width)
	var _start_x = (_area_width - _total_content_width) / 2
	
	# 计算间距
	if _count * _card_width > _area_width:
		_spacing = (_area_width - _card_width) / (_count - 1)
		
	# 开始排列
	for i in range(_count):
		var card = _cards[i]
		var target_x = _start_x + i * _spacing
		
		# 使用Tween动画处理平滑
		var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		t.tween_property(card, "position:x", target_x, 0.2)
		# 纵向位置重置为0，防止排列位置时出现跳动
		#t.parallel().tween_property(card, "position:y", 0, 0.2)
