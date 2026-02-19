# 配方数据类
class_name RecipeData

# 配方模板类
class RecipeTemplate:
	var main_product: String      # 主产品ID
	var worker_num: int          # 所需工人数量
	var inputs: Dictionary             # 输入物品字典，键为物品ID，值为数量
	var outputs: Dictionary            # 输出物品字典，键为物品ID，值为数量
	var source_building: String   # 来源建筑ID
	var preposition_building: String 	# 前置建筑ID
	
	# 构造函数
	func _init(p_main_product, p_worker_num, p_inputs, p_outputs, p_source_building, p_preposition_building):
		self.main_product = p_main_product
		self.worker_num = p_worker_num
		self.inputs = p_inputs
		self.outputs = p_outputs
		self.source_building = p_source_building
		self.preposition_building = p_preposition_building
	
	# 获取输入物品的字符串表示
	func get_inputs_string() -> String:
		var result = ""
		var i = 0
		for item_id in inputs:
			var quantity = inputs[item_id]
			var name = Locale.get_text(item_id)
			if i > 0:
				result += " + "
			result += str(quantity) + " " + name
			i += 1
		return result
	
	# 获取输出物品的字符串表示
	func get_outputs_string() -> String:
		var result = ""
		var i = 0
		for item_id in outputs:
			var quantity = outputs[item_id]
			var name = Locale.get_text(item_id)
			if i > 0:
				result += " + "
			result += str(quantity) + " " + name
			i += 1
		return result

# 所有配方的字典，key为主产品ID，value为RecipeTemplate数组
static var recipes: Dictionary = {}

static func ensure_recipes_loaded():
	if recipes == {}:
		ItemData.ensure_item_templates_loaded()
		_initialize_recipes()

# 初始化所有配方数据
static func _initialize_recipes():
	# 从CSV文件读取配方数据
	var csv_file = FileAccess.open("res://shared/resources/items/recipe/recipe.csv", FileAccess.READ)
	if csv_file == null:
		push_error("错误：无法打开配方CSV文件")
		return
	
	# 读取CSV头
	var headers = csv_file.get_csv_line()
	
	# 读取每一行数据
	while !csv_file.eof_reached():
		var line = csv_file.get_csv_line()
		if line.size() < headers.size() or line[0] == "":
			continue
			
		# 解析CSV数据
		var main_product = line[0]  # MainProduct
		var worker_count = int(line[1]) if line[1] != "" else 0  # Worker
		var inputs_str = line[2]  # Inputs
		var outputs_str = line[3]  # Outputs
		var source_building = line[4] if line[4] != "" and line[4] != "-" else ""  # Source
		var preposition = line[5] if line[5] != "" and line[5] != "-" else ""  # Preposition
		
		# 解析输入物品
		var inputs = _parse_items_string(inputs_str)
		
		# 解析输出物品
		var outputs = _parse_items_string(outputs_str)
		
		# 创建配方模板
		var recipe_template = RecipeTemplate.new(
			main_product,
			worker_count,
			inputs,
			outputs,
			source_building,
			preposition
		)
		
		# 添加到配方字典
		if not recipes.has(main_product):
			recipes[main_product] = []
		recipes[main_product].append(recipe_template)

	csv_file.close()

# 解析物品字符串，返回字典，每个元素是[item_id, quantity]
static func _parse_items_string(items_str: String) -> Dictionary:
	var result = {}
	
	if items_str == "":
		return result
	
	# 分割多个物品
	var item_parts = items_str.split("+")
	
	for part in item_parts:
		part = part.strip_edges()
		if part == "":
			continue
			
		# 分割数量和物品ID
		var space_index = part.find(" ")
		if space_index == -1:
			continue
			
		var quantity = int(part.substr(0, space_index))
		var item_id = part.substr(space_index + 1).strip_edges()
		
		result[item_id] = quantity
	
	return result

# 根据主产品ID获取所有配方
static func get_recipes_by_main_product(main_product: String) -> Array[RecipeTemplate]:
	if recipes.has(main_product):
		return recipes[main_product]
	return []

# 根据主产品ID和来源建筑获取配方
static func get_recipe_by_main_product_and_source(main_product: String, source_building: String) -> RecipeTemplate:
	if not recipes.has(main_product):
		return null
		
	for recipe in recipes[main_product]:
		if recipe.source_building == source_building:
			return recipe
	
	return null

# 获取所有配方
static func get_all_recipes() -> Array[RecipeTemplate]:
	var all_recipes: Array[RecipeTemplate] = []
	for value in recipes.values():
		for recipe in value:
			all_recipes.append(recipe)
	return all_recipes

# 检查是否有指定主产品的配方
static func has_recipe(main_product: String) -> bool:
	return recipes.has(main_product) and recipes[main_product].size() > 0
