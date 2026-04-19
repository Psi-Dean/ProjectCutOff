extends Node

# 商品价格文本。
@onready var price_label: Label = $"../UI/PriceLabel"
# 手牌区域容器。
@onready var hand_area: Control = $"../UI/HandArea"
# 本次砍价结果文本。
@onready var random_cut_value: Label = $"../UI/RandomCutValue"
# 已出牌次数文本。
@onready var play_times: Label = $"../UI/PlayTimes"
# 下一回合按钮。
@onready var next_round_button: Button = $"../UI/NextRoundButton"
# 跳过按钮。
@onready var skip_button: Button = $"../UI/SkipButton"
# 玩家现金文本。
@onready var player_money: Label = $"../UI/PlayerMoney"
# 购买面板。
@onready var pay_panel: Panel = $"../UI/PayPanel"
# 购买确认按钮。
@onready var pay_confirm: Button = $"../UI/PayPanel/PayConfirm"
# 目标价格文本。
@onready var pay_text: Label = $"../UI/PayPanel/PayText"
# 游戏结束文本。
@onready var game_over_label: Label = $"../GameOverLabel"
# 心态值进度条
@onready var mindset_bar: ProgressBar = $"../UI/MindSetBar"
# 心态值文本
@onready var mindset_value_label: Label = $"../UI/MindSetValueLabel"
# 心态爆表提示
@onready var mindset_warning_label: Label = $"../UI/MindSetWarningLabel"
# 心态值光照效果
@onready var risk_light: DirectionalLight2D = $"../UI/MindSetWarningLabel/RiskLight"


# 卡牌预制体场景。
const CardScene = preload("res://scenes/card_template.tscn")

# 当前游戏阶段。
var play_state = GameState.PlayState.PLAYER_TURN
# 当前商品价格。
var current_price: float = 200.00
# 当前玩家现金。
var current_money: float = 50.00
# 购买目标价格。
var goal_price: float = 40.00

# 基础卡池（从资源目录加载）。
var basic_cards_deck: Array[CardData] = []
# 开局发牌数量。
var setup_cards_limit: int = 6
# 每回合补牌数量。
var round_cards_limit: int = 1
# 玩家选择牌库限制数量
var player_setup_limit: int = 16
# 玩家手牌上限
var hand_limit:int = 15
# 玩家当前心态值
var current_mindset:float = 10.00 
# 玩家回合恢复心态值
var recovery_mindset:float = 3.00
# 玩家心态值上限
var max_mindset:float = 100.00
# 玩家心态爆表后的风险值
var risk_value:int = 0
# 玩家牌库数据
var player_deck: Array[CardData] = []
# 玩家当前手牌数据。
var player_cards: Array[CardData] = []
# 最终砍价值（用于滚动展示后定格）。
var final_cut_value: float = 0.00
# 当前打出的卡牌数据。
var current_select_card: CardData = null
# 滚动展示次数。
var roll_times: int = 15
# 每回合可出牌上限。
var move_limit: int = 3
# 当前回合已出牌数。
var move_count: int = 0
# 当前是否满足可购买条件。
var is_payable: bool = false
# 当前是否已完成购买。
var is_paid: bool = false

# 当前正在拖拽的卡牌节点。
var dragging_card: Control = null
# 是否处于出牌结算中（防止并发触发）。
var is_playing_card: bool = false

# ===== 手牌布局可调参数（中文注释，方便手工微调）=====
# 参数：手牌整体基准 Y，值越大越靠下。
const HAND_LAYOUT_BASE_Y: float = 10.0
# 参数：扇形中间抬升高度，值越大弧度越明显。
const HAND_FAN_RISE: float = 38.0
# 参数：两侧卡牌最大旋转角度（度）。
const HAND_FAN_MAX_ROTATION: float = 12.5
# 参数：横向最大间距系数，值越大越松散。
const HAND_MAX_SPACING_FACTOR: float = 0.92
# 参数：重排动画时长（秒）。
const HAND_LAYOUT_TIME: float = 0.35

# 初始化卡池、手牌显示和各类 UI 状态。
func _ready() -> void:
	load_card_resources()
	setup_card_deck()
	random_draw_cards()
	check_player_money()
	check_end_turn()
	update_cards_display()
	update_price_display()
	update_play_times()
	update_play_state()
	update_mindset_ui()
	call_deferred("_deferred_rearrange_cards")

