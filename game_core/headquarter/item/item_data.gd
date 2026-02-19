class_name ItemData

# 物品数据结构
class ItemTemplate:
	var id: String                     # 物品ID
	var name: String                   # 物品名称
	var icon: CompressedTexture2D      # 物品图标
	var category: String               # 物品类别
	var hierarchy: String              # 物品层级：Original（直接获取）或Processed（加工的）
	var unit_weight: float             # 单位重量
	var base_price: int                # 基础价格
	var food_rate: int                 # 食物换算率，表示一个单位物品可以换算成多少食物
	
	func _init(p_id: String, p_icon_path: String, 
				p_category: String, p_hierarchy: String, p_unit_value: int, p_unit_weight: float,
				p_food_rate: int = 0):
		id = p_id
		name = Locale.get_text(id)  # 从翻译管理器获取名称，如果没有翻译则使用type
		category = p_category
		hierarchy = p_hierarchy
		unit_weight = p_unit_weight
		food_rate = p_food_rate
		base_price =  p_unit_value
		
		# 加载图标
		if p_icon_path != "-":
			icon = load(p_icon_path)
		else:
			icon = null

# 所有物品 - 通过ID索引
static var itemTemplates: Dictionary = {}

# 确保物品数据已加载
static func ensure_item_templates_loaded():
	if itemTemplates == {}:
		_initialize_item_templates()

# 初始化所有物品数据
static func _initialize_item_templates():
	# 从CSV文件读取物品数据
	var csv_file = FileAccess.open("res://shared/resources/items/items.csv", FileAccess.READ)
	if csv_file == null:
		push_error("错误：无法打开物品CSV文件")
		return
	
	# 读取CSV头
	var headers = csv_file.get_csv_line()
	
	# 读取每一行数据
	while !csv_file.eof_reached():
		var line = csv_file.get_csv_line()
		if line.size() < headers.size() or line[0] == "":
			continue
			
		# 解析CSV数据
		var hierarchy = line[0]  # Hierarchy
		var id = line[1]  # Type
		var icon_path = line[2]  # IconPath
		var category = line[3]  # Category
		var unit_value = int(line[4]) if line[4] != "" else 0  # UnitValue
		var unit_weight = float(line[5]) if line[5] != "" else 0.0  # Unit Weight
		var food_rate = int(line[6]) if line[6] != "" and line[6] != "-" else 0  # FoodRate
		
		# 创建物品模板
		var item_template = ItemTemplate.new(
			id,  # 使用类型作为ID
			icon_path,
			category,
			hierarchy,  
			unit_value,
			unit_weight,
			food_rate  # 食物换算率
		)
		# 添加到模板字典
		itemTemplates[id] = item_template
	
	csv_file.close()

# 获取物品
static func get_item_template(item_id: String) -> ItemTemplate:
	# 检查物品是否存在
	for item_template in itemTemplates.values():
		if item_template.id == item_id:
			return item_template
		
	return null

# 获取所有物品模板
static func get_all_item_templates() -> Array[ItemTemplate]:
	var all_items: Array[ItemTemplate] = []
	for item_template in itemTemplates.values():
		all_items.append(item_template)
	return all_items

# 获取指定类别的所有物品模板
static func get_items_by_category(category: String) -> Array[ItemTemplate]:
	var result: Array[ItemTemplate] = []
	for item_template in itemTemplates.values():
		if item_template.category == category:
			result.append(item_template)
			
	return result
