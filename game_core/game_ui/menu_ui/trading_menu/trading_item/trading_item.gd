extends Control
class_name TradingItem

# 引用节点
@onready var number_spin_box = $TradingContainer/NumberSpinBox

# 需要频繁更新的UI节点
@onready var inventory_value = $InfoContainer/Info/Inventory/Value
@onready var demand_value = $InfoContainer/Info/Demand/value
@onready var supply_value = $InfoContainer/Info/Supply/value
@onready var buy_price_label = $TradingContainer/BuyPriceLabel
@onready var sell_price_label = $TradingContainer/SellPriceLabel

# 当前物品模板
var _item_template: ItemData.ItemTemplate = null

var buy_price : int = 0
var sell_price : int = 0

var customer : Headquarter = null

# 交易价格倍率
const BUY_PRICE_MULTIPLIER = 1.2  # 买入价格是基础价格的1.2倍
const SELL_PRICE_MULTIPLIER = 0.8  # 卖出价格是基础价格的0.8倍

# 设置物品数据
func set_item_template(item_template: ItemData.ItemTemplate):
	_item_template = item_template
	
	# 设置物品名称
	var item_name_label = $TradingContainer/ItemNameLabel
	item_name_label.text = item_template.name
	
	# 设置物品图标
	var icon_texture = $InfoContainer/IconTextureRect
	if item_template.icon:
		icon_texture.texture = item_template.icon
	else:
		push_warning("物品图标为空: " + item_template.name)
	
	# 连接按钮信号
	var buy_button = $TradingContainer/BuyButton
	var sell_button = $TradingContainer/SellButton
	buy_button.pressed.connect(_on_buy_button_pressed)
	sell_button.pressed.connect(_on_sell_button_pressed)

# 更新物品数据
func update_item_data(local_market: Dictionary, headquarter: Headquarter):
	customer = headquarter
	
	# 更新库存、需求、供应数量（频繁更新）
	inventory_value.text = str(customer.inventory.get_item_quantity(_item_template.id))
	demand_value.text = str(customer.production.supply_demand[_item_template.id]["demand"])
	supply_value.text = str(customer.production.supply_demand[_item_template.id]["supply"])

	# 更新价格（频繁更新）
	var local_price = local_market[_item_template.id]["price"]
	
	buy_price = int(local_price * BUY_PRICE_MULTIPLIER)
	sell_price = int(local_price * SELL_PRICE_MULTIPLIER)
	
	buy_price_label.text = str(buy_price)
	sell_price_label.text = str(sell_price)

# 买入按钮按下事件 事件交给策略处理
func _on_buy_button_pressed():
	var trade_amount = int(number_spin_box.value)
	CommandBus.execute_command(BuyCommand.new(customer, _item_template.id, buy_price, trade_amount))
	update()

# 卖出按钮按下事件 事件交给策略处理
func _on_sell_button_pressed():
	var trade_amount = int(number_spin_box.value)
	CommandBus.execute_command(SellCommand.new(customer, _item_template.id, sell_price, trade_amount))
	update()
	
func update():
	# 更新UI
	# 更新库存、需求、供应数量（频繁更新）
	inventory_value.text = str(customer.inventory.get_item_quantity(_item_template.id))
	demand_value.text = str(customer.production.supply_demand[_item_template.id]["demand"])
	supply_value.text = str(customer.production.supply_demand[_item_template.id]["supply"])
