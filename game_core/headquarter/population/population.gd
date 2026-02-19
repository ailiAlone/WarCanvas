class_name Population

# 人口基础属性
var _idle_population: int = 0  	# 闲置人口
var _work_population: int = 0  	# 工作人口
var _idle_military: int = 0    	# 闲置兵役人口
var _engaged_military: int = 0  # 已工作人口

# 人口系统参数
var population_capacity: int = 0           # 人口容量
var military_population_capacity: int = 0  # 兵役人口容量
var consumable_food: int = 0               # 可直接食用的食物
var potential_food: int = 0                # 潜在食物数量             
var population_growth_rate: float = 0.05   # 每回合人口增长率 (5%)
var base_population_growth: int = 10       # 基础人口增长值

# 人口增长参数
var food_consumption_per_person: float = 0.1  # 每人每回合食物消耗
var minimum_food_for_growth: float = 0.8      # 人口增长所需最低食物比例

var _headquarter: Headquarter = null

# 获取总人口数  当前总人口 = 闲置人口 + 工作人口 + 兵役人口
func get_total_population() -> int:
	return _idle_population + _work_population + _idle_military + _engaged_military
		
	# 获取人口容量
func get_population_capacity() -> int:
	return population_capacity

# 获取兵役人口容量
func get_military_population_capacity() -> int:
	return military_population_capacity

# 初始化人口系统
func _init(headquarter: Headquarter,idle_population: int,military_population: int):
	_headquarter = headquarter
	# 初始化人口
	_idle_population = idle_population
	_idle_military = military_population
	
# 处理人口增长
func process_population_growth():
	# 计算人口增长
	var growth_amount = _calculate_population_growth()
	
	# 应用人口增长（只有当增长为正数时才处理）
	if growth_amount > 0:
		# 人口增加，添加到当前人口
		_idle_population += growth_amount
		print("人口增长了 %d，当前总人口: %d" % [growth_amount, get_total_population()])
		
		#emit_signal("population_growth_occurred", growth_amount)
		_headquarter.population_changed.emit()
	elif growth_amount < 0:
		# 增长为负时，不执行减少逻辑，只记录信息
		print("人口增长为负值 %d，忽略本次增长" % growth_amount)

# 计算人口增长
func _calculate_population_growth() -> int:
	# 基础增长
	var growth = base_population_growth

	# 百分比增长（基于当前人口）
	var percentage_growth = int(get_total_population() * population_growth_rate)
	growth += percentage_growth
	
	# 食物影响
	var total_food = consumable_food + potential_food
	var food_ratio = float(total_food) / (get_total_population() * food_consumption_per_person) if get_total_population() > 0 else 1.0
	
	# 食物充足时增加增长，食物不足时减少增长
	if food_ratio > 1.2:  # 食物非常充足
		growth = int(growth * 1.5)
	elif food_ratio > 1.0:  # 食物充足
		growth = int(growth * 1.2)
	elif food_ratio > 0.8:  # 食物基本够用
		growth = int(growth * 1.0)
	elif food_ratio > 0.6:  # 食物略有不足
		growth = int(growth * 0.8)
	elif food_ratio > 0.4:  # 食物不足
		growth = int(growth * 0.5)
	else:  # 食物严重不足
		growth = int(growth * 0.2)
	
	# 容量限制（只限制正向增长）
	if growth > 0 and get_total_population() + growth > population_capacity:
		growth = population_capacity - get_total_population()
	
	# 返回增长值（可以为负数）
	return growth

# 分配人口到兵役
func assign_to_military(amount: int) -> bool:
	if _idle_population >= amount:
		_idle_population -= amount
		_idle_military += amount
		# # 检查是否超过兵役人口容量
		# if _idle_military > military_population_capacity:
		# 	return false
		print("成功分配 %d 人口到兵役,当前闲置兵役人口: %d" % [amount, _idle_military])
		_headquarter.population_changed.emit()
		return true
	else:
		print("分配失败,闲置人口不足,需要 %d,但只有 %d" % [amount, _idle_population])
		return false

