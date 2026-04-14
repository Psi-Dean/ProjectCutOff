class_name CutoffStateMachine
extends Node

var current_state: CutoffState
var previous_state: CutoffState
var states: Dictionary = {}
var owner_card: Control


func init_state(card: Control) -> void:
	owner_card = card
	for child in get_children():
		if child is CutoffState:
			if child is CutoffCardState:
				(child as CutoffCardState).card = owner_card
			states[child.state] = child
			child.transition_requested.connect(_on_transition_requested)
	if get_child_count() > 0:
		current_state = get_child(0) as CutoffState
		current_state.enter()


func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)


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


func transition_to(target_state: int) -> void:
	if not current_state:
		return
	_on_transition_requested(current_state, target_state)
