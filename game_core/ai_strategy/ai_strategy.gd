extends Node
# 引用
var _headquarter: Headquarter = null
var reactive_maintenance_system : ReactiveMaintenanceSystem = null

func _init():
	reactive_maintenance_system = ReactiveMaintenanceSystem.new()

# ========== AI执行逻辑 ==========
# 执行AI回合
func execute_ai_turn(headquarter: Headquarter):
	_headquarter = headquarter
	print("开始执行AI回合 - 总部ID: ", _headquarter._id)
	
	# 执行维护系统
	reactive_maintenance_system.process_turn(_headquarter)
	
	print("AI回合执行完成")
	CommandBus.execute_command(EndTurnCommand.new(_headquarter))