# 从兵役中解除人口
func release_from_military(amount: int) -> bool:
	if _idle_military >= amount:
		_idle_military -= amount
		_idle_population += amount
		print("成功从兵役中解除 %d 人口,当前闲置兵役人口: %d" % [amount, _idle_military])
		_headquarter.population_changed.emit()
		return true
	else:
		print("解除失败,Idle兵役人口不足,需要 %d,但只有 %d" % [amount, _idle_military])
		return false

# 外部调用 直接减少
func reduce_idle_military(amount: int) -> bool:
	if _idle_military >= amount:
		_idle_military -= amount
		print("成功减少 %d Idle兵役人口,当前闲置兵役人口: %d" % [amount, _idle_military])
		_headquarter.population_changed.emit()
		return true
	else:
		print("减少失败,Idle兵役人口不足,需要 %d,但只有 %d" % [amount, _idle_military])
		return false
		
# 外部调用 直接减少
func reduce_idle_population(amount: int) -> bool:
	if _idle_population >= amount:
		_idle_population -= amount
		print("成功减少 %d Idle人口,当前闲置人口: %d" % [amount, _idle_population])
		_headquarter.population_changed.emit()
		return true
	else:
		print("减少失败,Idle人口不足,需要 %d,但只有 %d" % [amount, _idle_population])
		return false

func on_turn_start():
	# 扫描人口建筑并计算人口容量
	_scan_population_buildings()
	
	# 处理人口增长
	process_population_growth()
	
	# 处理食物消耗
	process_food_consumption()
	
	# 处理肃清抵抗状态对兵役人口的影响
	_process_clearing_resistance_effect()


# 处理肃清抵抗状态对兵役人口的影响
func _process_clearing_resistance_effect():
	# 检查_headquarter是否为Settlement类型且具有clearing_resistance状态
	if _headquarter is Settlement:
		var settlement: Settlement = _headquarter as Settlement
		if settlement.governance_statuses["clearing_resistance"]["active"]:
			var clearing_status = settlement.governance_statuses["clearing_resistance"]
			if _idle_military > 0:
				# 计算减少量：兵役人口的25%
				var reduce_amount = int(_idle_military * 0.25)
				
				# 计算所有来源中population系统总人口总和的10%
				var total_sources_population = 0
				for battalion_name in clearing_status.sources:
					var source:Battalion = clearing_status.sources[battalion_name]
					total_sources_population += source.unit.info.armySize
				
				# 取两者中的较大值作为最终减少量
				reduce_amount = max(reduce_amount, total_sources_population)
				
				# 确保减少量不超过当前兵役人口
				reduce_amount = min(reduce_amount, _idle_military)
				
				# 应用减少
				_idle_military -= reduce_amount
				print("肃清抵抗状态影响：Idle兵役人口减少 %d，当前闲置兵役人口: %d" % [reduce_amount, _idle_military])
				_headquarter.population_changed.emit()

func process_food_consumption():
	# 计算总消耗
	var total_food_consumption = get_total_population() * food_consumption_per_person
	
	# 从库存中获取实际食物数量
	var available_food = _headquarter.inventory.get_food()
	
	# 如果食物不足，只能消耗可用食物
	var actual_consumption = min(total_food_consumption, available_food)
	
	# 消耗食物（从库存中扣除Foodstuffs类别的物品）
	if actual_consumption > 0:
		_consume_food_from_inventory(actual_consumption)
	
	# 记录消耗情况
	if actual_consumption < total_food_consumption:
		print("食物不足！需要 %d 食物，但只有 %d 可用，实际消耗: %d" % [total_food_consumption, available_food, actual_consumption])
	else:
		pass
		# print("消耗了 %d 食物，剩余食物: %d" % [actual_consumption, available_food - actual_consumption])

