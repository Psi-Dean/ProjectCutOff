extends Control

# 信号：卡牌进入销毁状态后，通知管理器执行出牌结算。
signal card_play_requested(card: Control)
# 信号：卡牌进入拖拽状态时发出。
signal card_drag_started(card: Control)
# 信号：卡牌离开拖拽状态时发出。
signal card_drag_ended(card: Control)

# 引用：卡牌名称文本节点。
@onready var name_label: Label = $NameLabel
# 引用：卡牌描述文本节点。
@onready var value_label: Label = $ValueLabel
# 引用：卡面贴图节点。
@onready var card_img: TextureRect = $CardImg
# 变量：阴影贴图节点（不存在时会在运行时自动创建）。
var shadow: TextureRect

# 常量：卡牌溶解着色器。
const DISSOLVE_SHADER = preload("res://assets/shader/dissolve.gdshader")
# 常量：卡牌阴影着色器。
const SHADOW_SHADER = preload("res://assets/shader/card_shadow.gdshader")
# 常量：待机状态脚本。
const IdleStateScript = preload("res://scripts/card_states/idle.gd")
# 常量：悬停状态脚本。
const HoveredStateScript = preload("res://scripts/card_states/hovered.gd")
# 常量：拖拽状态脚本。
const DraggingStateScript = preload("res://scripts/card_states/dragging.gd")
# 常量：销毁状态脚本。
const DestroyStateScript = preload("res://scripts/card_states/destroy.gd")
# 常量：禁用交互状态脚本。
const NoInteractStateScript = preload("res://scripts/card_states/no_interact.gd")
# 常量：悬停状态层级抬升值。
const Z_BOOST_HOVER: int = 1000
# 常量：拖拽状态层级抬升值。
const Z_BOOST_DRAGGING: int = 2000
# 常量：销毁状态层级抬升值。
const Z_BOOST_DESTROY: int = 3000

# 变量：当前卡牌在手牌数组中的索引。
var card_index: int = -1
# 变量：当前卡牌绑定的数据资源。
var card_data: CardData = null
# 变量：卡牌状态机实例。
var state_machine: CutoffStateMachine
# 变量：当前卡牌是否允许交互。
var interactable: bool = true
# 变量：缩放补间动画句柄。
var scale_tween: Tween
# 变量：Y 轴位移补间动画句柄。
var pos_y_tween: Tween
# 变量：旋转补间动画句柄。
var rot_tween: Tween
# 变量：阴影当前透明度缓存。
var shadow_alpha_current: float = 0.34
# 变量：布局锚点 Y（用于状态切换回位）。
var layout_anchor_y: float = 0.0
# 变量：布局锚点旋转角（用于状态切换回正）。
var layout_anchor_rotation: float = 0.0
# 变量：布局锚点是否已完成初始化。
var layout_anchor_ready: bool = false
# 变量：卡牌基础层级（由手牌排序确定，悬停结束后回到该层级）。
var base_z_index: int = 0

# ===== 卡牌阴影可调参数 =====
@export_group("卡牌阴影")
# 参数：阴影最大横向偏移（像素）。
@export var shadow_offset_max: float = 20.0
# 参数：阴影纵向固定偏移（像素）。
@export var shadow_y_offset: float = 15.0
# 参数：阴影位置跟随插值速度，越大跟随越快。
@export var shadow_follow_lerp_speed: float = 16.0
# 参数：待机状态阴影目标透明度。
@export var shadow_alpha_idle: float = 0.34
# 参数：悬停状态阴影目标透明度。
@export var shadow_alpha_hovered: float = 0.46
# 参数：拖拽状态阴影目标透明度。
@export var shadow_alpha_dragging: float = 0.58
# 参数：阴影透明度插值速度，越大变化越快。
@export var shadow_alpha_lerp_speed: float = 14.0

