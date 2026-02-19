extends VBoxContainer
class_name ExpeditionMenu

# UI元素引用
@onready var grid_container: GridContainer = $GridContainer
@onready var population_slider: HSlider = $HBoxContainer/VBoxContainer/HBoxContainer/HSlider
@onready var population_spinbox: SpinBox = $HBoxContainer/VBoxContainer/HBoxContainer/SpinBox
@onready var military_slider: HSlider = $HBoxContainer/VBoxContainer/HBoxContainer2/HSlider
@onready var military_spinbox: SpinBox = $HBoxContainer/VBoxContainer/HBoxContainer2/SpinBox
@onready var funds_slider: HSlider = $HBoxContainer/VBoxContainer/HBoxContainer3/HSlider
@onready var funds_spinbox: SpinBox = $HBoxContainer/VBoxContainer/HBoxContainer3/SpinBox
@onready var create_button: Button = $HBoxContainer/Button

# 引用expedition_item场景
var expedition_item_scene = preload("res://game_core/game_ui/menu_ui/expedition_menu/expedition_item/expedition_item.tscn")

# 当前关联的总部
var _headquarter: Headquarter = null

# 最大值限制
var max_population = 100
var max_military = 50
var max_funds = 1000

func _ready():
	# 初始化物品数据
	ItemData._initialize_item_templates()
	
	# 连接滑块和数字输入框
	population_slider.value_changed.connect(_on_population_slider_changed)
	population_spinbox.value_changed.connect(_on_population_spinbox_changed)
	
	military_slider.value_changed.connect(_on_military_slider_changed)
	military_spinbox.value_changed.connect(_on_military_spinbox_changed)
	
	funds_slider.value_changed.connect(_on_funds_slider_changed)
	funds_spinbox.value_changed.connect(_on_funds_spinbox_changed)
	
	# 连接创建按钮
	create_button.pressed.connect(_on_create_button_pressed)
	
	# 加载可用物品
	_load_available_items()

func _load_available_items():
	# 从ItemData获取所有物品模板
	for item in ItemData.get_all_item_templates():
		# 实例化expedition_item场景
		var expedition_item = expedition_item_scene.instantiate()
		grid_container.add_child(expedition_item)
		expedition_item.name = item.id.validate_node_name()
		
		# 设置物品数据
		expedition_item.set_item_template(item)
		
# 更新关联的总部
func set_headquarter(headquarter: Headquarter):
	_headquarter = headquarter
	update()

# 更新UI
func update():
	# 更新可用资源
	if _headquarter:
		population_slider.max_value = _headquarter.population.get_idle_population()
		population_spinbox.max_value = _headquarter.population.get_idle_population()
		
		military_slider.max_value = _headquarter.population.get_idle_military()
		military_spinbox.max_value = _headquarter.population.get_idle_military()
		
		funds_slider.max_value = _headquarter.inventory.get_money()
		funds_spinbox.max_value = _headquarter.inventory.get_money()
		
		# 更新物品可用数量
		for expedition_item in grid_container.get_children():
			expedition_item.update_available_quantity(_headquarter.inventory)

func _on_create_button_pressed():
	EventBus.paint_highlight.emit(_headquarter.get_generate_Battalion_grids())
	EventBus.grid_selected.connect(_create_expedition)
	EventBus.close_menu.emit()

func _create_expedition(grid: Grid):
	# 收集所有数据
	# 收集物资信息
	var inventory = {}
	for item in grid_container.get_children():
		inventory[item.get_item_id()] = item.get_quantity()

	var expedition_data = {
		"population": population_slider.value,
		"military": military_slider.value,
		"money": funds_slider.value,
		"inventory": inventory
	}

	CommandBus.execute_command(GenerateExpeditionCommand.new(_headquarter,grid,expedition_data))
	EventBus.grid_selected.disconnect(_create_expedition)
	EventBus.clean_highlight.emit()
	
	# 设置headquarter为非玩家状态
	_headquarter._is_player = false
	for old_grid in _headquarter.get_generate_Battalion_grids() + (_headquarter as Settlement).get_generate_building_grids():
		old_grid.update_color_by_owner()
		
	# 结束回合
	CommandBus.execute_command(EndTurnCommand.new(_headquarter))
	push_warning("此处的 代码使用不规范，应当尽早修改")

# 信号处理函数
func _on_population_slider_changed(value):
	if population_spinbox.value != value:
		population_spinbox.value = value

func _on_population_spinbox_changed(value):
	if population_slider.value != value:
		population_slider.value = value

func _on_military_slider_changed(value):
	if military_spinbox.value != value:
		military_spinbox.value = value

func _on_military_spinbox_changed(value):
	if military_slider.value != value:
		military_slider.value = value

func _on_funds_slider_changed(value):
	if funds_spinbox.value != value:
		funds_spinbox.value = value

func _on_funds_spinbox_changed(value):
	if funds_slider.value != value:
		funds_slider.value = value
