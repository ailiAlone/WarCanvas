extends Command
class_name BuyCommand

var _item_id:String = ""
var _price:float = 0.0
var _number:int = 0


func _init(headquarter: Headquarter, item_id:String,price:float,number:int):
	super(headquarter)
	_item_id = item_id
	_price = price
	_number = number
	
	# 设置命令属性
	name = "购买"
	type = "headquarter_command"
	detailinfo = "物品: " + item_id + ", 数量: " + str(number) + ", 单价: " + str(price)

func execute() -> void:
	super.execute()
	if status == Status.Failed:
		return
	print("执行购买命令: 购买 %d 个 %s，单价 %.2f" % [_number, _item_id, _price])
	
	# 检查总部是否有效
	if _headquarter == null or _headquarter.inventory == null:
		status = Status.Failed
		command_completed.emit()
		return
	
	# 检查购买数量是否有效
	if _number <= 0:
		status = Status.Failed
		command_completed.emit()
		return
	
	# 检查价格是否有效
	if _price <= 0:
		status = Status.Failed
		command_completed.emit()
		return
	
	# 计算总成本
	var total_cost = int(_price * _number)
	
	# 检查是否有足够的金钱
	if _headquarter.inventory.get_money() < total_cost:
		status = Status.Failed
		command_completed.emit()
		return
	
	# 准备资源变更
	var item_change = {_item_id: _number}
	
	# 执行资源变更
	_headquarter.inventory.set_money(_headquarter.inventory.get_money() - total_cost)
	_headquarter.inventory.replenish_resources(item_change)
	
	print("购买成功: 购买了 %d 个 %s，花费 %d 金钱" % [_number, _item_id, total_cost])
	status = Status.Success
	command_completed.emit()
