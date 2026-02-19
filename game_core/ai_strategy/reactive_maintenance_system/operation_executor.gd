# 操作执行机
class_name OperationExecutor

# 执行原子操作
static func execute_atomic_operation(headquarter, operation: Dictionary):
	"""执行原子操作，返回是否执行成功"""
	match operation["type"]:
		ReactiveMaintenanceSystem.AtomicOperation.NO_OPERATION:
			# 无操作，直接返回成功
			pass
		ReactiveMaintenanceSystem.AtomicOperation.RECRUIT_TROOPS:
			# 执行征兵操作
			_execute_recruit_troops(headquarter, operation)
		ReactiveMaintenanceSystem.AtomicOperation.CONSTRUCT_BUILDING:
			# 执行建筑建造操作
			_execute_construct_building(headquarter, operation)
		ReactiveMaintenanceSystem.AtomicOperation.ASSIGN_PRODUCTION:
			# 执行生产安排操作
			_execute_assign_production(headquarter, operation)
		ReactiveMaintenanceSystem.AtomicOperation.CLEAR_PRODUCTION:
			# 执行清空生产队列操作
			_execute_clear_production(headquarter, operation)
		ReactiveMaintenanceSystem.AtomicOperation.MOVE_UNITS:
			# 执行移动单位操作
			_execute_move_units(headquarter, operation)
		ReactiveMaintenanceSystem.AtomicOperation.ATTACK_TARGET:
			# 执行攻击目标操作
			_execute_attack_target(headquarter, operation)
		ReactiveMaintenanceSystem.AtomicOperation.RESEARCH_TECH:
			# 执行研究科技操作
			_execute_research_tech(headquarter, operation)
		_:
			# 未知操作类型
			push_error("未知操作类型: " + str(operation["type"]))

# 执行征兵操作
static func _execute_recruit_troops(headquarter, operation: Dictionary):
	# 执行前最后一次检测
	var problem = DependencyResolver._find_problem(headquarter, operation)
	if problem["type"] != DependencyResolver.ProblemType.NO_PROBLEM:
		print("征兵操作被阻塞")
		return
	
	var params = operation.get("params", {})
	var person_count = params.get("person_count", 0)
	
	# 检查征兵数量是否有效
	if person_count <= 0:
		print("征兵操作失败: 征兵数量必须大于0")
		return
	
	# 检查闲置人口是否足够
	if headquarter.population.get_idle_population() < person_count:
		print("征兵操作失败: 闲置人口不足，需要 %d，但只有 %d" % [person_count, headquarter.population.get_idle_population()])
		return
	
	# 使用RecruitCommand执行征兵操作
	await CommandBus.execute_command(RecruitCommand.new(headquarter, person_count))

# 执行建筑建造操作
static func _execute_construct_building(headquarter, operation: Dictionary):
	# 执行前最后一次检测
	var problem = DependencyResolver._find_problem(headquarter, operation)
	if problem["type"] != DependencyResolver.ProblemType.NO_PROBLEM:
		print("建筑建造操作被阻塞")
		return
	
	var params = operation.get("params", {})
	var building_id = params.get("building_id", "")
	var deficiency = params.get("deficiency", 0.0)
	var urgency = params.get("urgency", 0.0)
	
	# print("执行建筑建造操作: building_id=" + building_id + ", deficiency=" + str(deficiency) + ", urgency=" + str(urgency))
	
	# 1. 获取可用建筑网格
	var available_grids = (headquarter as Settlement).get_generate_building_grids()
	if available_grids.size() == 0:
		print("没有可用的建筑网格")
		return
	
	# 2. 随机选择一个网格（不需要最优选择）
	var random_index = randi() % available_grids.size()
	var selected_grid = available_grids[random_index]
	
	# 3. 检查网格是否已被占用
	if selected_grid.holding_node3D != null:
		print("选中的网格已被占用，重新选择")
		# 重新选择未被占用的网格
		var empty_grids = []
		for grid in available_grids:
			if grid.holding_node3D == null:
				empty_grids.append(grid)
		
		if empty_grids.size() == 0:
			print("所有可用网格都已被占用")
			return
		
		random_index = randi() % empty_grids.size()
		selected_grid = empty_grids[random_index]
	
	# 4. 使用_calculate_person_count_by_priority计算建造人数
	var constructer_count = params.get("person_count", 0)
	
	# 5. 通过CommandBus执行建筑建造命令
	await CommandBus.execute_command(SettleBuildCommand.new(headquarter, selected_grid, building_id, constructer_count))
	# print("建筑建造命令已提交: 网格(" + str(selected_grid.chunk_x) + ", " + str(selected_grid.chunk_y) + "), 人数=" + str(constructer_count))
	
