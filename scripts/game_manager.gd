extends Node

@onready var price_label: Label = $"../UI/PriceLabel"
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

var play_state = GameState.PlayState.PLAYER_TURN
var current_price: float = 100.00
var current_money: float = 50.00
var goal_price: float = 40.00

var basic_cards_deck: Array[CardData] = []
var setup_cards_limit: int = 6
var round_cards_limit: int = 3
var player_cards: Array[CardData] = []
var final_cut_value: float = 0.00
var current_select_card: CardData = null
var roll_times: int = 15
var move_limit: int = 3
var move_count: int = 0
var is_payable: bool = false
var is_paid: bool = false

var dragging_card: Control = null
var is_playing_card: bool = false


func _ready() -> void:
	load_card_resources()
	setup_cards()
	random_cut_value.visible = false
	check_player_money()
	check_end_turn()
	update_cards_display()
	update_price_display()
	update_play_times()
	update_play_state()


# ==================== 卡牌出牌逻辑 ====================

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
	final_cut_value = randf_range(current_select_card.min_cut_value, current_select_card.max_cut_value)
	current_price = maxf(0.0, current_price - final_cut_value)

	player_cards.remove_at(index)
	move_count += 1
	random_cut_value.visible = true
	dragging_card = null

	# 卡牌自身执行溶解动画并 queue_free，这里只处理手牌数据和布局
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


func _on_card_drag_started(card: Control) -> void:
	if not _can_cards_interact():
		return
	dragging_card = card
	_apply_cards_interactable()
	rearrange_cards()


func _on_card_drag_ended(card: Control) -> void:
	if dragging_card == card:
		dragging_card = null

	# 拖到销毁区时，不参与手牌重排，保留原地销毁表现
	if _is_destroying_card(card):
		rearrange_cards()
		_refresh_card_indices()
		_apply_cards_interactable()
		return

	# 放回手牌区时，按鼠标落点插入数组中间
	_insert_card_by_drop_position(card)
	_rebuild_player_cards_from_nodes()
	rearrange_cards()
	_apply_cards_interactable()


func _show_roll_animation() -> void:
	random_cut_value.text = "本次砍价：%.2f" % 0.00
	var t = create_tween()
	for _i in range(roll_times):
		t.tween_callback(func():
			if current_select_card:
				random_cut_value.text = "本次砍价：%.2f" % randf_range(current_select_card.min_cut_value, current_select_card.max_cut_value)
		)
		t.tween_interval(0.05)
	t.tween_callback(func(): random_cut_value.text = "本次砍价：%.2f" % final_cut_value)


# ==================== 手牌显示 ====================

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


func _is_destroying_card(card: Control) -> bool:
	return card != null and card.has_method("is_destroying") and card.is_destroying()


func _get_card_nodes() -> Array:
	var result: Array = []
	for child in hand_area.get_children():
		if not child.is_queued_for_deletion() and child.has_method("setup_card"):
			if not _is_destroying_card(child):
				result.append(child)
	return result


func _get_active_cards() -> Array:
	var result: Array = []
	for child in _get_card_nodes():
		if child != dragging_card:
			result.append(child)
	return result


func _refresh_card_indices() -> void:
	var cards = _get_card_nodes()
	for i in range(cards.size()):
		cards[i].card_index = i


func _rebuild_player_cards_from_nodes() -> void:
	player_cards.clear()
	var cards = _get_card_nodes()
	for i in range(cards.size()):
		cards[i].card_index = i
		player_cards.append(cards[i].card_data)


func _find_card_index(card: Control) -> int:
	var index = card.card_index
	if index >= 0 and index < player_cards.size() and player_cards[index] == card.card_data:
		return index
	return player_cards.find(card.card_data)


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


# ==================== 手牌布局 ====================

