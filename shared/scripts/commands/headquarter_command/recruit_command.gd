class_name RecruitCommand
extends Command

var _recruit_count: int

func _init(headquarter: Headquarter, recruit_count: int):
	super(headquarter)
	_recruit_count = recruit_count

func execute() -> void:
	super.execute()

	if not _headquarter.population.assign_to_military(_recruit_count):
		status = Status.Failed
		command_completed.emit()
		return
	
	status = Status.Success
	command_completed.emit()