# 执行生产安排操作
static func _execute_assign_production(headquarter, operation: Dictionary):
	# 执行前最后一次检测
	var problem = DependencyResolver._find_problem(headquarter, operation)
	if problem["type"] != DependencyResolver.ProblemType.NO_PROBLEM:
		print("生产安排操作被阻塞")
		return
	
	var params = operation.get("params", {})
	var production_line_id = params.get("production_line_id", -1)
	
	# 1. 检查生产线是否存在
	var production_line = headquarter.production.get_production_line_by_id(production_line_id)
	if production_line == null:
		print("生产安排操作失败: 生产线不存在, ID=" + str(production_line_id))
		return
	
	# 2. 使用dependency_resolver已经计算好的人数
	var person_count = operation["params"]["person_count"]

	# 3. 根据生产线配方计算需要新添加的激活数量
	var worker_num_per_unit = production_line.recipe.worker_num
	if worker_num_per_unit <= 0:
		print("生产安排操作失败: 生产线工人数量配置错误, worker_num=" + str(worker_num_per_unit))
		return
	
	# 计算需要新添加的激活生产单位数量
	var additional_active_num = max(1, int(person_count / worker_num_per_unit))
	
	# 4. 计算新的总激活数量（当前已有的 + 新添加的）
	var new_active_num = production_line.active_num + additional_active_num
	
	# 5. 检查闲置人口是否足够
	var required_workers = additional_active_num * worker_num_per_unit
	if headquarter.population.get_idle_population() < required_workers:
		print("生产安排操作失败: 闲置人口不足, 需要=" + str(required_workers) + ", 当前=" + str(headquarter.population.get_idle_population()))
		return
	
	# 6. 设置生产容量（保持原有容量不变）
	var product_cap = production_line.production_cap
	
	# 7. 通过CommandBus执行分配命令
	await CommandBus.execute_command(AssignCommand.new(headquarter, production_line, product_cap, new_active_num))

# 执行清空生产队列操作
static func	_execute_clear_production(headquarter,operation:Dictionary):
	# 执行前最后一次检测
	var problem = DependencyResolver._find_problem(headquarter, operation)
	if problem["type"] != DependencyResolver.ProblemType.NO_PROBLEM:
		print("清空生产队列操作被阻塞")
		return
	
	var params = operation.get("params", {})
	var production_line_id = params.get("production_line_id", -1)
	# 1. 检查生产线是否存在
	var production_line = headquarter.production.get_production_line_by_id(production_line_id)
	if production_line == null:
		print("清空生产队列操作失败: 生产线不存在, ID=" + str(production_line_id))
		return

	# 2. 设置生产容量（保持原有容量不变）
	var product_cap = production_line.production_cap
	# 3. 通过CommandBus执行分配命令
	await CommandBus.execute_command(AssignCommand.new(headquarter, production_line, product_cap, 0))

# 执行移动单位操作
static func _execute_move_units(headquarter, operation: Dictionary):
	# 执行前最后一次检测
	var problem = DependencyResolver._find_problem(headquarter, operation)
	if problem["type"] != DependencyResolver.ProblemType.NO_PROBLEM:
		print("移动单位操作被阻塞")
		return
	
	var params = operation.get("params", {})
	var unit_ids = params.get("unit_ids", [])
	var target_position = params.get("target_position", Vector2.ZERO)
	
	# 这里实现具体的移动单位逻辑
	# 检查单位是否存在
	# 检查目标位置是否可达
	# 执行移动
	
	print("执行移动单位操作: 单位数量=" + str(unit_ids.size()) + ", 目标位置=" + str(target_position))

# 执行攻击目标操作
static func _execute_attack_target(headquarter, operation: Dictionary):
	# 执行前最后一次检测
	var problem = DependencyResolver._find_problem(headquarter, operation)
	if problem["type"] != DependencyResolver.ProblemType.NO_PROBLEM:
		print("攻击目标操作被阻塞")
		return
	
	# 1. 获取目标网格
	var params = operation.get("params", {})
	var target_grid = params["grid"]
	var unit_info = UnitData.UnitInfo.new(20, "", UnitData.ArmorType.NONE, UnitData.ShieldType.NONE, false)
	
	#使用80% 的兵力 去 生成部队
	var battalion_grids = (headquarter as Settlement).get_generate_Battalion_grids()
		
	await CommandBus.execute_command(AssembleBattalionCommand.new(headquarter, unit_info, battalion_grids[0]))
	
	# 这里实现具体的攻击逻辑
	# 检查单位和目标是否存在
	# 检查攻击是否可行
	# 执行攻击
	
	print("执行攻击目标操作: 目标=" + str(target_grid))

	

# 执行研究科技操作
static func _execute_research_tech(headquarter, operation: Dictionary):
	# 执行前最后一次检测
	var problem = DependencyResolver._find_problem(headquarter, operation)
	if problem["type"] != DependencyResolver.ProblemType.NO_PROBLEM:
		print("研究科技操作被阻塞")
		return
	
	var params = operation.get("params", {})
	var tech_id = params.get("tech_id", "")
	
	# 这里实现具体的研究科技逻辑
	# 检查科技是否可研究
	# 检查资源是否足够
	# 执行研究
	
	print("执行研究科技操作: " + tech_id)
