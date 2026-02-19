extends VBoxContainer
class_name BattalionMenu

@onready var weapons: GridContainer = $Weapons
@onready var shields: GridContainer = $Shields
@onready var armors: GridContainer = $Armors
@onready var generate: Button = $Generate
@onready var troop_slider: HSlider = $HBoxContainer/HSlider
@onready var troop_spinbox: SpinBox = $HBoxContainer/SpinBox
@onready var max_label: Label = $HBoxContainer/MaxLabel

var _headquarter: Headquarter = null

var battalion_item_scene = preload("res://game_core/game_ui/menu_ui/battalion_menu/battalion_item/battalion_item.tscn")
var weapon_id: String = ""
var shield_type: UnitData.ShieldType = UnitData.ShieldType.NONE
var armor_type: UnitData.ArmorType = UnitData.ArmorType.NONE
var troop_count: int = 1

func _ready():
	# 连接兵力选择信号
	troop_slider.value_changed.connect(_on_troop_slider_changed)
	troop_spinbox.value_changed.connect(_on_troop_spinbox_changed)
	
	# 初始化武器按钮
	for weaponInfo in UnitData.WeaponInfo.get_all_weapon_info():
		var weapon_item = battalion_item_scene.instantiate()
		weapons.add_child(weapon_item)
		weapon_item.set_item_template(ItemData.get_item_template(weaponInfo.id))
		weapon_item.texture_button.pressed.connect(_on_weapon_selected.bind(weaponInfo.id))
		
	# 初始化盾牌按钮
	var shield_types = [
		["无盾", UnitData.ShieldType.NONE,"NONE"],
		["木盾", UnitData.ShieldType.WOOD_SHIELD,"WOOD_SHIELD"],
		["铁盾", UnitData.ShieldType.IRON_SHIELD,"IRON_SHIELD"]
	]
	
	for shield_data in shield_types:
		var shield_item = battalion_item_scene.instantiate()
		shields.add_child(shield_item)
		shield_item.set_item_template(ItemData.get_item_template(shield_data[2]))
		shield_item.texture_button.pressed.connect(_on_shield_selected.bind(shield_data[1]))
	shields.columns = shields.get_child_count()

	# 初始化护甲按钮
	var armor_types = [
		["无护甲", UnitData.ArmorType.NONE,"NONE"],
		["轻甲", UnitData.ArmorType.LIGHT,"LIGHT_ARMOR"],
		["重甲", UnitData.ArmorType.HEAVY,"HEAVY_ARMOR"]
	]
	
	for armor_data in armor_types:
		var armor_item = battalion_item_scene.instantiate()
		armors.add_child(armor_item)
		armor_item.set_item_template(ItemData.get_item_template(armor_data[2]))
		armor_item.texture_button.pressed.connect(_on_armor_selected.bind(armor_data[1]))
	armors.columns = armors.get_child_count()

	generate.pressed.connect(generate_unit)

func _on_weapon_selected(p_weapon_id: String):
	weapon_id = p_weapon_id
	print("选中武器ID: ", weapon_id)

func _on_shield_selected(p_shield_type: UnitData.ShieldType):
	shield_type = p_shield_type
	print("选中盾牌类型: ", shield_type)

func _on_armor_selected(p_armor_type: UnitData.ArmorType):
	armor_type = p_armor_type
	print("选中护甲类型: ", armor_type)

func _on_troop_slider_changed(value):
	troop_count = int(value)
	if troop_spinbox.value != value:
		troop_spinbox.value = troop_count

func _on_troop_spinbox_changed(value):
	troop_count = int(value)
	if troop_slider.value != value:
		troop_slider.value = troop_count

func generate_unit():
	# 验证是否选择了武器
	if weapon_id == "":
		print("错误：未选择武器")
		return
	
	# 创建单位信息并设置兵力数量
	var unit_info = UnitData.UnitInfo.new(
		troop_count,
		weapon_id,
		armor_type,
		shield_type,
		false
	)

	EventBus.paint_highlight.emit(_headquarter.get_generate_Battalion_grids())
	EventBus.grid_selected.connect(assemble_battalion.bind(unit_info))
	EventBus.close_menu.emit()

# 选择地点后 处理 生成单位
func assemble_battalion(grid: Grid, unit_info: UnitData.UnitInfo):
	EventBus.grid_selected.disconnect(assemble_battalion)
	EventBus.clean_highlight.emit()
	CommandBus.execute_command(AssembleBattalionCommand.new(_headquarter, unit_info, grid))

# 设置菜单显示的对象和位置
func set_headquarter(headquarter: Headquarter):
	_headquarter = headquarter
	update_item_inventory()
	update_max_troops()

# 更新最大兵力显示
func update_max_troops():
	var max_troops = _headquarter.population.get_idle_military()
	max_label.text = "兵役人数:" + str(max_troops)
	troop_slider.max_value = max_troops
	troop_spinbox.max_value = max_troops
	if troop_count > max_troops:
		troop_count = max_troops
		troop_slider.value = troop_count
		troop_spinbox.value = troop_count

func update_item_inventory():
	for weapon_item in weapons.get_children():
		weapon_item.update_item_inventory(_headquarter.inventory.get_item_quantity(weapon_item._item_template.id))
	for shield_item in shields.get_children():
		if shield_item._item_template != null:
			shield_item.update_item_inventory(_headquarter.inventory.get_item_quantity(shield_item._item_template.id))
	for armor_item in armors.get_children():
		if armor_item._item_template != null:
			armor_item.update_item_inventory(_headquarter.inventory.get_item_quantity(armor_item._item_template.id))
