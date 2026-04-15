class_name CutoffCardState
extends CutoffState

# 枚举：卡牌状态编号（兼容 CutoffCardState.States.IDLE 写法）。
enum States { IDLE, HOVERED, DRAGGING, DESTROY, NO_INTERACT }

# 常量：兼容旧代码直接使用 CutoffCardState.IDLE 等写法。
const IDLE: int = States.IDLE
# 常量：兼容旧代码直接使用 CutoffCardState.HOVERED 等写法。
const HOVERED: int = States.HOVERED
# 常量：兼容旧代码直接使用 CutoffCardState.DRAGGING 等写法。
const DRAGGING: int = States.DRAGGING
# 常量：兼容旧代码直接使用 CutoffCardState.DESTROY 等写法。
const DESTROY: int = States.DESTROY
# 常量：兼容旧代码直接使用 CutoffCardState.NO_INTERACT 等写法。
const NO_INTERACT: int = States.NO_INTERACT

# 变量：状态所属的卡牌节点引用。
var card: Control

# 功能：判断当前状态下卡牌是否允许交互。
func can_interact() -> bool:
	return card != null and card.interactable

# 功能：处理控件级输入（由子类按需重写）。
func on_gui_input(_event: InputEvent) -> void:
	pass

# 功能：处理全局输入（由子类按需重写）。
func on_input(_event: InputEvent) -> void:
	pass

# 功能：处理鼠标进入事件（由子类按需重写）。
func on_mouse_entered() -> void:
	pass

# 功能：处理鼠标离开事件（由子类按需重写）。
func on_mouse_exited() -> void:
	pass
