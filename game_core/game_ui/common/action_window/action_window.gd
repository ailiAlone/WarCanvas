extends PanelContainer
class_name ActionWindow

# UI元素
@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var move_button: Button = $MarginContainer/VBoxContainer/MoveButton
@onready var attack_button: Button = $MarginContainer/VBoxContainer/AttackButton
@onready var disband_button: Button = $MarginContainer/VBoxContainer/DisbandButton
@onready var occupy_button: Button = $MarginContainer/VBoxContainer/OccupyButton
@onready var clearing_resistance_button: Button = $MarginContainer/VBoxContainer/ClearingResistanceButton
@onready var restoring_order_button: Button = $MarginContainer/VBoxContainer/RestoringOrderButton
@onready var generate_camp_button: Button = $MarginContainer/VBoxContainer/GenerateCampButton

var _unit:Unit = null
var player_ui: Node = null  # 引用player_ui节点
func _ready():
	# 连接按钮信号
	move_button.pressed.connect(_on_move_button_pressed)
	attack_button.pressed.connect(_on_attack_button_pressed)
	disband_button.pressed.connect(_on_disband_button_pressed)
	occupy_button.pressed.connect(_on_occupy_button_pressed)
	clearing_resistance_button.pressed.connect(_on_clearing_resistance_button_pressed)
	restoring_order_button.pressed.connect(_on_restoring_order_button_pressed)
	generate_camp_button.pressed.connect(_on_generate_camp_button_pressed)

func set_unit(unit:Unit):
	print("设置单位为: %s" % [unit.info.name])
	_unit = unit
	if _unit.belonging_node is Battalion:
		show_unit_options()
	elif _unit.belonging_node is Expedition:
		show_expedition_options()

	update_position()

# 显示战斗单位选项
func show_unit_options():
	title_label.text = "战斗单位操作"
	attack_button.visible = true    			# 攻击按钮（启用）
	disband_button.visible = true    			# 解散按钮（启用）
	occupy_button.visible = true    			# 占领按钮（启用）
	clearing_resistance_button.visible = true	# 清除阻力按钮（启用）
	restoring_order_button.visible = false		# 恢复顺序按钮（禁用）
	generate_camp_button.visible = false		# 生成营地按钮（禁用）

	reset_size()

# 显示远征单位选项
func show_expedition_options():
	title_label.text = "远征单位操作"
	attack_button.visible = false
	disband_button.visible = false
	occupy_button.visible = false
	clearing_resistance_button.visible = false
	restoring_order_button.visible = true
	generate_camp_button.visible = true
	reset_size()

# 更新窗口位置到鼠标位置
func update_position():
	#获取当前的鼠标位置
	position = get_viewport().get_mouse_position()
	# 确保窗口不会超出屏幕边界
	var viewport_rect = get_viewport_rect()
	if position.x + size.x > viewport_rect.size.x:
		position.x = position.x - size.x
	if position.y + size.y > viewport_rect.size.y:
		position.y = position.y - size.y

func _on_move_button_pressed():
	print("移动按钮按下")
	if player_ui:
		player_ui.is_target_selecting = true
	EventBus.paint_highlight.emit(_unit.get_movable_area())
	EventBus.grid_selected.connect(unit_move)
	hide() 

func _on_attack_button_pressed():
	print("攻击按钮按下")
	if player_ui:
		player_ui.is_target_selecting = true
	EventBus.paint_highlight.emit(_unit.get_movable_area())
	EventBus.grid_selected.connect(battalion_attack)
	hide()

func _on_disband_button_pressed():
	print("解散按钮按下")
	if _unit != null:
		var headquarter = null
		if _unit.belonging_node is Battalion:
			headquarter = _unit.belonging_node.headquarter
		if headquarter != null:
			await CommandBus.execute_command(DisbandBattalionCommand.new(HeadquarterManager.get_current_headquarter(), _unit.belonging_node))
		else:
			push_error("Unit does not belong to a valid headquarter")
	_unit = null
	if _unit != null:
		print("actionwindow _unit is not null")
	else:
		print("actionwindow _unit is null")
	
	hide()  

func _on_occupy_button_pressed():
	print("占领按钮按下")
	if player_ui:
		player_ui.is_target_selecting = true
	EventBus.paint_highlight.emit(_unit.get_movable_area())
	EventBus.grid_selected.connect(battalion_occupy)
	hide()  

