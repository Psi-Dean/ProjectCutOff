extends CutoffCardState


func _init() -> void:
	state = CutoffCardState.DESTROY


func enter() -> void:
	if not card:
		return
	card.z_index = 10
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.reset_destroy_area_highlight()

	var mat = card.card_img.material as ShaderMaterial
	if mat:
		# 着色器溶解动画
		var t = card.create_tween().set_parallel(true)
		t.tween_property(mat, "shader_parameter/dissolve_value", 0.0, 0.8).from(1.0).set_trans(Tween.TRANS_CUBIC)
		t.tween_property(card.name_label, "modulate:a", 0.0, 0.3)
		t.tween_property(card.value_label, "modulate:a", 0.0, 0.3)
		t.tween_property(card, "scale", Vector2(0.8, 0.8), 0.8).set_ease(Tween.EASE_IN)
		t.chain().tween_callback(card.queue_free)
	else:
		# 兜底：无材质时执行简单淡出
		var t = card.create_tween().set_parallel(true)
		t.tween_property(card, "modulate:a", 0.0, 0.5)
		t.tween_property(card, "scale", Vector2(0.5, 0.5), 0.5).set_ease(Tween.EASE_IN)
		t.chain().tween_callback(card.queue_free)
