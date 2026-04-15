extends CutoffCardState

# ===== 悬停手感可调参数 =====
# HOVER_JELLY_TIME：悬停进入/退出时果冻动画时长。
const HOVER_JELLY_TIME: float = 0.45
# HOVER_SCALE：悬停时卡牌放大倍率。
const HOVER_SCALE: Vector2 = Vector2(1.28, 1.28)
# HOVER_BOTTOM_OVERFLOW：悬停时允许卡牌底边超出屏幕下边缘的像素。
const HOVER_BOTTOM_OVERFLOW: float = 20.0
# HOVER_TOP_MARGIN：悬停时卡牌顶部最小安全边距，避免超出屏幕顶端。
const HOVER_TOP_MARGIN: float = 10.0

# 功能：初始化状态编号为 HOVERED。
func _init() -> void:
	state = CutoffCardState.HOVERED

# 功能：进入悬停状态，执行放大、上浮和旋转回正。
func enter() -> void:
	if not card:
		return
	card.z_index = 20
	card.move_to_front()

	var anchor_y = card.position.y
	if card.has_method("get_layout_anchor_y"):
		anchor_y = card.get_layout_anchor_y()

	var target_y = anchor_y
	if card.has_method("get_hover_y_by_bottom"):
		target_y = card.get_hover_y_by_bottom(HOVER_SCALE, HOVER_BOTTOM_OVERFLOW, HOVER_TOP_MARGIN)
		target_y = minf(target_y, anchor_y)

	card.tween_scale_to(HOVER_SCALE, HOVER_JELLY_TIME, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	card.tween_position_y_to(target_y, HOVER_JELLY_TIME, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
	card.tween_rotation_to(0.0, HOVER_JELLY_TIME * 0.8, Tween.TRANS_ELASTIC, Tween.EASE_OUT)

# 功能：退出悬停状态时恢复默认层级。
func exit() -> void:
	if card:
		card.z_index = 0

# 功能：逐帧校验真实悬停目标，兜底清理高速划过导致的悬停残留。
func update(_delta: float) -> void:
	if not card:
		return

	var viewport = card.get_viewport()
	var hovered_control: Control = null
	if viewport and viewport.has_method("gui_get_hovered_control"):
		hovered_control = viewport.gui_get_hovered_control()
	if hovered_control == null:
		transition_requested.emit(self, CutoffCardState.IDLE)
		return
	if hovered_control != card and not card.is_ancestor_of(hovered_control):
		transition_requested.emit(self, CutoffCardState.IDLE)

# 功能：鼠标离开由 update 统一判断，避免边缘抖动导致状态来回切换。
func on_mouse_exited() -> void:
	pass

# 功能：悬停状态下响应左键按下，切换到拖拽状态。
func on_gui_input(event: InputEvent) -> void:
	if not can_interact():
		return
	if not (event is InputEventMouseButton):
		return
	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		transition_requested.emit(self, CutoffCardState.DRAGGING)
