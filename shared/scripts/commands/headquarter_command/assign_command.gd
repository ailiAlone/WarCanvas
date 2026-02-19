extends Command
class_name AssignCommand

var _production_line:Production.ProductionLine
var _product_cap:int
var _active_num:int


func _init(headquarter: Headquarter, production_line:Production.ProductionLine,product_cap:int,active_num:int):
	super(headquarter)
	_production_line = production_line
	_product_cap = product_cap
	_active_num = active_num
	
	# 设置命令属性
	name = "分配工人"
	type = "headquarter_command"
	detailinfo = "生产线: " + str(_production_line.id) + ", 容量: " + str(_product_cap) + ", 激活数量: " + str(_active_num)


func execute() -> void:
	super.execute()
	if status == Status.Failed:
		command_completed.emit()
		return
	print("执行分配命令: 分配 %d 个工人到 %s 生产 %s,容量为 %d" % [_active_num, _production_line.id, _production_line.recipe.main_product, _product_cap])
	
	# 检查激活数量是否有效
	if _active_num <= 0:
		push_error("分配命令失败: 激活数量 %d 无效" % _active_num)
		status = Status.Failed
		command_completed.emit()
		return
	
	# 检查人数是否足够 _headquarter.population.get_idle_population() 需要多余 _active_num * production_line.recipe.worker_num
	var required_workers = _active_num * _production_line.recipe.worker_num
	if _headquarter.population.get_idle_population() < required_workers:
		push_error("分配命令失败: 人数不足，需要 %d 人，当前只有 %d 人" % [
			required_workers, _headquarter.population.get_idle_population()
		])
		status = Status.Failed
		command_completed.emit()
		return
	
	# 设置生产线的激活数量和容量
	_production_line.set_active_num(_active_num)
	_production_line.set_production_cap(_product_cap)
	
	# 分配工人到工作
	status = Status.Success
	command_completed.emit()
