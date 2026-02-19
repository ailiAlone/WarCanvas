extends PanelContainer

@onready var system_menu_button = $MarginContainer/HBoxContainer/SystemMenuButton
@onready var help_menu_button = $MarginContainer/HBoxContainer/HBoxContainer2/HelpMenuButton

func _ready():
	# 连接系统菜单按钮的按下信号
	system_menu_button.pressed.connect(_on_system_menu_button_pressed)
	# 连接帮助菜单按钮的按下信号
	help_menu_button.pressed.connect(_on_help_menu_button_pressed)
	
# 当点击系统菜单按钮时调用
func _on_system_menu_button_pressed():
	EventBus.system_menu_toggled.emit()
	
# 当点击帮助菜单按钮时调用
func _on_help_menu_button_pressed():
	EventBus.help_menu_toggled.emit()
