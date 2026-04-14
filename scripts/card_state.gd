class_name CutoffCardState
extends CutoffState

enum { IDLE, HOVERED, DRAGGING, DESTROY, NO_INTERACT }

var card


func can_interact() -> bool:
	return card != null and card.interactable


func on_gui_input(_event: InputEvent) -> void:
	pass


func on_input(_event: InputEvent) -> void:
	pass


func on_mouse_entered() -> void:
	pass


func on_mouse_exited() -> void:
	pass
