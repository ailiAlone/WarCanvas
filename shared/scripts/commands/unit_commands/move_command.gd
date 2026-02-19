# 移动命令
class_name MoveCommand
extends Command

var _unit: Unit
var _target_grid: Grid
var _original_grid: Grid  # 记录单位原始位置

func _init(headquarter: Headquarter, unit: Unit, target_grid: Grid):
	super(headquarter)
	_unit = unit
	_target_grid = target_grid
	
	# 设置命令属性
	name = "移动"
	type = "unit_commands"
	detailinfo = "单位: " + unit.info.name + ", 目标位置: (" + str(target_grid.chunk_x) + ", " + str(target_grid.chunk_y) + ")"

func execute() -> void:
	super.execute()
	if status == Status.Failed:
		return
	# print("执行移动命令: 单位 %s 移动到网格 (%d, %d)" % [_unit.info.name, _target_grid.chunk_x, _target_grid.chunk_y])
	
	# 检查单位和目标网格是否有效
	if _unit == null:
		status = Status.Failed
		command_completed.emit()
		return
	
	if _target_grid == null:
		status = Status.Failed
		command_completed.emit()
		return
	
	if _target_grid.holding_node3D != null:
		status = Status.Failed
		command_completed.emit()
		return
	
	# 记录单位原始位置
	_original_grid = _unit.occupy_grid
	
	# 使用改进的路径查找算法找到从单位当前位置到目标网格的最优路径
	var path = GridUtils.get_shortest_path_bfs(_unit.occupy_grid, _target_grid)
	if path.size() == 0:
		status = Status.Failed
		command_completed.emit()
		return
	
	# print("起始网格: (%d, %d)" % [_unit.occupy_grid.chunk_x, _unit.occupy_grid.chunk_y])
	# print("路径长度: %d" % path.size())
	
	# 沿路径移动
	for i in range(path.size()):
		var target_grid = path[i]
		# print("移动到路径点 %d/%d: (%d, %d)" % [i+1, path.size(), target_grid.chunk_x, target_grid.chunk_y])
		
		_unit.move_to(target_grid)
		# 等待移动完成
		await _unit.movement_completed
	
	status = Status.Success
	command_completed.emit()
