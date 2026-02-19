extends Control

# UI元素
@onready var info_window: Control = null
@onready var action_window: Control = null

# 操作模式变量
var is_target_selecting: bool = false  # 是否正在选择目标

var info_window_scene = preload("res://game_core/game_ui/common/info_window/info_window.tscn")
var action_window_scene = preload("res://game_core/game_ui/common/action_window/action_window.tscn")

func _ready():
	EventBus.connect("grid_pointed", _on_show_info)
	EventBus.connect("grid_selected", _on_show_action)
	
	# 创建info_window实例但不显示
	info_window = info_window_scene.instantiate()
	info_window.name = "InfoWindow"
	info_window.hide()
	add_child(info_window)
	
	# 创建action_window实例但不显示
	action_window = action_window_scene.instantiate()
	action_window.name = "ActionWindow"
	action_window.hide()
	# 设置player_ui引用
	action_window.player_ui = self
	add_child(action_window)

func _on_show_info(grid: Grid):
	if not grid or not grid.holding_node3D:
		# 如果没有有效的单位，隐藏info_window
		info_window.hide()
		return
	elif not grid.holding_node3D is Unit:
		# 如果不是单位，隐藏info_window
		info_window.hide()
		return

	# 显示info_window并设置单位信息
	info_window.set_unit(grid.holding_node3D as Unit)
	info_window.show()
	
func _on_show_action(grid: Grid):
	# 如果当前处于特殊操作模式，不执行此函数 (grid.chunk_x == 0 and grid.chunk_y == 0)表示因为鼠标在UI上
	if is_target_selecting or (grid.chunk_x == 0 and grid.chunk_y == 0):
		return
	
	# 如果当前已选中目标，不执行此函数
	if action_window._unit != null:
		if grid == action_window._unit.occupy_grid:
			return

	if not grid or not grid.holding_node3D:
		# 如果没有有效的单位，隐藏action_window
		action_window.hide()
		action_window._unit = null
		return
	elif not grid.holding_node3D is Unit:
		# 如果不是单位，隐藏action_window
		action_window.hide()
		action_window._unit = null
		return

	action_window.set_unit(grid.holding_node3D as Unit)
	action_window.show()
	info_window.hide()
