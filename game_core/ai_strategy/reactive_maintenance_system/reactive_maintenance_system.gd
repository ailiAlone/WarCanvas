class_name ReactiveMaintenanceSystem
# 它的本质是 一个基于规则的反射系统。它不关心长远目标，只对当前环境的刺激做出反应，其核心驱动力是避免损失和维持稳态。
# 核心逻辑：IF (威胁/失衡) THEN (反应/修复)。

# 缺乏程度等级
enum Deficiency {
	NONE,       # 无缺乏
	MILD,       # 轻微缺乏
	MODERATE,   # 中度缺乏
	SEVERE,     # 严重缺乏
	CRITICAL    # 临界缺乏
}

# 紧急程度等级
enum Urgency {
	NONE,       # 无紧急
	LOW,        # 低紧急
	MEDIUM,     # 中紧急
	HIGH,       # 高紧急
	CRITICAL    # 临界紧急
}

#AtomicOperation(原子操作)
enum AtomicOperation {
	NO_OPERATION,          # 无操作
	RECRUIT_TROOPS,        # 征兵
	CONSTRUCT_BUILDING,    # 建造建筑
	ASSIGN_PRODUCTION,     # 安排生产
	CLEAR_PRODUCTION, 	   # 清空生产队列
	MOVE_UNITS,            # 移动单位
	ATTACK_TARGET,         # 攻击目标
	RESEARCH_TECH,         # 研究科技
	# ... 其他基础操作
}

var _headquarter: Headquarter
var _problem_queue: Array[Dictionary]
var _original__operations: Array[Dictionary]	#调试用
var _operations: Array[Dictionary]

func process_turn(headquarter: Headquarter):
	_headquarter = headquarter

	_problem_queue = []
	_original__operations = []
	_operations = []

	detect_situation()

	# 处理当前回合的所有操作
	for problem in _problem_queue:
		#过滤为可行操作
		var executable_op: Dictionary = DependencyResolver.find_executable_operation(_headquarter, problem)
		_original__operations.append(executable_op)
		if problem["type"] == DependencyResolver.ProblemType.IDLE_POPULATION_SHORTAGE:
			print(executable_op)


		if executable_op["type"] == AtomicOperation.NO_OPERATION:
			continue

		_operations.append(executable_op)
	
	# 合并相似操作
	_operations = _merge_similar_operations(_operations)
	
	# 整合对立操作（清空生产优先级高于安排生产）
	_operations = _merge_conflicting_operations(_operations)
	
	# 按优先级排序操作
	_operations = _sort_operations_by_priority(_operations)
	
	for op in _operations:
		# 执行操作
		OperationExecutor.execute_atomic_operation(_headquarter, op)

func _merge_similar_operations(operations: Array[Dictionary]) -> Array[Dictionary]:
	"""合并相似操作"""
	var merged_operations: Array[Dictionary] = []
	var processed_indices: Array[int] = []
	
	for i in range(operations.size()):
		if i in processed_indices:
			continue
			
		var current_op = operations[i]
		var similar_ops: Array[Dictionary] = [current_op]
		
		# 查找相似操作
		for j in range(i + 1, operations.size()):
			if j in processed_indices:
				continue
				
			var compare_op = operations[j]
			
			# 判断是否为相似操作
			if _are_operations_similar(current_op, compare_op):
				similar_ops.append(compare_op)
				processed_indices.append(j)
		
		# 合并相似操作
		if similar_ops.size() > 1:
			var merged_op = _merge_single_operation_group(similar_ops)
			merged_operations.append(merged_op)
		else:
			merged_operations.append(current_op)
		
		processed_indices.append(i)
	
	return merged_operations

