extends RefCounted
class_name GridUtils

# 六边形网格工具类，包含各种网格算法

# 6个方向的枚举（奇数时钟方向）
enum GridDirection6 {
	DIRECTION_1_OCLOCK = 1,     # 1点钟方向
	DIRECTION_3_OCLOCK = 3,     # 3点钟方向
	DIRECTION_5_OCLOCK = 5,     # 5点钟方向
	DIRECTION_7_OCLOCK = 7,     # 7点钟方向
	DIRECTION_9_OCLOCK = 9,     # 9点钟方向
	DIRECTION_11_OCLOCK = 11     # 11点钟方向
}

enum GridAngle {
	ANGLE_0,
	ANGLE_60,
	ANGLE_120,
	ANGLE_180,
	ANGLE_240,
	ANGLE_360	# 300度 网格逻辑上等于 360度
}

# 获取相邻网格
static func get_adjacent_grids(grid: Grid, direction6_group: Array) -> Dictionary:
	var adjacent_grids = {}
	var map_x = grid.chunk_x
	var map_z = grid.chunk_y

	var init_radius = 1

	# 计算偏移量
	var offset_x_positive = ceil(init_radius / 2)
	var offset_x_negative = ceil(init_radius / 2)
	var offset_z = init_radius

	if init_radius % 2 != 0:
		if map_z % 2 != 0:
			offset_x_negative += 1
		else:
			offset_x_positive += 1

	# 添加周围的单元网格
	# 右上
	if GridDirection6.DIRECTION_1_OCLOCK in direction6_group:
		var right_top = GameState.grid_manager.get_grid_by_map(map_x + offset_x_positive, map_z + offset_z)
		if right_top:
			adjacent_grids[GridDirection6.DIRECTION_1_OCLOCK] = right_top
	
	# 右极点
	if GridDirection6.DIRECTION_3_OCLOCK in direction6_group:
		var right_pole = GameState.grid_manager.get_grid_by_map(map_x + init_radius, map_z)
		if right_pole:
			adjacent_grids[GridDirection6.DIRECTION_3_OCLOCK] = right_pole
	
	# 右下
	if GridDirection6.DIRECTION_5_OCLOCK in direction6_group:
		var right_bottom = GameState.grid_manager.get_grid_by_map(map_x + offset_x_positive, map_z - offset_z)
		if right_bottom:
			adjacent_grids[GridDirection6.DIRECTION_5_OCLOCK] = right_bottom
	
	# 左下
	if GridDirection6.DIRECTION_7_OCLOCK in direction6_group:
		var left_bottom = GameState.grid_manager.get_grid_by_map(map_x - offset_x_negative, map_z - offset_z)
		if left_bottom:
			adjacent_grids[GridDirection6.DIRECTION_7_OCLOCK] = left_bottom
	
	# 左极点
	if GridDirection6.DIRECTION_9_OCLOCK in direction6_group:
		var left_pole = GameState.grid_manager.get_grid_by_map(map_x - init_radius, map_z)
		if left_pole:
			adjacent_grids[GridDirection6.DIRECTION_9_OCLOCK] = left_pole
	
	# 左上
	if GridDirection6.DIRECTION_11_OCLOCK in direction6_group:
		var left_top = GameState.grid_manager.get_grid_by_map(map_x - offset_x_negative, map_z + offset_z)
		if left_top:
			adjacent_grids[GridDirection6.DIRECTION_11_OCLOCK] = left_top

	return adjacent_grids

# 性能最优的网格扩展算法（广度优先）默认角度为360度
static func get_grids_by_expansion(source_grid: Grid, radius: int, angle: GridAngle = GridAngle.ANGLE_360) -> Array[Grid]:
	if radius < 0:
		return []
	if radius == 0:
		return [source_grid]
	
	var visited = {source_grid: true}
	var result: Array[Grid] = [source_grid]
	var current_layer = [source_grid]
	var direction6_group = get_direction6_group(angle, source_grid)
	
	# 需要执行radius次扩展，从距离1到距离radius
	for _i in range(radius):
		var next_layer = []
		
		for grid in current_layer:
			var adjacent_dict = get_adjacent_grids(grid, direction6_group)
			
			for direction in adjacent_dict:
				var adj_grid = adjacent_dict[direction]
				if adj_grid and not visited.has(adj_grid):
					visited[adj_grid] = true
					result.append(adj_grid)
					next_layer.append(adj_grid)
		
		if next_layer.is_empty():
			break
		
		current_layer = next_layer
	
	return result

