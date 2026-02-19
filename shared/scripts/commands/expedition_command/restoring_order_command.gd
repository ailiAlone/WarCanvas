# 建立秩序命令
class_name RestoringOrderCommand
extends Command

var _expedition: Expedition
var _target_grid: Grid

func _init(expedition: Expedition):
	super(expedition)
	_expedition = expedition
	_target_grid = expedition.unit.occupy_grid
	
	# 设置命令属性
	name = "建立秩序"
	type = "expedition_command"
	detailinfo = "远征: " + str(_expedition._id) + ", 目标位置: (" + str(_target_grid.chunk_x) + ", " + str(_target_grid.chunk_y) + ")"

func execute() -> void:
	super.execute()
	if status == Status.Failed:
		return
	print("执行建立秩序命令: 远征 %d 在网格 (%d, %d)" % [_expedition._id, _target_grid.chunk_x, _target_grid.chunk_y])
	
	# 检查远征和目标网格是否有效
	if _expedition == null:
		status = Status.Failed
		command_completed.emit()
		return
	
	if _target_grid == null:
		status = Status.Failed
		command_completed.emit()
		return
	
	# 检查目标网格是否属于某个定居点
	if _target_grid.owner_headquarter_id == -1:
		print("目标网格不属于任何定居点，无法执行建立秩序")
		status = Status.Failed
		command_completed.emit()
		return
	
	# 获取目标网格所属的定居点
	var settlement = null
	# HeadquarterManager是autoload单例，可以直接访问
	if HeadquarterManager != null:
		for hq in HeadquarterManager.headquarters.to_array_from_head():
			if hq._id == _target_grid.owner_headquarter_id and hq is Settlement:
				settlement = hq
				break
	
	if settlement == null or not settlement is Settlement:
		print("无法找到目标网格所属的定居点")
		status = Status.Failed
		command_completed.emit()
		return
	
	# 检查目标网格是否在该定居点的建筑生成范围内
	var generate_grids = settlement.get_generate_building_grids()
	if _target_grid not in generate_grids:
		print("目标网格不在定居点的建筑生成范围内，无法执行建立秩序")
		status = Status.Failed
		command_completed.emit()
		return
	
	# 检查该定居点是否已经处于肃清抵抗状态
	if not settlement.governance_statuses["clearing_resistance"]["active"]:
		print("该定居点未处于肃清抵抗状态，无法执行建立秩序")
		status = Status.Failed
		command_completed.emit()
		return
	
	# 检查该定居点是否已经在建立秩序状态中
	if settlement.governance_statuses["restoring_order"]["active"]:
		print("该定居点已经在建立秩序状态中")
		status = Status.Failed
		command_completed.emit()
		return
	
	# 执行数据转换：将定居点的全部人口和资源转移到远征
	_expedition.occupy_settlement(settlement)
	
	# 执行建立秩序操作
	settlement.governance_statuses["restoring_order"]["active"] = true
	settlement.governance_statuses["restoring_order"]["source"] = _expedition._id
	
	print("建立秩序操作成功，定居点 %d 进入建立秩序状态" % [settlement._id])
	status = Status.Success
	command_completed.emit()
