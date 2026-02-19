class_name DependencyResolver

# 阻塞类型枚举
enum ProblemType {
	NO_PROBLEM,           				# 无阻塞
	RESOURCE_SHORTAGE,      			# 资源短缺
	IDLE_POPULATION_SHORTAGE, 			# 闲置人口短缺
	MILITARY_POPULATION_SHORTAGE, 		# 军事人口短缺
	BUILDING_SHORTAGE,      			# 建筑短缺
	BUILDING_UNDER_CONSTRUCTION, 		# 建筑正在建造中
	FOOD_SHORTAGE,          			# 食物短缺
	PRODUCTION_LINE_INPUTS_NOT_ENOUGH, 	# 生产线输入物品不足
	DANGER_CLOSE,        				# 危险情况
	ERROR                   			# 错误情况
}

static func find_executable_operation(headquarter: Headquarter, problem: Dictionary) -> Dictionary:
	"""分析依赖链"""
	var current_problem = problem
	var answer_operation = null
	
	var max_attempts = 10
	var attempt_count = 0
	while true:
		# 解决当前问题 
		# 操作结构 : {"type": ReactiveMaintenanceSystem.AtomicOperation,"params": {"deficiency": deficiency,"urgency": urgency,...}}
		answer_operation = _resolve_problem(headquarter, current_problem)

		if answer_operation["type"] == ReactiveMaintenanceSystem.AtomicOperation.NO_OPERATION:
			return answer_operation

		attempt_count += 1
		if attempt_count >= max_attempts:
			return {
				"type": ReactiveMaintenanceSystem.AtomicOperation.NO_OPERATION,
				"params": {
					"msg": "超过最大尝试次数，无法解决依赖问题",
				},
				"original_problem": problem,
			}
		# 检查当前操作是否有问题,及其阻塞原因
		# 问题结构 : {"type": ProblemType,"deficiency": deficiency,"urgency": urgency}
		current_problem = _find_problem(headquarter, answer_operation)
		
		if current_problem["type"] == ProblemType.NO_PROBLEM:
			return {
				"type":answer_operation["type"],
				"params":answer_operation["params"],
				"original_problem": problem,
			}
		
		if current_problem["type"] == ProblemType.ERROR:
			return {
				"type": ReactiveMaintenanceSystem.AtomicOperation.NO_OPERATION,
				"params": {
					"msg": current_problem["msg"],
				},
				"original_problem": problem,
			}

	return {
		"type": ReactiveMaintenanceSystem.AtomicOperation.NO_OPERATION,
		"params": {
			"msg": "所有前置条件均不满足，维持现有状态",
		},
		"original_problem": problem,
	}

static func _find_problem(headquarter: Headquarter, operation: Dictionary) -> Dictionary:
	"""检查操作被阻塞的原因"""
	var problem = {}
	
	match operation["type"]:	
		ReactiveMaintenanceSystem.AtomicOperation.CONSTRUCT_BUILDING:    # 建造建筑
			problem = _check_building_prerequisites(headquarter, operation)
			
		ReactiveMaintenanceSystem.AtomicOperation.CLEAR_PRODUCTION: 	 # 清空生产队列
			problem = {"type": ProblemType.NO_PROBLEM}
			
		ReactiveMaintenanceSystem.AtomicOperation.ASSIGN_PRODUCTION:     # 安排生产
			problem = _check_production_prerequisites(headquarter, operation)
			
		ReactiveMaintenanceSystem.AtomicOperation.RECRUIT_TROOPS:        # 征兵
			problem = _check_recruitment_prerequisites(headquarter, operation)

		ReactiveMaintenanceSystem.AtomicOperation.ATTACK_TARGET:        # 攻击目标
			problem = {"type": ProblemType.NO_PROBLEM}

		ReactiveMaintenanceSystem.AtomicOperation.NO_OPERATION:          # 空操作
			problem = {"type": ProblemType.NO_PROBLEM}
		_:
			problem = {"type": ProblemType.ERROR}
	
	return problem

