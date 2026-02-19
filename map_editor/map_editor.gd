extends Node3D

var brush_renderer: BrushRenderer
var editor_state_manager: EditorStateManager
@onready var ui = $UI
@onready var gpu_terrain:GPU_Terrain = $GPU_Terrain

# 编辑器初始化
# 
# 初始化地图编辑器，包括地图数据、地形生成器、网格管理器和笔刷材质
func _ready(): 
	editor_state_manager.state_label = $UI/CurrentEditState

	GameState.init_gamestate(self,GameState.WorldMode.MAP_EDIT)

	gpu_terrain.init_blank_terrain({
		"map_width": GameState.map_width,
		"map_height": GameState.map_height,
	},true)

	InputManager.mouse_moved.connect(_on_mouse_moved)
	InputManager.mouse_left_pressed.connect(_on_mouse_left_pressed)

func _init():
	brush_renderer = BrushRenderer.new()
	add_child(brush_renderer)
	editor_state_manager = EditorStateManager.get_instance()
	add_child(editor_state_manager)

# 鼠标左键是否按下
var _is_left_pressed: bool = false

# 鼠标左键按下信号处理
func _on_mouse_left_pressed(pressed: bool):
	_is_left_pressed = pressed

func _process(_delta: float) -> void:
	if _is_left_pressed:
		_perform_edit_operation()

# 鼠标移动信号处理
func _on_mouse_moved(position: Vector2, delta: Vector2):
	# 清理现有的笔刷可视化效果
	brush_renderer.clear_brush_visualization()

	#绘制笔刷
	if editor_state_manager.is_terrain_edit_state() or editor_state_manager.is_geology_edit_state():
		 #清理现有的高亮网格
		#grating_manager.clear_highlight()
		brush_renderer.render_brush_circle()
	#高亮指示 grating
	if editor_state_manager.is_grid_edit_state():
		if GameState.grid_manager.pointing_grid:
			var target_grids = GridUtils.get_grids_by_expansion(GameState.grid_manager.pointing_grid,round(Config.brush_size))
			#grating_manager.repaint_highlight(target_grids)

# 执行编辑操作的公共函数
func _perform_edit_operation() -> void:
	var hit_pos = RayUtil.get_mouse_raycast_hit()
	if hit_pos == null:
		return
		
	var map_x = round(hit_pos.x)
	var map_z = round(hit_pos.z)

	# todo 只改了一部分，之后还需完善
	if editor_state_manager.is_terrain_edit_state():
		gpu_terrain._editor.edit_terrain(
			Vector2(hit_pos.x,hit_pos.z),
			Config.brush_size,
			Config.brush_strength,
			1
		)
		# 更新地形和 grating
		gpu_terrain.update()
		#grating_manager.update_grating(map_x, map_z)
	elif editor_state_manager.is_geology_edit_state():
		var points_in_area = GameState.point_manager.get_points_in_circle_area(map_x, map_z, round(Config.brush_size))
		for point in points_in_area:
			point.set_color(GeologyType.get_color_for_type(GeologyType.get_current_geology_type()))
		# 更新地形
		gpu_terrain.update()
	elif editor_state_manager.is_grid_edit_state():
		if editor_state_manager.is_in_state(EditorStateManager.EditorState.GRID_FORREST):
			GameState.grid_manager.set_forrest_density(GridUtils.get_grids_by_expansion(GameState.grid_manager.pointing_grid,round(Config.brush_size)),Config.brush_strength/10)
		elif editor_state_manager.is_in_state(EditorStateManager.EditorState.GRID_GEOLOGY):
			GameState.grid_manager.set_grid_type(GridUtils.get_grids_by_expansion(GameState.grid_manager.pointing_grid,round(Config.brush_size)),GeologyType.get_current_geology_type())
