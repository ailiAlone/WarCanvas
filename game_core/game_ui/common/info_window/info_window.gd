extends Panel
class_name InfoWindow

# UI元素
@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthLabel
@onready var attack_label: Label = $MarginContainer/VBoxContainer/AttackLabel
@onready var defense_label: Label = $MarginContainer/VBoxContainer/DefenseLabel
@onready var speed_label: Label = $MarginContainer/VBoxContainer/SpeedLabel
@onready var attack_range_label: Label = $MarginContainer/VBoxContainer/AttackRangeLabel
@onready var vision_range_label: Label = $MarginContainer/VBoxContainer/VisionRangeLabel

# 显示单位信息
func set_unit(unit: Unit):
	if title_label == null or health_label == null or attack_label == null or defense_label == null or speed_label == null or attack_range_label == null or vision_range_label == null:
		push_error("UI elements not initialized in set_unit")
		return
		
	if unit.belonging_node is Expedition:
		title_label.text = "军团信息"
	elif unit.belonging_node is Battalion:
		title_label.text = " 部队信息"
	
	# 设置各个标签的文本
	health_label.text = "生命值: " + str(unit.info.armySize)
	attack_label.text = "攻击力: " + str(unit.attack)
	defense_label.text = "防御力: " + str(unit.defense)
	speed_label.text = "速度: " + str(unit.speed)
	attack_range_label.text = "攻击范围: " + str(unit.attack_range)
	vision_range_label.text = "视野范围: " + str(unit.vision_range)
	
	await get_tree().process_frame
	size = $MarginContainer.size
	update_position()


# 更新窗口位置到单位位置
func update_position():
	# 获取鼠标在屏幕上的位置
	position = get_viewport().get_mouse_position()
	# 将窗口定位到鼠标位置上方
	var viewport_rect = get_viewport_rect()
	if position.x + size.x > viewport_rect.size.x:
		position.x = position.x - size.x
	if position.y + size.y > viewport_rect.size.y:
		position.y = position.y - size.y