# 功能：节点初始化，配置材质、阴影与状态机，并连接鼠标信号。
func _ready() -> void:
	pivot_offset = size / 2.0
	layout_anchor_y = position.y
	layout_anchor_rotation = rotation_degrees
	layout_anchor_ready = false
	z_index = base_z_index

	var mat = ShaderMaterial.new()
	mat.shader = DISSOLVE_SHADER
	mat.set("shader_parameter/dissolve_value", 1.0)
	card_img.material = mat

	_setup_shadow()
	_setup_state_machine()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

# 功能：逐帧更新阴影位置与透明度。
func _process(delta: float) -> void:
	_update_shadow(delta)

# 功能：初始化阴影节点与阴影材质。
func _setup_shadow() -> void:
	shadow = get_node_or_null("Shadow") as TextureRect
	if shadow == null:
		shadow = TextureRect.new()
		shadow.name = "Shadow"
		shadow.layout_mode = 1
		shadow.offset_right = card_img.offset_right
		shadow.offset_bottom = card_img.offset_bottom
		shadow.expand_mode = card_img.expand_mode
		shadow.stretch_mode = card_img.stretch_mode
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(shadow)
		move_child(shadow, card_img.get_index())

	shadow.z_index = -1
	shadow.position = Vector2(0.0, shadow_y_offset)
	shadow.texture = card_img.texture

	var shadow_mat = ShaderMaterial.new()
	shadow_mat.shader = SHADOW_SHADER
	shadow_mat.set("shader_parameter/alpha", shadow_alpha_idle)
	shadow.material = shadow_mat
	shadow_alpha_current = shadow_alpha_idle

# 功能：根据卡牌与屏幕中心距离更新阴影横向偏移和透明度。
func _update_shadow(delta: float) -> void:
	if shadow == null:
		return

	var viewport_size = get_viewport_rect().size
	if viewport_size.x <= 1.0:
		return

	var center_x = viewport_size.x * 0.5
	var card_center_x = global_position.x + size.x * scale.x * 0.5
	var distance = card_center_x - center_x
	var ratio = clampf(abs(distance / center_x), 0.0, 1.0)
	var target_x = lerpf(0.0, shadow_offset_max * sign(distance), ratio)
	var follow_weight = clampf(delta * shadow_follow_lerp_speed, 0.0, 1.0)
	shadow.position.x = lerpf(shadow.position.x, target_x, follow_weight)
	shadow.position.y = shadow_y_offset

	var alpha_weight = clampf(delta * shadow_alpha_lerp_speed, 0.0, 1.0)
	var target_alpha = _get_shadow_target_alpha()
	shadow_alpha_current = lerpf(shadow_alpha_current, target_alpha, alpha_weight)

	var mat = shadow.material as ShaderMaterial
	if mat:
		mat.set("shader_parameter/alpha", shadow_alpha_current)

# 功能：根据当前状态返回目标阴影透明度。
func _get_shadow_target_alpha() -> float:
	var state_id = get_current_state_id()
	if state_id == CutoffCardState.HOVERED:
		return shadow_alpha_hovered
	if state_id == CutoffCardState.DRAGGING:
		return shadow_alpha_dragging
	if state_id == CutoffCardState.DESTROY:
		return 0.0
	return shadow_alpha_idle

# 功能：创建并初始化卡牌状态机与各状态节点。
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

# 功能：绑定卡牌资源数据并刷新显示内容。
func setup_card(data: CardData, index: int) -> void:
	card_index = index
	card_data = data
	base_z_index = index
	refresh_visual_z_index()
	name_label.text = data.card_title
	value_label.text = data.description
	if data.card_ui:
		card_img.texture = data.card_ui
		if shadow:
			shadow.texture = data.card_ui

# 功能：将控件级输入转发给当前状态。
func _gui_input(event: InputEvent) -> void:
	if state_machine and state_machine.current_state:
		(state_machine.current_state as CutoffCardState).on_gui_input(event)

# 功能：将全局输入转发给当前状态。
func _input(event: InputEvent) -> void:
	if state_machine and state_machine.current_state:
		(state_machine.current_state as CutoffCardState).on_input(event)

# 功能：鼠标进入时转发给当前状态。
func _on_mouse_entered() -> void:
	if state_machine and state_machine.current_state:
		(state_machine.current_state as CutoffCardState).on_mouse_entered()