# 从库存中消耗食物
func _consume_food_from_inventory(food_amount: int):
	var remaining_food = food_amount
	
	# 获取所有Foodstuffs类别的物品
	var food_items = []
	var food_templates = ItemData.get_items_by_category("Foodstuffs")
	for item_template in food_templates:
		var item_quantity = _headquarter.inventory.get_item_quantity(item_template.id)
		if item_quantity > 0:
			food_items.append({
				"item_id": item_template.id,
				"quantity": item_quantity,
				"food_rate": item_template.food_rate
			})
	
	# 按食物转化率排序（从高到低），优先消耗转化率高的食物
	food_items.sort_custom(func(a, b): return a.food_rate > b.food_rate)
	
	# 计算需要消耗的物品数量
	var items_to_consume = {}
	
	# 计算消耗策略
	for food_item in food_items:
		if remaining_food <= 0:
			break
		
		# 计算这个物品能提供的食物量
		var available_food_from_item = food_item.quantity * food_item.food_rate
		
		if available_food_from_item <= remaining_food:
			# 消耗全部这个物品
			items_to_consume[food_item.item_id] = food_item.quantity
			remaining_food -= available_food_from_item
			# print("计划消耗全部 %s (%d 单位)，提供 %d 食物" % [food_item.item_id, food_item.quantity, available_food_from_item])
		else:
			# 消耗部分这个物品
			var items_needed = int(remaining_food / food_item.food_rate)
			# 确保至少消耗1个单位
			items_needed = max(1, items_needed)
			var food_provided = items_needed * food_item.food_rate
			items_to_consume[food_item.item_id] = items_needed
			remaining_food -= food_provided
			# print("计划消耗 %d 单位 %s，提供 %d 食物" % [items_needed, food_item.item_id, food_provided])
	
	# 使用标准的consume_resources方法消耗资源
	if items_to_consume.size() > 0:
		# 检查资源是否足够
		if _headquarter.inventory.has_enough_resources(items_to_consume):
			# 消耗资源
			if _headquarter.inventory.consume_resources(items_to_consume):
				# print("成功消耗食物资源：%s" % items_to_consume)
				# 更新供需统计：记录食物消耗量
				for item_id in items_to_consume:
					_headquarter.production.update_item_demand_and_supply(item_id, items_to_consume[item_id], 0)
			else:
				print("消耗食物资源失败：%s" % items_to_consume)
		else:
			print("食物资源不足，无法消耗：%s" % items_to_consume)
	else:
		print("没有需要消耗的食物资源")

# 扫描人口建筑并计算人口容量
func _scan_population_buildings():
	# 检查_headquarter是否为Settlement类型
	if not (_headquarter is Settlement):
		print("警告：总部不是Settlement类型，无法扫描人口建筑")
		return
	
	var settlement = _headquarter as Settlement
	
	# 获取所有已建成的人口建筑
	var buildings = settlement.get_buildings_is_finished_by_category("POPULATION")
	
	# 计算总人口容量
	var total_capacity = 0
	for building in buildings:
		# 累加每个建筑的人口容量
		total_capacity += building.building_info.capacity

	population_capacity = total_capacity

	# 获取所有已建成的兵营建筑
	buildings = settlement.get_buildings_is_finished_by_id("BARRACKS")

	# 计算兵役人口容量
	total_capacity = 0
	for building in buildings:
		# 累加每个建筑的人口容量
		total_capacity += building.building_info.capacity

	military_population_capacity = total_capacity
	_headquarter.population_changed.emit()

func get_working_population():
	#遍历所有生产线，累加 激活数量 * 每单位的生产线工人数
	var working_population = 0
	for production_line in _headquarter.production.production_lines.values():
		working_population += production_line.active_num * production_line.recipe.worker_num
	
	if _headquarter is Settlement:
		#遍历所有在建建筑，累加所有建筑的工人数
		for building:Building in _headquarter.buildings:
			if not building.is_finished:
				working_population += building.constructor_num
	
	return working_population

func get_idle_population() -> int:
	return _idle_population

func get_idle_military() -> int:
	return _idle_military

func get_engaged_military() -> int:
	return _engaged_military
