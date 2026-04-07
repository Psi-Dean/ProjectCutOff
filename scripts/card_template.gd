extends Control
# 声明一个自定义的singal信号
signal card_clicked(index:int)
@onready var card_color_bg: ColorRect = $CardColorBG
@onready var card_color_ft: ColorRect = $CardColorFT
@onready var name_label: Label = $NameLabel
@onready var value_label: Label = $ValueLabel

var card_index:int = -1
# 位移距离变量
var hover_offset:float = 30
# 放大比例变量
var scale_factor: Vector2 = Vector2(1.4, 1.4)
# 定义补间动画变量
var tween: Tween

var is_selected: bool = false
var is_hovering: bool = false

func _ready() -> void:
	mouse_entered.connect(self._on_mouse_entered)
	mouse_exited.connect(self._on_mouse_exited)
	# Godot中所有节点的默认轴心点(pivot)都在左上角(0,0)
	# 将卡牌轴心点设置为custom_minimum_size的一半，即中心点
	pivot_offset = size / 2
	
# 获取game_manager传入的卡牌字典值和卡牌索引
func setup_card(data:Dictionary, index:int):
	card_index = index
	name_label.text = data["name"]
	value_label.text = data["description"]
# 监听鼠标输入
func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton):
		if (event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
			emit_signal("card_clicked", card_index)

func set_card_style(selected:bool):
	is_selected = selected
	if is_selected:
		z_index = 1
		card_color_bg.color = Color("fd1d44ff")
		#if tween: 
			#tween.kill()
		#tween = create_tween()
		#tween.tween_property(self, "scale", scale_factor, 0.2)\
			#.set_trans(Tween.TRANS_BACK)\
			#.set_ease(Tween.EASE_OUT)
	else:
		z_index = 0
		card_color_bg.color = Color("17a5feff")
		#if tween: 
			#tween.kill()
		#tween = create_tween()
		#tween.tween_property(self, "scale", Vector2(1, 1), 0.3)\
			#.set_trans(Tween.TRANS_SINE)\
			#.set_ease(Tween.EASE_OUT)
	update_card_visuals()
	
func _on_mouse_entered():
	# 单独使用这种写法存在隐患：如果鼠标进出极快，导致旧动画未播放完，新动画抢夺控制
	# 会导致卡牌抖动或者停止半空中
	#create_tween().tween_property(self, "position:y", -hover_offset, 0.1)
	
	# 优化方法
	# 如果存在旧动画播放，直接终止
	#if tween: 
		#tween.kill()
	#tween = create_tween()
	# 将卡牌移到上层
	#z_index = 1
	# 动画1向上位移
	# tween函数末尾增加\使用链式调用：设置过渡为 BACK (回弹)，缓动为 OUT (末端减速)
	#tween.tween_property(self, "position:y", -hover_offset, 0.2)\
		#.set_trans(Tween.TRANS_BACK)\
		#.set_ease(Tween.EASE_OUT)
	#tween.tween_property(self, "scale", scale_factor, 0.2)\
		#.set_trans(Tween.TRANS_BACK)\
		#.set_ease(Tween.EASE_OUT)
	z_index = 1
	is_hovering = true
	update_card_visuals()
	
func _on_mouse_exited():
	#create_tween().tween_property(self, "position:y", 0, 0.1)
	#if tween: 
		#tween.kill()
	#tween = create_tween()
	#z_index = 0
	# 离开时用 SINE，让它平稳落回，不要太晃
	#tween.tween_property(self, "position:y", 0, 0.3)\
		#.set_trans(Tween.TRANS_SINE)\
		#.set_ease(Tween.EASE_OUT)
	#tween.tween_property(self, "scale", Vector2(1, 1), 0.3)\
		#.set_trans(Tween.TRANS_SINE)\
		#.set_ease(Tween.EASE_OUT)
	z_index = 0
	is_hovering = false
	update_card_visuals()
	
func update_card_visuals():
	if tween: 
		tween.kill()
	tween = create_tween().set_parallel(true)
	# 逻辑1,只要悬停或者选中，卡牌保持升起
	#var target_y = -hover_offset
	#if is_hovering or is_selected:
		#target_y = -hover_offset
	#else:
		#target_y = 0
	# 采用三元逻辑写法，简化上面的if else
	var target_y = -hover_offset if(is_hovering or is_selected) else 0
	tween.tween_property(self, "position:y", target_y, 0.2).set_trans(Tween.TRANS_SINE)
	# 逻辑2，只有选中卡牌才放大
	var target_scale = scale_factor if is_selected else Vector2(1,1)
	tween.tween_property(self, "scale", target_scale, 0.2).set_trans(Tween.TRANS_SINE)
