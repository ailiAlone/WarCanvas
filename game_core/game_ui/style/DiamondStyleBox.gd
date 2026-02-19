@tool  # 重要：允许脚本在编辑器中运行
class_name DiamondStyleBox  # 定义类名，方便在资源中识别
extends StyleBox

@export var fill_color: Color = Color(0.94, 0.94, 0.96, 0.53)  # 菱形的填充颜色
@export var border_color: Color = Color(0.65, 0.94, 0.92, 0.89)  # 菱形边框颜色
@export var border_width: float = 2.0  # 边框宽度
@export var corner_ratio: float = 0.9  # 菱形尖锐度 (0.5-1.0)

# 当导出属性改变时，通知Godot更新显示
func _validate_property(property: Dictionary) -> void:
	if property.name == "corner_ratio":
		property.hint = PROPERTY_HINT_RANGE
		property.hint_string = "0.5,1.0,0.01"

# 核心绘制函数
func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var size = rect.size
	# 关键：计算外扩系数，使菱形能触及矩形边界
	var expand_factor = 1.0 / corner_ratio if corner_ratio > 0 else 1.0
	var half_width = size.x / 2 * expand_factor
	var half_height = size.y / 2 * expand_factor
	
	 # 顶点计算（现在菱形会超出矩形）
	var points = PackedVector2Array([
		Vector2(size.x/2, -size.y + size.y/2),      # 上（超出顶部）
		Vector2(size.x/2 + size.x, size.y/2),        # 右（超出右侧）
		Vector2(size.x/2, size.y/2 + size.y),       # 下（超出底部）
		Vector2(size.x/2 - size.x, size.y/2)         # 左（超出左侧）
	])
	 # 启用裁剪，防止绘制到控件外
	# RenderingServer.canvas_item_set_clip(to_canvas_item, true)
	# 绘制填充的菱形
	RenderingServer.canvas_item_add_polygon(
		to_canvas_item, 
		points, 
		[fill_color]
	)
	
	# 如果设置了边框宽度，则绘制边框
	if border_width > 0:
		# 闭合边框（在末尾添加第一个点）
		var border_points = points.duplicate()
		border_points.append(points[0])
		
		RenderingServer.canvas_item_add_polyline(
			to_canvas_item,
			border_points,
			[border_color],
			border_width,
			true  # antialiased抗锯齿
		)

# 可选：获取内容区域的矩形（用于调整子控件位置）
func get_draw_rect(rect: Rect2) -> Rect2:
	# 可以根据需要缩小内容区域，避免内容紧贴菱形边缘
	var padding = border_width + 5
	return Rect2(
		rect.position + Vector2(padding, padding),
		rect.size - Vector2(padding * 2, padding * 2)
	)
