extends Control

# 引用主编辑器脚本
@export var map_editor: Node
@export var editor_ui: Control

# UI元素引用
@onready var terrain_button = $TerrainButton
@onready var geology_button = $GeologyButton
@onready var grid_button = $GridButton
@onready var save_button = $SaveButton
@onready var load_button = $LoadButton
@onready var brush_size_slider = $BrushSizeSlider
@onready var brush_strength_slider = $BrushStrengthSlider
@onready var brush_size_label = $BrushSizeLabel
@onready var brush_strength_label = $BrushStrengthLabel

@onready var test_button = $TestButton
@onready var back_to_menu_button = $BackToMenuButton

# 地图尺寸UI元素引用
@onready var width_spinbox = $WidthSpinBox
@onready var height_spinbox = $HeightSpinBox
@onready var apply_size_button = $ApplySizeButton

# 网格线控制UI元素引用
@onready var show_grid_lines = $ShowGridLines
@onready var show_chunk_boundaries = $ShowChunkBoundaries
@onready var show_highlight_line = $ShowHighlightLine
@onready var reset_button = $ResetButton

var grid_button_group: ButtonGroup
# 初始化UI
# 
# 初始化UI控件，连接信号，并设置初始值
func _ready():

	# 如果map_editor未初始化，尝试通过节点路径获取引用
	if not map_editor:
		map_editor = get_node("../..")
	
	if not editor_ui:
		editor_ui = get_node("..")
	
	# 连接按钮信号
	terrain_button.pressed.connect(editor_ui.show_terrain_sub_container)
	geology_button.pressed.connect(editor_ui.show_geology_sub_container)
	grid_button.pressed.connect(editor_ui.show_grid_sub_container)
	save_button.pressed.connect(editor_ui.show_save_dialog)
	load_button.pressed.connect(editor_ui.show_load_dialog)
	reset_button.pressed.connect(editor_ui.show_reset_dialog)
	
	test_button.pressed.connect(test)

	back_to_menu_button.pressed.connect(back_to_menu)
	
	# 连接滑块信号
	brush_size_slider.value_changed.connect(on_brush_size_changed)
	brush_size_slider.value = Config.brush_size
	brush_strength_slider.value_changed.connect(on_brush_strength_changed)
	brush_strength_slider.value = Config.brush_strength
	
	# 连接地图尺寸按钮信号
	apply_size_button.pressed.connect(on_apply_size_button_pressed)
	
	grid_button_group = ButtonGroup.new()
	show_grid_lines.button_group = grid_button_group
	show_chunk_boundaries.button_group = grid_button_group
	show_highlight_line.button_group = grid_button_group

	# 初始化网格线显示状态
	show_grid_lines.button_pressed = Config.show_basic_grating
	show_chunk_boundaries.button_pressed = Config.show_chunk_grating
	show_highlight_line.button_pressed = Config.show_rounded_grating
	
	# 连接网格线控制开关信号
	show_grid_lines.toggled.connect(on_show_grid_lines_toggled)
	show_chunk_boundaries.toggled.connect(on_show_chunk_boundaries_toggled)
	show_highlight_line.toggled.connect(on_show_highlight_line_toggled)
	
	# 初始化地图尺寸控件的值
	if width_spinbox:
		width_spinbox.value = GameState.map_width
	if height_spinbox:
		height_spinbox.value = GameState.map_height

# 画笔大小改变
# 
# 设置地图编辑器的画笔大小，并更新标签文本
# 
# @param value 新的画笔大小值
func on_brush_size_changed(value: float):
	Config.brush_size = value
	# 更新标签文本
	brush_size_label.text = "画笔大小: " + str(int(value))

# 画笔强度改变
# 
# 设置地图编辑器的画笔强度，并更新标签文本
# 
# @param value 新的画笔强度值
func on_brush_strength_changed(value: float):
	Config.brush_strength = value
	# 更新标签文本
	brush_strength_label.text = "画笔强度: " + str(value)

# 应用地图尺寸按钮按下
# 
# 获取用户输入的地图尺寸并重置地图
func on_apply_size_button_pressed():
	var new_width = int(width_spinbox.value)
	var new_height = int(height_spinbox.value)
	
	# 检查输入值是否有效
	if new_width <= 0 or new_height <= 0:
		return
	
	GameState.reset_size(new_width, new_height, GameState.cell_size)

	map_editor.terrain_manager.generate_terrain()
	map_editor.grating_manager.generate_grating()
	GameState.grid_manager.generate_grids()

# 基础网格开关切换
# 
# 控制是否显示基础网格
func on_show_grid_lines_toggled(toggled_on: bool):
	Config.show_basic_grating = toggled_on
	map_editor.grating_manager.generate_grating()

# 单元网格显示开关切换
# 
# 控制是否显示单元网格线
func on_show_chunk_boundaries_toggled(toggled_on: bool):
	Config.show_chunk_grating = toggled_on
	map_editor.grating_manager.generate_grating()

# 高亮网格开关切换
# 
# 控制是否显示高亮网格线
func on_show_highlight_line_toggled(toggled_on: bool):
	Config.show_rounded_grating = toggled_on
	map_editor.grating_manager.generate_grating()


func test():
	var timer = Time.get_ticks_msec()
	var timer1 = 0
	var timer2 = 0
	var timer3 = 0
	
	print("\n========== GPU模式测试 ==========")
	timer1 = Time.get_ticks_msec()
	GameState.test()
	timer3 = Time.get_ticks_msec()
	
	var timer_end_gpu = Time.get_ticks_msec()
	print("=== main_menu_ui.test() 计时 [GPU模式] ===")
	print("GameState.test(): %d ms" % (timer2 - timer1))
	print("terrain_manager.generate_terrain(): %d ms" % (timer3 - timer2))
	print("grating_manager.generate_grating(): %d ms" % (timer_end_gpu - timer3))
	print("总计: %d ms" % (timer_end_gpu - timer1))

func back_to_menu():
	RayUtil._camera = null
	RayUtil._viewport = null
	RayUtil._world_3d = null
	RayUtil.exclusion_UI_List.clear()
	get_tree().change_scene_to_file("res://game_content/main_menu/main_menu.tscn")