func _merge_conflicting_operations(operations: Array[Dictionary]) -> Array[Dictionary]:
	"""整合对立操作，清空生产的优先级高于安排生产"""
	var resolved_operations: Array[Dictionary] = []
	var processed_indices: Array[int] = []
	
	for i in range(operations.size()):
		if i in processed_indices:
			continue
			
		var current_op = operations[i]
		var has_conflict = false
		
		# 检查当前操作是否有对立操作
		for j in range(i + 1, operations.size()):
			if j in processed_indices:
				continue
				
			var compare_op = operations[j]
			
			# 检查是否为对立操作：安排生产 vs 清空生产
			if _are_operations_conflicting(current_op, compare_op):
				has_conflict = true
				processed_indices.append(j)
				
				# 清空生产的优先级更高，保留清空生产操作
				if current_op["type"] == AtomicOperation.ASSIGN_PRODUCTION:
					# 当前操作是安排生产，对立操作是清空生产，保留清空生产
					resolved_operations.append(compare_op)
					print("整合对立操作：清空生产优先级更高，保留清空生产操作")
				else:
					# 当前操作是清空生产，对立操作是安排生产，保留清空生产
					resolved_operations.append(current_op)
					print("整合对立操作：清空生产优先级更高，保留清空生产操作")
				break
		
		# 如果没有对立操作，保留当前操作
		if not has_conflict:
			resolved_operations.append(current_op)
		
		processed_indices.append(i)
	
	return resolved_operations

func _are_operations_conflicting(op1: Dictionary, op2: Dictionary) -> bool:
	"""判断两个操作是否对立"""
	# 安排生产和清空生产是对立操作
	if (op1["type"] == AtomicOperation.ASSIGN_PRODUCTION and op2["type"] == AtomicOperation.CLEAR_PRODUCTION) or \
	   (op1["type"] == AtomicOperation.CLEAR_PRODUCTION and op2["type"] == AtomicOperation.ASSIGN_PRODUCTION):
		# 检查是否针对同一个生产线
		var op1_production_line_id = op1.get("params", {}).get("production_line_id", -1)
		var op2_production_line_id = op2.get("params", {}).get("production_line_id", -1)
		
		# 如果生产线ID相同，则是对立操作
		if op1_production_line_id == op2_production_line_id:
			return true
		# 如果生产线ID不同，但都是针对生产线的操作，也视为对立操作
		elif op1_production_line_id != -1 and op2_production_line_id != -1:
			return true
		
	return false

func _are_operations_similar(op1: Dictionary, op2: Dictionary) -> bool:
	"""判断两个操作是否相似"""
	if op1["type"] != op2["type"]:
		return false
	
	match op1["type"]:
		AtomicOperation.CONSTRUCT_BUILDING:
			# 对于建筑建造操作，检查building_id是否相同
			return op1.get("params", {}).get("building_id") == op2.get("params", {}).get("building_id")
		AtomicOperation.ASSIGN_PRODUCTION:
			# 对于生产安排操作，检查production_line_id是否相同
			return op1.get("params", {}).get("production_line_id") == op2.get("params", {}).get("production_line_id")
		AtomicOperation.RECRUIT_TROOPS:
			# 对于征兵操作，只要type相同就可以合并，避免反复执行
			return true
		_:
			# 其他操作类型，默认不合并
			return false

func _merge_single_operation_group(operations: Array[Dictionary]) -> Dictionary:
	"""合并一组相似操作"""
	if operations.is_empty():
		return {}
	
	# 以第一个操作为基础
	var merged_op = operations[0].duplicate(true)
	
	# 计算合并后的deficiency和urgency（取最高级别）
	var max_deficiency = merged_op.get("deficiency", Deficiency.NONE)
	var max_urgency = merged_op.get("urgency", Urgency.NONE)
	
	for i in range(1, operations.size()):
		var op = operations[i]
		
		# 更新deficiency为最高级别
		var current_deficiency = op.get("deficiency", Deficiency.NONE)
		if current_deficiency > max_deficiency:
			max_deficiency = current_deficiency
		
		# 更新urgency为最高级别
		var current_urgency = op.get("urgency", Urgency.NONE)
		if current_urgency > max_urgency:
			max_urgency = current_urgency
	
	# 设置合并后的参数
	merged_op["deficiency"] = max_deficiency
	merged_op["urgency"] = max_urgency
	
	# 添加合并标记
	merged_op["merged_from"] = operations.size()
	
	return merged_op