static func _check_building_prerequisites(headquarter: Headquarter, operation: Dictionary) -> Dictionary:
	"""检查建筑前提条件"""
	var building_id = operation["params"]["building_id"]
	var building_info = BuildingData.get_building_by_id(building_id)
	
	if building_info == null:
		push_error("严重异常:建筑ID无效: %s" % building_id)
		return {
			"type":ProblemType.ERROR,
			"msg": "BUILDING_ID_INVALID"
		}
	
	# 1. 检查资源是否足够
	if not headquarter.inventory.has_enough_resources(building_info.required_materials):
		#检查哪一种资源不足
		var required_items = building_info.required_materials
		for item_id in required_items:
			if headquarter.inventory.get_item_quantity(item_id) < required_items[item_id]:
				return {
					"type": ProblemType.RESOURCE_SHORTAGE,
					"resource": item_id,
					"required": required_items[item_id],
					"current": headquarter.inventory.get_item_quantity(item_id),
					"urgency": operation["params"]["urgency"],
					"deficiency": operation["params"]["deficiency"]
				}

	# 2.检查所安排的人数是否充实
	if operation["params"]["person_count"] > headquarter.population.get_idle_population():
		return {
			"type": ProblemType.IDLE_POPULATION_SHORTAGE,
			"required": operation["params"]["person_count"],
			"current": headquarter.population.get_idle_population(),
			"urgency": operation["params"]["urgency"],
			"deficiency": operation["params"]["deficiency"]
		}
	
	return {"type": ProblemType.NO_PROBLEM}

static func _check_production_prerequisites(headquarter: Headquarter, operation: Dictionary) -> Dictionary:
	"""检查生产前提条件"""
	var production_line_id = operation["params"]["production_line_id"]
	
	# 1. 检查生产线是否存在
	var production_line = headquarter.production.get_production_line_by_id(production_line_id)
	if production_line == null:
		push_error("严重异常：生产线不存在: %s" % production_line_id)
		return {
			"type": ProblemType.ERROR,
			"msg": "PRODUCTION_LINE_MISSING"
		}
	
	# 2. 检查前置建筑是否存在
	if production_line.require_preposition_building and not production_line.has_preposition_building:
		# 检查前置建筑是否正在建造中
		var buildings_under_construction = (headquarter as Settlement).get_buildings_is_not_finished_by_id(production_line.recipe.preposition_building)
		if buildings_under_construction.size() == 0:
			return {
				"type": ProblemType.BUILDING_SHORTAGE,
				"building_id": production_line.recipe.preposition_building,
				"urgency": operation["params"]["urgency"],
				"deficiency": operation["params"]["deficiency"]
			}
		else:
			return {
				"type": ProblemType.BUILDING_UNDER_CONSTRUCTION,
				"building": production_line.recipe.preposition_building
			}
	
	# 3. 检查来源建筑容量限制
	if production_line.require_source_building:
		var building_info = BuildingData.get_building_by_id(production_line.recipe.source_building)
		var source_building_count = production_line.source_building_num
		
		var max_worker_capacity = building_info.capacity * source_building_count
		var max_active_num = round(max_worker_capacity / production_line.recipe.worker_num)
		
		# 如果激活数量超过当前建筑容量
		if production_line.active_num >= max_active_num:
			# 检查是否有该建筑正在建造中
			var buildings_under_construction = (headquarter as Settlement).get_buildings_is_not_finished_by_id(production_line.recipe.source_building)
			if buildings_under_construction.size() == 0:
				return {
					"type": ProblemType.BUILDING_SHORTAGE,
					"building_id": production_line.recipe.source_building,
					"urgency": operation["params"]["urgency"],
					"deficiency": operation["params"]["deficiency"]
				}
			else:
				return {
					"type": ProblemType.BUILDING_UNDER_CONSTRUCTION,
					"building": production_line.recipe.source_building
				}
	
	# 4. 检查是否有足够的闲置人口
	var person_count = operation["params"].get("person_count", 0)
	if person_count > 0:
		var idle_population = headquarter.population.get_idle_population()
		if idle_population < person_count:
			# 闲置人口不足，返回人口短缺问题
			return {
				"type": ProblemType.IDLE_POPULATION_SHORTAGE,
				"required": person_count,
				"current": idle_population,
				"urgency": operation["params"]["urgency"],
				"deficiency": operation["params"]["deficiency"]
			}
	
	# 5. 检查生产线输入资源是否充足
	var inputs: Dictionary = production_line.recipe.inputs
	if inputs.size() > 0 and person_count > 0:
		for item_id in inputs:
			var active_num = int(person_count / production_line.recipe.worker_num)
			var required_amount = inputs[item_id] * active_num
			var current_amount = headquarter.inventory.get_item_quantity(item_id)
			if current_amount < required_amount:
				# 输入资源不足，返回资源短缺问题
				return {
					"type": ProblemType.RESOURCE_SHORTAGE,      		# 资源短缺,
					"resource": item_id,
					"required": required_amount,
					"current": current_amount,
					"urgency": operation["params"]["urgency"],
					"deficiency": operation["params"]["deficiency"]
				}
	
	return {"type": ProblemType.NO_PROBLEM}

