class_name GridManager

var pointing_grid: Grid = null

# 单元网格数组
var grids: Dictionary = {}
var chunk_count_x: int = 0
var chunk_count_z: int = 0

var highlight_grids: Array[Grid] = []

# 全局共享资源
static var tree_scenes: Array[PackedScene] = []
static var tree_lod_scenes: Dictionary = {} # 存储不同LOD级别的树木模型

func _init() -> void:
	EventBus.camera_moved.connect(_on_camera_moved)
	InputManager.mouse_moved.connect(_on_mouse_moved)
	InputManager.mouse_left_pressed.connect(_on_mouse_left_pressed)
	EventBus.clean_highlight.connect(clear_highlight)
	EventBus.paint_highlight.connect(paint_highlight)
	generate_grids()
	# 预加载树木模型
	load_tree_scenes()

# 鼠标移动信号处理
func _on_mouse_moved(position: Vector2, delta: Vector2):
	# 处理鼠标移动
	var hit_pos = RayUtil.get_mouse_raycast_hit()
	if hit_pos != null:
		var grid = get_grid_at_coord(int(hit_pos.x),int(hit_pos.z))
		if grid and pointing_grid != grid:
			pointing_grid = grid
			EventBus.grid_pointed.emit(grid)

# 鼠标左键点击信号处理
func _on_mouse_left_pressed(pressed: bool):
	if pressed:
		if pointing_grid != null:
			EventBus.grid_selected.emit(pointing_grid)

# 生成单元网格
func generate_grids():
	# 清理现有的单元网格
	for grid in grids.values():
		grid.clear_trees()
		grid.clear_grating()
	grids.clear()
	
	# 计算需要的单元网格数量
	chunk_count_x = int(float(GameState.map_width) / Config.grating_chunk_size)
	chunk_count_z = int(float(GameState.map_height) / Config.grating_chunk_size)

	# 创建单元网格
	for z in range(chunk_count_z):
		for x in range(chunk_count_x):
			grids[Vector2(x, z)] = Grid.new(x, z)
	
# 获取指定世界坐标的单元网格
func get_grid_at_coord(x: int, z: int) -> Grid:
	var chunk_z = int(z / Config.grating_chunk_size)
	var offset_x = 0
	if chunk_z % 2 == 0:
		offset_x += Config.grating_chunk_size / 2
	var chunk_x = int((x - offset_x) / Config.grating_chunk_size)

	return get_grid_by_map(chunk_x, chunk_z)

# 获取指定单元坐标的单元网格
func get_grid_by_map(chunk_x: int, chunk_z: int) -> Grid:
	if chunk_x < 0 or chunk_x >= chunk_count_x or chunk_z < 0 or chunk_z >= chunk_count_z:
		return null
	return grids[Vector2(chunk_x, chunk_z)]

func set_forrest_density(target_grids: Array[Grid],tree_density:float):
	if target_grids:
		for unit_grid in target_grids:
			unit_grid.tree_density = tree_density
			unit_grid.generate_tree()
	
func set_grid_type(target_grids: Array[Grid],grid_type:String):
	if target_grids:
		for grid in target_grids:
			grid.set_grid_type(grid_type)
			grid.render_light_sphere()

func update_grids(target_grids: Array[Grid]):
	if target_grids:
		for grid in target_grids:
			grid.calculate_center_point()

#返回size个不重复的grid
func get_random_grids(size:int) -> Array:
	# 确保请求的数量不超过可用网格数量
	size = min(size, grids.size())
	
	var result = []
	var selected_indices = {}  # 使用字典来记录已选索引，确保不重复
	
	# 循环直到获取足够数量的网格
	while result.size() < size:
		# 随机选择一个索引
		var random_x = randi() % chunk_count_x
		var random_z = randi() % chunk_count_z
		
		# 检查是否已经选择过这个索引
		if not selected_indices.has(Vector2(random_x, random_z)):
			# 如果没有选择过，添加到结果中
			result.append(grids[Vector2(random_x, random_z)])
			# 记录已选择的索引
			selected_indices[Vector2(random_x, random_z)] = true
	
	return result