# 在场景完成一次布局后再次刷新手牌位置，确保初始扇形布局正确生效。
func _deferred_rearrange_cards() -> void:
	rearrange_cards()

# 响应卡牌出牌请求，执行结算、扣牌、重排与状态刷新。
func _on_card_play_requested(card: Control) -> void:
	if is_playing_card:
		card.cancel_play()
		return
	if not _can_cards_interact():
		card.cancel_play()
		return

	is_playing_card = true
	_apply_cards_interactable()

	var index = _find_card_index(card)
	if index < 0:
		is_playing_card = false
		card.cancel_play()
		_apply_cards_interactable()
		return
	current_select_card = card.card_data
	# 判断是否超出心态上限，并增加相应的风险值
	calc_risk_value(current_select_card)
	current_mindset += current_select_card.mindset_cost
	update_mindset_ui()
	print("心态值增加：",current_select_card.mindset_cost)
	print("当前心态值：", current_mindset)
	final_cut_value = randf_range(current_select_card.min_cut_value, current_select_card.max_cut_value)
	current_price = maxf(0.0, current_price - final_cut_value)
	player_cards.remove_at(index)
	move_count += 1
	random_cut_value.visible = true
	dragging_card = null

	# 说明：给 queue_free 一帧时间，确保节点树状态稳定后再重排。
	await get_tree().create_timer(0.1).timeout
	_refresh_card_indices()
	rearrange_cards()

	check_game_result()
	check_player_money()
	check_end_turn()
	update_play_times()
	update_play_state()
	update_price_display()
	_show_roll_animation()

	is_playing_card = false
	_apply_cards_interactable()

# 响应卡牌进入拖拽，锁定仅拖拽卡可交互并触发手牌重排。
func _on_card_drag_started(card: Control) -> void:
	if not _can_cards_interact():
		return
	dragging_card = card
	_apply_cards_interactable()
	rearrange_cards()

# 响应卡牌结束拖拽，按落点重排并重建手牌数据。
func _on_card_drag_ended(card: Control) -> void:
	if dragging_card == card:
		dragging_card = null

	# 说明：拖到销毁区时保持原地销毁，不参与回插排序。
	if _is_destroying_card(card):
		rearrange_cards()
		_refresh_card_indices()
		_apply_cards_interactable()
		return

	# 说明：按落点 X 计算插入位置，并同步手牌数组顺序。
	_insert_card_by_drop_position(card)
	_rebuild_player_cards_from_nodes()
	rearrange_cards()
	_apply_cards_interactable()

# 播放本次砍价随机滚动文本动画并最终定格。
func _show_roll_animation() -> void:
	random_cut_value.text = "本次砍价：¥%.2f" % 0.00
	var t = create_tween()
	for _i in range(roll_times):
		t.tween_callback(func():
			if current_select_card:
				random_cut_value.text = "本次砍价：¥%.2f" % randf_range(current_select_card.min_cut_value, current_select_card.max_cut_value)
		)
		t.tween_interval(0.05)
	t.tween_callback(func(): random_cut_value.text = "本次砍价：¥%.2f" % final_cut_value)

# 同步手牌节点与数据，并连接卡牌事件信号。
func update_cards_display() -> void:
	var current_nodes = _get_card_nodes()
	if current_nodes.size() != player_cards.size():
		for child in current_nodes:
			child.queue_free()
		for i in range(player_cards.size()):
			var card = CardScene.instantiate()
			hand_area.add_child(card)
			card.setup_card(player_cards[i], i)
			if not card.card_play_requested.is_connected(_on_card_play_requested):
				card.card_play_requested.connect(_on_card_play_requested)
			if not card.card_drag_started.is_connected(_on_card_drag_started):
				card.card_drag_started.connect(_on_card_drag_started)
			if not card.card_drag_ended.is_connected(_on_card_drag_ended):
				card.card_drag_ended.connect(_on_card_drag_ended)
	else:
		_refresh_card_indices()

	rearrange_cards()
	_apply_cards_interactable()

