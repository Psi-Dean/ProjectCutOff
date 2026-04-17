extends CutoffCardState

# 变量：拖拽时鼠标点与卡牌中心的偏移量，用于保持“抓取手感”。
var drag_offset: Vector2 = Vector2.ZERO
# 变量：是否已进入“点击跟随后可放下”的武装状态。
var drop_armed: bool = false
# 变量：是否已触发下一次点击放下。
var pending_drop_click: bool = false
# 变量：开始拖拽时的鼠标全局位置，用于区分点击与拖拽释放。
var drag_start_mouse_pos: Vector2 = Vector2.ZERO

# 常量：首按后释放时，超过该位移判定为“拖拽释放”（像素）。
const DRAG_RELEASE_DISTANCE: float = 14.0

# 功能：初始化状态编号为 DRAGGING。
func _init() -> void:
	state = CutoffCardState.DRAGGING

# 功能：进入拖拽状态，记录偏移并提升层级。
func enter() -> void:
	if not card:
		return
	if card.has_method("refresh_visual_z_index"):
		card.refresh_visual_z_index()
	drop_armed = false
	pending_drop_click = false
	drag_start_mouse_pos = card.get_global_mouse_position()
	# 说明：用“卡牌中心 - 鼠标点”的偏移，保证拖拽过程中抓取点不跳动。
	drag_offset = (card.global_position + card.pivot_offset) - drag_start_mouse_pos
	card.tween_scale_to(Vector2(1.1, 1.1), 0.15, Tween.TRANS_SINE, Tween.EASE_OUT)
	if card.has_method("tween_rotation_to"):
		card.tween_rotation_to(0.0, 0.12, Tween.TRANS_SINE, Tween.EASE_OUT)

# 功能：每帧跟随鼠标更新卡牌位置，并刷新销毁区高亮。
func update(_delta: float) -> void:
	if not card:
		return

	var mouse_pos = card.get_global_mouse_position()
	var hand_area = card.get_parent() as Control
	if hand_area == null:
		return
	card.position = mouse_pos + drag_offset - hand_area.global_position - card.pivot_offset

	var is_over = card.check_destroy_area_overlap()
	for area in card.get_tree().get_nodes_in_group("destroy_area"):
		area.modulate = Color(1.3, 1.3, 1.3) if is_over else Color.WHITE

# 功能：退出拖拽状态时清理销毁区高亮。
func exit() -> void:
	if card:
		card.reset_destroy_area_highlight()

# 功能：处理拖拽状态的点击释放逻辑（拖拽释放 / 点击跟随再次点击放下）。
func on_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if event.is_released():
		# 说明：若已进入“待放下点击”阶段，则本次松开直接执行放下逻辑。
		if pending_drop_click:
			pending_drop_click = false
			get_viewport().set_input_as_handled()
			if card.check_destroy_area_overlap():
				transition_requested.emit(self, CutoffCardState.DESTROY)
			else:
				transition_requested.emit(self, CutoffCardState.IDLE)
			return

		# 说明：第一次抬起时，位移足够则按拖拽释放处理，否则进入点击跟随模式。
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

	# 说明：点击跟随模式下，下一次按下会标记“本轮松开执行放下”。
	if event.is_pressed() and drop_armed:
		pending_drop_click = true
