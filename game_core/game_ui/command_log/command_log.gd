extends PanelContainer

# 获取UI元素引用
@onready var last_button = $MarginContainer/VBoxContainer/HBoxContainer2/VBoxContainer/HBoxContainer/LastButton
@onready var next_button = $MarginContainer/VBoxContainer/HBoxContainer2/VBoxContainer/HBoxContainer/NextButton
@onready var toggle_button = $MarginContainer/VBoxContainer/HBoxContainer/ToggleButton
@onready var command_list_container = $MarginContainer/VBoxContainer/HBoxContainer2/VBoxContainer/ScrollContainer/VBoxContainer
@onready var headquarter_id_label = $MarginContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/HBoxContainer/headquarter_id
@onready var time_label = $MarginContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/HBoxContainer/time
@onready var type_label = $MarginContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/HBoxContainer2/type
@onready var name_label = $MarginContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/HBoxContainer2/name
@onready var status_label = $MarginContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/HBoxContainer2/status
@onready var detail_info_rich_text = $MarginContainer/VBoxContainer/HBoxContainer2/VBoxContainer2/DeatailInfoRichTextLabel
@onready var command_detail_container = $MarginContainer/VBoxContainer/HBoxContainer2

# 当前选中的命令索引
var current_command_index = 0

# 展开/折叠状态
var is_expanded = false

func _ready():
	# 连接按钮信号
	last_button.pressed.connect(_on_last_button_pressed)
	next_button.pressed.connect(_on_next_button_pressed)
	toggle_button.pressed.connect(_on_toggle_button_pressed)
	
	# 连接新命令信号
	CommandBus.new_command_completed.connect(refresh)

	# 初始更新UI
	update_command_list()
	update_command_detail()
	
func _on_last_button_pressed():
	# 上一个命令
	if current_command_index > 0:
		current_command_index -= 1
		update_command_detail()

func _on_next_button_pressed():
	# 下一个命令
	if current_command_index < CommandBus.get_command_list().size() - 1:
		current_command_index += 1
		update_command_detail()

func _on_toggle_button_pressed():
	# 切换展开/折叠状态
	is_expanded = !is_expanded
	if is_expanded:
		toggle_button.text = "折叠"
		command_detail_container.show()
	else:
		toggle_button.text = "展开"
		command_detail_container.hide()

func update_command_list():
	# 清空现有列表
	for child in command_list_container.get_children():
		child.queue_free()
	
	# 获取命令列表
	var commands = CommandBus.get_command_list()
	
	# 为每个命令创建一个按钮
	for i in range(commands.size()):
		var command = commands[i]
		var button = Button.new()
		button.text = "%s: %s" % [i + 1, command.name]
		button.pressed.connect(_on_command_button_pressed.bind(i))
		command_list_container.add_child(button)

func _on_command_button_pressed(index):
	# 点击命令列表中的按钮时更新当前选中的命令
	current_command_index = index
	update_command_detail()

func update_command_detail():
		
	var commands = CommandBus.get_command_list()
	
	# 如果没有命令，清空详情
	if commands.size() == 0:
		headquarter_id_label.text = "headquarter_id: 无"
		time_label.text = "时间: 无"
		type_label.text = "类型: 无"
		name_label.text = "名称: 无"
		status_label.text = "状态: 无"
		detail_info_rich_text.text = "详情描述: 无"
		return
	
	# 确保索引在有效范围内
	current_command_index = clamp(current_command_index, 0, commands.size() - 1)
	
	# 获取当前命令
	var command = commands[current_command_index]
	
	# 更新UI元素
	headquarter_id_label.text = "id: %s" % command._headquarter._id if command._headquarter else "未知"
	time_label.text = command.time
	type_label.text = command.type
	name_label.text = command.name
	
	# 根据状态设置不同的文本和颜色
	match command.status:
		Command.Status.Running:
			status_label.text = "运行中"
			status_label.modulate = Color.YELLOW
		Command.Status.Success:
			status_label.text = "成功"
			status_label.modulate = Color.GREEN
		Command.Status.Failed:
			status_label.text = "失败"
			status_label.modulate = Color.RED
		_:
			status_label.text = "未知"
			status_label.modulate = Color.WHITE
	
	detail_info_rich_text.text = "详情描述:\n%s" % command.detailinfo
	
	# 更新按钮状态
	last_button.disabled = current_command_index <= 0
	next_button.disabled = current_command_index >= commands.size() - 1

func refresh():
	# 刷新命令日志
	update_command_list()
	update_command_detail()
