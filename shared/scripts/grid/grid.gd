class_name Grid

var chunk_x: int = 0
var chunk_y: int = 0

var tree_density: float = 0.0
var center_point: Vector3 = Vector3.ZERO

var grid_type: String = ""
var height: float = 0.0

# 网格属性
var is_walkable: bool = true  # 是否可行走，默认为true

# 存储gridbound内的所有point
var points: Array[Vector3] = []

var tree_multimeshes: Dictionary = {}  # {0: MultiMeshInstance3D, 1: MultiMeshInstance3D}

# 存储当前网格内的节点
var holding_node3D: Node3D = null

# 网格归属，记录该网格属于哪个势力（玩家ID），-1表示中立，表示未占领
var owner_headquarter_id: int = -1
var default_color: Color = GratingUtils.rounded_default_color
# 设置网格类型并更新可行走属性
func set_grid_type(type: String):
	grid_type = type
	update_walkability()
	# 重新生成grating以反映可行走性变化
	generate_grating()

# 更新网格的可行走属性
func update_walkability():
	# 根据网格类型设置可行走属性
	match grid_type:
		"TYPE_SAND":
			is_walkable = false  # 地地可行走
		"TYPE_WATER":
			is_walkable = false  # 水域不可行走
		_:
			is_walkable = true   # 其他类型默认可行走

# 设置网格所有者并更新颜色
func set_owner_headquarter_id(headquarter_id: int):
	owner_headquarter_id = headquarter_id
	update_color_by_owner()

# 更新网格颜色（根据所有者）
func update_color_by_owner():
	if not _rounded_grating_material:
		return

	# 根据所有者ID设置颜色
	if owner_headquarter_id == -1:
		# 中立网格使用默认颜色
		default_color = GratingUtils.rounded_default_color
	elif owner_headquarter_id == GameState.player_id:
		# 己方网格
		default_color = GratingUtils.self_side_color
	else:
		# 需要检查是否是友方或敌方
		if GameState.is_friendly_player(owner_headquarter_id):
			# 友方网格
			default_color = GratingUtils.friendly_side_color
		else:
			# 敌方网格
			default_color = GratingUtils.enemy_side_color
	
	# 应用颜色
	_rounded_grating_material.albedo_color = default_color
	
var current_lod: int = 0

# Grating相关属性
var _grating_node: MeshInstance3D = null
var _grating_material: Material = null
var _chunk_boundary_material: Material = null
var _rounded_grating_material: Material = null

var _shared_materials: Dictionary = {}

func _init(x: int = 0, y: int = 0):
	chunk_x = x
	chunk_y = y
	grid_type = GeologyType.get_default_geology_type()
	
	# 根据网格类型更新可行走属性
	update_walkability()

	# 计算中心点坐标
	calculate_center_point()
	# 初始化point_heights数组
	initialize_points()
	# 初始化Grating
	initialize_grating()
	
	# 根据所有者更新颜色
	update_color_by_owner()

# 初始化point_heights数组，包含gridbound内的所有point
func initialize_points():
	var bounds = {
		"min_x": chunk_x * Config.grating_chunk_size,
		"max_x": (chunk_x + 1) * Config.grating_chunk_size - 1,
		"min_y": chunk_y * Config.grating_chunk_size,
		"max_y": (chunk_y + 1) * Config.grating_chunk_size - 1
	}
	points.clear()
	for x in range(bounds.min_x, bounds.max_x + 1):
		for y in range(bounds.min_y, bounds.max_y + 1):
			points.append(Vector3(x, GameState._world_node.gpu_terrain.get_height_at(x, y), y))
			
