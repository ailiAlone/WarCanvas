extends VBoxContainer
class_name GovernanceMenu

# 引用场景节点
@onready var current_troops_label = $MilitaryServicePopulation/HBoxContainer2/Value
@onready var progress_bar = $MilitaryServicePopulation/ProgressBar
@onready var slider = $MilitaryServicePopulation/HBoxContainer/HSlider
@onready var spinbox = $MilitaryServicePopulation/HBoxContainer/SpinBox
@onready var recruit_button = $MilitaryServicePopulation/HBoxContainer/RecruitButton
@onready var disband_button = $MilitaryServicePopulation/HBoxContainer/DisbandButton

# 当前关联的总部
var _headquarter: Headquarter = null

func _ready() -> void:
	# 连接信号
	slider.value_changed.connect(_on_slider_value_changed)
	spinbox.value_changed.connect(_on_spinbox_value_changed)
	recruit_button.pressed.connect(_on_recruit_button_pressed)
	disband_button.pressed.connect(_on_disband_button_pressed)
	
# 更新关联的总部
func set_headquarter(headquarter: Headquarter):
	_headquarter = headquarter
	_update_ui()

func _update_ui():
	if not _headquarter:
		return
	
	# 更新当前兵力显示
	var total_troops = _headquarter.population.get_idle_military()
	current_troops_label.text = str(total_troops)
	
	# 更新进度条（显示兵力占总人口的比例）
	var total_population = _headquarter.population.get_total_population()
	if total_population > 0:
		var troop_ratio = float(total_troops) / float(total_population)
		progress_bar.value = troop_ratio * 100
		progress_bar.max_value = 100
	else:
		progress_bar.value = 0
	
	# 更新滑条和输入框的范围
	var max_recruit = _calculate_max_recruit()
	slider.min_value = 0
	slider.max_value = max_recruit
	slider.value = 0
	
	spinbox.min_value = 0
	spinbox.max_value = max_recruit
	spinbox.value = 0
	
	# 根据当前状态更新按钮状态
	_update_button_states()

# 计算最大可征集数量
func _calculate_max_recruit() -> int:
	if not _headquarter:
		return 0
	
	# 最大可征集数量 = 闲置人口 - 当前正在征集的数量
	var idle_population = _headquarter.population.get_idle_population()
	return max(0, idle_population)

# 更新按钮状态
func _update_button_states():
	var can_recruit = _can_recruit()
	var can_disband = _can_disband()
	
	recruit_button.disabled = not can_recruit
	disband_button.disabled = not can_disband
	
	# 根据按钮状态设置颜色
	if can_recruit:
		recruit_button.modulate = Color.GREEN
	else:
		recruit_button.modulate = Color.GRAY
		
	if can_disband:
		disband_button.modulate = Color.RED
	else:
		disband_button.modulate = Color.GRAY

# 检查是否可以征集
func _can_recruit() -> bool:
	if not _headquarter:
		return false
	
	var recruit_count = int(spinbox.value)
	return recruit_count > 0 and recruit_count <= _calculate_max_recruit()

# 检查是否可以解散
func _can_disband() -> bool:
	if not _headquarter:
		return false
	
	var disband_count = int(spinbox.value)
	return disband_count > 0 and disband_count <= _headquarter.population.get_idle_military()

# 滑条值改变事件
func _on_slider_value_changed(value: float):
	if spinbox.value != value:
		spinbox.value = value
	_update_button_states()

# 输入框值改变事件
func _on_spinbox_value_changed(value: float):
	if slider.value != value:
		slider.value = value
	_update_button_states()

# 征集按钮点击事件
func _on_recruit_button_pressed():
	if not _headquarter:
		return
	
	var recruit_count = int(spinbox.value)
	if recruit_count <= 0:
		print("征集失败: 征集数量必须大于0")
		return
	
	if recruit_count > _calculate_max_recruit():
		print("征集失败: 征集数量超过最大可征集数量")
		return
	
	# 执行征集命令
	print("执行征集命令: 征集", recruit_count, "名士兵")
	# TODO: 这里需要实现具体的征集逻辑
	CommandBus.execute_command(RecruitCommand.new(_headquarter, recruit_count))
	
	# 征集成功后重置UI
	spinbox.value = 0
	slider.value = 0
	_update_ui()

# 解散按钮点击事件
func _on_disband_button_pressed():
	if not _headquarter:
		return
	
	var disband_count = int(spinbox.value)
	if disband_count <= 0:
		print("解散失败: 解散数量必须大于0")
		return
	
	if disband_count > _headquarter.population.get_idle_military():
		print("解散失败: 解散数量超过当前总兵力")
		return
	
	# 执行解散命令
	print("执行解散命令: 解散", disband_count, "名士兵")
	# TODO: 这里需要实现具体的解散逻辑
	# CommandBus.execute_command(DisbandCommand.new(_headquarter, disband_count, _selected_unit_type))
	
	# 解散成功后重置UI
	spinbox.value = 0
	slider.value = 0
	_update_ui()
