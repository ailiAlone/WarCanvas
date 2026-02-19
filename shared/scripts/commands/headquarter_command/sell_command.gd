extends Command
class_name SellCommand

var _item_id:String = ""
var _price:float = 0.0
var _number:int = 0


func _init(headquarter: Headquarter, item_id:String,price:float,number:int):
	super(headquarter)
	_item_id = item_id
	_price = price
	_number = number
	
	# 设置命令属性
	name = "销售"
	type = "headquarter_command"
	detailinfo = "物品: " + item_id + ", 数量: " + str(number) + ", 单价: " + str(price)

func execute() -> void:
	super.execute()
	if status == Status.Failed:
		return
	print("执行销售命令: 销售 %d 个 %s，单价 %.2f" % [_number, _item_id, _price])
	
	# 检查总部是否有效
	if _headquarter == null or _headquarter.inventory == null:
		push_error("销售命令失败: 总部或资源管理器为空")
		status = Status.Failed
		command_completed.emit()
		return
	
	# 检查销售数量是否有效
	if _number <= 0:
		push_error("销售命令失败: 销售数量 %d 无效" % _number)
		status = Status.Failed
		command_completed.emit()
		return
	
	# 检查价格是否有效
	if _price <= 0:
		push_error("销售命令失败: 价格 %.2f 无效" % _price)
		status = Status.Failed
		command_completed.emit()
		return
	
	# 检查是否有足够的物品可以销售
	var current_quantity = _headquarter.inventory.get_item_quantity(_item_id)
	if current_quantity < _number:
		push_error("销售命令失败: 物品 %s 数量不足，需要 %d，当前拥有 %d" % [
			_item_id, _number, current_quantity
		])
		status = Status.Failed
		command_completed.emit()
		return
	
	# 计算总收入
	var total_income = int(_price * _number)
	
	# 准备资源变更
	var item_change = {_item_id: _number}
	
	# 执行资源变更
	_headquarter.inventory.set_money(_headquarter.inventory.get_money() + total_income)
	_headquarter.inventory.consume_resources(item_change)
	
	print("销售成功: 销售了 %d 个 %s，获得 %d 金钱" % [_number, _item_id, total_income])
	status = Status.Success
	command_completed.emit()
