# 解散battalion命令
class_name DisbandBattalionCommand
extends Command

var _battalion: Battalion

func _init(headquarter: Headquarter, battalion: Battalion):
	super(headquarter)
	_battalion = battalion
	
	# 设置命令属性
	name = "解散部队"
	type = "battalion_command"
	detailinfo = "解散部队: " + battalion.unit.info.name

func execute() -> void:
	super.execute()
	if status == Status.Failed:
		command_completed.emit()
		return
	print("执行解散battalion命令: 解散 %s" % [_battalion.unit.info.name])
	
	# 检查battalion是否有效
	if _battalion == null:
		push_error("解散battalion命令失败: battalion为空")
		status = Status.Failed
		command_completed.emit()
		return
	
	# 检查battalion是否属于当前headquarter
	if _battalion.headquarter != _headquarter:
		push_error("解散battalion命令失败: battalion不属于当前headquarter")
		status = Status.Failed
		command_completed.emit()
		return
	
	# 获取battalion的单位信息
	if _battalion.unit == null or _battalion.unit.info == null:
		push_error("解散battalion命令失败: battalion的单位信息为空")
		status = Status.Failed
		command_completed.emit()
		return
	var unit_info = _battalion.unit.info
	
	# 返还兵役人口
	if _headquarter.population != null:
		_headquarter.population.add_military_troops(unit_info.armySize)
	
	# 返还资源
	var returned_items = {}
	
	# 返还武器
	if unit_info.weapon_info != null and unit_info.weapon_info.id != "":
		returned_items[unit_info.weapon_info.id] = unit_info.armySize
	
	# 返还盾牌
	match unit_info.shield:
		UnitData.ShieldType.WOOD_SHIELD:
			returned_items["WOOD_SHIELD"] = unit_info.armySize
		UnitData.ShieldType.IRON_SHIELD:
			returned_items["IRON_SHIELD"] = unit_info.armySize
	
	# 返还护甲
	match unit_info.armor:
		UnitData.ArmorType.LIGHT:
			returned_items["LIGHT_ARMOR"] = unit_info.armySize
		UnitData.ArmorType.HEAVY:
			returned_items["HEAVY_ARMOR"] = unit_info.armySize
	
	# 将资源返还到headquarter的inventory
	if _headquarter.inventory != null:
		_headquarter.inventory.replenish_resources(returned_items)
	
	# 从headquarter的battalions数组中移除
	_headquarter.battalions.erase(_battalion)
	
	# 清理battalion所在的网格
	if _battalion.unit.occupy_grid != null:
		_battalion.unit.occupy_grid.holding_node3D = null
	
	# 销毁battalion节点
	_battalion.queue_free()
	
	print("解散battalion成功: 解散了 %s，返还了 %d 兵役人口和相应资源" % [unit_info.name, unit_info.armySize])
		
	status = Status.Success
	command_completed.emit()
