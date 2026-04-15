extends CutoffCardState

# 常量：从悬停/拖拽回到待机时的果冻回位时长（秒）。
const IDLE_BACK_TIME: float = 0.42

# 功能：初始化状态编号为 IDLE。
func _init() -> void:
	state = CutoffCardState.IDLE

# 功能：进入待机状态，恢复缩放，并按布局锚点回位与回正。
func enter() -> void:
	if not card:
		return
	card.z_index = 0
	card.tween_scale_to(Vector2.ONE, IDLE_BACK_TIME, Tween.TRANS_ELASTIC, Tween.EASE_OUT)

	var prev_state_id := -1
	if card.state_machine and card.state_machine.previous_state:
		prev_state_id = card.state_machine.previous_state.state

	# 说明：从拖拽回到待机时，位置与角度由 GameManager 的布局 Tween 接管，避免双 Tween 叠加导致轻微漂移。
	if prev_state_id == CutoffCardState.DRAGGING:
		return

	# 说明：开局首帧锚点可能尚未准备好，避免错误回位。
	if card.has_method("is_layout_anchor_ready") and not card.is_layout_anchor_ready():
		return

	if card.has_method("get_layout_anchor_y"):
		card.tween_position_y_to(card.get_layout_anchor_y(), IDLE_BACK_TIME, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	if card.has_method("get_layout_anchor_rotation"):
		card.tween_rotation_to(card.get_layout_anchor_rotation(), IDLE_BACK_TIME * 0.9, Tween.TRANS_ELASTIC, Tween.EASE_OUT)

# 功能：鼠标进入时切换到悬停状态。
func on_mouse_entered() -> void:
	if can_interact():
		transition_requested.emit(self, CutoffCardState.HOVERED)

# 功能：待机状态下响应左键按下，切换到拖拽状态。
func on_gui_input(event: InputEvent) -> void:
	if not can_interact():
		return
	if not (event is InputEventMouseButton):
		return
	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		transition_requested.emit(self, CutoffCardState.DRAGGING)
