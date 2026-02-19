# 结束回合命令
class_name EndTurnCommand
extends Command

func _init(headquarter: Headquarter):
	super(headquarter)
	
	# 设置命令属性
	name = "结束回合"
	type = "commands"
	detailinfo = "结束当前回合"

func execute() -> void:
	super.execute()
	if status == Status.Failed:
		return

	# print("执行结束回合命令: 势力 %d 结束回合" % _headquarter.id)
	#判断当前是否属于自己的回合
	if _headquarter != HeadquarterManager.get_current_headquarter():
		push_error("错误: 不是当前势力的回合")
		status = Status.Failed
		command_completed.emit()
		return
	
	# 通过事件总线发射结束回合信号
	EventBus.pass_turn.emit()
	status = Status.Success
	command_completed.emit()
