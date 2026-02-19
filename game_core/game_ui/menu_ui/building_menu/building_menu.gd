extends VBoxContainer
class_name BuildingMenu

@onready var populationBuildings = $PopulationBuildings
@onready var resourceBuildings = $ResourceBuildings
@onready var processorBuildings = $ProcessorBuildings
@onready var economicBuildings = $EconomicBuildings
@onready var coreBuildings = $CoreBuildings
@onready var advancedBuildings = $AdvancedBuildings
@onready var militaryBuildings = $MilitaryBuildings
@onready var defenseBuildings = $DefenseBuildings
@onready var build_button = $Build
@onready var constructer_slider = $BuildConfig/HSlider
@onready var constructer_spinbox = $BuildConfig/SpinBox
@onready var constructer_label = $BuildConfig/Label
@onready var inventory_resources_list = $HBoxContainer
@onready var required_resources_list = $HBoxContainer2
var _settlement:Settlement = null
var _selected_building_info:BuildingData.BuildingInfo = null
var _max_constructer_value:int = 0

# 建筑资源类型
var building_resources:Array[String] = ["WOOD", "PLANK", "STONE_ORE", "STONE_BRICK", "IRON_INGOT", "GOLD_INGOT", "LUXURY"]
var inventory_resources_labels:Dictionary = {}
var required_resources_labels:Dictionary = {}

func _ready():
	# 连接滑条和输入框的信号
	constructer_slider.value_changed.connect(_on_slider_value_changed)
	constructer_spinbox.value_changed.connect(_on_spinbox_value_changed)
	build_button.pressed.connect(_on_build_button_pressed)
	
	# 按类别添加建筑按钮
	for building_info in BuildingData.get_all_building_info():
		var button = Button.new()
		button.name = building_info.id.validate_node_name()
		button.text = building_info.name
		button.tooltip_text = building_info.description
		button.pressed.connect(select_building.bind(building_info))
		
		# 根据类别添加到对应的容器	
		match building_info.category:
			"POPULATION":
				populationBuildings.columns += 1
				populationBuildings.add_child(button)
			"RESOURCE":
				resourceBuildings.columns += 1
				resourceBuildings.add_child(button)
			"PROCESSOR":
				processorBuildings.columns += 1
				processorBuildings.add_child(button)
			"ECONOMIC":
				economicBuildings.columns += 1
				economicBuildings.add_child(button)
			"CORE":
				coreBuildings.columns += 1
				coreBuildings.add_child(button)
			"ADVANCED":
				advancedBuildings.columns += 1
				advancedBuildings.add_child(button)
			"DEFENSE":
				defenseBuildings.columns += 1
				defenseBuildings.add_child(button)
			"MILITARY":
				militaryBuildings.columns += 1
				militaryBuildings.add_child(button)
			_:
				print("未处理的建筑类别: %s" % building_info.category)

	# 初始化资源显示
	for resource_ID in building_resources:
		var resource_label = Label.new()
		resource_label.text = "%s" % Locale.get_text(resource_ID)
		inventory_resources_list.add_child(resource_label)

		var resource_value = Label.new()
		resource_value.name = "inventory_" + resource_ID
		resource_value.text = "%d" % 0
		inventory_resources_list.add_child(resource_value)
		inventory_resources_labels[resource_ID] = resource_value

		var required_label = Label.new() 
		required_label.name = "required_" + resource_ID
		required_label.text = "%s:%d" % [Locale.get_text(resource_ID), 0]
		required_label.hide()
		required_resources_list.add_child(required_label)
		required_resources_labels[resource_ID] = required_label

func select_building(building_info: BuildingData.BuildingInfo):
	_selected_building_info = building_info
	# 更新ui数据
	update_population_controls()
	# 更新资源显示
	update_required_resources_display()

func update_population_controls():
	if _selected_building_info and _settlement:
		# 计算最大值：建筑的max_health和settlement的idle_population中的最小值
		var building_max_health = _selected_building_info.max_health
		var settlement_idle_population = _settlement.population.get_idle_population()
		_max_constructer_value = min(building_max_health, settlement_idle_population)
		
		# 更新滑条和输入框
		constructer_slider.min_value = 0
		constructer_slider.max_value = _max_constructer_value
		constructer_slider.value = 0

		constructer_spinbox.min_value = 0
		constructer_spinbox.max_value = _max_constructer_value
		constructer_spinbox.value = 0

		constructer_label.text = "建造人数上限 (%d)" %  _max_constructer_value
		
func _on_slider_value_changed(value):
	if constructer_spinbox.value != value:
		constructer_spinbox.value = value

func _on_spinbox_value_changed(value):
	if constructer_slider.value != value:
		constructer_slider.value = value

func update():
	_selected_building_info = null
	# 更新ui数据
	update_population_controls()
	# 更新资源显示
	update_inventory_resources_display()
	update_required_resources_display()

func update_inventory_resources_display():
	for resource_ID in building_resources:
		var quantity = _settlement.inventory.get_item_quantity(resource_ID)
		inventory_resources_labels[resource_ID].text = "%d" % quantity

func update_required_resources_display():

	for resource_ID in building_resources:
		var required_quantity  = 0
		if _selected_building_info:
			required_quantity = _selected_building_info.required_materials.get(resource_ID, 0)
		if required_quantity > 0:
			required_resources_labels[resource_ID].text = "%s:%d" % [Locale.get_text(resource_ID), required_quantity]
			required_resources_labels[resource_ID].show()
		else:
			required_resources_labels[resource_ID].hide()

# 建筑按钮点击事件
func _on_build_button_pressed():
	if _selected_building_info:
		# 计算建造人数 四舍五入
		var constructer_count:int = round(constructer_spinbox.value)

		EventBus.paint_highlight.emit(_settlement.get_generate_building_grids())
		EventBus.grid_selected.connect(settlement_build.bind(_selected_building_info.id,constructer_count))
		EventBus.close_menu.emit()
		
func set_settlement(settlement:Settlement):
	_settlement = settlement
	_selected_building_info = null
	
	# 重置人口控件
	constructer_slider.value = 0
	constructer_spinbox.value = 0

# 选择地点后 处理 生成建筑
func settlement_build(grid: Grid,building_id: String,constructer_count: int):
	CommandBus.execute_command(SettleBuildCommand.new(_settlement,grid,building_id,constructer_count))
	EventBus.grid_selected.disconnect(settlement_build)
	EventBus.clean_highlight.emit()