func calculate_center_point():
	var offset = 0

	if chunk_y % 2 == 0:
		offset = 0.5

	# 计算单元网格在地形中的中心位置
	var center_x = (chunk_x + offset) * Config.grating_chunk_size + Config.grating_chunk_size / 2
	var center_y = (chunk_y ) * Config.grating_chunk_size + Config.grating_chunk_size / 2

	# 四舍五入取整，再限制范围
	center_x = clamp(int(round(center_x)), 0, GameState.map_width - 1)
	center_y = clamp(int(round(center_y)), 0, GameState.map_height - 1)

	
	height = GameState._world_node.gpu_terrain.get_height_at(center_x, center_y)
	
	# 设置中心点坐标
	center_point = Vector3(center_x * Config.terrain_cell_size, height, center_y * Config.terrain_cell_size)

func generate_tree():
	clear_trees()
	
	var BASE_DENSITY = 0.2
	var PEAK_DENSITY = BASE_DENSITY * 2

	var effective_density = tree_density
	var scale_multiplier = 1.0

	# 作用 当密度超过阈值时，减少生成数量，转为放大树木 1 降低渲染压力 2 模拟真实生态效果
	if tree_density > PEAK_DENSITY:
		# 增长率系数 `growth_rate` 可调，控制树木放大的速度
		var growth_rate = 1.2  # 例如：每超过阈值0.1，缩放倍率增加0.1
		var excess = tree_density - PEAK_DENSITY
		scale_multiplier = 1.0 + growth_rate * excess
		
		# 简单衰减公式
		var decay_per_excess = 0.3  # decay_per_excess 上升 effective_density 下降
		effective_density = PEAK_DENSITY * (1.0 - decay_per_excess * (excess / (1.0 - PEAK_DENSITY)))

		# print("密度: %.2f -> 生成率: %.2f, 放大: %.2f" % [tree_density, effective_density, scale_multiplier])
	
	# 重叠补偿因子 点阵边缘树的生成会重复结算，导致生成概率隐性提高，所以需要调整树的生成密度
	var overlap_compensation: float = 0.64
	
	# 收集所有树的位置和变换
	var transforms: Array[Transform3D] = []
	
	for point: Vector3 in points:
		if effective_density * overlap_compensation > randf():
			var position_offset = Vector2(randf_range(-0.4, 0.4), randf_range(-0.4, 0.4))
			var position = Vector3(point.x + position_offset.x, point.y, point.z + position_offset.y)
			var scale_variation = randf_range(1-0.2, 1+0.2)
			
			# FBX 模型通常是 Z 轴朝上，转换为 Godot 的 Y 轴朝上
			var basis = Basis().rotated(Vector3.RIGHT, -PI / 2)  # 绕 X 轴旋转 -90 度，让树直立
			basis = basis.scaled(Vector3.ONE * scale_multiplier * scale_variation)
			transforms.append(Transform3D(basis, position))
	
	if transforms.size() == 0:
		return
	
	# 获取唯一的树类型（现在只有一种）
	var tree_types = GridManager.tree_lod_scenes.keys()
	var tree_type = tree_types[0]
	var lod_scenes = GridManager.tree_lod_scenes[tree_type]
	
	# 为每个 LOD 级别创建一个 MultiMeshInstance3D (2个LOD级别)
	for lod_level in range(2):
		var multimesh = MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.instance_count = transforms.size()
		
		# 设置该 LOD 的 mesh
		var scene = lod_scenes[lod_level]
		var mesh = _extract_mesh(scene)
		
		if mesh == null:
			continue
			
		multimesh.mesh = mesh
		
		# 设置所有实例的变换
		for i in range(transforms.size()):
			multimesh.set_instance_transform(i, transforms[i])
		
		# 创建 MultiMeshInstance3D
		var mm_instance = MultiMeshInstance3D.new()
		mm_instance.name = "Trees_LOD%d" % lod_level
		mm_instance.multimesh = multimesh
		mm_instance.visible = (lod_level == current_lod)
		mm_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		
		GameState.get_world_node().add_child(mm_instance)
		tree_multimeshes[lod_level] = mm_instance