static func _check_recruitment_prerequisites(headquarter: Headquarter, operation: Dictionary) -> Dictionary:
	"""检查征兵前提条件"""
	# 检查是否为 Settlement
	if not (headquarter is Settlement):
		push_error("严重异常：征兵操作只能在 Settlement 中进行，当前总部类型：%s" % headquarter.get_class())
		return {
			"type": ProblemType.ERROR
		}
	
	var settlement = headquarter as Settlement
	
	# 1. 检查是否有已建成的兵营
	var finished_barracks = settlement.get_buildings_is_finished_by_id("BARRACKS")
	# 检查是否有正在建造的兵营
	var under_construction_barracks = settlement.get_buildings_is_not_finished_by_id("BARRACKS")
	if finished_barracks.size() == 0:
			if under_construction_barracks.size() == 0:
				return {
					"type": ProblemType.BUILDING_SHORTAGE,
					"building_id": "BARRACKS", 
					"urgency": operation["params"]["urgency"],
					"deficiency": operation["params"]["deficiency"]
				}
			else:
				return {
					"type": ProblemType.BUILDING_UNDER_CONSTRUCTION,
					"building": "BARRACKS"
				}
	
	# 2. 检查兵营容量
	var current_soldiers = headquarter.population.get_idle_military()
	var capacity = headquarter.population.get_military_population_capacity()
	var new_count =  operation["params"]["person_count"]
	if new_count + current_soldiers >= capacity:
		return {
			"type": ProblemType.BUILDING_SHORTAGE,
			"building_id": "BARRACKS",
			"urgency": operation["params"]["urgency"],
			"deficiency": operation["params"]["deficiency"]
		}
	
	# 检查闲置人数是否足够
	var idle_population = headquarter.population.get_idle_population()
	if new_count > idle_population:
		return {
			"type": ProblemType.IDLE_POPULATION_SHORTAGE,
			"required": operation["params"]["person_count"],
			"current": idle_population,
			"urgency": operation["params"]["urgency"],
			"deficiency": operation["params"]["deficiency"]
		}

	return {"type": ProblemType.NO_PROBLEM}

