# WarCanvas AI脚本实现方法

## 概述
WarCanvas的AI系统基于双组件架构，通过ReactiveMaintenanceSystem（自动维护系统）和StrategicInitiativeEngine（战略发起引擎）的协同工作，实现智能化的游戏决策。这两个组件分别处理短期反应和长期规划，形成了一个平衡而高效的AI决策体系。

## ReactiveMaintenanceSystem（自动维护系统）

### 系统本质
ReactiveMaintenanceSystem是一个基于规则的反射系统。它不关心长远目标，只对当前环境的刺激做出反应，其核心驱动力是避免损失和维持稳态。

### 核心逻辑
```
IF (威胁/失衡) THEN (反应/修复)
```

### 系统架构
ReactiveMaintenanceSystem由三个核心组件构成：

1. **ReactiveMaintenanceSystem.gd** - 主控制器
   - 负责检测当前状态和问题
   - 管理问题队列和操作队列
   - 协调各组件的工作流程

2. **DependencyResolver.gd** - 依赖解析器
   - 分析操作的前置条件
   - 解决操作间的依赖关系
   - 构建可执行的操作链

3. **OperationExecutor.gd** - 操作执行器
   - 执行具体的原子操作
   - 通过CommandBus与游戏系统交互
   - 处理操作执行的结果

### 问题检测机制

#### 问题类型定义
系统通过枚举定义了多种问题类型：
```gdscript
enum ProblemType {
    NO_PROBLEM,               # 无阻塞
    RESOURCE_SHORTAGE,         # 资源短缺
    IDLE_POPULATION_SHORTAGE,   # 闲置人口短缺
    MILITARY_POPULATION_SHORTAGE, # 军事人口短缺
    BUILDING_SHORTAGE,         # 建筑短缺
    BUILDING_UNDER_CONSTRUCTION, # 建筑正在建造中
    FOOD_SHORTAGE,             # 食物短缺
    PRODUCTION_LINE_INPUTS_NOT_ENOUGH, # 生产线输入物品不足
    ERROR                     # 错误情况
}
```

#### 缺乏程度和紧急程度评估
系统使用两个枚举来量化问题的严重性：
```gdscript
enum Deficiency {
    NONE,       # 无缺乏
    MILD,       # 轻微缺乏
    MODERATE,   # 中度缺乏
    SEVERE,     # 严重缺乏
    CRITICAL    # 临界缺乏
}

enum Urgency {
    NONE,       # 无紧急
    LOW,        # 低紧急
    MEDIUM,     # 中紧急
    HIGH,       # 高紧急
    CRITICAL    # 临界紧急
}
```

#### 具体检测方法
1. **人口短缺检测**：
   - 闲置人口比例检测（低于10%、6%、3%分别对应不同严重程度）
   - 人口容量检测（人口超过容量触发建筑需求）
   - 军事人口比例检测（低于24%、16%、8%分别对应不同严重程度）

2. **资源短缺检测**：
   - 粮食短缺检测（基于剩余粮食可维持的回合数）
   - 材料和牲畜短缺检测（基于供需关系）
   - 军事装备短缺检测（武器、盾牌、盔甲、坐骑）

3. **建筑状态检测**：
   - 基本建筑存在性检测
   - 建筑建造状态检测
   - 生产线状态检测

### 依赖解析机制

#### 依赖链分析
DependencyResolver通过递归分析构建完整的操作链：
```gdscript
static func find_executable_operation(headquarter: Headquarter, problem: Dictionary) -> Dictionary:
    var current_problem = problem
    var answer_operation = null
    
    var max_attempts = 10
    var attempt_count = 0
    while true:
        # 解决当前问题 
        answer_operation = _resolve_problem(headquarter, current_problem)
        
        if answer_operation["type"] == ReactiveMaintenanceSystem.AtomicOperation.NO_OPERATION:
            return answer_operation
            
        attempt_count += 1
        if attempt_count >= max_attempts:
            return {"type": ReactiveMaintenanceSystem.AtomicOperation.NO_OPERATION, ...}
            
        # 检查当前操作是否有问题,及其阻塞原因
        current_problem = _find_problem(headquarter, answer_operation)
        
        if current_problem["type"] == ProblemType.NO_PROBLEM:
            return {
                "type":answer_operation["type"],
                "params":answer_operation["params"],
                "original_problem": problem,
            }
```

#### 前置条件检查
系统针对不同操作类型进行详细的前置条件检查：
- **建筑建造**：检查资源、人口、建筑位置等
- **生产安排**：检查生产线状态、输入资源、人口等
- **征兵操作**：检查兵营存在性、人口容量、闲置人口等

### 操作执行机制

#### 原子操作定义
系统定义了多种原子操作类型：
```gdscript
enum AtomicOperation {
    NO_OPERATION,          # 无操作
    RECRUIT_TROOPS,        # 征兵
    CONSTRUCT_BUILDING,    # 建造建筑
    ASSIGN_PRODUCTION,     # 安排生产
    CLEAR_PRODUCTION,      # 清空生产队列
    MOVE_UNITS,            # 移动单位
    ATTACK_TARGET,         # 攻击目标
    RESEARCH_TECH,         # 研究科技
}
```

