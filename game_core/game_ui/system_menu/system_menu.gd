extends PanelContainer

@onready var continue_button = $MarginContainer/VBoxContainer/ContinueButton
@onready var load_button = $MarginContainer/VBoxContainer/LoadButton
@onready var save_button = $MarginContainer/VBoxContainer/SaveButton
@onready var return_to_main_menu_button = $MarginContainer/VBoxContainer/ReturnToMainMenuButton
@onready var exit_button = $MarginContainer/VBoxContainer/ExitButton

func _ready():
	continue_button.pressed.connect(_on_continue_button_pressed)
	load_button.pressed.connect(_on_load_button_pressed)
	save_button.pressed.connect(_on_save_button_pressed)
	return_to_main_menu_button.pressed.connect(_on_return_to_main_menu_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	EventBus.system_menu_toggled.connect(_on_toggle_system_menu_from_eventbus)
	InputManager.key_escape_pressed.connect(_on_toggle_system_menu_from_keyboard)
	# 隐藏菜单直到需要显示
	hide()

# 处理鼠标事件
func _input(event):
	# 当菜单可见时，拦截所有鼠标事件以防止其他UI元素响应
	if visible:
		if event is InputEventMouseButton and event.pressed:
			# 检查鼠标点击是否在面板外部
			if not get_global_rect().has_point(event.position):
				hide()
				# 接受事件以防止其他UI元素响应
				get_viewport().set_input_as_handled()

# 处理来自 EventBus 的信号（无参数）
func _on_toggle_system_menu_from_eventbus():
	if visible:
		hide()
	else:
		show()

# 处理来自键盘的信号（有参数）
func _on_toggle_system_menu_from_keyboard(pressed: bool):
	if pressed:
		if visible:
			hide()
		else:
			show()
	
# 当点击"继续游戏"按钮时调用
func _on_continue_button_pressed():
	hide()

# 当点击"加载游戏"按钮时调用
func _on_load_button_pressed():
	# TODO: 实现加载游戏逻辑
	hide()

# 当点击"保存游戏"按钮时调用
func _on_save_button_pressed():
	# TODO: 实现保存游戏逻辑
	hide()

# 当点击"回到主菜单"按钮时调用
func _on_return_to_main_menu_pressed():
	# TODO: 实现回到主菜单逻辑
	get_tree().change_scene_to_file("res://game_content/main_menu/main_menu.tscn")
	hide()

# 当点击"退出游戏"按钮时调用
func _on_exit_pressed():
	get_tree().quit()