static func _resolve_problem(headquarter: Headquarter, problem: Dictionary) -> Dictionary:
	"""根据阻塞原因创建前提操作"""
	var operation = {}
	
	match problem["type"]:
		ProblemType.RESOURCE_SHORTAGE:
			# 资源短缺 -> 安排生产
			var resource = problem["resource"]
			
			var production_line = headquarter.production.get_productionlines_by_main_product_id(resource)
			if production_line.size() == 0:
				operation = {
					"type": ReactiveMaintenanceSystem.AtomicOperation.NO_OPERATION, 
					"params": {}
				}
			else:
				# 计算所需人数
				var person_count = calculate_person_count_by_priority(problem["deficiency"], problem["urgency"])
				
				operation = {
					"type": ReactiveMaintenanceSystem.AtomicOperation.ASSIGN_PRODUCTION, 
					"params": {
						"production_line_id": production_line[0].id,
						"urgency": problem["urgency"],
						"deficiency": problem["deficiency"],
						"person_count": person_count
					}
				}
		
		ProblemType.IDLE_POPULATION_SHORTAGE:
			# 1. 检查正在建设中的建筑，调整实际需求
			var adjusted_deficiency = problem["deficiency"]
			var adjusted_urgency = problem["urgency"]
			
			if headquarter is Settlement:
				var building_list = (headquarter as Settlement).get_buildings_is_not_finished_by_category("POPULATION")
				var building_num = building_list.size()
				
				# 根据在建建筑数量合理调整需求程度
				if building_num > 0:
					# 每有一个在建建筑，降低一级缺乏程度
					adjusted_deficiency = max(ReactiveMaintenanceSystem.Deficiency.NONE, adjusted_deficiency - building_num)
					# 紧急程度也相应调整，降低一级紧急程度
					adjusted_urgency = max(ReactiveMaintenanceSystem.Urgency.NONE, adjusted_urgency - building_num)
			
			# 2. 如果调整后无需建设，返回无操作
			if adjusted_deficiency == ReactiveMaintenanceSystem.Deficiency.NONE or adjusted_urgency == ReactiveMaintenanceSystem.Urgency.NONE:
				operation = {
					"type": ReactiveMaintenanceSystem.AtomicOperation.NO_OPERATION,
					"params": {}
				}
			else:
				# 3. 确定需要增加的人口建筑类型
				var building_id = ""
				match adjusted_deficiency:
					ReactiveMaintenanceSystem.Deficiency.CRITICAL, ReactiveMaintenanceSystem.Deficiency.SEVERE:
						building_id = "LARGE_HOUSE"
					ReactiveMaintenanceSystem.Deficiency.MODERATE:
						building_id = "MEDIUM_HOUSE"
					ReactiveMaintenanceSystem.Deficiency.MILD:
						building_id = "SMALL_HOUSE"
				
				# 计算所需人数
				var person_count = calculate_person_count_by_priority(adjusted_deficiency, adjusted_urgency)
				
				operation = {
					"type": ReactiveMaintenanceSystem.AtomicOperation.CONSTRUCT_BUILDING,
					"params": {
						"building_id": building_id,
						"person_count": person_count,
						"deficiency": adjusted_deficiency,
						"urgency": adjusted_urgency,
						"priority": 1,  # 最高优先级
					}
				}
			
		ProblemType.BUILDING_SHORTAGE:
			# 建筑短缺 -> 建造该建筑
			# 计算所需人数
			var person_count = calculate_person_count_by_priority(problem["deficiency"], problem["urgency"])

			# 针对民居短缺，进行特殊判断
			if problem["building_id"] == "LARGE_HOUSE" or problem["building_id"] == "MEDIUM_HOUSE" or problem["building_id"] == "SMALL_HOUSE":
				var possible_id = select_building_for_house_shortage(headquarter, problem["building_id"])
				if possible_id == "LARGE_HOUSE" or possible_id == "MEDIUM_HOUSE" or possible_id == "SMALL_HOUSE":
					operation = {
						"type": ReactiveMaintenanceSystem.AtomicOperation.CONSTRUCT_BUILDING,
						"params": {
							"building_id": possible_id,
							"person_count": person_count,
							"urgency": problem["urgency"],
							"deficiency": problem["deficiency"]
						}
					}
				else:
					var production_line = headquarter.production.get_productionlines_by_main_product_id(possible_id)
					if production_line.size() == 0:
						operation = {
							"type": ReactiveMaintenanceSystem.AtomicOperation.NO_OPERATION, 
							"params": {}
						}
					else:
						operation = {
							"type": ReactiveMaintenanceSystem.AtomicOperation.ASSIGN_PRODUCTION,
							"params": {
								"production_line_id": production_line[0].id,
								"person_count": person_count,
								"urgency": problem["urgency"],
								"deficiency": problem["deficiency"]
							}
						}
			else:
				operation = {
					"type": ReactiveMaintenanceSystem.AtomicOperation.CONSTRUCT_BUILDING,
					"params": {
						"building_id": problem["building_id"],
						"person_count": person_count,
						"urgency": problem["urgency"],
						"deficiency": problem["deficiency"]
					}
				}
		
		ProblemType.MILITARY_POPULATION_SHORTAGE:
			# 军事短缺 -> 征兵
			var person_count = calculate_person_count_by_priority(problem["deficiency"], problem["urgency"])
			operation = {
				"type": ReactiveMaintenanceSystem.AtomicOperation.RECRUIT_TROOPS,
				"params": {
					"person_count": person_count,
					"urgency": problem["urgency"],
					"deficiency": problem["deficiency"]
				}
			}
			
		ProblemType.FOOD_SHORTAGE:
				# 食物短缺 -> 安排粮食生产
				var food_items = ItemData.get_items_by_category("Foodstuffs")
				
				var solutions: Array[Dictionary] = []
			
				# 1. 检查现有生产线的增产潜力
				for food_item in food_items:
					var productionlines = headquarter.production.get_productionlines_by_main_product_id(food_item.id)
					if productionlines.size() > 0:
						# 使用第一个生产线
						var productionline = productionlines[0]

						# 如果当前建筑容量足够，优先使用现有生产线
						solutions.append({
							"type": "assign_production",
							"production_id": productionline.id,
							"complexity": 1,  # 最简单的方法
							"food_rate": food_item.food_rate
						})

				# 按复杂度排序，优先选择简单的方法
				solutions.sort_custom(func(a, b): return a["complexity"] < b["complexity"])
				
				# 在相同复杂度下，选择食物换算率最高的
				var best_solution = solutions[0]
				for solution in solutions:
					if solution["complexity"] == best_solution["complexity"] and solution["food_rate"] > best_solution["food_rate"]:
						best_solution = solution

				# 计算所需人数
				var person_count = calculate_person_count_by_priority(problem["deficiency"], problem["urgency"])
					
				operation = {
					"type": ReactiveMaintenanceSystem.AtomicOperation.ASSIGN_PRODUCTION,
					"params": {
						"production_line_id": best_solution["production_id"],
						"urgency": problem["urgency"],
						"deficiency": problem["deficiency"],
						"person_count": person_count
					}
				}
			
		ProblemType.BUILDING_UNDER_CONSTRUCTION:
			# 建筑正在建造中 -> 等待
			operation = {
				"type": ReactiveMaintenanceSystem.AtomicOperation.NO_OPERATION,
				"params": {}
			}
		
		ProblemType.PRODUCTION_LINE_INPUTS_NOT_ENOUGH:
			# 生产线输入不足 -> 清除生产线
			operation = {
				"type": ReactiveMaintenanceSystem.AtomicOperation.CLEAR_PRODUCTION, 
				"params": {
					"production_line_id": problem["production_line_id"],
					"urgency": problem["urgency"],
					"deficiency": problem["deficiency"],
				}
			}
		
		ProblemType.DANGER_CLOSE:
			# 危险情况 -> 攻击
			operation = {
				"type": ReactiveMaintenanceSystem.AtomicOperation.ATTACK_TARGET,
				"params": {
					"grid": problem["grid"]
				}
			}
		
		ProblemType.ERROR:
			push_error("异常跳转")
			# 错误情况 -> 返回错误操作
			operation = {
				"type": ReactiveMaintenanceSystem.AtomicOperation.NO_OPERATION,
				"params": {}
			}
		
		ProblemType.NO_PROBLEM:
			push_error("异常跳转")
			# 非阻塞情况 -> 返回空操作
			operation = {
				"type": ReactiveMaintenanceSystem.AtomicOperation.NO_OPERATION,
				"params": {}
			}
		
		_:
			push_error("异常跳转")
			# 错误情况 -> 返回空操作
			operation = {
				"type": ReactiveMaintenanceSystem.AtomicOperation.NO_OPERATION,
				"params": {}
			}
	
	return operation

