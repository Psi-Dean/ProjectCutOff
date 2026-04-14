extends CutoffCardState

# ===== 悬停果冻动画参数（参考 Demo，可手工微调）=====
# 说明：
# 1) HOVER_JELLY_TIME 控制“悬停进入 / 离开回位”的持续时间
# 2) HOVER_SCALE 控制悬停放大倍率
const HOVER_JELLY_TIME: float = 0.3
const HOVER_SCALE: Vector2 = Vector2(1.2, 1.2)


func _init() -> void:
	state = CutoffCardState.HOVERED


func enter() -> void:
	if not card:
		return
	card.z_index = 2
	card.move_to_front()
	card.tween_scale_to(HOVER_SCALE, HOVER_JELLY_TIME, Tween.TRANS_ELASTIC, Tween.EASE_OUT)


func exit() -> void:
	if card:
		card.z_index = 0


func update(_delta: float) -> void:
	if not card:
		return
	# 兜底：高速划过时，按当前真正 Hover 控件强制回收状态
	var viewport = card.get_viewport()
	var hovered_control: Control = null
	if viewport and viewport.has_method("gui_get_hovered_control"):
		hovered_control = viewport.gui_get_hovered_control()
	if hovered_control == null:
		transition_requested.emit(self, CutoffCardState.IDLE)
		return
	if hovered_control != card and not card.is_ancestor_of(hovered_control):
		transition_requested.emit(self, CutoffCardState.IDLE)


func on_mouse_exited() -> void:
	transition_requested.emit(self, CutoffCardState.IDLE)


func on_gui_input(event: InputEvent) -> void:
	if not can_interact():
		return
	if not event is InputEventMouseButton:
		return
	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		transition_requested.emit(self, CutoffCardState.DRAGGING)
