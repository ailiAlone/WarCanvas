# 生成营地命令
class_name GenerateSettlementCommand
extends Command

var _expedition: Expedition

func _init(expedition: Expedition):
	super(expedition)
	_expedition = expedition
	
	# 设置命令属性
	name = "生成营地"
	type = "expedition_command"
	detailinfo = "远征: " + str(_expedition._id) + ", 位置: (" + str(expedition.unit.occupy_grid.chunk_x) + ", " + str(expedition.unit.occupy_grid.chunk_y) + ")"

func execute() -> void:
	super.execute()
	if status == Status.Failed:
		return
	print("执行生成营地命令: 军队 %d 在网格 (%d, %d)" % [_expedition._id, _expedition.unit.occupy_grid.chunk_x, _expedition.unit.occupy_grid.chunk_y])
	
	# 检查军队是否有效
	if _expedition == null:
		status = Status.Failed
		command_completed.emit()
		return
	
	# 检查军队是否有单位
	if _expedition.unit == null:
		print("军队没有单位，无法生成营地")
		status = Status.Failed
		command_completed.emit()
		return
	
	# 检查单位是否在有效网格上
	if _expedition.unit.occupy_grid == null:
		print("单位不在有效网格上，无法生成营地")
		status = Status.Failed
		command_completed.emit()
		return
	
	# 调用Expedition的generate_camp方法生成营地
	_expedition.generate_camp()
	
	print("生成营地成功")
	status = Status.Success
	command_completed.emit()
