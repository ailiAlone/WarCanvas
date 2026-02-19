extends VBoxContainer
class_name TradingMenu

# 引用场景节点
@onready var items_container = $ItemsContainer

# 引用trading_item场景
var trading_item_scene = preload("res://game_core/game_ui/menu_ui/trading_menu/trading_item/trading_item.tscn")

func _ready() -> void:
	ItemData._initialize_item_templates()
	for item in ItemData.get_all_item_templates():
		# 实例化trading_item场景
		var trading_item = trading_item_scene.instantiate()
		items_container.add_child(trading_item)
		trading_item.name = item.id.validate_node_name()
		# 设置物品数据
		trading_item.set_item_template(item)
	
# 更新关联的当地市场
func set_local_market(local_market: Dictionary, headquarter: Headquarter):
	# 更新物品数量和价格
	for trading_item in items_container.get_children():
		if trading_item is TradingItem:
			trading_item.update_item_data(local_market, headquarter)

func update():
	# 更新UI
	for trading_item in items_container.get_children():
		if trading_item is TradingItem:
			trading_item.update()
