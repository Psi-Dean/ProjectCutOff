extends CutoffCardState

# 功能：初始化状态编号为 NO_INTERACT。
func _init() -> void:
	state = CutoffCardState.NO_INTERACT

# 功能：进入不可交互状态，重置高亮并回归默认缩放。
func enter() -> void:
	if not card:
		return
	if card.has_method("refresh_visual_z_index"):
		card.refresh_visual_z_index()
	card.reset_destroy_area_highlight()
	card.tween_scale_to(Vector2.ONE, 0.15, Tween.TRANS_SINE, Tween.EASE_OUT)

# 功能：不可交互状态下忽略控件输入。
func on_gui_input(_event: InputEvent) -> void:
	pass

# 功能：不可交互状态下忽略全局输入。
func on_input(_event: InputEvent) -> void:
	pass

# 功能：不可交互状态下忽略鼠标进入。
func on_mouse_entered() -> void:
	pass

# 功能：不可交互状态下忽略鼠标离开。
func on_mouse_exited() -> void:
	pass
