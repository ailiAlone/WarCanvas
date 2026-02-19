# 占领定居点命令
class_name OccupySettlementCommand
extends Command

var _expedition: Expedition
var _target_settlement: Settlement

func _init(expedition: Expedition, target_settlement: Settlement):
	super(expedition)
	_expedition = expedition
	_target_settlement = target_settlement
	
	# 设置命令属性
	name = "占领定居点"
	type = "expedition_command"
	detailinfo = "远征: " + str(_expedition._id) + ", 目标定居点: " + str(_target_settlement._id)

func execute() -> void:
	super.execute()
	if status == Status.Failed:
		return
	print("执行占领定居点命令: 远征 %d 占领定居点 %d" % [_expedition._id, _target_settlement._id])
	
	# 检查远征和目标定居点是否有效
	if _expedition == null:
		status = Status.Failed
		command_completed.emit()
		return
	
	if _target_settlement == null:
		status = Status.Failed
		command_completed.emit()
		return
	
	# 检查远征是否有单位
	if _expedition.unit == null:
		print("远征没有单位，无法占领定居点")
		status = Status.Failed
		command_completed.emit()
		return
	
	# 检查单位是否在有效网格上
	if _expedition.unit.occupy_grid == null:
		print("单位不在有效网格上，无法占领定居点")
		status = Status.Failed
		command_completed.emit()
		return
	
	# 检查目标定居点是否已经被占领
	if _target_settlement.governance_statuses["normal"]["active"] == false:
		print("目标定居点处于特殊状态，无法占领")
		status = Status.Failed
		command_completed.emit()
		return
	
	# 调用Expedition的occupy_settlement方法占领定居点
	_expedition.occupy_settlement(_target_settlement)
	
	print("占领定居点成功")
	status = Status.Success
	command_completed.emit()