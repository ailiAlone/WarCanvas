extends Node
# 命令列表，用于记录所有执行的命令
var command_list: Array[Command] = []
signal new_command_completed

# 获取命令列表
func get_command_list() -> Array[Command]:
	return command_list

# 清空命令列表
func clear_command_list() -> void:
	command_list.clear()
	
# 使用一次性连接确保每次都是新的等待
func execute_command(command: Command) -> void:
	# 记录命令开始执行的时间（时:分:秒格式）
	var datetime = Time.get_datetime_dict_from_system()
	command.time = "%02d:%02d:%02d" % [datetime.hour, datetime.minute, datetime.second]
	
	# 执行命令
	command.execute()
	
	# 将命令添加到命令列表
	command_list.append(command)
	
	# 根据命令状态处理
	match command.status:
		Command.Status.Failed:
			# 命令失败，发射信号
			new_command_completed.emit()
			return
		Command.Status.Running:
			# 等待命令完成
			await command.command_completed
			# 命令完成后发射信号
			new_command_completed.emit()
			return
		Command.Status.Success:
			# 命令立即成功，发射信号
			new_command_completed.emit()
			return
		_:
			# 未知状态，发射信号
			new_command_completed.emit()
			return





	
	
