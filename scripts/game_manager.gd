extends Node
@onready var price_label: Label = $"../UI/PriceLabel"
@onready var test_button: Button = $"../UI/TestButton"
var current_price = 100


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	price_label.text = "当前价格:100"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass




func _on_test_button_pressed() -> void:
	current_price -= 1
	price_label.text = \
	"%s%d" % [
		"当前价格:",
		current_price
	]
