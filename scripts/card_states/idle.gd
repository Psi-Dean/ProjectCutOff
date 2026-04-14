extends CutoffCardState

# ===== 悬停果冻动画参数（参考 Demo，可手工微调）=====
# 说明：
# 1) HOVER_JELLY_TIME 控制“悬停进入 / 离开回位”的持续时间
# 2) HOVER_SCALE 控制悬停放大倍率
const HOVER_JELLY_TIME: float = 0.3
const HOVER_SCALE: Vector2 = Vector2(1.2, 1.2)


func _init() -> void:
	state = CutoffCardState.IDLE


func enter() -> void:
	if not card:
		return
	card.z_index = 0
	card.tween_scale_to(Vector2.ONE, HOVER_JELLY_TIME, Tween.TRANS_ELASTIC, Tween.EASE_OUT)


func on_mouse_entered() -> void:
	if can_interact():
		transition_requested.emit(self, CutoffCardState.HOVERED)


func on_gui_input(event: InputEvent) -> void:
	if not can_interact():
		return
	if not event is InputEventMouseButton:
		return
	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		transition_requested.emit(self, CutoffCardState.DRAGGING)