func detect_situation():
	_problem_queue = []
	#检测是否有危险
	detect_danger()
	# 检查基本资源建筑是否存在（非常重要）
	check_essential_buildings()
	#检测是否有人口短缺
	detect_population_shortage()
	#检测是否有资源短缺
	detect_resource_shortage()
	# 检查生产线状态
	check_production_line_status()

func detect_danger():
	if _headquarter is Settlement:
		for building in _headquarter.buildings:
			# 只统计已经建成的且core值大于1的建筑
			if building.is_finished and building.building_info.core_value > 1:
				var grids = GridUtils.get_grids_by_expansion(building.occupy_grid, 5)
				for grid in grids:
					#如果grid上有单位 
					if grid.holding_node3D != null and grid.holding_node3D is Unit:
						var unit = grid.holding_node3D
						#判断是否是敌人单位
						if unit.belonging_node is Battalion:
							if unit.belonging_node not in _headquarter.battalions:
								_problem_queue.append({
									"type": DependencyResolver.ProblemType.DANGER_CLOSE,
									"grid": grid
								})

# 检测人口短缺
func detect_population_shortage():
	# 检查是否有人口短缺
	# 简单的设置为 空闲人口  小于 10% 人口 为轻微短缺 小于 6% 为大幅短缺 小于 3% 为紧急短缺
	var deficiency: Deficiency = Deficiency.NONE
	var urgency: Urgency = Urgency.NONE
	if _headquarter.population.get_idle_population() < _headquarter.population.get_total_population() * 0.1:
		deficiency = Deficiency.MILD
		urgency = Urgency.LOW
	elif _headquarter.population.get_idle_population() < _headquarter.population.get_total_population() * 0.06:
		deficiency = Deficiency.MODERATE
		urgency = Urgency.LOW
	elif _headquarter.population.get_idle_population() < _headquarter.population.get_total_population() * 0.03:
		deficiency = Deficiency.SEVERE
		urgency = Urgency.MEDIUM
	
	if deficiency != Deficiency.NONE and urgency != Urgency.NONE:
		_problem_queue.append({
			"type": DependencyResolver.ProblemType.IDLE_POPULATION_SHORTAGE,
			"deficiency": deficiency,
			"urgency": urgency
		})

	#检测当前人口与人口容量 对比  简单的设置为  人口  大于  人口容量 为严重短缺
	if _headquarter.population.get_total_population() > _headquarter.population.get_population_capacity():
		deficiency = Deficiency.SEVERE
		urgency = Urgency.MEDIUM
	
		_problem_queue.append({
			"type": DependencyResolver.ProblemType.BUILDING_SHORTAGE,
			"building_id": "LARGE_HOUSE",
			"deficiency": deficiency,
			"urgency": urgency
		})

	# 检查是否有军事人口短缺
	# 简单的设置为 军事人口  小于 24% 人口 为轻微短缺 小于 16% 为大幅短缺 小于 8% 为紧急短缺
	deficiency = Deficiency.NONE
	urgency = Urgency.LOW
	if _headquarter.population.get_idle_military() < _headquarter.population.get_total_population() * 0.24:
		deficiency = Deficiency.MILD
		urgency = Urgency.LOW
	elif _headquarter.population.get_idle_military() < _headquarter.population.get_total_population() * 0.16:
		deficiency = Deficiency.MODERATE
		urgency = Urgency.LOW
	elif _headquarter.population.get_idle_military() < _headquarter.population.get_total_population() * 0.08:
		deficiency = Deficiency.SEVERE
		urgency = Urgency.MEDIUM
	
	if deficiency != Deficiency.NONE and urgency != Urgency.NONE:
		_problem_queue.append({
			"type": DependencyResolver.ProblemType.MILITARY_POPULATION_SHORTAGE,
			"deficiency": deficiency,
			"urgency": urgency
		})

# 检测资源短缺
func detect_resource_shortage():
	"""主要的资源短缺检测函数，调用各个子检测函数"""
	detect_food_shortage()
	detect_materials_and_livestock_shortage()
	# detect_military_equipment_shortage()