func rearrange_cards() -> void:
	var cards = _get_active_cards()
	var count = cards.size()
	if count == 0:
		return

	var area_width = hand_area.size.x
	var card_width = 120.0

	# 卡牌过多时允许适度重叠
	var max_spacing = card_width * 1.1
	var spacing = max_spacing
	if count > 1:
		spacing = (area_width - card_width) / (count - 1)
		spacing = min(spacing, max_spacing)

	# 居中排列
	var total_width = spacing * (count - 1) + card_width
	var start_x = (area_width - total_width) / 2.0

	for i in range(count):
		var card = cards[i]
		var target_x = start_x + i * spacing
		var target_pos = Vector2(target_x, 10.0)
		var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		t.tween_property(card, "position", target_pos, 0.35)


# ==================== 游戏状态 ====================

func update_price_display() -> void:
	price_label.text = "商品价格：%.2f" % current_price
	player_money.text = "现金：%.2f" % current_money
	pay_text.text = "目标金额：%.2f" % goal_price


func update_play_times() -> void:
	play_times.text = "已出牌：%d张" % move_count


func check_game_result() -> void:
	if current_price <= 0.00 or is_paid:
		play_state = GameState.PlayState.GAME_OVER


func check_end_turn() -> void:
	if play_state == GameState.PlayState.GAME_OVER:
		return
	if move_count >= move_limit:
		play_state = GameState.PlayState.ROUND_END
	else:
		play_state = GameState.PlayState.PLAYER_TURN


func check_player_money() -> void:
	is_payable = false
	if not is_paid and current_price <= goal_price and current_price <= current_money:
		is_payable = true


func update_play_state() -> void:
	var can_skip = play_state == GameState.PlayState.PLAYER_TURN and not is_playing_card
	var show_next_round = play_state == GameState.PlayState.ROUND_END
	var can_pay = is_payable and play_state != GameState.PlayState.GAME_OVER and not is_paid

	skip_button.disabled = not can_skip
	next_round_button.visible = show_next_round
	pay_confirm.disabled = not can_pay
	pay_panel.visible = not is_paid and play_state != GameState.PlayState.GAME_OVER
	game_over_label.visible = play_state == GameState.PlayState.GAME_OVER
	update_pay_confirm_text()
	_apply_cards_interactable()


func update_pay_confirm_text() -> void:
	if is_payable:
		pay_confirm.text = "购买"
	else:
		pay_confirm.text = "当前金额未达标"


func _can_cards_interact() -> bool:
	return play_state == GameState.PlayState.PLAYER_TURN and not is_playing_card and not is_paid


func _apply_cards_interactable() -> void:
	var can_interact = _can_cards_interact()
	if not can_interact:
		dragging_card = null
	for card in _get_card_nodes():
		var enabled = can_interact and (dragging_card == null or card == dragging_card)
		card.set_interactable(enabled)


# ==================== 按钮事件 ====================

func _on_skip_button_pressed() -> void:
	if play_state == GameState.PlayState.PLAYER_TURN and not is_playing_card:
		play_state = GameState.PlayState.ROUND_END
		update_play_state()


func _on_next_round_pressed() -> void:
	if play_state == GameState.PlayState.ROUND_END:
		move_count = 0
		play_state = GameState.PlayState.PLAYER_TURN
		next_round_cards()
		check_player_money()
		update_cards_display()
		update_play_state()
		update_play_times()
		update_price_display()


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


# ==================== 卡牌池 ====================

func setup_cards() -> void:
	if basic_cards_deck.is_empty():
		return
	for _i in range(setup_cards_limit):
		var random_idx = randi_range(0, basic_cards_deck.size() - 1)
		player_cards.append(basic_cards_deck[random_idx].duplicate(true))


func next_round_cards() -> void:
	if basic_cards_deck.is_empty():
		return
	for _i in range(round_cards_limit):
		var random_idx = randi_range(0, basic_cards_deck.size() - 1)
		player_cards.append(basic_cards_deck[random_idx].duplicate(true))


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