func _on_clearing_resistance_button_pressed():
	print("肃清按钮按下")
	if _unit != null:
		var headquarter:Headquarter = null
		var battalion:Battalion = null
		if _unit.belonging_node is Battalion:
			battalion = _unit.belonging_node
			headquarter = battalion.headquarter
			# 执行肃清抵抗命令
			print("执行肃清抵抗操作: 部队 %s 在网格 (%d, %d)" % [headquarter._id, _unit.occupy_grid.chunk_x, _unit.occupy_grid.chunk_y])
			await CommandBus.execute_command(ClearingResistanceCommand.new(headquarter, battalion))


		else:
			# _unit.belonging_node 不是 Battalion 的情况
			push_error("Unit does not belong to a valid headquarter")
	hide()

func _on_restoring_order_button_pressed():
	print("建立秩序按钮按下")
	if _unit != null:
		var expedition:Expedition = null
		if _unit.belonging_node is Expedition:
			expedition = _unit.belonging_node
			# 执行建立秩序命令
			print("执行建立秩序操作: 远征 %s 在网格 (%d, %d)" % [expedition._id, _unit.occupy_grid.chunk_x, _unit.occupy_grid.chunk_y])
			await CommandBus.execute_command(RestoringOrderCommand.new(expedition))
			# 移除远征
			HeadquarterManager.remove_headquarter(expedition)
		else:
			# _unit.belonging_node 不是 Expedition 的情况
			push_error("Unit does not belong to a valid Expedition")
	hide()  

# 选择地点后 处理 单位移动
func unit_move(grid: Grid):
	EventBus.grid_selected.disconnect(unit_move)
	EventBus.clean_highlight.emit()

	if _unit != null:
		var headquarter = null
		if _unit.belonging_node is Battalion:
			headquarter = _unit.belonging_node.headquarter
		elif _unit.belonging_node is Expedition:
			headquarter = _unit.belonging_node
		if headquarter != null:
			await CommandBus.execute_command(MoveCommand.new(headquarter,_unit, grid))
		else:
			push_error("Unit does not belong to a valid headquarter")
	_unit = null
	
	# 重置操作模式
	if player_ui:
		player_ui.is_target_selecting = false

# 选择地点后 处理 单位攻击
func battalion_attack(grid: Grid):
	EventBus.grid_selected.disconnect(battalion_attack)
	EventBus.clean_highlight.emit()

	if _unit != null:
		var battalion:Battalion = null
		if _unit.belonging_node is Battalion:
			battalion = _unit.belonging_node
			await CommandBus.execute_command(AttackCommand.new(battalion.headquarter, battalion, grid))
		else:
			# _unit.belonging_node is Expedition 的情况不该出现在此处
			push_error("Unit does not belong to a valid headquarter")
	_unit = null
	
	# 重置操作模式
	if player_ui:
		player_ui.is_target_selecting = false

# 选择地点后 处理 单位占领
func battalion_occupy(grid: Grid):
	EventBus.grid_selected.disconnect(battalion_occupy)
	EventBus.clean_highlight.emit()

	if _unit != null:
		var battalion:Battalion = null
		if _unit.belonging_node is Battalion:
			battalion = _unit.belonging_node
			# TODO: 实现占领逻辑
			print("执行占领操作: 部队 %s 占领网格 (%d, %d)" % [battalion.unit.name, grid.chunk_x, grid.chunk_y])
			await CommandBus.execute_command(OccupyBuildingCommand.new(battalion.headquarter, battalion, grid))
		else:
			# _unit.belonging_node is Expedition 的情况不该出现在此处
			push_error("Unit does not belong to a valid headquarter")
	_unit = null
	
	# 重置操作模式
	if player_ui:
		player_ui.is_target_selecting = false

func _on_generate_camp_button_pressed():
	print("生成营地按钮按下")
	if _unit != null:
		var expedition:Expedition = null
		if _unit.belonging_node is Expedition:
			expedition = _unit.belonging_node
			# 执行生成营地命令
			print("执行生成营地操作: 远征 %s 在网格 (%d, %d)" % [expedition._id, _unit.occupy_grid.chunk_x, _unit.occupy_grid.chunk_y])
			await CommandBus.execute_command(GenerateSettlementCommand.new(expedition))
			HeadquarterManager.remove_headquarter(expedition)
		else:
			# _unit.belonging_node 不是 Expedition 的情况
			push_error("Unit does not belong to a valid Expedition")
		
	hide()