# 功能：鼠标离开时转发给当前状态。
func _on_mouse_exited() -> void:
	if state_machine and state_machine.current_state:
		(state_machine.current_state as CutoffCardState).on_mouse_exited()

# 功能：处理状态切换后的业务信号派发。
func _on_state_transitioned(old_state: int, new_state: int) -> void:
	if new_state == CutoffCardState.DRAGGING:
		card_drag_started.emit(self)
	elif old_state == CutoffCardState.DRAGGING:
		card_drag_ended.emit(self)
		if new_state == CutoffCardState.DESTROY:
			card_play_requested.emit(self)

# 功能：检测卡牌中心点是否进入销毁区域。
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

# 功能：获取当前状态编号。
func get_current_state_id() -> int:
	if not state_machine or not state_machine.current_state:
		return -1
	var current = state_machine.current_state as CutoffCardState
	if not current:
		return -1
	return current.state

# 功能：判断当前是否处于销毁状态。
func is_destroying() -> bool:
	return get_current_state_id() == CutoffCardState.DESTROY

# 功能：重置所有销毁区域的高亮显示。
func reset_destroy_area_highlight() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	#if not tree.has_group("destroy_area"):
		#return
	for area in tree.get_nodes_in_group("destroy_area"):
		area.modulate = Color.WHITE

# 功能：执行卡牌缩放补间。
func tween_scale_to(target_scale: Vector2, duration: float, tween_trans: Tween.TransitionType, tween_ease: Tween.EaseType = Tween.EASE_OUT) -> void:
	if scale_tween and scale_tween.is_valid():
		scale_tween.kill()
	scale_tween = create_tween().set_trans(tween_trans).set_ease(tween_ease)
	scale_tween.tween_property(self, "scale", target_scale, duration)

# 功能：执行卡牌 Y 轴位移补间。
func tween_position_y_to(target_y: float, duration: float, tween_trans: Tween.TransitionType, tween_ease: Tween.EaseType = Tween.EASE_OUT) -> void:
	if pos_y_tween and pos_y_tween.is_valid():
		pos_y_tween.kill()
	pos_y_tween = create_tween().set_trans(tween_trans).set_ease(tween_ease)
	pos_y_tween.tween_property(self, "position:y", target_y, duration)

# 功能：执行卡牌旋转补间。
func tween_rotation_to(target_rotation_degrees: float, duration: float, tween_trans: Tween.TransitionType, tween_ease: Tween.EaseType = Tween.EASE_OUT) -> void:
	if rot_tween and rot_tween.is_valid():
		rot_tween.kill()
	rot_tween = create_tween().set_trans(tween_trans).set_ease(tween_ease)
	rot_tween.tween_property(self, "rotation_degrees", target_rotation_degrees, duration)

# 功能：记录布局锚点（用于待机回位与扇形恢复）。
func set_layout_anchor(y_pos: float, rot_deg: float) -> void:
	layout_anchor_y = y_pos
	layout_anchor_rotation = rot_deg
	layout_anchor_ready = true

# 功能：返回布局锚点 Y。
func get_layout_anchor_y() -> float:
	return layout_anchor_y

# 功能：返回布局锚点旋转角。
func get_layout_anchor_rotation() -> float:
	return layout_anchor_rotation

# 功能：判断布局锚点是否已准备完成。
func is_layout_anchor_ready() -> bool:
	return layout_anchor_ready

# 功能：停止位置与旋转相关补间，避免重排时与状态 Tween 冲突。
func stop_position_rotation_tweens() -> void:
	if pos_y_tween and pos_y_tween.is_valid():
		pos_y_tween.kill()
	if rot_tween and rot_tween.is_valid():
		rot_tween.kill()

# 功能：设置卡牌基础层级，并立即刷新可视层级。
func set_base_z_index(value: int) -> void:
	base_z_index = value
	refresh_visual_z_index()

# 功能：获取卡牌基础层级。
func get_base_z_index() -> int:
	return base_z_index