# 检测粮食是否短缺
func detect_food_shortage():
	"""检测粮食短缺情况"""
	# 设置为 每人回合消耗0.1个粮食 计算剩余粮食 和 粮食净消耗 的关系
	# 如果 剩余粮食 足够维持 15回合 则 认为 粮食不短缺
	# 如果 剩余粮食 足够维持 10回合 则 认为 粮食一般短缺
	# 如果 剩余粮食 足够维持 5回合 则 认为 粮食严重短缺
	var deficiency: Deficiency = Deficiency.NONE
	var urgency: Urgency = Urgency.LOW
	if _headquarter.inventory.get_food() < _headquarter.population.get_total_population() * 0.1 * 15:
		deficiency = Deficiency.MILD
		urgency = Urgency.LOW
	elif _headquarter.inventory.get_food() < _headquarter.population.get_total_population() * 0.1 * 10:
		deficiency = Deficiency.MODERATE
		urgency = Urgency.LOW
	elif _headquarter.inventory.get_food() < _headquarter.population.get_total_population() * 0.1 * 5:
		deficiency = Deficiency.SEVERE
		urgency = Urgency.MEDIUM
	
	if deficiency != Deficiency.NONE:
		_problem_queue.append({
			"type": DependencyResolver.ProblemType.FOOD_SHORTAGE,
			"deficiency": deficiency,
			"urgency": urgency
		})

# 检测材料和牲畜资源短缺
func detect_materials_and_livestock_shortage():
	"""检测材料和牲畜资源短缺情况"""
	var supply_demand = _headquarter.production.supply_demand
	var deficiency: Deficiency = Deficiency.NONE
	var urgency: Urgency = Urgency.LOW
	
	for item in ItemData.get_items_by_category("Materials") + ItemData.get_items_by_category("Livestock"): 
		# 如果其 demand 大于 supply 则 认为 短缺
		if supply_demand[item.id].demand > supply_demand[item.id].supply:
			# 评估短缺程度
			var quantity = _headquarter.inventory.get_item_quantity(item.id)
			var demand_15_turns = supply_demand[item.id].demand * 15
			var demand_10_turns = supply_demand[item.id].demand * 10
			var demand_5_turns = supply_demand[item.id].demand * 5
			
			if quantity >= demand_15_turns:
				deficiency = Deficiency.MILD
				urgency = Urgency.LOW
			elif quantity >= demand_10_turns:
				deficiency = Deficiency.MODERATE
				urgency = Urgency.LOW
			elif quantity >= demand_5_turns:
				deficiency = Deficiency.SEVERE
				urgency = Urgency.MEDIUM

			if deficiency != ReactiveMaintenanceSystem.Deficiency.NONE and urgency != ReactiveMaintenanceSystem.Urgency.NONE:
				_problem_queue.append({
					"type": DependencyResolver.ProblemType.RESOURCE_SHORTAGE,
					"resource": item.id,
					"deficiency": deficiency,
					"urgency": urgency
				})

# 检测军事装备短缺
func detect_military_equipment_shortage():
	"""检测各类军事装备短缺情况"""
	detect_weapon_shortage()
	detect_shield_shortage()
	detect_armor_shortage()
	detect_mount_shortage()

# 检测武器短缺
func detect_weapon_shortage():
	"""检测武器短缺情况"""
	var military_population = _headquarter.population.get_idle_military()
	var deficiency: Deficiency = Deficiency.NONE
	var urgency: Urgency = Urgency.LOW
	
	for item in ItemData.get_items_by_category("Weapon"):
		var quantity = _headquarter.inventory.get_item_quantity(item.id)
		
		# 如果库存小于兵役人口的70%则认为短缺轻微
		if quantity < military_population * 0.7:
			deficiency = Deficiency.MILD
			urgency = Urgency.LOW
		# 如果库存小于兵役人口的40%则认为短缺一般
		elif quantity < military_population * 0.4:
			deficiency = Deficiency.MODERATE
			urgency = Urgency.LOW
		# 如果库存小于兵役人口的10%则认为短缺严重
		elif quantity < military_population * 0.1:
			deficiency = Deficiency.SEVERE
			urgency = Urgency.MEDIUM

		if deficiency != ReactiveMaintenanceSystem.Deficiency.NONE and urgency != ReactiveMaintenanceSystem.Urgency.NONE:
			_problem_queue.append({
				"type": DependencyResolver.ProblemType.RESOURCE_SHORTAGE,
				"resource": item.id,
				"deficiency": deficiency,
				"urgency": urgency
			})

