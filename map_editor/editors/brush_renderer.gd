extends Node3D

class_name BrushRenderer

# 笔刷可视化节点和材质
var _brush_node: MeshInstance3D
var _brush_material: StandardMaterial3D

# 初始化笔刷材质
func init_brush_material():
	# 创建笔刷材质
	_brush_material = StandardMaterial3D.new()
	_brush_material.albedo_color = Color(0, 0, 1, 1)  # 蓝色
	_brush_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# _brush_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHAss

# 清理笔刷可视化效果
func clear_brush_visualization():
	if _brush_node and _brush_node.get_parent():
		_brush_node.get_parent().remove_child(_brush_node)
		_brush_node.queue_free()
		_brush_node = null

# 绘制笔刷圆圈
func render_brush_circle():
	var hit_pos = RayUtil.get_mouse_raycast_hit()
	if hit_pos == null:
		return
	init_brush_material()
	# 创建新的笔刷可视化节点
	_brush_node = MeshInstance3D.new()
	_brush_node.name = "BrushVisualization"
	add_child(_brush_node)
	_brush_node.owner = get_owner() if get_owner() else self
	
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_LINES)
	surface_tool.set_material(_brush_material)
	
	# 绘制圆圈
	var segments = Config.brush_segments
	var radius = Config.brush_size * 1.0
	
	for i in range(segments):
		var angle1 = (i / float(segments)) * 2 * PI
		var angle2 = ((i + 1) / float(segments)) * 2 * PI
		
		var x1 = hit_pos.x + cos(angle1) * radius
		var z1 = hit_pos.z + sin(angle1) * radius
		var x2 = hit_pos.x + cos(angle2) * radius
		var z2 = hit_pos.z + sin(angle2) * radius
		
		# 获取地形高度
		var height1 = get_real_height(x1, z1)
		var height2 = get_real_height(x2, z2)
		
		surface_tool.add_vertex(Vector3(x1, height1 + 0.25, z1))
		surface_tool.add_vertex(Vector3(x2, height2 + 0.25, z2))
	
	# 生成网格
	_brush_node.mesh = surface_tool.commit()

# 获取地形在指定坐标的高度
# 
# @param x 世界X坐标
# @param z 世界Z坐标
# @return float 指定坐标的地形高度
func get_real_height(x: float, z: float) -> float:
	# 调用射线检测获取高度
	return RayUtil.raycast_to_y(x, z)+ 0.2
	
# 更新笔刷颜色
# 
# @param color 新的笔刷颜色
func update_brush_color(color: Color):
	if _brush_material:
		_brush_material.albedo_color = color

# 更新笔刷透明度
# 
# @param alpha 新的透明度值（0.0-1.0）
func update_brush_alpha(alpha: float):
	if _brush_material:
		var current_color = _brush_material.albedo_color
		current_color.a = alpha
		_brush_material.albedo_color = current_color
