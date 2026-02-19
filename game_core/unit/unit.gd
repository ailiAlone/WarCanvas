extends Node3D
class_name Unit

#移动力
var speed: float = 5.0
#攻击力
var attack: int = 10
#防御力
var defense: int = 5
#攻击范围
var attack_range: int = 1
#视野范围
var vision_range: int = 10

var belonging_node:Node = null
#信息
var info:UnitData.UnitInfo = null

#单位方向（弧度）
var direction: float = 0.0
var model: PackedScene
var basic_info_window: Node3D

# 配置
var squad_size: int = 5 # 1~61 个模型（满格61，37，19，7）
var max_squad_size: int = 61
var model_scale: float = 0.7     # 模型大小 0.7

# 移动状态
var is_moving: bool = false
var move_target: Vector3 = Vector3.ZERO

var occupy_grid: Grid = null
func _init(p_info:UnitData.UnitInfo,p_grid:Grid,p_belonging_node:Node):
	info = p_info
	belonging_node = p_belonging_node
	
	occupy_grid = p_grid
	p_grid.holding_node3D = self
	position = p_grid.center_point + Vector3(0, 1, 0)

func _ready():
	# 初始状态下禁用_process，只在移动时启用
	set_process(false)

func generate_model():
	# 生成紧凑的六边形排布位置
	var positions = generate_hexagon_positions()
	
	# 加载单位模型
	# model = info.load_unit_model_scene()
	
	# if model:
	# 在每个位置实例化模型
	for i in range(squad_size):
		var model_instance:Node3D = info.load_unit_model_scene()
		# 设置模型位置
		model_instance.position = positions[i]
		# 设置模型缩放
		model_instance.scale = Vector3(model_scale, model_scale, model_scale)
		# 将模型实例添加到当前节点作为子节点
		add_child(model_instance)
	# else:
	# 	push_error("警告：无法加载单位模型 ")
	# 创建基础信息窗口
	generate_basic_info_window()

# 移动完成信号
signal movement_completed

func move_to(grid: Grid):
	# 设置移动目标
	move_target = grid.center_point
	is_moving = true
	# 启用处理
	set_process(true)
	occupy_grid.holding_node3D = null
	occupy_grid = grid
	grid.holding_node3D = self

# 设置单位方向（弧度）
func set_direction(new_direction: float):
	direction = new_direction
	# 更新单位旋转
	rotation.y = direction
	# 更新所有子模型的方向
	update_models_direction()

# 设置单位朝向目标位置
func face_towards(target_position: Vector3):
	var direction_vector = target_position - position
	# 只考虑水平面上的方向
	direction_vector.y = 0
	# 计算方向角度（弧度）
	var new_direction = atan2(direction_vector.x, direction_vector.z)
	set_direction(new_direction)

# 获取单位当前方向（弧度）
func get_direction() -> float:
	return direction

# 获取单位当前方向（角度）
func get_direction_degrees() -> float:
	return rad_to_deg(direction)

# 更新所有子模型的方向
func update_models_direction():
	for child in get_children():
		if child is Node3D and child != basic_info_window:
			child.rotation.y = direction

func _process(delta):
	# 如果正在移动，持续向目标位置移动
	if is_moving:
		# 计算移动方向和距离
		var direction = (move_target - position).normalized()
		var distance = (move_target - position).length()
		
		# 计算这一帧应该移动的距离
		var move_distance = 24 * delta
		
		# 如果距离小于这一帧的移动距离，直接到达目标位置
		if distance <= move_distance:
			position = move_target
			is_moving = false
			
			set_process(false)  # 停止处理以节省性能
			movement_completed.emit()	
		else:
			# 向目标位置移动
			position += direction * move_distance
			# 更新单位朝向移动方向
			face_towards(move_target)

# 生成六边形位置
func generate_hexagon_positions() -> Array:
	var positions = []
	var spacing = model_scale * 0.6
	var sqrt3 = sqrt(3)
	
	# 使用六边形坐标系统 (axial coordinates)
	# 从中心开始向外逐层填充
	var layer = 0
	while positions.size() < squad_size:
		# 遍历当前层的所有六边形
		for q in range(-layer, layer + 1):
			for r in range(max(-layer, -q - layer), min(layer, -q + layer) + 1):
				# 检查是否在当前层
				var distance = max(abs(q), abs(r), abs(-q - r))
				if distance == layer:
					# 转换为实际坐标
					var pos_x = spacing * sqrt3 * (q + r * 0.5)
					var pos_z = spacing * 1.5 * r
					
					positions.append(Vector3(pos_x, 0, pos_z))
					
					if positions.size() >= squad_size:
						break
				if positions.size() >= squad_size:
						break
		layer += 1
	
	return positions

func generate_basic_info_window() -> void:
	# 根据 belonging_node 的类型决定使用哪种badge系统
	if belonging_node is Battalion:
		var battalion_badge_scene = preload("res://game_core/game_ui/common/battalion_badge/battalion_badge.tscn")
		basic_info_window = battalion_badge_scene.instantiate()
		add_child(basic_info_window)
		# 确保节点已添加到场景树后再调用initialize
		await get_tree().process_frame
		basic_info_window.initialize(belonging_node as Battalion)
	elif belonging_node is Expedition:
		var expedition_badge_scene = preload("res://game_core/game_ui/common/expedition_badge/expedition_badge.tscn")
		basic_info_window = expedition_badge_scene.instantiate()
		add_child(basic_info_window)
		# 确保节点已添加到场景树后再调用initialize
		await get_tree().process_frame
		basic_info_window.initialize(belonging_node as Expedition)
	else:
		# 如果不属于任何已知类型，使用默认的battalion_badge
		var battalion_badge_scene = preload("res://game_core/game_ui/common/battalion_badge/battalion_badge.tscn")
		basic_info_window = battalion_badge_scene.instantiate()
		add_child(basic_info_window)
		# 确保节点已添加到场景树后再调用initialize
		await get_tree().process_frame
		basic_info_window.initialize(belonging_node as Battalion)

func get_movable_area() -> Array[Grid]:
	return GridUtils.get_grids_by_expansion(occupy_grid, int(speed))
