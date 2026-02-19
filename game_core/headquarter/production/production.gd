class_name Production

# 生产任务类
class ProductionLine:
	var id : int
	var recipe: RecipeData.RecipeTemplate  # 配方模板
	var active_num: int  # 正在生产的数量
	var production_cap:int #生产上限 	0表示无上限
	var inputs: Dictionary  # 输入物品字典，键为物品ID，值为数量
	var outputs: Dictionary  # 输出物品字典，键为物品ID，值为数量
	var require_source_building: bool  # 是否需要来源建筑
	var require_preposition_building: bool  # 是否需要前置建筑
	var source_building_num: int
	var has_preposition_building: bool  # 是否有前置建筑
	var status = {
		"is_inputs_not_enough": false
	}
	
	func _init(p_id: int, p_recipe: RecipeData.RecipeTemplate):
		id = p_id
		recipe = p_recipe
		active_num = 0
		production_cap = 0

		if recipe.source_building != "":
			require_source_building = true
		else:
			require_source_building = false
		
		if recipe.preposition_building != "":
			require_preposition_building = true
		else:
			require_preposition_building = false
		
		source_building_num = 0
		has_preposition_building = false
	
	#自动更新
	func update(p_source_building_num: int, p_has_preposition_building: bool):
		source_building_num = p_source_building_num
		has_preposition_building = p_has_preposition_building
	
	#手动设置
	func set_active_num(p_active_num: int):
		active_num = p_active_num
		
		# 清空之前的输入输出
		inputs.clear()
		outputs.clear()
		
		# 根据活动数量计算输入和输出
		for item_id in recipe.inputs:
			inputs[item_id] = recipe.inputs[item_id] * active_num
		
		for item_id in recipe.outputs:
			outputs[item_id] = recipe.outputs[item_id] * active_num
	
	func set_production_cap(p_production_cap: int):
		production_cap = p_production_cap
		
# 生产管理器
var headquarter: Headquarter = null  # 所属总部
var production_lines: Dictionary = {}  # 所有生产任务
# 供需表格，记录每个物品的产量和消耗量 {item_id: {"supply": int, "demand": int}}
var supply_demand: Dictionary = {}

func _init(p_headquarter: Headquarter):
	headquarter = p_headquarter
	for recipe in RecipeData.get_all_recipes():
		production_lines[len(production_lines)] = ProductionLine.new(len(production_lines), recipe)

	_initialize_supply_demand()
	headquarter.buildings_changed.connect(update_production_lines)

func on_turn_start():
	# 每回合开始时处理生产
	process_production()

#建造新的建筑之后自动调用
func update_production_lines():
	for production_line in production_lines.values():
		var source_building_count = 0
		var has_preposition_building = false
		if production_line.require_source_building or production_line.require_preposition_building:
			for building in headquarter.buildings:
				if building.building_info.id == production_line.recipe.source_building and building.is_finished:
					source_building_count += 1
				if building.building_info.id == production_line.recipe.preposition_building and building.is_finished:
					has_preposition_building = true
			production_line.update(source_building_count, has_preposition_building)
			headquarter.production_line_changed.emit()

func set_production_line_active_num(line_id: int, active_num: int):
	production_lines[line_id].set_active_num(active_num)

# 处理生产（每回合调用）
func process_production():
	for production_line in production_lines.values():
		# 初始化状态
		production_line.status["is_inputs_not_enough"] = false
		# 如果正在生产的数量为0，则不进行生产
		if production_line.active_num <= 0:
			continue
		
		# 检查是否有足够的输入物品
		if not headquarter.inventory.has_enough_resources(production_line.inputs):
			production_line.status["is_inputs_not_enough"] = true
			continue
		
		# 消耗输入物品
		headquarter.inventory.consume_resources(production_line.inputs)

		headquarter.inventory.replenish_resources(production_line.outputs)
		
		# 完成生产
		complete_production(production_line)

# 完成一个生产周期
func complete_production(production_line: ProductionLine):
	_initialize_supply_demand()
	for item_id in production_line.inputs:
		update_item_demand_and_supply(item_id, production_line.inputs[item_id], 0)
	for item_id in production_line.outputs:
		update_item_demand_and_supply(item_id, 0, production_line.outputs[item_id])

# 获取所有生产任务
func get_production_lines() -> Array[ProductionLine]:
	var result:Array[ProductionLine] = []
	for production_line in production_lines.values():
			result.append(production_line)
	return result

func get_production_line_by_id(line_id: int) -> ProductionLine:
	return production_lines[line_id]

func get_productionlines_by_main_product_id(product_id: String) -> Array[ProductionLine]:
	var result:Array[ProductionLine] = []
	for production_line in production_lines.values():
		if production_line.recipe.main_product == product_id:
			result.append(production_line)
	return result

# 初始化（重置）供需表格
func _initialize_supply_demand():
	for item_template in ItemData.get_all_item_templates():
		supply_demand[item_template.id] = {
			"supply": 0,
			"demand": 0
		}

# 更新物品 的 供需
func update_item_demand_and_supply(item_id: String, demand_amount: int, supply_amount: int):
	supply_demand[item_id]["demand"] += demand_amount
	supply_demand[item_id]["supply"] += supply_amount
