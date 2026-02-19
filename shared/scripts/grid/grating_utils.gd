class_name GratingUtils
# Grating生成工具函数

const rounded_default_color: Color = Color(0.7, 0.7, 0, 0.7)	# 默认颜色
const boundary_default_color: Color = Color(0.7, 0.7, 0.7, 0.7)	# 默认颜色
const basic_default_color: Color = Color(0.5, 0.5, 0.5, 0.5)	# 默认颜色

const self_side_color: Color = Color("#2890f8ff")		# 己方颜色
const friendly_side_color: Color = Color("#3cefccff")	# 友方颜色 
const enemy_side_color: Color = Color("#f85341ff")		# 敌方颜色 

const available_color: Color = Color("#61ff12ff")		# 可选标记 	
# 生成基本网格
static func generate_basic_grating(surface_tool: SurfaceTool,chunk_x: int, chunk_z: int, get_height_func: Callable):
	var start_x = chunk_x * Config.grating_chunk_size
	var start_z = chunk_z * Config.grating_chunk_size
	var end_x = start_x + Config.grating_chunk_size
	var end_z = start_z + Config.grating_chunk_size
	
	# 绘制X方向线（横向）
	for z in range(start_z, end_z):
		for x in range(start_x, end_x):
			var h1 = get_height_func.call(x, z)
			var h2 = get_height_func.call(x + 1, z)

			surface_tool.add_vertex(Vector3(x * Config.grating_cell_size, h1, z * Config.grating_cell_size))
			surface_tool.add_vertex(Vector3((x + 1) * Config.grating_cell_size, h2, z * Config.grating_cell_size))

	# 绘制Z方向线（纵向）
	for x in range(start_x, end_x):
		for z in range(start_z, end_z):
			var h1 = get_height_func.call(x, z)
			var h2 = get_height_func.call(x, z + 1)
			surface_tool.add_vertex(Vector3(x * Config.grating_cell_size, h1, z * Config.grating_cell_size))
			surface_tool.add_vertex(Vector3(x * Config.grating_cell_size, h2, (z + 1) * Config.grating_cell_size))

# 生成区块边界
static func generate_chunk_grating(surface_tool: SurfaceTool, chunk_x: int, chunk_z: int, get_height_func: Callable):
	var start_x = chunk_x * Config.grating_chunk_size
	var start_z = chunk_z * Config.grating_chunk_size
	var end_x = start_x + Config.grating_chunk_size
	var end_z = start_z + Config.grating_chunk_size
	
	# 绘制X方向线（横向）
	for z in range(start_z, end_z, Config.grating_chunk_size):
		for x in range(start_x, end_x):
			var h1 = get_height_func.call(x, z)
			var h2 = get_height_func.call(x + 1, z)

			surface_tool.add_vertex(Vector3(x * Config.grating_cell_size, h1, z * Config.grating_cell_size))
			surface_tool.add_vertex(Vector3((x + 1) * Config.grating_cell_size, h2, z * Config.grating_cell_size))

	# 绘制Z方向线（纵向）
	for x in range(start_x, end_x, Config.grating_chunk_size):
		for z in range(start_z, end_z):
			var z_offset: int = 0
			if z % (2*Config.grating_chunk_size) < Config.grating_chunk_size:
				z_offset = Config.grating_chunk_size/2

			var h1 = get_height_func.call(x + z_offset, z)
			var h2 = get_height_func.call(x + z_offset, z + 1)

			surface_tool.add_vertex(Vector3((x + z_offset) * Config.grating_cell_size, h1, z * Config.grating_cell_size))
			surface_tool.add_vertex(Vector3((x + z_offset) * Config.grating_cell_size, h2, (z + 1) * Config.grating_cell_size))