func _extract_mesh(scene: PackedScene) -> Mesh:
	var instance = scene.instantiate()
	var mesh: Mesh = null
	
	if instance is MeshInstance3D:
		mesh = instance.mesh
	elif instance is Node3D:
		var found = false
		for child in instance.get_children():
			if child is MeshInstance3D:
				mesh = child.mesh
				found = true
				break
		
		if not found:
			for child in instance.get_children():
				for grandchild in child.get_children():
					if grandchild is MeshInstance3D:
						mesh = grandchild.mesh
						found = true
						break
				if found:
					break
	
	instance.queue_free()
	
	if mesh == null:
		print("警告: 无法从场景中提取mesh: ", scene.resource_path)
	
	return mesh

#清理树木
func clear_trees():
	for lod_level in tree_multimeshes.keys():
		var mm_instance = tree_multimeshes[lod_level]
		if mm_instance != null and is_instance_valid(mm_instance):
			mm_instance.queue_free()
	tree_multimeshes.clear()

# 直接设置所有树木的LOD级别（用于从外部控制）
# 规则：近处显示高LOD(LOD0)，远处显示低LOD(LOD1)，确保树木始终可见
func set_tree_lod_level(lod_level: int):
	if lod_level < 0 or lod_level == current_lod:
		return
	current_lod = lod_level
	
	if not tree_multimeshes.has(lod_level):
		return

	if tree_multimeshes.has(0) and tree_multimeshes.has(1):

		if lod_level == 0:
			tree_multimeshes[0].visible = true
			tree_multimeshes[1].visible = false
		else:
			tree_multimeshes[0].visible = false
			tree_multimeshes[1].visible = true
	
#重新生成网格全部内容
func regenerate_grid():
	# 计算中心点坐标
	calculate_center_point()
	# 初始化point_heights数组
	initialize_points()	
	clear_trees()
	generate_tree()
	generate_grating()

# 初始化Grating
func initialize_grating():	
	# 获取共享材质
	_grating_material = StandardMaterial3D.new()
	_grating_material.albedo_color = GratingUtils.basic_default_color
	_chunk_boundary_material = StandardMaterial3D.new()
	_chunk_boundary_material.albedo_color = GratingUtils.boundary_default_color
	_rounded_grating_material = StandardMaterial3D.new()
	_rounded_grating_material.albedo_color = GratingUtils.rounded_default_color
	_rounded_grating_material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED

# 生成Grating
func generate_grating():
	# 如果网格不可行走，则不渲染grating
	if not is_walkable:
		clear_grating()
		return
		
	# 创建或获取grating节点
	if not _grating_node:
		_grating_node = MeshInstance3D.new()
		_grating_node.name = "Grating_%d_%d" % [chunk_x, chunk_y]
		GameState.get_world_node().add_child(_grating_node)
	
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_LINES)

	# 创建高度获取回调函数
	var get_height_func = Callable(self, "_get_height_at")
	# 绘制基本网格
	if Config.show_basic_grating:
		# 调用静态工具函数
		surface_tool.set_material(_grating_material)
		GratingUtils.generate_basic_grating(surface_tool, chunk_x, chunk_y, get_height_func)
	
	# 绘制区块边界
	if Config.show_chunk_grating:
		# 调用静态工具函数
		surface_tool.set_material(_chunk_boundary_material)
		GratingUtils.generate_chunk_grating(surface_tool, chunk_x, chunk_y, get_height_func)
	
	if Config.show_rounded_grating:
		# 调用静态工具函数
		surface_tool.set_material(_rounded_grating_material)
		GratingUtils.generate_rounded_grating(surface_tool, chunk_x, chunk_y, get_height_func)
	
	# 提交网格
	var mesh = surface_tool.commit()
	_grating_node.mesh = mesh
	
# 获取指定位置的高度
func _get_height_at(x: float, z: float) -> float:
	var int_x = int(round(x))
	var int_z = int(round(z))
	return GameState._world_node.gpu_terrain.get_height_at(int_x, int_z) + 0.3

# 更新高亮颜色
func update_highlight_color(color: Color):
	_rounded_grating_material.albedo_color = color

# 清理Grating
func clear_grating():
	if _grating_node and is_instance_valid(_grating_node):
		_grating_node.queue_free()
	_grating_node = null
