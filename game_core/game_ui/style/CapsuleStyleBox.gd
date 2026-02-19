@tool
class_name CapsuleStyleBox
extends StyleBox

# ========== 外观属性 ==========
@export_category("Appearance")
@export var fill_color: Color = Color(1, 1, 1, 0.5)
@export var border_color: Color = Color(0.6, 0.6, 0.9, 0.7)
@export_range(0.0, 10.0, 0.5) var border_width: float = 2.0

# ========== 胶囊形状控制 ==========
@export_category("Capsule Shape")
@export var vertical_capsule: bool = false
@export_range(8, 32, 4) var smoothness: int = 16

func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var size = rect.size
	var pos = rect.position
	
	# 1. 中间矩形部分
	var rect_points = PackedVector2Array([
		Vector2(pos.x, pos.y),                    # 左上
		Vector2(pos.x + size.x, pos.y),           # 右上
		Vector2(pos.x + size.x, pos.y + size.y),  # 右下
		Vector2(pos.x, pos.y + size.y)            # 左下
	])
	RenderingServer.canvas_item_add_polygon(to_canvas_item, rect_points, [fill_color])
	
	if vertical_capsule:
		 # 2. 上半圆
		var top_left = Vector2(pos.x, pos.y)
		var top_right = Vector2(pos.x + size.x, pos.y)
		_draw_half_circle_advanced(to_canvas_item, top_left, top_right, "up")
		
		# 3. 下半圆
		var bottom_left = Vector2(pos.x, pos.y + size.y)
		var bottom_right = Vector2(pos.x + size.x, pos.y + size.y)
		_draw_half_circle_advanced(to_canvas_item, bottom_left, bottom_right, "down")

		if border_width > 0:
			# 上下边界
			RenderingServer.canvas_item_add_polyline(
				to_canvas_item, [top_left, bottom_left], [border_color], border_width, true
			)
			RenderingServer.canvas_item_add_polyline(
				to_canvas_item, [top_left, bottom_right], [border_color], border_width, true
			)

	else:
		# 2. 左半圆
		var left_top = Vector2(pos.x , pos.y)
		var left_bottom = Vector2(pos.x , pos.y + size.y)
		_draw_half_circle_advanced(to_canvas_item, left_top, left_bottom, "left")
		
		# 3. 右半圆
		var right_top = Vector2(pos.x + size.x , pos.y)
		var right_bottom = Vector2(pos.x + size.x, pos.y + size.y)
		_draw_half_circle_advanced(to_canvas_item, right_top, right_bottom, "right")
		
		if border_width > 0:
			# 左右边界
			RenderingServer.canvas_item_add_polyline(
				to_canvas_item, [left_top, right_top], [border_color], border_width, true
			)
			RenderingServer.canvas_item_add_polyline(
				to_canvas_item, [left_bottom, right_bottom], [border_color], border_width, true
			)

#direct: "left" , "right" , "up" , "down"
func _draw_half_circle_advanced(to_canvas_item: RID, point_a: Vector2, point_b: Vector2, 
							   direct: String, fill: bool = true, draw_border: bool = true) -> void:
	"""
	高级版本：可以控制是否填充和绘制边框
	
	Args:
		point_a, point_b: 直径端点
		direct: 凸出方向
		fill: 是否填充
		draw_border: 是否绘制边框
	"""
	
	if point_a == point_b:
		return
	
	# 计算圆心和半径
	var center = (point_a + point_b) / 2.0
	var radius = point_a.distance_to(point_b) / 2.0
	
	# 确定角度范围
	var angles = _get_half_circle_angles(direct)
	if angles == []:
		return
	
	var start_angle = angles[0]
	var end_angle = angles[1]
	
	# 生成点集
	var points = PackedVector2Array()
	var segments = smoothness
	
	for i in range(segments + 1):
		var angle = start_angle + ((end_angle - start_angle) * i / segments)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	
	# 如果需要填充，需要闭合多边形
	if fill:
		# 对于填充，需要确保多边形闭合
		var fill_points = points.duplicate()
		
		# 根据方向闭合多边形
		match direct:
			"up":
				# 向上凸出：连接两端点形成闭合
				fill_points.append(point_b)
				fill_points.append(point_a)
			"down":
				# 向下凸出：连接两端点形成闭合
				fill_points.append(point_a)
				fill_points.append(point_b)
			"left":
				# 向左凸出：point_a在上，point_b在下
				fill_points.append(point_b)
				fill_points.append(point_a)
			"right":
				# 向右凸出：point_a在下，point_b在上
				fill_points.append(point_a)
				fill_points.append(point_b)
		
		fill_points.append(points[0])  # 闭合回起点
		RenderingServer.canvas_item_add_polygon(to_canvas_item, fill_points, [fill_color])
	
	# 绘制边框
	if draw_border and border_width > 0:
		RenderingServer.canvas_item_add_polyline(
			to_canvas_item, points, [border_color], border_width, true
		)
	
func _get_half_circle_angles(direct: String) -> Array:
	"""获取半圆的角度范围"""
	match direct:
		"up":
			return [PI, 2 * PI]  # 180°到360°
		"down":
			return [0.0, PI]  # 0°到180°
		"left":
			return [PI / 2, 3 * PI / 2]  # 90°到270°
		"right":
			return [3 * PI / 2, 5 * PI / 2]  # 270°到450°（相当于-90°到90°）
		_:
			return []
