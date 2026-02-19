class_name BuildingData

# 建筑数据结构
class BuildingInfo:
	var id: String               # 建筑ID
	var model_scene: PackedScene       # 建筑模型场景
	var icon: CompressedTexture2D        # 建筑图标
	var max_health: int          # 最大生命值
	var capacity: int 			 # 容量 (对于人口建筑是人口容量  对于资源建筑是工人容量  对于兵营兵力容量)
	var core_value: float        # 核心值
	var category: String         # 建筑分类
	var name: String             # 建筑名称
	var required_materials: Dictionary         # 解析后的建造成本
	var description: String      # 建筑描述
	
	func _init(p_id: String, p_model_path: String, p_icon_path: String, 
				p_max_health: int, p_required_materials: String, 
				p_capacity: int, p_core_value: float, p_category: String):
		id = p_id
		if p_model_path == "-":
			push_error("建筑 %s 没有模型路径" % id)
		else:
			model_scene = load(p_model_path)
		# icon = load(p_icon_path)
		max_health = p_max_health
		required_materials = _parse_cost(p_required_materials)
		capacity = p_capacity
		core_value = p_core_value
		category = p_category
		name = Locale.get_text(id)
		description = _generate_description()
	
	# 解析所需材料字符串为成本字典
	func _parse_cost(p_required_materials: String) -> Dictionary:
		var cost_dict = {}
		if p_required_materials == "" or p_required_materials == "-":
			return cost_dict
		
		# 处理格式如 "2 Wood" 或 "5 Wood + 2 Cloth"
		var materials = p_required_materials.split("+")
		for material in materials:
			material = material.strip_edges()
			if material == "":
				continue
				
			# 处理格式如 "2 Wood" 或 "10 Stone per section"
			var parts = material.split(" ", true, true)
			if parts.size() >= 2:
				var amount_str = parts[0]
				var resource_id = ""
				
				# 提取资源名称（跳过数量和可能的"per section"等修饰词）
				for i in range(1, parts.size()):
					if parts[i] == "per":
						break
					if resource_id != "":
						resource_id += " "
					resource_id += parts[i]
				
				# 尝试解析数量
				if amount_str.is_valid_int():
					cost_dict[resource_id] = amount_str.to_int()
		
		return cost_dict
	
	# 根据建筑类型生成描述
	func _generate_description() -> String:
		match category:
			"POPULATION":
				return "提供住所，可容纳%d人" % capacity
			"RESOURCE":
				return "提供基础资源，最多可容纳%d名工人" % capacity
			"PROCESSOR":
				return "加工和提升资源价值，最多可容纳%d名工人" % capacity
			"ECONOMIC":
				return "促进经济发展和贸易"
			"CORE":
				return "核心建筑，提供基础功能"
			"ADVANCED":
				return "高级建筑，提供额外功能"
			"MILITARY":
				return "增强军事能力和防御"
			"DEFENSE":
				return "防御建筑，提供防御功能"
			_:
				return "%s建筑" % category.capitalize()

# 所有建筑信息字典，以ID为键
static var building_info_dict: Dictionary = {}

static var construction_scene: PackedScene
# 初始化所有建筑数据
static func _initialize_buildings():
	# 从CSV文件读取建筑数据
	var csv_file = FileAccess.open("res://shared/resources/buildings/buildings.csv", FileAccess.READ)
	if csv_file == null:
		push_error("错误：无法打开建筑CSV文件")
		return
	
	# 读取CSV头
	var headers = csv_file.get_csv_line()
	
	# 读取CSV数据行
	while not csv_file.eof_reached():
		var line = csv_file.get_csv_line()
		if line.size() < headers.size() or line[0] == "":
			continue
		
		# 解析CSV数据
		var id = line[0] # ID
		var model_path = line[1] # ModelPath
		var icon_path = line[2] # IconPath
		var max_health = int(line[3]) if line[3] != "" and line[3] != "-" else 100 # MaxHealth
		var required_materials = line[4] # Required Materials
		var capacity = line[5] # Capacity
		var core_value = float(line[6]) if line[6] != "" and line[6] != "-" else 1.0 # Core_Value
		var category = line[7] # Category
		
		# 创建建筑信息对象并添加到字典
		var building_info = BuildingInfo.new(
			id, model_path, icon_path, max_health, required_materials,
			capacity.to_int(), core_value, category
		)
		building_info_dict[id] = building_info
	
	# 加载建造场景
	construction_scene = load("res://shared/resources/buildings/building_models/construction_site/construction_site.fbx")
	if construction_scene == null:
		push_error("错误：无法加载施工场景")
		return

# 确保建筑数据已初始化
static func _ensure_initialized():
	if building_info_dict.is_empty():
		_initialize_buildings()

# 根据ID获取建筑信息
static func get_building_by_id(id: String) -> BuildingInfo:
	_ensure_initialized()
	return building_info_dict.get(id, null)

# 获取所有建筑信息
static func get_all_building_info() -> Array:
	_ensure_initialized()
	return building_info_dict.values()

# 根据类别获取建筑信息
static func get_buildings_by_category(category: String) -> Array:
	_ensure_initialized()
	var result = []
	for building in building_info_dict.values():
		if building.category == category:
			result.append(building)
	return result

# 打印所有建筑信息（调试用）
static func print_all_buildings():
	_ensure_initialized()
	print("=== 所有建筑信息 ===")
	for id in building_info_dict:
		var building = building_info_dict[id]
		print("ID: %s, 名称: %s, 模型路径: %s, 最大生命值: %d" % [
			building.id, building.name, building.model_path, building.max_health
		])
		print("  所需材料: %s" % building.required_materials)
		print("  解析后成本: %s" % building.cost)
		print("  最大工人: %d, 人口容量: %d" % [building.max_worker, building.population_capacity])
		print("  核心值: %.1f, 类别: %s" % [building.core_value, building.category])
		print("  描述: %s" % building.description)
		print("------------------")
	print("==================")

# 获取建筑类别列表
static func get_all_categories() -> Array:
	_ensure_initialized()
	var categories = {}
	for building in building_info_dict.values():
		categories[building.category] = true
	return categories.keys()

# 获取建筑总数
static func get_building_count() -> int:
	_ensure_initialized()
	return building_info_dict.size()

static func get_construction_scene() -> PackedScene:
	return construction_scene
