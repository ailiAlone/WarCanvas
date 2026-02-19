extends HBoxContainer
class_name AssignmentItem

# 引用节点
@onready var production_cap_slider = $ArrangeContainer/ProductionCap/HSlider
@onready var production_cap_spin_box = $ArrangeContainer/ProductionCap/SpinBox
@onready var capacity_slider = $ArrangeContainer/Capacity/HSlider
@onready var capacity_spin_box = $ArrangeContainer/Capacity/SpinBox
@onready var inventory_label = $ProductInfo/InventoryLabel
@onready var explanation_label = $VBoxContainer/ExplanationLabel

# 当前配方模板
var _recipe_template: RecipeData.RecipeTemplate = null
var _production_line: Production.ProductionLine = null
var _headquarter: Headquarter = null

# 设置配方数据 只调用一次
func set_recipe_template(recipe_template: RecipeData.RecipeTemplate):
	_recipe_template = recipe_template
	
	# 设置主产品名称
	$ProductInfo/MainProductionLabel.text = Locale.get_text(recipe_template.main_product)
	
	# 设置主产品图标
	var item_template = ItemData.get_item_template(recipe_template.main_product)
	if item_template and item_template.icon:
		$ProductInfo/ProductTextureRect.texture = item_template.icon
	else:
		$ProductInfo/ProductTextureRect.texture = null
	
	# 构建配方字符串
	var inputs_str = _recipe_template.get_inputs_string()
	var outputs_str = _recipe_template.get_outputs_string()
	var worker_str = str(_recipe_template.worker_num) + " " + Locale.get_text("WORKER")
	
	$ArrangeContainer/RecipeLabel.text = worker_str + " : \n" + inputs_str + " -> " + outputs_str

	#设置生产力步长
	$ArrangeContainer/ProductionCap/HSlider.step = _recipe_template.worker_num
	$ArrangeContainer/ProductionCap/SpinBox.step = _recipe_template.worker_num

	# 连接信号
	$ArrangeContainer/ProductionCap/HSlider.value_changed.connect(_on_production_cap_slider_changed)
	$ArrangeContainer/ProductionCap/SpinBox.value_changed.connect(_on_production_cap_spin_box_changed)
	$ArrangeContainer/Capacity/HSlider.value_changed.connect(_on_capacity_slider_changed)
	$ArrangeContainer/Capacity/SpinBox.value_changed.connect(_on_capacity_spin_box_changed)
	$VBoxContainer/ConfirmButton.pressed.connect(_on_confirm_button_pressed)

# 更新生产数据
func update_assignment_item_data(p_production_line: Production.ProductionLine,headquarter: Headquarter):
	_production_line = p_production_line
	_headquarter = headquarter
	
	# 更新库存信息
	var main_product_id = _recipe_template.main_product
	var inventory_count = _headquarter.inventory.get_item_quantity(main_product_id)
	inventory_label.text = "库存: " + str(inventory_count)
	explanation_label.text = ""

	#设置他们现在的生产上限和当前生产数量
	production_cap_slider.value = _production_line.production_cap
	production_cap_spin_box.value = _production_line.production_cap
	capacity_slider.value = _production_line.active_num * _recipe_template.worker_num
	capacity_spin_box.value = _production_line.active_num * _recipe_template.worker_num

	# 更新生产上限和生产
	production_cap_slider.max_value = 10000  # 假设最大生产上限为100
	production_cap_spin_box.max_value = 10000
	capacity_slider.max_value = 10000
	capacity_spin_box.max_value = 10000

	if _production_line.require_source_building:
		capacity_slider.max_value = _production_line.source_building_num * 30
		capacity_spin_box.max_value = _production_line.source_building_num * 30
		var building_name = BuildingData.get_building_by_id(_recipe_template.source_building).name
		explanation_label.text = "生产建筑: " + building_name  +"\n当前数量: " + str(_production_line.source_building_num) +"\n"

	#需要前置建筑，且没有达成要求，则无法设定生产力
	if _production_line.require_preposition_building:
		var building_name = BuildingData.get_building_by_id(_recipe_template.preposition_building).name
		explanation_label.text += "前置建筑: " + building_name
		if not _production_line.has_preposition_building:
			capacity_slider.max_value = 0
			capacity_spin_box.max_value = 0

# 生产上限滑块变化
func _on_production_cap_slider_changed(value):
	if value != production_cap_spin_box.value:
		production_cap_spin_box.value = value

# 生产上限数值框变化
func _on_production_cap_spin_box_changed(value):
	if value != production_cap_slider.value:
		production_cap_slider.value = value

# 生产力滑块变化
func _on_capacity_slider_changed(value):
	if value != capacity_spin_box.value:
		capacity_spin_box.value = value

# 生产力数值框变化
func _on_capacity_spin_box_changed(value):
	if value != capacity_slider.value:
		capacity_slider.value = value

# 确认按钮按下
func _on_confirm_button_pressed():
	# 更新生产上限和生产力
	CommandBus.execute_command(AssignCommand.new(
		_headquarter,
		_production_line,
		production_cap_slider.value,
		int(capacity_slider.value / _recipe_template.worker_num)
	))


# 更新UI
func update():
	update_assignment_item_data(_production_line, _headquarter)
