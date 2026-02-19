extends VSplitContainer

# 引用主编辑器脚本
@export var map_editor: Node

@onready var reset_all = $HBoxContainer/ResetAll
@onready var reset_terrain = $HBoxContainer/ResetTerrain
@onready var reset_geology = $HBoxContainer/ResetGeology
@onready var cancel = $HBoxContainer/Cancel

func _ready():
	if not map_editor:
		map_editor = get_node("../..")
	reset_all.pressed.connect(on_reset_all_pressed)
	reset_terrain.pressed.connect(on_reset_terrain_pressed)
	reset_geology.pressed.connect(on_reset_geology_pressed)
	cancel.pressed.connect(on_cancel_pressed)

# 全部重置
func on_reset_all_pressed():
	GameState.reset_all()# todo:修正
	on_reset_confirmed()
	close()

# 重置地形
func on_reset_terrain_pressed():
	GameState.reset_terrain()# todo:修正
	on_reset_confirmed()

	close()

# 重置地质
func on_reset_geology_pressed():
	GameState.reset_geology() 	# todo:修正
	on_reset_confirmed()

	close()

# 取消
func on_cancel_pressed():
	close()

# 关闭弹窗
func close():
	visible = false

# 处理输入事件
func _input(event):
	# 只有在弹窗可见时才处理点击事件
	if visible and event is InputEventMouseButton and event.pressed:
		# 检查点击是否在VSplitContainer之外
		var local_pos = get_local_mouse_position()
		if local_pos.x < 0 or local_pos.x > size.x or local_pos.y < 0 or local_pos.y > size.y:
			close()
			# 接受事件，防止事件冒泡
			accept_event()

# 执行重置操作
func on_reset_confirmed():
	# 重新生成地形
	map_editor.terrain_manager.generate_terrain()
	# 重新生成网格线
	map_editor.grating_manager.generate_grating()
