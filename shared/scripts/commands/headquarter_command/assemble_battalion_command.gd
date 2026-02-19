# 建筑生成单位命令
class_name AssembleBattalionCommand
extends Command

#改成settlement
var _unit_info: UnitData.UnitInfo = null
var _grid: Grid

func _init(headquarter: Headquarter, unit_info: UnitData.UnitInfo, grid: Grid):
	super(headquarter)
	_grid = grid
	_unit_info = unit_info
	
	# 设置命令属性
	name = "组建部队"
	type = "headquarter_command"
	detailinfo = "组建类型: " + _unit_info.name + ", 武器: " + (_unit_info.weapon_info.id if _unit_info.weapon_info else "") + ", 盾牌: " + str(_unit_info.shield) + ", 护甲: " + str(_unit_info.armor)

func execute() -> void:
	super.execute()
	if status == Status.Failed:
		return
	print("执行建筑生成单位命令: 在网格 (%d, %d) 生成 %s" % [ _grid.chunk_x, _grid.chunk_y, _unit_info.name])

	# 获取建筑周围的空网格
	if _grid.holding_node3D != null:
		print("网格已被占用，无法生成单位")
		status = Status.Failed
		command_completed.emit()
		return

	# 检查兵役人口是否足够
	if _headquarter.population.get_idle_military() < _unit_info.armySize:
		print("兵役人口不足，需要 %d，当前只有 %d" % [_unit_info.armySize, _headquarter.population.get_idle_military()])
		status = Status.Failed
		command_completed.emit()
		return

	# 检查武器装备是否足够
	var required_items = {}
	
	# 添加武器需求
	if _unit_info.weapon_info != null and _unit_info.weapon_info.id != "":
		required_items[_unit_info.weapon_info.id] = _unit_info.armySize
	
	# 添加盾牌需求
	match _unit_info.shield:
		UnitData.ShieldType.WOOD_SHIELD:
			required_items["WOOD_SHIELD"] = _unit_info.armySize
		UnitData.ShieldType.IRON_SHIELD:
			required_items["IRON_SHIELD"] = _unit_info.armySize
	
	# 添加护甲需求
	match _unit_info.armor:
		UnitData.ArmorType.LIGHT:
			required_items["LIGHT_ARMOR"] = _unit_info.armySize
		UnitData.ArmorType.HEAVY:
			required_items["HEAVY_ARMOR"] = _unit_info.armySize
	
	# 使用 ItemStock 的 has_enough_resources 方法检查是否有足够的物品
	if not _headquarter.inventory.has_enough_resources(required_items):
		print("物品不足，无法生成单位")
		status = Status.Failed
		command_completed.emit()
		return
	
	# 所有资源检查通过，扣除相应资源
	# 扣除物品
	if not _headquarter.inventory.consume_resources(required_items):
		print("扣除物品失败")
		status = Status.Failed
		command_completed.emit()
		return
	
	# 扣除兵役人口
	_headquarter.population.reduce_idle_military(_unit_info.armySize)
	
	print("资源扣除完成，生成单位")
	_headquarter.generate_battalion(_unit_info,_grid)
	status = Status.Success
	command_completed.emit()
