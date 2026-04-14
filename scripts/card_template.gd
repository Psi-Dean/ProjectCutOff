extends Control

signal card_play_requested(card: Control)
signal card_drag_started(card: Control)
signal card_drag_ended(card: Control)

@onready var name_label: Label = $NameLabel
@onready var value_label: Label = $ValueLabel
@onready var card_img: TextureRect = $CardImg

const DISSOLVE_SHADER = preload("res://assets/shader/dissolve.gdshader")
const IdleStateScript = preload("res://scripts/card_states/idle.gd")
const HoveredStateScript = preload("res://scripts/card_states/hovered.gd")
const DraggingStateScript = preload("res://scripts/card_states/dragging.gd")
const DestroyStateScript = preload("res://scripts/card_states/destroy.gd")
const NoInteractStateScript = preload("res://scripts/card_states/no_interact.gd")

var card_index: int = -1
var card_data: CardData = null
var state_machine: CutoffStateMachine
var interactable: bool = true
var scale_tween: Tween


func _ready() -> void:
	pivot_offset = size / 2.0

	# 初始化溶解材质
	var mat = ShaderMaterial.new()
	mat.shader = DISSOLVE_SHADER
	mat.set("shader_parameter/dissolve_value", 1.0)
	card_img.material = mat

	_setup_state_machine()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _setup_state_machine() -> void:
	state_machine = CutoffStateMachine.new()
	state_machine.name = "StateMachine"
	add_child(state_machine)

	var idle_node = IdleStateScript.new()
	idle_node.name = "Idle"
	state_machine.add_child(idle_node)

	var hovered_node = HoveredStateScript.new()
	hovered_node.name = "Hovered"
	state_machine.add_child(hovered_node)

	var dragging_node = DraggingStateScript.new()
	dragging_node.name = "Dragging"
	state_machine.add_child(dragging_node)

	var destroy_node = DestroyStateScript.new()
	destroy_node.name = "Destroy"
	state_machine.add_child(destroy_node)

	var no_interact_node = NoInteractStateScript.new()
	no_interact_node.name = "NoInteract"
	state_machine.add_child(no_interact_node)

	state_machine.init_state(self)


func setup_card(data: CardData, index: int) -> void:
	card_index = index
	card_data = data
	name_label.text = data.card_title
	value_label.text = data.description
	if data.card_ui:
		card_img.texture = data.card_ui


func _gui_input(event: InputEvent) -> void:
	if state_machine and state_machine.current_state:
		(state_machine.current_state as CutoffCardState).on_gui_input(event)


func _input(event: InputEvent) -> void:
	if state_machine and state_machine.current_state:
		(state_machine.current_state as CutoffCardState).on_input(event)


func _on_mouse_entered() -> void:
	if state_machine and state_machine.current_state:
		(state_machine.current_state as CutoffCardState).on_mouse_entered()


func _on_mouse_exited() -> void:
	if state_machine and state_machine.current_state:
		(state_machine.current_state as CutoffCardState).on_mouse_exited()


func _on_state_transitioned(old_state: int, new_state: int) -> void:
	if new_state == CutoffCardState.DRAGGING:
		card_drag_started.emit(self)
	elif old_state == CutoffCardState.DRAGGING:
		card_drag_ended.emit(self)
		if new_state == CutoffCardState.DESTROY:
			card_play_requested.emit(self)


func check_destroy_area_overlap() -> bool:
	var areas = get_tree().get_nodes_in_group("destroy_area")
	if areas.is_empty():
		return false

	var card_center = global_position + pivot_offset
	for area in areas:
		var area_rect = Rect2(area.global_position, area.size)
		if area_rect.has_point(card_center):
			return true
	return false


func get_current_state_id() -> int:
	if not state_machine or not state_machine.current_state:
		return -1
	var current = state_machine.current_state as CutoffCardState
	if not current:
		return -1
	return current.state


func is_destroying() -> bool:
	return get_current_state_id() == CutoffCardState.DESTROY


func reset_destroy_area_highlight() -> void:
	for area in get_tree().get_nodes_in_group("destroy_area"):
		area.modulate = Color.WHITE


func tween_scale_to(target_scale: Vector2, duration: float, trans: Tween.TransitionType, ease: Tween.EaseType = Tween.EASE_OUT) -> void:
	if scale_tween and scale_tween.is_valid():
		scale_tween.kill()
	scale_tween = create_tween().set_trans(trans).set_ease(ease)
	scale_tween.tween_property(self, "scale", target_scale, duration)


func set_interactable(enabled: bool) -> void:
	interactable = enabled
	if not state_machine:
		mouse_filter = Control.MOUSE_FILTER_STOP if interactable else Control.MOUSE_FILTER_IGNORE
		return

	var current = state_machine.current_state as CutoffCardState
	if not current:
		mouse_filter = Control.MOUSE_FILTER_STOP if interactable else Control.MOUSE_FILTER_IGNORE
		return

	if current.state == CutoffCardState.DESTROY:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		mouse_filter = Control.MOUSE_FILTER_STOP if interactable else Control.MOUSE_FILTER_IGNORE

	if interactable:
		if current.state == CutoffCardState.NO_INTERACT:
			state_machine.transition_to(CutoffCardState.IDLE)
	else:
		if current.state != CutoffCardState.DESTROY and current.state != CutoffCardState.NO_INTERACT:
			state_machine.transition_to(CutoffCardState.NO_INTERACT)


func cancel_play() -> void:
	if not state_machine or not state_machine.current_state:
		return

	# 重置视觉效果
	var mat = card_img.material as ShaderMaterial
	if mat and mat.get("shader_parameter/dissolve_value") < 1.0:
		var t = create_tween()
		t.tween_property(mat, "shader_parameter/dissolve_value", 1.0, 0.1)

	if scale_tween and scale_tween.is_valid():
		scale_tween.kill()
	modulate = Color.WHITE
	scale = Vector2.ONE
	name_label.modulate.a = 1.0
	value_label.modulate.a = 1.0
	reset_destroy_area_highlight()
	mouse_filter = Control.MOUSE_FILTER_STOP if interactable else Control.MOUSE_FILTER_IGNORE

	if interactable:
		var current = state_machine.current_state as CutoffCardState
		if current and current.state != CutoffCardState.IDLE:
			state_machine.transition_to(CutoffCardState.IDLE)
