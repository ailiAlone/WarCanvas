extends Node3D
class_name RayUtil

# 射线检测配置
const ray_length: float = 1000.0
static var exclusion_UI_List:Array[Control] = []

static var _camera: Camera3D = null
static var _viewport: Viewport = null
static var _world_3d: World3D = null

static func reset(viewport: Viewport,ui:Control):
	# 重置排除UI列表
	exclusion_UI_List.clear()

	# 遍历UI节点，将所有可见的Control节点添加到排除列表 不能直接添加ui节点
	for child in ui.get_children():
		if child is Control:
			exclusion_UI_List.append(child)

	# 重置视口引用
	_viewport = viewport
	if _viewport == null:
		push_error("No viewport available")
		return false

	# 重置相机引用
	_camera = viewport.get_camera_3d()
	if _camera == null:
		print("Error: No camera available for ray casting")
		return

	# 重置世界引用
	_world_3d = viewport.get_world_3d()
	if _world_3d == null:
		push_error("No World3D available")
		return false

# 向y轴发射射线并返回碰撞点的y坐标
static func raycast_to_y(x: float, z: float) -> float:
	var space_state = _world_3d.direct_space_state
		
	# 定义射线起点和终点
	# 从高处向低处发射射线
	var from = Vector3(x, ray_length, z)
	var to = Vector3(x, -ray_length, z)
	
	# 执行射线投射
	var result = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
	
	# 如果有碰撞，返回碰撞点的y坐标，否则返回0
	if result:
		return result.position.y + 0.3
	else:
		return 0.0

# 获取鼠标射线与地形的交点坐标
# 成功返回交点位置 Vector3
# 失败返回 null
static func get_mouse_raycast_hit():
	# 获取鼠标在3D空间中的位置
	if _viewport == null:
		return null
	var mouse_pos = _viewport.get_mouse_position()

	# 检查鼠标是否在UI控件上（包括主菜单和子菜单）
	for control in exclusion_UI_List:
		if control.visible and control.get_global_rect().has_point(mouse_pos):
			return null
	
	# 创建一个从摄像机出发的射线
	var ray_origin = _camera.project_ray_origin(mouse_pos)
	var ray_direction = _camera.project_ray_normal(mouse_pos)
	
	# 计算与地形的交点
	var space_state = _world_3d.direct_space_state
	var params = PhysicsRayQueryParameters3D.new()
	params.from = ray_origin
	params.to = ray_origin + ray_direction * ray_length
	
	var result = space_state.intersect_ray(params)
		# 如果有交点，返回交点位置，否则尝试从有效点栈中获取
	if result.has("position"):
		return result["position"]
	else:
		return null

static func is_mouse_over_ui() -> bool:
	var mouse_pos = _viewport.get_mouse_position()
	# 检查鼠标是否在UI控件上（包括主菜单和子菜单）
	for control in exclusion_UI_List:
		if control.visible and control.get_global_rect().has_point(mouse_pos):
			return true
	return false

# 获取从屏幕中心射出的射线与地形的交点
# 成功返回交点位置 Vector3
# 失败返回 null
static func get_center_ray_intersection():
	# 获取屏幕中心点
	var screen_center = _viewport.size / 2

	# 从摄像机发射射线
	var ray_origin = _camera.project_ray_origin(screen_center)
	var ray_direction = _camera.project_ray_normal(screen_center)
	
	# 创建一个空间状态对象来执行射线检测
	var space_state = _world_3d.direct_space_state
	var ray_query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * ray_length)
	
	# 执行射线检测
	var result = space_state.intersect_ray(ray_query)
	
	# 如果有交点，返回交点位置，否则尝试从有效点栈中获取
	if result.has("position"):
		return result["position"]
	else:
		return null