# 判断指定卡牌是否处于销毁状态。
func _is_destroying_card(card: Control) -> bool:
	return card != null and card.has_method("is_destroying") and card.is_destroying()

# 获取当前所有有效手牌节点（排除待删除与销毁中节点）。
func _get_card_nodes() -> Array:
	var result: Array = []
	for child in hand_area.get_children():
		if not child.is_queued_for_deletion() and child.has_method("setup_card"):
			if not _is_destroying_card(child):
				result.append(child)
	return result

# 获取参与布局的手牌节点（排除正在拖拽的节点）。
func _get_active_cards() -> Array:
	var result: Array = []
	for child in _get_card_nodes():
		if child != dragging_card:
			result.append(child)
	return result

# 刷新所有手牌节点的 card_index。
func _refresh_card_indices() -> void:
	var cards = _get_card_nodes()
	for i in range(cards.size()):
		cards[i].card_index = i

# 按当前手牌顺序同步每张卡牌的基础层级，避免悬停后层级错乱。
func _sync_cards_base_z_index() -> void:
	var cards = _get_card_nodes()
	for i in range(cards.size()):
		var card = cards[i]
		if card.has_method("set_base_z_index"):
			card.set_base_z_index(i)
		else:
			card.z_index = i

# 根据当前节点顺序重建玩家手牌数据数组。
func _rebuild_player_cards_from_nodes() -> void:
	player_cards.clear()
	var cards = _get_card_nodes()
	for i in range(cards.size()):
		cards[i].card_index = i
		player_cards.append(cards[i].card_data)

# 查找卡牌在玩家手牌数据中的索引。
func _find_card_index(card: Control) -> int:
	var index = card.card_index
	if index >= 0 and index < player_cards.size() and player_cards[index] == card.card_data:
		return index
	return player_cards.find(card.card_data)

# 根据拖拽放下时的横向位置计算卡牌插入下标。
func _insert_card_by_drop_position(card: Control) -> void:
	if not card:
		return
	var cards = _get_card_nodes()
	if not cards.has(card) or cards.size() <= 1:
		return

	var others: Array = []
	for c in cards:
		if c != card:
			others.append(c)
	others.sort_custom(func(a, b): return (a.global_position.x + a.size.x * 0.5) < (b.global_position.x + b.size.x * 0.5))

	var drop_x = card.global_position.x + card.size.x * 0.5
	var insert_index = 0
	for other in others:
		var center_x = other.global_position.x + other.size.x * 0.5
		if drop_x > center_x:
			insert_index += 1

	_move_card_node_to_insert_index(card, insert_index)

# 按插入下标调整卡牌节点在手牌容器中的顺序。
func _move_card_node_to_insert_index(card: Control, insert_index: int) -> void:
	var orderable: Array = []
	for child in hand_area.get_children():
		if not child.is_queued_for_deletion() and child.has_method("setup_card") and not _is_destroying_card(child):
			if child != card:
				orderable.append(child)

	insert_index = clampi(insert_index, 0, orderable.size())
	if insert_index < orderable.size():
		var anchor = orderable[insert_index]
		hand_area.move_child(card, anchor.get_index())
		return

	var last_index = -1
	for child in hand_area.get_children():
		if not child.is_queued_for_deletion() and child.has_method("setup_card") and not _is_destroying_card(child):
			if child != card:
				last_index = child.get_index()

	if last_index < 0:
		hand_area.move_child(card, 0)
	else:
		hand_area.move_child(card, last_index + 1)