#### 操作合并与冲突解决
系统实现了智能的操作合并和冲突解决机制：
1. **相似操作合并**：合并同类型的多个操作，提高效率
2. **冲突操作解决**：处理对立操作（如安排生产vs清空生产）
3. **优先级排序**：根据紧急度和缺乏程度排序操作

#### 具体操作实现
每种操作都有详细的实现逻辑：
- **征兵操作**：检查前置条件，通过RecruitCommand执行
- **建筑建造**：选择合适位置，通过SettleBuildCommand执行
- **生产安排**：计算工人数量，通过AssignCommand执行
- **生产清空**：重置生产线状态

### 优势与局限
**优势**：
- 反应迅速，能及时应对突发情况
- 实现简单，规则明确
- 稳定可靠，不会做出过于激进的决策
- 支持复杂的依赖关系解析
- 具备操作合并和冲突解决能力

**局限**：
- 缺乏长远规划能力
- 可能陷入局部最优解
- 无法主动创造机会
- 依赖规则的完整性

## StrategicInitiativeEngine（战略发起引擎） （暂时还未实现）

### 系统本质
StrategicInitiativeEngine是一个目标驱动的规划系统。它主动发出指令，打破当前的平衡，以追求一个更高级的、预设的未来状态。其核心驱动力是实现增长和完成项目。

### 核心逻辑
```
WHILE (有目标 且 无紧急威胁) DO (执行计划 -> 打破平衡 -> 等待反应式维护系统解决问题 -> 实现目标)
```

### 主要功能
1. **长期目标设定**
   - 根据游戏阶段设定战略目标
   - 评估目标的可行性和优先级
   - 动态调整目标以适应游戏变化

2. **战略规划**
   - 制定实现目标的详细计划
   - 分解长期目标为短期任务
   - 预估资源需求和时间成本

3. **扩张决策**
   - 评估扩张时机和方向
   - 规划新定居点的建立
   - 决定探险队的组成和任务

4. **军事战略**
   - 规划军事发展路线
   - 制定攻击和防御策略
   - 平衡军事投入与经济发展

### 实现原理
- **目标树**：将大目标分解为子目标和具体任务
- **状态评估**：定期评估当前状态与目标的差距
- **计划生成器**：根据目标和当前状态生成可行的行动计划
- **风险评估**：评估计划的风险和收益，选择最优方案

### 优势与局限
**优势**：
- 具备长远规划能力
- 能够主动创造机会
- 适应性强，能根据情况调整策略

**局限**：
- 计划可能过于理想化
- 对突发情况反应不足
- 可能过度消耗资源

## 双系统协同机制

### 协同原理
ReactiveMaintenanceSystem和StrategicInitiativeEngine通过以下方式协同工作：

1. **优先级协调**：StrategicInitiativeEngine只有在无紧急威胁时才执行计划
2. **资源平衡**：ReactiveMaintenanceSystem确保基本生存，StrategicInitiativeEngine追求发展
3. **反馈循环**：StrategicInitiativeEngine的行动会触发ReactiveMaintenanceSystem的反应
4. **动态平衡**：两个系统共同维持AI在稳定与发展之间的平衡

### 工作流程
1. **状态评估**：两个系统共同评估当前游戏状态
2. **威胁检测**：ReactiveMaintenanceSystem检测并处理紧急威胁
3. **战略规划**：在无紧急威胁时，StrategicInitiativeEngine制定并执行计划
4. **问题解决**：计划执行过程中产生的问题由ReactiveMaintenanceSystem处理
5. **目标实现**：循环往复，逐步实现战略目标

## 实现细节

### 代码结构
```
AIStrategy
├── ReactiveMaintenanceSystem
│   ├── reactive_maintenance_system.gd (主控制器)
│   ├── dependency_resolver.gd (依赖解析器)
│   └── operation_executor.gd (操作执行器)
└── StrategicInitiativeEngine
    ├── TO COMPLETE
```

### 数据交互
- **共享状态**：两个系统共享游戏状态数据
- **命令总线**：通过CommandBus执行具体操作
- **优先级标记**：使用优先级标记协调系统行动

### 性能优化
- **帧率控制**：限制AI决策频率，避免性能问题
- **增量更新**：只处理发生变化的状态
- **缓存机制**：缓存计算结果，减少重复计算
- **分层决策**：不同层级的决策有不同的执行频率

## 调试与优化

### 调试工具
- **决策日志**：记录AI的决策过程和原因
- **状态可视化**：可视化AI的内部状态和计划
- **性能监控**：监控AI系统的性能表现
- **行为分析**：分析AI行为的合理性和效率

### 优化方向
1. **规则优化**：完善ReactiveMaintenanceSystem的规则库
2. **算法改进**：改进StrategicInitiativeEngine的规划算法
3. **学习机制**：添加简单的学习机制，适应玩家行为
4. **动态调整**：根据游戏难度动态调整AI参数

## 总结
WarCanvas的AI系统通过ReactiveMaintenanceSystem和StrategicInitiativeEngine的协同工作，实现了既能应对短期威胁又能进行长期规划的智能行为。ReactiveMaintenanceSystem采用了基于规则的反应式设计，通过问题检测、依赖解析和操作执行三个核心组件，实现了复杂的自适应行为。这种双系统架构既保证了AI的稳定性，又赋予了AI发展能力，为玩家提供了富有挑战性的游戏体验。

## 相关文档
详细的算法实现请参考：[AI脚本相关算法](./ai脚本相关算法.md)
