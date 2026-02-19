# 命令接口
class_name Command
extends RefCounted

signal command_completed
var status: Status = Status.Running

enum Status{
	Running = 0,
	Failed = 1,
	Success = 2
}

# 命令所属的总部
var _headquarter: Headquarter = null

# 新增属性
var time: String = ""  # 命令执行时间（时:分:秒格式）
var name: String = ""  # 命令名称，如"攻击"、"建造"等
var type: String = ""  # 命令类型，即该命令所在文件夹的名称，如"expedition_command"、"battalion_command"等
var detailinfo: String = ""  # 命令详细信息

func _init(headquarter: Headquarter):
	_headquarter = headquarter

# 执行命令
func execute() -> void:
	if _headquarter != HeadquarterManager.get_current_headquarter():
		push_error("错误: 不是当前势力的回合")
		status = Status.Failed
		return
