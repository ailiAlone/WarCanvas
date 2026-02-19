extends Node3D

class_name Building

# 建筑基本信息
var building_info: BuildingData.BuildingInfo  # 建筑数据信息
var settlement: Settlement = null            # 所属定居点
# 建筑属性
var health: int = 1                         # 当前生命值
var is_core: bool = false                   # 是否核心建筑 默认不是核心建筑

# 建筑状态
var is_finished: bool = false               # 是否建造完成 默认不是建造未完成
var is_occupied: bool = false               # 是否被占领 默认未被占领

# 建筑人员
var constructor_num: int				# 建造者数量

# 建筑模型和UI
var model: Node3D = null                    # 建筑模型节点
var badge: Node3D = null        			# 基础信息窗口
var model_scale: float = 1.5                # 模型缩放比例

# 建筑位置
var occupy_grid: Grid = null                # 占据的网格

var building_badge_scene = preload("res://game_core/game_ui/common/building_badge/building_badge.tscn")

# 初始化
func _init(p_info: BuildingData.BuildingInfo, p_grid: Grid, p_settlement: Settlement,constructor_count: int):
	# 初始化建筑基本信息
	building_info = p_info

	occupy_grid = p_grid
	p_grid.holding_node3D = self
	position = p_grid.center_point + Vector3(0, 1, 0)
	# 初始化建造者数量
	constructor_num = constructor_count

	settlement = p_settlement
	settlement.buildings.append(self)

# 根据建筑类型加载相应的模型
func load_building_model():
	model = building_info.model_scene.instantiate()
	model.scale = Vector3(model_scale, model_scale, model_scale)
	add_child(model)

#生成基础信息窗口
func generate_badge() -> void:
	badge = building_badge_scene.instantiate()
	add_child(badge)
	# 确保节点已添加到场景树后再调用set_building
	await get_tree().process_frame
	badge.initialize(self)


func create_construction_site() -> void:
	# 设置建筑初始状态
	health = 1
	is_finished = false
	
	# 检查是否为0个建筑工人（表示立即建成）
	if constructor_num == 0:
		# 立即完成建筑
		health = building_info.max_health
		is_finished = true
		
		# 生成最终的建筑模型
		load_building_model()
		
		# 创建基础信息窗口
		generate_badge()
		
		# 更新定居点
		settlement.buildings_changed.emit()
		settlement.update_occypied_grids()
		settlement.population._scan_population_buildings()
		
		print("建筑 %s 已立即建成" % building_info.name)
		return
	

	var construction_site = BuildingData.get_construction_scene().instantiate()
		
	# 设置模型缩放以适应建筑大小
	construction_site.scale = Vector3(model_scale, model_scale, model_scale)

	# 将施工场地添加到场景
	add_child(construction_site)
	model = construction_site  # 将施工场地作为模型

	# 创建基础信息窗口
	generate_badge()
	EventBus.new_headquarter_started.connect(increase_construction_progress)

# 回合开始时调用，更新建筑进度
func increase_construction_progress(headquarter: Headquarter) -> void:
	if settlement != (headquarter as Settlement):
		return

	# 每回合增加生命值
	health += constructor_num
	
	# 检查建筑是否完成
	if health >= building_info.max_health:
		health = building_info.max_health

		# 移除当前施工场地模型
		if model and model is MeshInstance3D:
			model.queue_free()
			model = null
			
		is_finished = true
		EventBus.new_headquarter_started.disconnect(increase_construction_progress)
		settlement.buildings_changed.emit()
		# 生成最终的建筑模型
		load_building_model()
		settlement.update_occypied_grids()
		settlement.population._scan_population_buildings()

	badge.update_info()