# 检测盾牌短缺
func detect_shield_shortage():
	"""检测盾牌短缺情况"""
	var military_population = _headquarter.population.get_idle_military()
	var deficiency: Deficiency = Deficiency.NONE
	var urgency: Urgency = Urgency.LOW
	
	for item in ItemData.get_items_by_category("Shield"):
		var quantity = _headquarter.inventory.get_item_quantity(item.id)
		
		# 如果库存小于兵役人口的50%则认为短缺轻微
		if quantity < military_population * 0.7:
			deficiency = Deficiency.MILD
			urgency = Urgency.LOW
		# 如果库存小于兵役人口的25%则认为短缺一般
		elif quantity < military_population * 0.4:
			deficiency = Deficiency.MODERATE
			urgency = Urgency.LOW
		# 如果库存小于兵役人口的10%则认为短缺严重
		elif quantity < military_population * 0.1:
			deficiency = Deficiency.SEVERE
			urgency = Urgency.MEDIUM

		if deficiency != ReactiveMaintenanceSystem.Deficiency.NONE and urgency != ReactiveMaintenanceSystem.Urgency.NONE:
			_problem_queue.append({
				"type": DependencyResolver.ProblemType.RESOURCE_SHORTAGE,
				"resource": item.id,
				"deficiency": deficiency,
				"urgency": urgency
			})

# 检测盔甲短缺
func detect_armor_shortage():
	"""检测盔甲短缺情况"""
	var military_population = _headquarter.population.get_idle_military()
	var deficiency: Deficiency = Deficiency.NONE
	var urgency: Urgency = Urgency.LOW
	
	for item in ItemData.get_items_by_category("Armor"):
		var quantity = _headquarter.inventory.get_item_quantity(item.id)
		
		# 如果库存小于兵役人口的25%则认为短缺轻微
		if quantity < military_population * 0.7:
			deficiency = Deficiency.MILD
			urgency = Urgency.LOW
		# 如果库存小于兵役人口的15%则认为短缺一般
		elif quantity < military_population * 0.4:
			deficiency = Deficiency.MODERATE
			urgency = Urgency.LOW
		# 如果库存小于兵役人口的5%则认为短缺严重
		elif quantity < military_population * 0.1:
			deficiency = Deficiency.SEVERE
			urgency = Urgency.MEDIUM

		if deficiency != ReactiveMaintenanceSystem.Deficiency.NONE and urgency != ReactiveMaintenanceSystem.Urgency.NONE:
			_problem_queue.append({
				"type": DependencyResolver.ProblemType.RESOURCE_SHORTAGE,
				"resource": item.id,
				"deficiency": deficiency,
				"urgency": urgency
			})

# 检测坐骑短缺
func detect_mount_shortage():
	"""检测坐骑短缺情况"""
	var military_population = _headquarter.population.get_idle_military()
	var deficiency: Deficiency = Deficiency.NONE
	var urgency: Urgency = Urgency.LOW
	
	for item in ItemData.get_items_by_category("Mount"):
		var quantity = _headquarter.inventory.get_item_quantity(item.id)
		
		# 如果库存小于兵役人口的30%则认为短缺轻微
		if quantity < military_population * 0.7:
			deficiency = Deficiency.MILD
			urgency = Urgency.LOW
		# 如果库存小于兵役人口的15%则认为短缺一般
		elif quantity < military_population * 0.4:
			deficiency = Deficiency.MODERATE
			urgency = Urgency.LOW
		# 如果库存小于兵役人口的5%则认为短缺严重
		elif quantity < military_population * 0.1:
			deficiency = Deficiency.SEVERE
			urgency = Urgency.MEDIUM

		if deficiency != ReactiveMaintenanceSystem.Deficiency.NONE and urgency != ReactiveMaintenanceSystem.Urgency.NONE:
			_problem_queue.append({
				"type": DependencyResolver.ProblemType.RESOURCE_SHORTAGE,
				"resource": item.id,
				"deficiency": deficiency,
				"urgency": urgency
			})