# 根据deficiency和urgency参数计算人数
static func calculate_person_count_by_priority(deficiency: float, urgency: float) -> int:
	"""
	根据紧缺度和紧急度计算需要的人数
	
	参数:
		deficiency: 紧缺度 (0.0-1.0)
		urgency: 紧急度 (0.0-1.0)
	
	返回:
		计算得出的人数
	"""
	# 基础人数计算：紧缺度越高，需要的人数越多
	# 紧急度作为权重因子，紧急度越高，人数需求越强烈
	
	# 基础人数范围：1-10人
	var base_count = int(deficiency * 10)
	
	# 紧急度权重：紧急度越高，人数需求增加
	var urgency_multiplier = 1.0 + (urgency * 0.5)  # 紧急度最高可增加50%的人数
	
	# 计算最终人数
	var final_count = int(base_count * urgency_multiplier)
	
	# 确保人数至少为10
	final_count = max(10, final_count)
		
	# 限制最大人数为100
	final_count = min(80, final_count)
	
	return final_count

# 格式化问题链用于调试
static func format_problem_chain_for_debug(operation: Dictionary) -> String:
	"""
	格式化问题链，用于调试输出
	
	参数:
		operation: 包含问题链的操作字典
	
	返回:
		格式化的问题链字符串
	"""
	if not operation.has("original_problem"):
		return "无原始问题信息"
	
	var result = ""
	var original_problem = operation["original_problem"]
	
	# 添加原始问题
	result += "原始问题: " + _format_single_problem(original_problem) + "\n"
	
	# 添加问题链
	if operation.has("problem_chain"):
		result += "问题链:\n"
		for i in range(operation["problem_chain"].size()):
			var problem = operation["problem_chain"][i]
			result += "  步骤%d: %s\n" % [i+1, _format_single_problem(problem)]
	
	return result

