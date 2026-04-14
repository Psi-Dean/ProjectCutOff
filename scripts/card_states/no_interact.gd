extends CutoffCardState


func _init() -> void:
	state = CutoffCardState.NO_INTERACT


func enter() -> void:
	if not card:
		return
	card.z_index = 0
	card.reset_destroy_area_highlight()
	card.tween_scale_to(Vector2.ONE, 0.15, Tween.TRANS_SINE, Tween.EASE_OUT)


func on_gui_input(_event: InputEvent) -> void:
	pass


func on_input(_event: InputEvent) -> void:
	pass


func on_mouse_entered() -> void:
	pass


func on_mouse_exited() -> void:
	pass
