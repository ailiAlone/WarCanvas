# 生成远征命令
class_name GenerateExpeditionCommand
extends Command

var _expedition_data: Dictionary
var _settlement: Settlement
var _grid: Grid

func _init(settlement: Settlement,grid:Grid, expedition_data: Dictionary):
	super(settlement)
	_settlement = settlement
	_grid = grid
	_expedition_data = expedition_data
	
	# 设置命令属性
	name = "生成远征"
	type = "settlement_commands"
	detailinfo = "定居点: " + str(settlement._id) + ", 军事人口: " + str(expedition_data.military) + ", 资金: " + str(expedition_data.money)

func execute() -> void:
	super.execute()
	if status == Status.Failed:
		return
	print("执行生成远征命令: 定居点 %d" % [_settlement._id])
	
	# 检查定居点是否有效
	if _settlement == null:
		status = Status.Failed
		command_completed.emit()
		return
	
	# 检查是否有足够的军事人口
	if _settlement.population.get_idle_military() < _expedition_data.military:
		print("军事人口不足，需要 %d，当前只有 %d" % [_expedition_data.military, _settlement.population.get_idle_military()])
		status = Status.Failed
		command_completed.emit()
		return
	
	# 检查是否有足够的资金
	if _settlement.inventory.get_money() < _expedition_data.money:
		print("资金不足，需要 %d，当前只有 %d" % [_expedition_data.money, _settlement.inventory.get_money()])
		status = Status.Failed
		command_completed.emit()
		return
	
	# 检查是否有足够的物品
	if not _settlement.inventory.has_enough_resources(_expedition_data.inventory):
		print("物品不足")
		status = Status.Failed
		command_completed.emit()
		return
	
	# 消耗资源
	_consume_resources()
	
	# 创建远征单位信息
	var unit_info = _create_unit_info()
	
	# 添加到HeadquarterManager
	var expedition = HeadquarterManager.create_expedition(_grid,unit_info,_expedition_data,true)
	# 更新友方关系
	_settlement.friend_relations[expedition._id] = true
	expedition.friend_relations[_settlement._id] = true
		
	print("生成远征成功")
	status = Status.Success
	command_completed.emit()

# 消耗资源
func _consume_resources():
	# 消耗军事人口
	_settlement.population.reduce_idle_military(_expedition_data.military)
	
	# 消耗闲置人口
	_settlement.population.reduce_idle_population(_expedition_data.population)
	
	# 消耗资金
	_settlement.inventory.set_money(_settlement.inventory.get_money() - _expedition_data.money)
	
	# 消耗物品
	_settlement.inventory.consume_resources(_expedition_data.inventory)

# 创建单位信息
func _create_unit_info() -> UnitData.UnitInfo:
	# 创建一个默认的远征单位信息
	# 这里可以根据需要从远征数据中获取武器和护甲信息
	var unit_info = UnitData.UnitInfo.new(
		_expedition_data.military + _expedition_data.population,  # 军队规模
		"",  # 武器ID
		UnitData.ArmorType.NONE,  # 护甲类型
		UnitData.ShieldType.NONE,  # 盾牌类型
		false,  # 是否有坐骑
		"远征队"  # 名称
	)
	
	return unit_info