# 格式化单个问题
static func _format_single_problem(problem: Dictionary) -> String:
	"""
	格式化单个问题
	
	参数:
		problem: 问题字典
	
	返回:
		格式化的问题字符串
	"""
	var result = ""
	
	# 问题类型
	if problem.has("type"):
		result += "类型=" + str(problem["type"])
	
	# 资源
	if problem.has("resource"):
		result += ", 资源=" + str(problem["resource"])
	
	# 建筑ID
	if problem.has("building_id"):
		result += ", 建筑=" + str(problem["building_id"])
	
	# 需要数量
	if problem.has("required"):
		result += ", 需要=" + str(problem["required"])
	
	# 当前数量
	if problem.has("current"):
		result += ", 当前=" + str(problem["current"])
	
	# 紧急度
	if problem.has("urgency"):
		result += ", 紧急度=" + str(problem["urgency"])
	
	# 紧缺度
	if problem.has("deficiency"):
		result += ", 紧缺度=" + str(problem["deficiency"])
	
	return result

#针对民居短缺，进行特殊判断，选择合适的建筑,都不适合则返回所需资源id
static func select_building_for_house_shortage(headquarter: Headquarter, current_building_id: String) -> String:
	var result_id = "NONE"
	
	# 根据当前建筑ID确定优先选择的建筑类型
	var priority_buildings = []
	match current_building_id:
		"LARGE_HOUSE":
			# 从大到小优先选择
			priority_buildings = ["LARGE_HOUSE", "MEDIUM_HOUSE", "SMALL_HOUSE"]
		"MEDIUM_HOUSE":
			# 从中到小优先选择
			priority_buildings = ["MEDIUM_HOUSE", "SMALL_HOUSE"]
		"SMALL_HOUSE":
			# 只选择SMALL_HOUSE
			priority_buildings = ["SMALL_HOUSE"]
		_:
			# 未知建筑ID，返回NONE
			return "NONE"
	
	# 按照优先级顺序检查资源是否足够
	for building_id in priority_buildings:
		var required_materials = BuildingData.get_building_by_id(building_id).required_materials
		if headquarter.inventory.has_enough_resources(required_materials):
			return building_id
			
	# 到此处 ，没有找到合适的建筑
	# 则返回 最小建筑所需的 最基础的资源 
	var required_materials = BuildingData.get_building_by_id("SMALL_HOUSE").required_materials
	for item_id in required_materials.keys():
		if headquarter.inventory.get_item_quantity(item_id) < required_materials[item_id]:
			result_id = item_id
			break

	return result_id
