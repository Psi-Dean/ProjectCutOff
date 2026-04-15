class_name CutoffState
extends Node

# 信号：状态请求从当前状态切换到目标状态。
signal transition_requested(from: CutoffState, to: int)

# 变量：当前状态编号，由子类在 _init() 中设置。
var state: int = -1

# 功能：进入状态时执行一次。
func enter() -> void:
	pass

# 功能：退出状态时执行一次。
func exit() -> void:
	pass

# 功能：状态逐帧更新。
func update(_delta: float) -> void:
	pass
