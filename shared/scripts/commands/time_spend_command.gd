# 时间消耗命令
class_name TimeSpendCommand
extends Command

var _time_amount: float

func _init(headquarter: Headquarter, time_amount: float):
	super(headquarter)
	_time_amount = time_amount
	
	# 设置命令属性
	name = "消耗时间"
	type = "commands"
	detailinfo = "消耗时间: " + str(time_amount) + " 秒"

func execute() -> void:
	super.execute()
	if status == Status.Failed:
		return
	print("执行时间消耗命令: 消耗 %.1f 秒" % _time_amount)
	# 这里可以添加时间消耗的具体逻辑
	# 例如：等待指定时间，或者更新游戏内时间等
	# 由于是异步操作，可能需要在调用处使用await
	# await get_tree().create_timer(_time_amount).timeout
	status = Status.Success
	command_completed.emit()
