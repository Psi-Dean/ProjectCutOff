extends Resource
class_name CardData

# 变量：卡牌标题。
@export var card_title:String = ""
# 变量：卡牌描述文本。
@export var description:String = ""
# 变量：砍价值下限。
@export var min_cut_value:float = 0.00
# 变量：砍价值上限。
@export var max_cut_value:float = 0.00
# 变量：心态消耗值。
@export var mindset_cost:float = 0.00
# 变量：人气消耗值。
@export var popularity_cost:int = 0
# 变量：卡牌显示贴图。
@export var card_ui:Texture2D
# 变量：卡牌等级。
@export var level:int = 0
# 变量：卡牌升级价格。
@export var upgrade_price = 0