# 功能：按当前状态刷新可视层级，避免悬停后层级漂移。
func refresh_visual_z_index() -> void:
	var state_id = get_current_state_id()
	if state_id == CutoffCardState.HOVERED:
		z_index = base_z_index + Z_BOOST_HOVER
		return
	if state_id == CutoffCardState.DRAGGING:
		z_index = base_z_index + Z_BOOST_DRAGGING
		return
	if state_id == CutoffCardState.DESTROY:
		z_index = base_z_index + Z_BOOST_DESTROY
		return
	z_index = base_z_index

# 功能：按屏幕底边对齐规则计算悬停目标 Y（支持轻微超出屏幕）。
func get_hover_y_by_bottom(target_scale: Vector2, bottom_overflow: float = 4.0, top_margin: float = 8.0) -> float:
	var viewport_height = get_viewport_rect().size.y
	if viewport_height <= 1.0:
		return position.y

	var scaled_height = size.y * target_scale.y
	var unscaled_height = size.y
	var top_offset = (unscaled_height - scaled_height) * 0.5

	var parent_control = get_parent() as Control
	var parent_y = 0.0
	if parent_control:
		parent_y = parent_control.global_position.y

	var desired_bottom = viewport_height + bottom_overflow
	var target_y = desired_bottom - parent_y - top_offset - scaled_height

	var global_top = parent_y + target_y + top_offset
	if global_top < top_margin:
		target_y += top_margin - global_top

	return target_y

# 功能：按安全边距约束计算悬停目标 Y（通用兜底方法）。
func get_safe_hover_y(desired_y: float, target_scale: Vector2, margin: float = 14.0) -> float:
	var safe_y = desired_y
	var viewport_height = get_viewport_rect().size.y
	if viewport_height <= 1.0:
		return safe_y

	var scaled_height = size.y * target_scale.y
	var unscaled_height = size.y
	var top_offset = (unscaled_height - scaled_height) * 0.5

	var parent_control = get_parent() as Control
	var parent_y = 0.0
	if parent_control:
		parent_y = parent_control.global_position.y

	var global_top = parent_y + safe_y + top_offset
	var global_bottom = global_top + scaled_height

	if global_top < margin:
		safe_y += margin - global_top
		global_top = parent_y + safe_y + top_offset
		global_bottom = global_top + scaled_height

	var bottom_limit = viewport_height - margin
	if global_bottom > bottom_limit:
		safe_y -= global_bottom - bottom_limit

	return safe_y

# 功能：设置是否允许交互，并在必要时切换 NO_INTERACT/IDLE 状态。
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

# 功能：取消出牌过程并重置卡牌视觉状态。
func cancel_play() -> void:
	if not state_machine or not state_machine.current_state:
		return

	var mat = card_img.material as ShaderMaterial
	if mat and mat.get("shader_parameter/dissolve_value") < 1.0:
		var t = create_tween()
		t.tween_property(mat, "shader_parameter/dissolve_value", 1.0, 0.1)

	if scale_tween and scale_tween.is_valid():
		scale_tween.kill()
	if pos_y_tween and pos_y_tween.is_valid():
		pos_y_tween.kill()
	if rot_tween and rot_tween.is_valid():
		rot_tween.kill()

	modulate = Color.WHITE
	scale = Vector2.ONE
	name_label.modulate.a = 1.0
	value_label.modulate.a = 1.0
	reset_destroy_area_highlight()

	shadow_alpha_current = shadow_alpha_idle
	if shadow:
		var shadow_mat = shadow.material as ShaderMaterial
		if shadow_mat:
			shadow_mat.set("shader_parameter/alpha", shadow_alpha_idle)

	mouse_filter = Control.MOUSE_FILTER_STOP if interactable else Control.MOUSE_FILTER_IGNORE
	refresh_visual_z_index()

	if interactable:
		var current = state_machine.current_state as CutoffCardState
		if current and current.state != CutoffCardState.IDLE:
			state_machine.transition_to(CutoffCardState.IDLE)