# 按可调参数执行手牌扇形布局与平滑动画。
func rearrange_cards() -> void:
	_sync_cards_base_z_index()

	var cards = _get_active_cards()
	var count = cards.size()
	if count == 0:
		return

	var area_width = hand_area.size.x
	var card_width = 120.0
	var first_card = cards[0] as Control
	if first_card and first_card.size.x > 1.0:
		card_width = first_card.size.x

	var max_spacing = card_width * HAND_MAX_SPACING_FACTOR
	var spacing = max_spacing
	if count > 1:
		spacing = (area_width - card_width) / (count - 1)
		spacing = minf(spacing, max_spacing)

	var total_width = spacing * (count - 1) + card_width
	var start_x = (area_width - total_width) / 2.0

	for i in range(count):
		var card = cards[i]
		var target_x = start_x + i * spacing
		var t_norm = 0.0 if count <= 1 else (float(i) / float(count - 1) - 0.5) * 2.0
		var center_factor = 1.0 - (t_norm * t_norm)
		var target_y = HAND_LAYOUT_BASE_Y - center_factor * HAND_FAN_RISE
		var target_rot = t_norm * HAND_FAN_MAX_ROTATION
		var target_pos = Vector2(target_x, target_y)

		if card.has_method("set_layout_anchor"):
			card.set_layout_anchor(target_y, target_rot)
		if card.has_method("stop_position_rotation_tweens"):
			card.stop_position_rotation_tweens()

		var tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(card, "position", target_pos, HAND_LAYOUT_TIME)
		tween.tween_property(card, "rotation_degrees", target_rot, HAND_LAYOUT_TIME * 0.9)

# 刷新价格、现金与目标金额显示。
func update_price_display() -> void:
	price_label.text = "当前价格：¥%.2f" % current_price
	player_money.text = "玩家现金：¥%.2f" % current_money
	pay_text.text = "目标价格：¥%.2f" % goal_price

# 刷新已出牌计数显示。
func update_play_times() -> void:
	play_times.text = "已出牌次数：%d" % move_count

# 检查是否满足游戏结束条件。
func check_game_result() -> void:
	if current_price <= 0.00 or is_paid:
		play_state = GameState.PlayState.GAME_OVER

# 检查当前回合是否结束。
func check_end_turn() -> void:
	if play_state == GameState.PlayState.GAME_OVER:
		return
	if move_count >= move_limit:
		play_state = GameState.PlayState.ROUND_END
	else:
		play_state = GameState.PlayState.PLAYER_TURN

# 检查当前是否达到可购买条件。
func check_player_money() -> void:
	is_payable = false
	if not is_paid and current_price <= goal_price and current_price <= current_money:
		is_payable = true

# 根据游戏阶段统一刷新按钮与面板状态。
func update_play_state() -> void:
	var can_skip = play_state == GameState.PlayState.PLAYER_TURN
	var show_next_round = play_state == GameState.PlayState.ROUND_END
	var can_pay = is_payable and play_state != GameState.PlayState.GAME_OVER and not is_paid

	skip_button.disabled = not can_skip
	next_round_button.visible = show_next_round
	pay_confirm.disabled = not can_pay
	pay_panel.visible = not is_paid and play_state != GameState.PlayState.GAME_OVER
	game_over_label.visible = play_state == GameState.PlayState.GAME_OVER
	update_pay_confirm_text()
	_apply_cards_interactable()

# 刷新购买按钮文案。
func update_pay_confirm_text() -> void:
	pay_confirm.text = "购买" if is_payable else "价格未达成"

# 刷新心态值进度条
func update_mindset_ui() -> void:
	mindset_bar.max_value = max_mindset
	mindset_bar.value = current_mindset
	mindset_value_label.text = \
	"心态值:%.2f/%.2f" % [
		current_mindset,
		max_mindset
	]
	mindset_warning_label.visible = false if current_mindset < mindset_bar.max_value else true
	play_risk_warning_effect()
# 统一判断当前阶段是否允许手牌交互。
func _can_cards_interact() -> bool:
	return play_state == GameState.PlayState.PLAYER_TURN and not is_playing_card and not is_paid

# 统一应用手牌可交互状态（拖拽时仅允许当前拖拽卡交互）。
func _apply_cards_interactable() -> void:
	var can_interact = _can_cards_interact()
	if not can_interact:
		dragging_card = null
	for card in _get_card_nodes():
		var enabled = can_interact and (dragging_card == null or card == dragging_card)
		card.set_interactable(enabled)
		
# 计算心态值超出上限后风险值累加逻辑
func calc_risk_value(current_card:CardData) -> void:
	var is_risk = true if current_card.mindset_cost + current_mindset > max_mindset else false
	if not is_risk:
		return 
	var actual_mindset = current_card.mindset_cost + current_mindset
	var risk_range = actual_mindset - max_mindset
	print("当前风险值计算：",actual_mindset)
	print("风险范围值：",risk_range)
	if 0 < risk_range and risk_range <= 10:
		risk_value += 1
	elif 10< risk_range and risk_range<= 30:
		risk_value += 3
	elif 30 < risk_range and risk_range<= 50:
		risk_value += 6
	elif 50< risk_range and risk_range<= 80:
		risk_value += 10
	elif risk_range > 80:
		risk_value += 18
	print("风险超出限定范围值：",risk_range)
	print("当前风险累计：",risk_value)

