extends Control

# 引用场景中的按钮
@onready var start_button = $MarginContainer/VBoxContainer/StartButton
@onready var load_button = $MarginContainer/VBoxContainer/LoadButton
@onready var editor_button = $MarginContainer/VBoxContainer/EditorButton
@onready var exit_button = $MarginContainer/VBoxContainer/ExitButton

@onready var panel_container = $PanelContainer

@onready var campaign_button = $PanelContainer/MarginContainer/NewGameOptionVBoxContainer/CampaignButton
@onready var sandbox_button = $PanelContainer/MarginContainer/NewGameOptionVBoxContainer/SandboxButton
@onready var tutorial_button = $PanelContainer/MarginContainer/NewGameOptionVBoxContainer/TutorialButton

func _ready():
	# 连接按钮点击信号到处理函数
	start_button.pressed.connect(_on_start_button_pressed)
	load_button.pressed.connect(_on_load_button_pressed)
	editor_button.pressed.connect(_on_editor_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)

	campaign_button.pressed.connect(_on_campaign_button_pressed)
	sandbox_button.pressed.connect(_on_sandbox_button_pressed)
	tutorial_button.pressed.connect(_on_tutorial_button_pressed)

# 开始新游戏按钮处理函数
func _on_start_button_pressed():
	panel_container.show()

# 加载游戏按钮处理函数
func _on_load_button_pressed():
	print("加载游戏")
	# 这里可以添加加载存档的代码

# 进入编辑器按钮处理函数
func _on_editor_button_pressed():
	print("进入编辑器")
	# 这里可以添加切换到地图编辑器的代码
	get_tree().change_scene_to_file("res://map_editor/map_editor.tscn")

# 退出游戏按钮处理函数
func _on_exit_button_pressed():
	print("退出游戏")
	get_tree().quit()

# 战役模式按钮处理函数
func _on_campaign_button_pressed():
	print("进入战役模式")

# 沙盒模式按钮处理函数
func _on_sandbox_button_pressed():
	print("进入沙盒模式")
	# 这里可以添加切换到沙盒模式场景的代码
	get_tree().change_scene_to_file("res://game_content/sandbox/intro/intro.tscn")

# 教程按钮处理函数
func _on_tutorial_button_pressed():
	print("进入教程")
	# 这里可以添加切换到教程场景的代码
