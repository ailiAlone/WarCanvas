extends PanelContainer

class_name BasicInfoUI

var _headquarter: Headquarter = null

# 人口信息标签
@onready var total_population_label = $MarginContainer/VBoxContainer/TotalPopulation/Value
@onready var idle_population_label = $MarginContainer/VBoxContainer/IdlePopulation/HBoxContainer/Value
@onready var military_population_label = $MarginContainer/VBoxContainer/MilitaryPopulation/HBoxContainer/Value
@onready var working_population_label = $MarginContainer/VBoxContainer/WorkingPopulation/HBoxContainer/Value

# 回合信息标签
@onready var turn_label = $MarginContainer/VBoxContainer/TurnInfo/Value

# 人口进度条
@onready var idle_progress_bar = $MarginContainer/VBoxContainer/IdlePopulation/ProgressBar
@onready var military_progress_bar = $MarginContainer/VBoxContainer/MilitaryPopulation/ProgressBar
@onready var working_progress_bar = $MarginContainer/VBoxContainer/WorkingPopulation/ProgressBar

func _ready():
	# 连接EventBus的全局信号
	EventBus.new_headquarter_started.connect(_on_headquarter_changed)
	EventBus.new_turn_started.connect(_on_turn_changed)
	
	# 初始隐藏，直到有总部数据
	visible = false

# 处理总部变化信号
func _on_headquarter_changed(headquarter: Headquarter):
	# 如果之前有总部，断开连接
	if _headquarter:
		_headquarter.disconnect("population_changed", _on_population_changed)
	
	_headquarter = headquarter
	
	if _headquarter:
		# 连接人口变化信号
		_headquarter.connect("population_changed", _on_population_changed)
		visible = true
		update_info()
	else:
		visible = false

# 处理回合变化信号
func _on_turn_changed(turn: int):
	turn_label.text = str(turn)

# 处理人口变化信号
func _on_population_changed():
	update_info()

# 更新人口信息显示
func update_info():
	if not _headquarter:
		return
		
	# 更新人口数值标签
	var total_pop = _headquarter.population.get_total_population()
	var pop_capacity = _headquarter.population.get_population_capacity()
	total_population_label.text = str(total_pop) + " / " + str(pop_capacity)
	idle_population_label.text = str(_headquarter.population.get_idle_population())
	military_population_label.text = str(_headquarter.population.get_idle_military())
	working_population_label.text = str(_headquarter.population.get_working_population())
	
	# 更新人口进度条
	if total_pop > 0:
		idle_progress_bar.value = float(_headquarter.population.get_idle_population()) / total_pop * 100
		military_progress_bar.value = float(_headquarter.population.get_idle_military()) / total_pop * 100
		working_progress_bar.value = float(_headquarter.population.get_working_population()) / total_pop * 100
	else:
		idle_progress_bar.value = 0
		military_progress_bar.value = 0
		working_progress_bar.value = 0
