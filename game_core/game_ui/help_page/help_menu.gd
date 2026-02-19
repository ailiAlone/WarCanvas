extends PanelContainer

func _ready():
	# 连接帮助菜单按钮的按下信号
	EventBus.help_menu_toggled.connect(_on_help_menu_button_pressed)

func _on_help_menu_button_pressed():
	show()
	# 鼠标左键或者右键 点击时 隐藏帮助菜单
	InputManager.mouse_left_pressed.connect(_on_mouse_pressed)
	InputManager.mouse_right_pressed.connect(_on_mouse_pressed)

func _on_mouse_pressed(pressed: bool):
	hide()
	# 断开鼠标左键或者右键 点击时 隐藏帮助菜单的信号
	InputManager.mouse_left_pressed.disconnect(_on_mouse_pressed)
	InputManager.mouse_right_pressed.disconnect(_on_mouse_pressed)
