class_name CutoffStateMachine
extends Node

# 变量：当前激活状态实例。
var current_state: CutoffState
# 变量：上一个状态实例，用于转场后判断来源状态。
var previous_state: CutoffState
# 变量：状态字典，键为状态编号，值为状态节点。
var states: Dictionary = {}
# 变量：状态机宿主卡牌节点。
var owner_card: Control

# 功能：初始化状态机，绑定所有子状态并进入默认状态。
func init_state(card: Control) -> void:
	owner_card = card
	states.clear()
	previous_state = null
	current_state = null

	var default_state: CutoffState = null
	for child in get_children():
		if not (child is CutoffState):
			continue
		var state_node := child as CutoffState
		if default_state == null:
			default_state = state_node
		if state_node is CutoffCardState:
			(state_node as CutoffCardState).card = owner_card
		states[state_node.state] = state_node
		if not state_node.transition_requested.is_connected(_on_transition_requested):
			state_node.transition_requested.connect(_on_transition_requested)

	if default_state:
		current_state = default_state
		current_state.enter()

# 功能：驱动当前状态执行逐帧更新。
func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

# 功能：处理状态切换请求，执行 exit/enter 并通知宿主。
func _on_transition_requested(from: CutoffState, to: int) -> void:
	if from != current_state:
		return
	var new_state = states.get(to) as CutoffState
	if not new_state:
		return
	if new_state == current_state:
		return

	current_state.exit()
	previous_state = current_state
	current_state = new_state
	new_state.enter()

	if owner_card and owner_card.has_method("_on_state_transitioned"):
		owner_card._on_state_transitioned(previous_state.state, current_state.state)

# 功能：对外暴露状态切换接口。
func transition_to(target_state: int) -> void:
	if not current_state:
		return
	_on_transition_requested(current_state, target_state)