# 获取方向组
static func get_direction6_group(angle: GridAngle, source_grid: Grid) -> Array:
	var group = []
	
	if angle == GridAngle.ANGLE_360:
		return GridDirection6.values()
	else:
		var adjacent_grids = get_adjacent_grids(source_grid, GridDirection6.values())
		var mouse_pos = RayUtil.get_mouse_raycast_hit()
		# 获取到距离鼠标位置最近的两个网格所对应的方向，并加入到group中
		
		if mouse_pos != Vector3.ZERO:
			# 计算每个相邻网格到鼠标位置的距离
			var distances = []
			for direction in adjacent_grids:
				var grid = adjacent_grids[direction]
				if grid:
					var grid_center = grid.center_point
					var distance = grid_center.distance_to(mouse_pos)
					distances.append({"direction": direction, "distance": distance, "grid": grid})
			
			# 按距离排序
			distances.sort_custom(func(a, b): return a.distance < b.distance)
			
			# 根据角度参数决定返回几个方向
			var count = 0
			match angle:
				GridAngle.ANGLE_0:
					count = 1
				GridAngle.ANGLE_60:
					count = 2
				GridAngle.ANGLE_120:
					count = 3
				GridAngle.ANGLE_180:
					count = 4
				GridAngle.ANGLE_240:
					count = 5
			
			# 添加最近的方向到组中
			for i in min(count, distances.size()):
				group.append(distances[i].direction)
	
	# 返回GridDirection6 group
	return group

# 基于BFS的最短路径查找（更简单）
static func get_shortest_path_bfs(source_grid: Grid, target_grid: Grid, limit: int = 100) -> Array[Grid]:
	if source_grid == null or target_grid == null:
		return []
	
	if source_grid == target_grid:
		return [source_grid]
	
	var queue = []          # 待处理的网格队列
	var visited = {}        # 已访问的网格
	var previous = {}       # 路径关系
	var distance = {}       # 距离记录
	
	# 初始化起点
	queue.append(source_grid)
	visited[source_grid] = true
	distance[source_grid] = 0
	previous[source_grid] = null
	
	while queue.size() > 0:
		var current = queue.pop_front()
		
		# 如果找到目标，重建路径
		if current == target_grid:
			return _reconstruct_bfs_path(previous, target_grid)
		
		# 如果超出距离限制，停止
		if distance[current] >= limit:
			continue
		
		# 获取所有相邻网格
		var neighbors = get_adjacent_grids(current, GridDirection6.values())
		
		for direction in neighbors:
			var neighbor = neighbors[direction]
			
			if neighbor == null or visited.has(neighbor):
				continue
			
			# 检查网格是否可通过
			if neighbor.holding_node3D != null and neighbor != target_grid:
				continue
			
			# 标记为已访问并更新信息
			visited[neighbor] = true
			distance[neighbor] = distance[current] + 1
			previous[neighbor] = current
			queue.append(neighbor)
	
	queue.erase(source_grid)
	return []

# 重建BFS路径
static func _reconstruct_bfs_path(previous: Dictionary, target_grid: Grid) -> Array[Grid]:
	var path: Array[Grid] = []
	var current = target_grid
	
	while current != null:
		path.append(current)
		current = previous.get(current)
	
	path.reverse()
	return path

static func generate_grid_by_heightmap(height_map_float_data: PackedFloat32Array, map_size: Vector2, cell_size: float, elevation_scale: float = 10.0) -> Array:
	var grids = []
	var chunk_size = 4  # 每个网格 4x4 个点
	var grid_count_x = int(ceil((map_size.x * cell_size) / chunk_size))
	var grid_count_z = int(ceil((map_size.y * cell_size) / chunk_size))

	for gz in range(grid_count_z):
		for gx in range(grid_count_x):
			var avg_height = 0.0
			var point_count = 0
			
			# 计算该网格的平均高度
			for dz in range(chunk_size):
				for dx in range(chunk_size):
					var px = gx * chunk_size + dx
					var pz = gz * chunk_size + dz
					
					if px < map_size.x and pz < map_size.y:
						var idx = pz * map_size.x + px
						avg_height += height_map_float_data[idx]
						point_count += 1
			
			if point_count > 0:
				avg_height /= point_count
			
			var grid_type = _get_grid_type_for_height(avg_height / elevation_scale)
			var tree_density = _calculate_tree_density(avg_height / elevation_scale)
			
			var grid_data = {
				"x": gx,
				"y": gz,
				"tree_density": tree_density,
				"type": grid_type
			}
			grids.append(grid_data)
	return grids

