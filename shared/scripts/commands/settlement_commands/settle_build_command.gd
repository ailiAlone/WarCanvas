# 建筑扩张生成命令
class_name SettleBuildCommand
extends Command

var _grid: Grid
var _building_id: String
var _constructer_count: int = 0

func _init(headquarter: Headquarter, grid: Grid, building_id: String,constructer_count: int):
	super(headquarter)
	_grid = grid
	_building_id = building_id
	_constructer_count = constructer_count
	
	# 设置命令属性
	name = "建造建筑"
	type = "settlement_commands"
	detailinfo = "建筑类型: " + building_id + ", 位置: (" + str(grid.chunk_x) + ", " + str(grid.chunk_y) + "), 建造人数: " + str(constructer_count)

func execute() -> void:
	super.execute()
	if status == Status.Failed:
		return
	

	# 检查目标网格是否为空
	if _grid.holding_node3D != null:
		print("目标网格已有物体，无法生成建筑")
		status = Status.Failed
		command_completed.emit()
		return
	
	var generate_grids = (_headquarter as Settlement).get_generate_building_grids()
	if _grid not in generate_grids:
		push_error("目标网格不在生成范围，无法生成建筑")
		status = Status.Failed
		command_completed.emit()
		return

	# 获取建筑信息
	var building_info = BuildingData.get_building_by_id(_building_id)
	if building_info == null:
		push_error("错误：未找到ID为 %s 的建筑信息" % _building_id)
		status = Status.Failed
		command_completed.emit()
		return

	# 检查是否有足够的资源
	if not _headquarter.inventory.has_enough_resources(building_info.required_materials):
		print("资源不足，无法建造建筑")
		status = Status.Failed
		command_completed.emit()
		return
	
	# 消耗资源
	if not _headquarter.inventory.consume_resources(building_info.required_materials):
		print("资源消耗失败")
		status = Status.Failed
		command_completed.emit()
		return

	# 生成建筑，并关联到同一个定居点
	(_headquarter as Settlement).generate_building(_building_id, _grid,_constructer_count)
	print("执行建筑扩张生成命令: 建筑在网格 (%d, %d) 生成 %s,建造人数 %d" % [ _grid.chunk_x, _grid.chunk_y, _building_id,_constructer_count])
	status = Status.Success
	command_completed.emit()