# 检查生产线异常
func check_production_line_status():
	for production_line: Production.ProductionLine in _headquarter.production.production_lines.values():
		# 检查是否有足够的输入物品
		if production_line.status["is_inputs_not_enough"]:
			_problem_queue.append({
				"type": DependencyResolver.ProblemType.PRODUCTION_LINE_INPUTS_NOT_ENOUGH,
				"production_line_id": production_line.id,
				"deficiency": Deficiency.SEVERE,
				"urgency": Urgency.HIGH
			})

func _sort_operations_by_priority(operations: Array[Dictionary]) -> Array[Dictionary]:
	"""根据优先级排序操作"""
	# operation 的结构为 {"type": AtomicOperation,"params": {"deficiency": deficiency,"urgency": urgency,...}}
	
	# 创建操作副本以避免修改原数组
	var sorted_operations = operations.duplicate()
	
	# 自定义排序函数：先按urgency（紧急度）降序，再按deficiency（紧缺度）降序
	sorted_operations.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		# 比较urgency（第一优先级）
		var urgency_a = a.get("urgency", Urgency.NONE)
		var urgency_b = b.get("urgency", Urgency.NONE)
		
		if urgency_a != urgency_b:
			return urgency_a > urgency_b
		
		# 如果urgency相同，比较deficiency（第二优先级）
		var deficiency_a = a.get("deficiency", Deficiency.NONE)
		var deficiency_b = b.get("deficiency", Deficiency.NONE)
		
		if deficiency_a != deficiency_b:
			return deficiency_a > deficiency_b
		
		# 如果urgency和deficiency都相同，保持原顺序
		return false
	)
	
	return sorted_operations

# 检查基本建筑是否存在
func check_essential_buildings():
	"""检测基本建筑是否存在，按顺序检测，发现缺失立即返回"""
	# 定义基本建筑列表 - 按建造优先级排序
	var essential_buildings = [
		# 基础资源生产建筑 - 生产基本原材料
		{"id": "LUMBER_CAMP", "name": "伐木场", "category": "RESOURCE"},
		{"id": "MINE", "name": "矿场", "category": "RESOURCE"},
		
		# 基础加工建筑 - 将原材料加工为可用材料
		{"id": "WOOD_WORKSHOP", "name": "木工坊", "category": "PROCESSOR"},
		{"id": "STONE_WORKSHOP", "name": "石工坊", "category": "PROCESSOR"}
	]
	
	# 按顺序检测每个基本建筑
	for building in essential_buildings:
		var building_id = building["id"]
		var building_name = building["name"]
		var building_category = building["category"]
		
		# 检查建筑是否存在
		var building_exists = false
		var building_under_construction = false
		

		var existing_buildings = (_headquarter as Settlement).get_buildings_is_finished_by_id(building_id)
		if existing_buildings.size() > 0:
			building_exists = true
	
		var constructing_buildings = (_headquarter as Settlement).get_buildings_is_not_finished_by_id(building_id)
		if constructing_buildings.size() > 0:
			building_under_construction = true
		
		# 如果建筑不存在且没有在建造中，则添加到问题队列并立即返回
		if not building_exists and not building_under_construction:
			# 根据建筑类别确定缺乏程度和紧急程度
			var deficiency: Deficiency
			var urgency: Urgency
			
			match building_category:
				"RESOURCE":
					# 资源生产建筑是生存必需，没有资源就无法生产
					deficiency = Deficiency.SEVERE
					urgency = Urgency.HIGH
				"PROCESSOR":
					# 加工建筑是发展必需，将原材料转化为可用材料
					deficiency = Deficiency.MODERATE
					urgency = Urgency.MEDIUM
				_:
					# 其他建筑
					deficiency = Deficiency.MILD
					urgency = Urgency.LOW
			
			# 添加到问题队列
			_problem_queue.append({
				"type": DependencyResolver.ProblemType.BUILDING_SHORTAGE,
				"building_id": building_id,
				"building_name": building_name,
				"building_category": building_category,
				"deficiency": deficiency,
				"urgency": urgency
			})
			
			# 立即返回，不再继续检测
			return