## 根据高度获取网格类型
static func _get_grid_type_for_height(normalized_height: float) -> String:
	# 使用与着色器相同的12个固定相对阈值
	var t_deep_water = -1.0      # 深水阈值
	var t_water = -0.8           # 标准水阈值
	var t_shallow = -0.4         # 浅水阈值
	var t_sand = -0.3            # 沙滩阈值
	var t_wetland = -0.25        # 湿地阈值
	var t_light_grass = -0.2     # 浅草地阈值
	var t_grass = 0.0            # 标准草地阈值
	var t_dark_grass = 0.05      # 深草地阈值
	var t_hill = 0.3             # 丘陵阈值
	var t_light_rock = 0.4       # 浅岩石阈值
	var t_rock = 0.5             # 标准岩石阈值
	var t_dark_rock = 0.6        # 深岩石阈值
	var t_snow = 0.7             # 雪地阈值

	# 修正逻辑：高于阈值才属于对应的地形类型
	if normalized_height > t_snow:
		return "TYPE_MOUNTAIN"     # 雪线以上（山脉）
	elif normalized_height > t_dark_rock:
		return "TYPE_MOUNTAIN"     # 雪线以下（山脉）
	elif normalized_height > t_rock:
		return "TYPE_WASTELAND"    # 深岩石（荒地）
	elif normalized_height > t_light_rock:
		return "TYPE_WASTELAND"    # 标准岩石（荒地）
	elif normalized_height > t_hill:
		return "TYPE_WASTELAND"    # 浅岩石（荒地）
	elif normalized_height > t_dark_grass:
		return "TYPE_DARK_GRASS"   # 丘陵（使用深草地类型）
	elif normalized_height > t_grass:
		return "TYPE_DARK_GRASS"   # 深草地
	elif normalized_height > t_light_grass:
		return "TYPE_LIGHT_GRASS"  # 标准草地
	elif normalized_height > t_wetland:
		return "TYPE_LIGHT_GRASS"  # 浅草地
	elif normalized_height > t_sand:
		return "TYPE_LIGHT_GRASS"  # 湿地
	elif normalized_height > t_shallow:
		return "TYPE_SAND"         # 沙滩
	elif normalized_height > t_water:
		return "TYPE_SAND"         # 浅水/沙滩过渡
	elif normalized_height > t_deep_water:
		return "TYPE_WATER"        # 标准水体
	else:
		return "TYPE_WATER"        # 深水
## 计算树木密度（使用归一化高度和新的12阈值体系）
## 计算树木密度（直接基于归一化高度）
static func _calculate_tree_density(normalized_height: float) -> float:
	# 使用与着色器相同的12个固定相对阈值
	var t_deep_water = -1.0      # 深水阈值
	var t_water = -0.8           # 标准水阈值
	var t_shallow = -0.4         # 浅水阈值
	var t_sand = -0.3            # 沙滩阈值
	var t_wetland = -0.25        # 湿地阈值
	var t_light_grass = -0.2     # 浅草地阈值
	var t_grass = 0.0            # 标准草地阈值
	var t_dark_grass = 0.05      # 深草地阈值
	var t_hill = 0.3             # 丘陵阈值
	var t_light_rock = 0.4       # 浅岩石阈值
	var t_rock = 0.5             # 标准岩石阈值
	var t_dark_rock = 0.6        # 深岩石阈值
	var t_snow = 0.7             # 雪地阈值
	
	var global_tree_density_scale: float = 1.0
	var base_density: float = 0.0
	
	# 直接根据高度范围分配树木密度
	if normalized_height > t_snow:
		# 雪线以上：无树木
		base_density = 0.0
	elif normalized_height > t_dark_rock:
		# 深岩石区域：极少量树木
		base_density = 0.01
	elif normalized_height > t_rock:
		# 标准岩石区域：少量树木
		base_density = 0.03
	elif normalized_height > t_light_rock:
		# 浅岩石区域：适中树木
		base_density = 0.08
	elif normalized_height > t_hill:
		# 丘陵区域：较多树木
		base_density = 0.15
	elif normalized_height > t_dark_grass:
		# 深草地区域：密集树木（主要分布区）
		base_density = 0.55
	elif normalized_height > t_grass:
		# 标准草地区域：较多树木
		base_density = 0.05
	elif normalized_height > t_light_grass:
		# 浅草地区域：适中树木
		base_density = 0.01
	elif normalized_height > t_wetland:
		# 湿地区域：少量树木
		base_density = 0.00
	elif normalized_height > t_sand:
		# 沙滩区域：极少量树木
		base_density = 0.00
	elif normalized_height > t_shallow:
		# 浅水区域：基本无树木
		base_density = 0.0
	elif normalized_height > t_water:
		# 标准水体：无树木
		base_density = 0.0
	elif normalized_height > t_deep_water:
		# 深水区域：无树木
		base_density = 0.0
	else:
		# 最深水区域：无树木
		base_density = 0.0
	
	# 应用全局密度缩放
	return base_density * global_tree_density_scale