# 根据实际风险值计算后续负面逻辑
func check_risk_value() -> void:
	if risk_value > 0:
		# 风险值执行对应逻辑
		pass 
	recover_mindset()

# 玩家心态值恢复逻辑
func recover_mindset() -> void:
	var actual_recovery = recovery_mindset if current_mindset >= recovery_mindset else current_mindset
	current_mindset -= actual_recovery
	print("回合开始降低心态值:", actual_recovery)
	print("降低后心态值:", current_mindset)
# 响应“跳过”按钮，结束当前回合。
func _on_skip_button_pressed() -> void:
	if play_state == GameState.PlayState.PLAYER_TURN:
		play_state = GameState.PlayState.ROUND_END
		update_play_state()

# 响应“下一回合”按钮，重置回合计数并补牌。
func _on_next_round_pressed() -> void:
	if play_state == GameState.PlayState.ROUND_END:
		move_count = 0
		play_state = GameState.PlayState.PLAYER_TURN
		random_draw_cards()
		check_player_money()
		check_risk_value()
		update_mindset_ui()
		update_cards_display()
		update_play_state()
		update_play_times()
		update_price_display()

# 响应“购买”按钮，扣款并刷新终局状态。
func _on_pay_confirm_pressed() -> void:
	if not is_payable:
		return
	current_money -= current_price
	is_paid = true
	check_game_result()
	check_player_money()
	update_play_state()
	update_play_times()
	update_price_display()
		
# 随机抽牌函数，获取calculate_draw_limit函数返回的数值进行随机抽牌
func random_draw_cards() -> void:
	if player_deck.is_empty():
		return
	for i in range(calculate_draw_limit()):
		if not player_deck.is_empty():
			var randomidx = randi_range(0, player_deck.size() - 1)
			player_cards.append(player_deck[randomidx].duplicate(true))
			player_deck.remove_at(randomidx)
		else:
			return
	print("玩家手牌数量:", player_cards.size())
	print("牌库剩余手牌:", player_deck.size())
	print("手牌剩余位置:", hand_limit - player_cards.size())

# 根据基础卡牌池basic_cards_deck，初始化本局玩家牌库
# basic_cards_deck基础卡牌池不会在对局中消耗
# player_deck作为玩家本局牌库，在对局中抽牌时会被消耗
# 当前版本允许玩家从基础卡牌池重复抽卡
# TODO 后续改为从卡牌构筑/选牌界面加入player_deck
func setup_card_deck() -> void:
	if basic_cards_deck.is_empty():
		return
	player_deck = []
	for i in range(player_setup_limit):
		var randomidx = randi_range(0, basic_cards_deck.size() -1)
		player_deck.append(basic_cards_deck[randomidx].duplicate(true))
	play_state =  GameState.PlayState.GAME_START
	
func play_risk_warning_effect() -> void:
	if mindset_warning_label.visible:
		print("闪烁动画播放中...")
		mindset_warning_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		var tween = create_tween().set_loops().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		tween.tween_property(mindset_warning_label,"modulate", Color(1.0, 1.0, 1.0, 0.0), 0.2)
		tween.tween_property(mindset_warning_label,"modulate",Color(1.0, 1.0, 1.0, 1.0), 0.2)
# 计算卡牌抽取的数量限制
# cards_limit计算当前是初始化抽牌数量还是下一局补牌数量
# card_space计算当前手牌剩余可补牌的数量，通过hand_limit限制手牌上限
# current_draw_limit判断上面两个变量值，取最小值返回抽牌数量
func calculate_draw_limit() -> int:
	var cards_limit = setup_cards_limit  if play_state == GameState.PlayState.GAME_START else round_cards_limit
	var card_space = hand_limit - player_cards.size()
	var current_draw_limit = cards_limit if cards_limit < card_space else card_space
	return current_draw_limit if current_draw_limit > 0 else 0
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
