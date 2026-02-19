class_name Turn

# 回合基础信息
static var turn_number: int = 0
# 总部管理
static var current_headquarter: Headquarter = null
# 初始化回合
static func _init():
	EventBus.pass_turn.connect(end_current_headquarter_turn)
	EventBus.all_headquarter_finished_turn.connect(start_turn)
	start_turn()

# 开始回合
static func start_turn():
	turn_number += 1
	if HeadquarterManager.headquarters.size() > 0:
		# 开始第一个总部回合
		start_first_headquarter_turn()
	else:
		print("没有可用的总部，无法开始回合")

# 开始第一个总部回合
static func start_first_headquarter_turn():	
	EventBus.new_turn_started.emit(turn_number)
	current_headquarter = HeadquarterManager.get_headquarter_in_order()
	# 开始总部回合
	EventBus.new_headquarter_started.emit(current_headquarter)
	await current_headquarter.on_turn_start()

# 结束当前总部的回合
static func end_current_headquarter_turn():
	# 先结束当前总部的回合（如果有的话）
	if current_headquarter != null:
		# 这里可以添加当前总部回合结束的逻辑
		print("结束总部 %d 的回合" % current_headquarter._id)
	
	# 获取下一个总部
	current_headquarter = HeadquarterManager.get_headquarter_in_order()

	if current_headquarter != null:
		EventBus.new_headquarter_started.emit(current_headquarter)
		print("开始总部 %d 的回合" % current_headquarter._id)
		await current_headquarter.on_turn_start()
	else:
		# 所有总部都已处理完毕，结束回合
		print("所有总部回合执行完毕，回合 %d 结束" % turn_number)
		EventBus.all_headquarter_finished_turn.emit()
