# 肃清抵抗命令
class_name ClearingResistanceCommand
extends Command


var _target_grid: Grid
var _battalion: Battalion

func _init(headquarter: Headquarter, battalion: Battalion):
	super(headquarter)
	_battalion = battalion
	_target_grid = battalion.unit.occupy_grid
	
	# 设置命令属性
	name = "肃清抵抗"
	type = "battalion_command"
	detailinfo = "部队: " + str(_battalion.unit.name) + ", 目标位置: (" + str(_target_grid.chunk_x) + ", " + str(_target_grid.chunk_y) + ")"

func execute() -> void:
	super.execute()
	if status == Status.Failed:
		return
	print("执行肃清抵抗命令: 部队 %s 在网格 (%d, %d)" % [_battalion.unit.name, _target_grid.chunk_x, _target_grid.chunk_y])
	
	# 检查军队和目标网格是否有效
	if _battalion.unit == null:
		status = Status.Failed
		command_completed.emit()
		return
	
	if _target_grid == null:
		status = Status.Failed
		command_completed.emit()
		return
	
	# 检查目标网格是否属于某个定居点
	if _target_grid.owner_headquarter_id == -1:
		print("目标网格不属于任何定居点，无法执行肃清抵抗")
		status = Status.Failed
		command_completed.emit()
		return
	
	# 获取目标网格所属的定居点
	var settlement: Settlement = HeadquarterManager.get_headquarter_by_id(_target_grid.owner_headquarter_id) as Settlement
	if settlement == null:
		print("无法找到目标网格所属的定居点")
		status = Status.Failed
		command_completed.emit()
		return
	
	# 检查目标网格是否在该定居点的建筑生成范围内
	var generate_grids = settlement.get_generate_building_grids()
	if _target_grid not in generate_grids:
		print("目标网格不在定居点的建筑生成范围内，无法执行肃清抵抗")
		status = Status.Failed
		command_completed.emit()
		return
	
	# 执行肃清抵抗操作
	settlement.governance_statuses["clearing_resistance"]["active"] = true
	settlement.governance_statuses["clearing_resistance"]["sources"][_battalion.unit.name] = _battalion
	
	if settlement.governance_statuses["clearing_resistance"]["sources"].size() == 1:
		print("肃清抵抗操作成功，定居点 %d 进入肃清抵抗状态" % [settlement._id])
	else:
		print("部队 %s 已加入定居点 %d 的肃清抵抗行动" % [_battalion.unit.name, settlement._id])
	
	status = Status.Success
	command_completed.emit()
