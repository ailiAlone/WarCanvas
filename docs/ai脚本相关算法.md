# WarCanvas AI脚本相关算法详解

## 概述
本文档详细介绍了WarCanvas AI系统中使用的各种算法，包括问题检测、依赖解析、操作合并与冲突解决等核心算法的实现细节。

## 问题检测算法

### 人口检测算法
系统使用多层次的人口检测算法来识别不同类型的人口短缺问题：

```gdscript
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
```

### 资源检测算法
系统使用基于供需关系的资源检测算法：

```gdscript
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
```

### 军事装备检测算法
系统针对不同类型的军事装备实现了专门的检测算法：

```gdscript
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
```

## 依赖解析算法

### 依赖链分析算法
系统使用递归算法来解决复杂的依赖关系，构建完整的操作链：

```gdscript
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
```

### 前置条件检查算法
系统针对不同操作类型实现了详细的前置条件检查：

```gdscript
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
```

## 操作合并与冲突解决算法

### 相似操作合并算法
系统实现了智能的操作合并算法，将相似操作合并以提高效率：

```gdscript
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
```

### 冲突操作解决算法
系统实现了优先级驱动的冲突解决机制：

```gdscript
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
```

## 优先级排序算法

### 操作优先级排序
系统实现了基于紧急度和缺乏程度的优先级排序算法：

```gdscript
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
```

## 人数计算算法

### 基于优先级的人数计算
系统实现了基于优先级的人数计算算法，根据问题的严重程度决定投入的人力资源：

```gdscript
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
```

## 调试辅助算法

### 问题链格式化
系统提供了专门的调试辅助函数，用于格式化问题链：

```gdscript
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
    
    # 缺乏度
    if problem.has("deficiency"):
        result += ", 缺乏度=" + str(problem["deficiency"])
    
    return result
```

## 总结
WarCanvas AI系统中的这些算法共同构成了一个复杂而高效的决策系统。通过多层次的问题检测、递归的依赖解析、智能的操作合并与冲突解决，以及基于优先级的排序机制，AI能够做出合理且高效的游戏决策。这些算法的设计充分考虑了游戏机制的复杂性，同时保证了系统的可维护性和可扩展性。