# 生成圆角高亮网格
static func generate_rounded_grating(surface_tool: SurfaceTool, chunk_x: int, chunk_z: int, get_height_func: Callable):
	# 使用用户提供的偏移量计算方式确定中心位置
	var offset = 0.0
	if chunk_z % 2 == 0:
		offset = 0.5
	# 计算单元网格在地形中的中心位置
	var center_x = (chunk_x + offset) * Config.grating_chunk_size + Config.grating_chunk_size / 2
	var center_z = chunk_z * Config.grating_chunk_size + Config.grating_chunk_size / 2
	
	# 计算正方形的边长和圆角半径
	var square_size: float =  Config.grating_chunk_size * 0.9
	var corner_radius: float = square_size * 0.1
	
	# 根据LOD级别调整线段数（LOD级别越高，线段数越少）
	var segments_per_corner: int = 4 # 每个角的线段数，值越大越平滑，性能消耗也增加

	for corner_idx in range(4):
		_draw_corner_arc(surface_tool, corner_idx, center_x, center_z, square_size, corner_radius, segments_per_corner, get_height_func)
		
	# 连接四条边（同样根据LOD级别简化）
	# 计算四个角点坐标
	var top_left_x: float = center_x - square_size / 2 + corner_radius
	var top_right_x: float = center_x + square_size / 2 - corner_radius
	var top_z: float = center_z - square_size / 2

	var right_x: float = center_x + square_size / 2
	var right_top_z: float = center_z - square_size / 2 + corner_radius
	var right_bottom_z: float = center_z + square_size / 2 - corner_radius

	var bottom_left_x: float = center_x - square_size / 2 + corner_radius
	var bottom_right_x: float = center_x + square_size / 2 - corner_radius
	var bottom_z: float = center_z + square_size / 2

	var left_x: float = center_x - square_size / 2
	var left_top_z: float = center_z - square_size / 2 + corner_radius
	var left_bottom_z: float = center_z + square_size / 2 - corner_radius

	# 绘制四条边（根据LOD级别跳过一些点）
	_draw_side(surface_tool, top_left_x, top_z, top_right_x, top_z, true, get_height_func)
	_draw_side(surface_tool, right_x, right_top_z, right_x, right_bottom_z, false, get_height_func)
	_draw_side(surface_tool, bottom_left_x, bottom_z, bottom_right_x, bottom_z, true, get_height_func)
	_draw_side(surface_tool, left_x, left_top_z, left_x, left_bottom_z, false, get_height_func)

# 绘制圆角弧线
static func _draw_corner_arc(surface_tool: SurfaceTool, corner_idx: int, center_x: float, center_z: float, square_size: float, corner_radius: float, segments: int, get_height_func: Callable):
	# 定义四个角的参数
	var corner_params = [
		{"offset_x":  1, "offset_z":  1, "start_angle": 0 * PI / 2},    # 右下角
		{"offset_x": -1, "offset_z":  1, "start_angle": 1 * PI / 2},    # 左下角
		{"offset_x": -1, "offset_z": -1, "start_angle": 2 * PI / 2},    # 左上角
		{"offset_x":  1, "offset_z": -1, "start_angle": 3 * PI / 2}		# 右上角
	]
	
	var params = corner_params[corner_idx]
	
	# 计算圆心坐标
	var circle_center_x = center_x + params.offset_x * (square_size / 2 - corner_radius)
	var circle_center_z = center_z + params.offset_z * (square_size / 2 - corner_radius)
	
	# 绘制圆弧
	for i in range(segments):
		var angle: float = params.start_angle + (i / float(segments)) * (PI / 2)
		var x: float = circle_center_x + cos(angle) * corner_radius
		var z: float = circle_center_z + sin(angle) * corner_radius
		
		var next_angle: float = params.start_angle + ((i + 1) / float(segments)) * (PI / 2)
		var next_x: float = circle_center_x + cos(next_angle) * corner_radius
		var next_z: float = circle_center_z + sin(next_angle) * corner_radius
		
		surface_tool.add_vertex(Vector3(x * Config.grating_cell_size, get_height_func.call(x, z), z * Config.grating_cell_size))
		surface_tool.add_vertex(Vector3(next_x * Config.grating_cell_size, get_height_func.call(next_x, next_z), next_z * Config.grating_cell_size))

static func _draw_side(surface_tool: SurfaceTool, start_x: float, start_z: float, end_x: float, end_z: float, is_horizontal: bool, get_height_func: Callable):
	if is_horizontal:
		# 水平边绘制
		var current_x: float = start_x
		var fixed_z: float = start_z
		var step_size = Config.grating_cell_size
		while current_x < end_x:
			var next_x: float = min(current_x + step_size, end_x)
			surface_tool.add_vertex(Vector3(current_x, get_height_func.call(current_x, fixed_z), fixed_z))
			surface_tool.add_vertex(Vector3(next_x, get_height_func.call(next_x, fixed_z), fixed_z))
			current_x = next_x
	else:
		# 垂直边绘制
		var fixed_x: float = start_x
		var current_z: float = start_z
		var step_size = Config.grating_cell_size
		while current_z < end_z:
			var next_z: float = min(current_z + step_size, end_z)
			surface_tool.add_vertex(Vector3(fixed_x, get_height_func.call(fixed_x, current_z), current_z))
			surface_tool.add_vertex(Vector3(fixed_x, get_height_func.call(fixed_x, next_z), next_z))
			current_z = next_z
