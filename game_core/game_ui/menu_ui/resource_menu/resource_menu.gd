extends VBoxContainer
class_name ResourceMenu

# 引用场景节点
@onready var food_value = $BasicResources/ResourceGrid/FoodValue
@onready var money_value = $BasicResources/ResourceGrid/MoneyValue
@onready var total_value_value = $BasicResources/ResourceGrid/TotalValueValue
@onready var weight_value = $BasicResources/ResourceGrid/WeightValue

@onready var original_items = $OriginalItems
@onready var processed_items = $ProcessedItems

# 当前关联的总部
var _headquarter: Headquarter = null

func _ready() -> void:
	ItemData._initialize_item_templates()
	for item in ItemData.get_all_item_templates():
		# 创建物品容器
		var item_container = VBoxContainer.new()
		item_container.name = item.id.validate_node_name()
		item_container.alignment = BoxContainer.ALIGNMENT_CENTER  # 设置容器内元素居中对齐
		item_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # 水平居中
		item_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # 垂直居中
		
		# 创建物品图片
		var item_texture = TextureRect.new()
		item_texture.name = "Icon"
		item_texture.custom_minimum_size = Vector2(56, 56)  # 设置图标大小为56x56像素
		
		item_texture.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # 垂直居中
		item_texture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # 水平居中
		item_texture.stretch_mode = TextureRect.STRETCH_SCALE  # 缩放图片以适应控件大小
		item_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL  # 保持宽高比适应宽度
		
		# 加载图标
		if item.icon:
			item_texture.texture = item.icon
		else:
			push_warning("物品图标为空: " + item.name)
		
		# 创建物品标签
		var item_label = Label.new()
		item_label.name = "Label"
		item_label.text = item.name + "*" + "0" 
		
		# 将图标和标签添加到容器
		item_container.add_child(item_texture)
		item_container.add_child(item_label)
		
		# 根据物品类型添加到相应的容器
		if item.hierarchy == "Original":
			original_items.add_child(item_container)
		elif item.hierarchy == "Processed":
			processed_items.add_child(item_container)
		else:
			push_error("unexpected item hierarchy:" + item.hierarchy)

# 更新关联的总部
func set_headquarter(headquarter: Headquarter):
	_headquarter = headquarter
	update()

# 更新资源数据
func update():
	# 更新基础资源
	food_value.text =  str(_headquarter.inventory.get_food())
	money_value.text =  str(_headquarter.inventory._money)
	total_value_value.text = str(_headquarter.inventory.get_total_value())
	weight_value.text = str(_headquarter.inventory.get_total_weight())

	# 更新物品数量
	for item_container in original_items.get_children():
		if item_container is VBoxContainer:
			var item_id = item_container.name
			var item_template = ItemData.get_item_template(item_id)
			var item_label = item_container.get_node("Label")
			var item_count = _headquarter.inventory.get_item_quantity(item_id)
			item_label.text = item_template.name + "*" + str(item_count)
	
	for item_container in processed_items.get_children():
		if item_container is VBoxContainer:
			var item_id = item_container.name
			var item_template = ItemData.get_item_template(item_id)
			var item_label = item_container.get_node("Label")
			var item_count = _headquarter.inventory.get_item_quantity(item_id)
			item_label.text = item_template.name + "*" + str(item_count)
