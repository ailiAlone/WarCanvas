# 占领建筑命令
class_name OccupyBuildingCommand
extends Command

var _battalion: Battalion
var _target_grid: Grid

func _init(headquarter: Headquarter, battalion: Battalion, target_grid: Grid):
	super(headquarter)
	_battalion = battalion
	_target_grid = target_grid
	
	# 设置命令属性
	name = "占领建筑"
	type = "battalion_command"
	detailinfo = "部队: " + battalion.unit.name + ", 目标位置: (" + str(target_grid.chunk_x) + ", " + str(target_grid.chunk_y) + ")"

func execute() -> void:
	super.execute()
	if status == Status.Failed:
		return
	print("执行占领建筑命令: 部队 %s 占领网格 (%d, %d)" % [_battalion.unit.name, _target_grid.chunk_x, _target_grid.chunk_y])
	
	# 检查部队和目标网格是否有效
	if _battalion == null:
		status = Status.Failed
		command_completed.emit()
		return
	
	if _target_grid == null:
		status = Status.Failed
		command_completed.emit()
		return
	
	# 检查目标网格上是否有建筑
	if _target_grid.holding_node3D == null:
		print("目标网格上没有建筑，无法占领")
		status = Status.Failed
		command_completed.emit()
		return
	
	# 检查目标网格上的是否是建筑
	var building = _target_grid.holding_node3D
	if not building is Building:
		print("目标网格上的不是建筑，无法占领")
		status = Status.Failed
		command_completed.emit()
		return

	# 检查是否已经占领
	if building.is_occupied:
		print("建筑已被占领，无法重复占领")
		status = Status.Failed
		command_completed.emit()
		return
	
	# 执行占领
	building.is_occupied = true
	print("建筑占领成功")
	status = Status.Success
	command_completed.emit()