func load_tree_scenes():
	# 加载不同LOD级别的树木模型
	# 格式: { "tree_type": [lod0_scene, lod1_scene, lod2_scene] }
	
	# # Oak Tree LOD级别 (605 -> 255 -> 103)
	# var oak_lod0 = load("res://shared/resources/tree/Oak_Tree_605face.fbx")
	# var oak_lod1 = load("res://shared/resources/tree/Oak_Tree_255face.fbx")
	# var oak_lod2 = load("res://shared/resources/tree/Oak_Tree_103face.fbx")
	# tree_lod_scenes["Oak_Tree"] = [oak_lod0, oak_lod1, oak_lod2]
	
	# # Fir Tree LOD级别 (408 -> 205 -> 150)
	# var fir_lod0 = load("res://shared/resources/tree/Fir_Tree_408face.fbx")
	# var fir_lod1 = load("res://shared/resources/tree/Fir_Tree_205face.fbx")
	# var fir_lod2 = load("res://shared/resources/tree/Fir_Tree_150face.fbx")
	# tree_lod_scenes["Fir_Tree"] = [fir_lod0, fir_lod1, fir_lod2]
	
	# 使用新模型 (2个LOD级别)
	# LOD0: 114面 - 近距离高细节
	# LOD1: 18面 - 远距离低细节
	var tree_lod0 = load("res://shared/resources/tree/tree_default_114face.fbx")
	var tree_lod1 = load("res://shared/resources/tree/tree_default_18face.fbx")
	tree_lod_scenes["Default_Tree"] = [tree_lod0, tree_lod1]
	
	# 为了兼容性，保留旧的tree_scenes数组（使用LOD0）
	for tree_type in tree_lod_scenes.keys():
		tree_scenes.append(tree_lod_scenes[tree_type][0])


func free_grid_owner(owner_id:int):
	for grid in grids.values():
		if grid.owner_headquarter_id == owner_id:
			grid.owner_headquarter_id = -1
			grid.update_color_by_owner()

# 设置网格的所有者并更新颜色
func set_grid_owner(grid: Grid, owner_id: int):
	if not grid:
		return
	grid.set_owner_headquarter_id(owner_id)

# 批量设置多个网格的所有者
func set_grids_owner(target_grids: Array[Grid], owner_id: int):
	for grid in target_grids:
		if grid:
			grid.set_owner_headquarter_id(owner_id)


func _on_camera_moved(camera_pos: Vector3):
	for grid:Grid in grids.values():
		#计算镜头位置 与 网格中心点的距离
		var dx = camera_pos.x - grid.center_point.x
		var dz = camera_pos.z - grid.center_point.z
		var dist_sq = dx * dx + dz * dz

		var new_lod = 0
		
		if dist_sq > 16384:    # 超过 128 距离使用低细节
			new_lod = 1
			
		grid.set_tree_lod_level(new_lod)

# 从数据中加载网格数据
func load_from_data(data: Dictionary) -> bool:
	# 验证必要字段
	if not data.has("grids"):
		print("数据缺少grids字段")
		return false
	

	# 清空并重新生成 新尺寸的grids
	generate_grids()
	
	# 加载网格数据
	var grids_data = data["grids"]
	for grid_data in grids_data:
		var x = grid_data.get("x", 0)
		var y = grid_data.get("y", 0)
		var tree_density = grid_data.get("tree_density", 0.0)
		var grid_type = grid_data.get("type", "")
		
		# 获取对应的网格对象
		var grid = get_grid_by_map(x, y)
		if grid:
			grid.tree_density = tree_density
			grid.set_grid_type(grid_type)
			#刷新网格
			grid.regenerate_grid()
	
	print("成功加载网格数据: ", grids_data.size(), " 个网格")
	return true

# 获取要保存的网格数据
func get_save_data() -> Array:
	var grids_array = []
	
	# 转换网格数据为数组格式
	for grid in grids.values():
		var grid_data = {
			"x": grid.chunk_x,
			"y": grid.chunk_y,
			"tree_density": grid.tree_density,
			"type": grid.grid_type
		}
		grids_array.append(grid_data)
	
	return grids_array

# 清除高亮
func clear_highlight():
	for grid in highlight_grids:
		grid.update_highlight_color(grid.default_color)
	highlight_grids.clear()

# 绘制高亮
func paint_highlight(new_list: Array[Grid]):
	for grid in new_list:
		grid.update_highlight_color(GratingUtils.available_color)
	highlight_grids = new_list
