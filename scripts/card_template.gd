extends Control
# 声明一个自定义的singal信号
signal card_clicked(index:int)
@onready var card_color_bg: ColorRect = $CardColorBG
@onready var card_color_ft: ColorRect = $CardColorFT
@onready var name_label: Label = $NameLabel
@onready var value_label: Label = $ValueLabel

var card_index:int = -1

# 获取game_manager传入的卡牌字典值和卡牌索引
func setup_card(data:Dictionary, index:int):
	card_index = index
	name_label.text = data["name"]
	value_label.text = data["description"]
# 监听鼠标输入
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			emit_signal("card_clicked", card_index)
