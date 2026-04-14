extends CutoffCardState

var drag_offset: Vector2 = Vector2.ZERO
var drop_armed: bool = false
var pending_drop_click: bool = false
var drag_start_mouse_pos: Vector2 = Vector2.ZERO

# 首次按住拖拽后，如果释放时鼠标位移超过该阈值，判定为“拖拽释放”
# 手感微调：可直接改这个值（单位：像素）
const DRAG_RELEASE_DISTANCE: float = 14.0


func _init() -> void:
	state = CutoffCardState.DRAGGING


func enter() -> void:
	if not card:
		return
	card.z_index = 10
	card.move_to_front()
	drop_armed = false
	pending_drop_click = false
	drag_start_mouse_pos = card.get_global_mouse_position()
	# 记录鼠标按下点与卡牌中心偏移，保持拖拽手感
	drag_offset = (card.global_position + card.pivot_offset) - drag_start_mouse_pos
	card.tween_scale_to(Vector2(1.1, 1.1), 0.15, Tween.TRANS_SINE, Tween.EASE_OUT)


func update(_delta: float) -> void:
	if not card:
		return
	var mouse_pos = card.get_global_mouse_position()
	var hand_area = card.get_parent()
	card.position = mouse_pos + drag_offset - hand_area.global_position - card.pivot_offset

	# 拖拽时高亮出牌区
	var is_over = card.check_destroy_area_overlap()
	for area in card.get_tree().get_nodes_in_group("destroy_area"):
		area.modulate = Color(1.3, 1.3, 1.3) if is_over else Color.WHITE


func exit() -> void:
	if card:
		card.reset_destroy_area_highlight()


func on_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if event.is_released():
		# 第二次点击抬起：直接放下
		if pending_drop_click:
			pending_drop_click = false
			get_viewport().set_input_as_handled()
			if card.check_destroy_area_overlap():
				transition_requested.emit(self, CutoffCardState.DESTROY)
			else:
				transition_requested.emit(self, CutoffCardState.IDLE)
			return

		# 第一次抬起：拖拽释放 or 进入点击跟随
		var moved_distance = card.get_global_mouse_position().distance_to(drag_start_mouse_pos)
		if moved_distance >= DRAG_RELEASE_DISTANCE:
			get_viewport().set_input_as_handled()
			if card.check_destroy_area_overlap():
				transition_requested.emit(self, CutoffCardState.DESTROY)
			else:
				transition_requested.emit(self, CutoffCardState.IDLE)
		else:
			drop_armed = true
		return

	# 点击跟随后，下一次按下用于“准备放下”
	if event.is_pressed() and drop_armed:
		pending_drop_click = true
