class_name ItemStock

# 物品库存信息类
class ItemEntry:
	var item_id: String                # 物品ID
	var quantity: int                  # 物品数量
	
	func _init(p_item_id: String, p_quantity: int = 0):
		item_id = p_item_id
		quantity = p_quantity
	
	# 获取物品总重量
	func get_total_weight() -> float:
		var template = ItemData.get_item_template(item_id)
		return quantity * (template.unit_weight if template else 0)

	
# 物品库存管理
var item_entries: Dictionary = {}  # {item_id: ItemEntry}

# 基本资源
var _money: int = 0
var _headquarter: Headquarter = null

# 初始化
func _init( headquarter: Headquarter = null,inventory:Dictionary = {},money:int = 0):
	_money = money
	# 初始化物品库存
	_initialize_all_items(inventory)
	_headquarter = headquarter

# 初始化所有物品
func _initialize_all_items(inventory:Dictionary = {}):
	# 获取所有物品模板
	# 为所有物品创建库存记录，初始数量为0
	if inventory != {}:
		for item_id in inventory:
			var item_entry = ItemEntry.new(item_id, inventory[item_id])
			item_entries[item_id] = item_entry
	else:
		for item_template in ItemData.get_all_item_templates():
			var item_entry = ItemEntry.new(item_template.id, 100)
			item_entries[item_template.id] = item_entry
		
	push_error("物品大量初始化完成，仅测试")

# 获取食物数量
func get_food() -> int:
	var total_food = 0
	
	# 计算Foodstuffs类别物品的食物总量
	for item_id in item_entries:
		var item_template = ItemData.get_item_template(item_id)
		if item_template and item_template.category == "Foodstuffs":
			var item_quantity = item_entries[item_id].quantity
			var food_rate = item_template.food_rate 
			total_food += item_quantity * food_rate
	
	return total_food

# 获取金钱数量
func get_money() -> int:
	return _money

# 设置金钱数量
func set_money(amount: int):
	_money = amount

func set_item_quantity(item_id: String, amount: int):
	item_entries[item_id].quantity = amount
	_headquarter.inventory_changed.emit()

# 获取物品数量
func get_item_quantity(item_id: String) -> int:
	return item_entries[item_id].quantity

# 获取所有物品库存
func get_all_items() -> Dictionary:
	return item_entries.duplicate(true)

# 获取物品库存信息
func get_item_entry(item_id: String) -> ItemEntry:
	return item_entries.get(item_id, null)

# 检查是否有足够的资源（包括基本资源和物品）
func has_enough_resources(required_items: Dictionary) -> bool:
	# 检查物品
	for item_id in required_items:
		if not get_item_quantity(item_id) >= required_items[item_id]:
			return false
	return true

# 消耗资源
func consume_resources(required_items: Dictionary) -> bool:
	if not has_enough_resources(required_items):
		return false
	# 消耗物品
	for item_id in required_items:
		if _headquarter is Settlement:
			var popup_effect = preload("res://game_core/game_ui/popup_effect/popupeffect.tscn").instantiate()
			_headquarter.add_child(popup_effect)
			# await _headquarter.get_tree().process_frame
			popup_effect.show_resource_loss(ItemData.get_item_template(item_id).name, required_items[item_id], (_headquarter as Settlement).badge.position)
		set_item_quantity(item_id, get_item_quantity(item_id) - required_items[item_id])
	return true

# 添加资源
func replenish_resources(resources: Dictionary):
	# 添加物品
	for item_id in resources:
		# 使用物资增加特效
		if _headquarter is Settlement:
			var popup_effect = preload("res://game_core/game_ui/popup_effect/popupeffect.tscn").instantiate()
			_headquarter.add_child(popup_effect)
			# await _headquarter.get_tree().process_frame
			popup_effect.show_resource_gain(ItemData.get_item_template(item_id).name, resources[item_id], (_headquarter as Settlement).badge.position)
		set_item_quantity(item_id, get_item_quantity(item_id) + resources[item_id])

# 获取库存总价值
func get_total_value() -> int:
	var total = _money  # 金钱直接计入总价值
	
	# 计算物品总价值
	for item_id in item_entries:
		total += item_entries[item_id].quantity * ItemData.get_item_template(item_id).base_price
	
	return total

# 获取库存总重量
func get_total_weight() -> float:
	var total = 0.0
	
	# 计算物品总重量
	for item_id in item_entries:
		total += item_entries[item_id].get_total_weight()
	
	return total

# 清空库存
func clear_inventory():
	item_entries.clear()

# 获取库存摘要
func get_inventory_summary() -> Dictionary:
	var summary = {
		"food": get_food(),
		"money": _money,
		"items": {},
		"total_value": get_total_value(),
		"total_weight": get_total_weight()
	}
	
	# 添加物品摘要
	for item_id in item_entries:
		var entry = item_entries[item_id]
		summary.items[item_id] = entry.quantity
			
	return summary
