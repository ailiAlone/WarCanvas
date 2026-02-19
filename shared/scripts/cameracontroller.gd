extends Camera3D

class_name CameraController

# 摄像头参数
@export var rotation_speed: float = 0.005
@export var move_speed: float = 200.0
@export var zoom_speed: float = 5.0  # 位置缩放速度
@export var base_fov: float = 75.0

const MIN_DISTANCE: float = 10.0   # 最小距离（最近）
const MAX_DISTANCE: float = 300.0  # 最大距离（最远）

# 摄像头位置和旋转
# 水平角度：围绕Y轴的左右旋转 0.0为正前方 受鼠标移动控制
var horizontal_angle: float = 0.0
# 垂直角度：围绕X轴的上下旋转 0.5为正上方 受鼠标移动控制
var vertical_angle: float = 0.5
# 当前摄像机到目标点的距离 受滚轮控制
var target_distance: float = 100.0  

# 输入状态
var _is_rotating: bool = false
var _moving_forward: bool = false
var _moving_backward: bool = false
var _moving_left: bool = false
var _moving_right: bool = false

# 目标点
var _target_position: Vector3

# 有效目标点栈管理
var _valid_target_points: Array[Vector3] = []  # 有效目标点栈
var _record_timer: float = 0.0  # 记录计时器
var _record_ready: bool = false  # 记录就绪状态，true为激活态，false为冷却态
const RECORD_INTERVAL: float = 0.3  # 记录间隔(秒)
const MAX_STACK_SIZE: int = 10  # 栈最大容量

func _ready():
	reset()
	# 连接输入信号
	InputManager.mouse_moved.connect(_on_mouse_moved)
	InputManager.mouse_wheel.connect(_on_mouse_wheel)
	InputManager.mouse_right_pressed.connect(_on_mouse_right_pressed)
	InputManager.key_w_pressed.connect(_on_key_w_pressed)
	InputManager.key_s_pressed.connect(_on_key_s_pressed)
	InputManager.key_a_pressed.connect(_on_key_a_pressed)
	InputManager.key_d_pressed.connect(_on_key_d_pressed)

# 重置摄像头位置和朝向
func reset():
	# 重置所有状态
	_is_rotating = false
	_moving_forward = false
	_moving_backward = false
	_moving_left = false
	_moving_right = false
	
	# 重置角度和距离
	horizontal_angle = 0.0
	vertical_angle = 0.5
	target_distance = 100.0
	
	# 重置有效点栈
	_valid_target_points.clear()
	_record_timer = 0.0
	_record_ready = false
	
	# 使用地图中心作为目标位置
	_target_position = Vector3(GameState.map_width/2, 0, GameState.map_height/2)
		
	# 更新摄像机位置
	update_camera_position()
	
	# 让摄像机看向目标点
	look_at(_target_position, Vector3.UP)

# 更新摄像机位置（基于目标点、角度和距离）
func update_camera_position():
	var new_x = _target_position.x + target_distance * sin(horizontal_angle) * sin(vertical_angle)
	var new_y = _target_position.y + target_distance * cos(vertical_angle)
	var new_z = _target_position.z + target_distance * cos(horizontal_angle) * sin(vertical_angle)
	
	position = Vector3(new_x, new_y, new_z)
	look_at(_target_position, Vector3.UP)

	# 发射相机移动信号
	EventBus.camera_moved.emit(position)

func _process(delta):
	_handle_camera_movement(delta)

func _handle_camera_rotation(delta: Vector2):
	# 只更新水平角度，实现围绕Y轴的左右旋转 （水平角度不受限制）
	horizontal_angle -= delta.x * rotation_speed
	# 只更新垂直角度，实现围绕X轴的上下旋转
	vertical_angle -= delta.y * rotation_speed
	vertical_angle = clamp(vertical_angle, 0.1, 0.9)  # 限制垂直角度在合理范围内
	
	# 更新摄像机位置（基于目标点、角度和距离）
	update_camera_position()

# 获取从屏幕中心射出的射线与地形的交点
func get_center_ray_intersection():
	# 获取屏幕中心点
	var viewport = get_viewport()
	var screen_center = viewport.size / 2
	
	# 从摄像机发射射线
	var ray_origin = project_ray_origin(screen_center)
	var ray_direction = project_ray_normal(screen_center)
	
	# 创建一个空间状态对象来执行射线检测
	var space_state = get_world_3d().direct_space_state
	var ray_query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * 1000)
	
	# 执行射线检测
	var result = space_state.intersect_ray(ray_query)
	
	# 如果有交点，返回交点位置，否则尝试从有效点栈中获取
	if result.has("position"):
		return result["position"]
	else:
		return null

# 处理相机移动
func _handle_camera_movement(delta):
	var input = Vector3()
	
	# 根据距离计算移动速度倍率（距离越近移动越慢，距离越远移动越快）
	var distance_ratio = target_distance / 100.0  # 以100为基准
	var adjusted_speed = move_speed * distance_ratio

	# 获取摄像机的前方向量和右方向量（投影到 XZ 平面）
	var forward = transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	
	var right = transform.basis.x
	right.y = 0
	right = right.normalized()

	if _moving_forward:
		input -= forward * adjusted_speed * delta
	if _moving_backward:
		input += forward * adjusted_speed * delta
	if _moving_left:
		input -= right * adjusted_speed * delta
	if _moving_right:
		input += right * adjusted_speed * delta

	if input != Vector3.ZERO:
		var new_target = _target_position + input
		
		if new_target.x >= 0 and new_target.x < GameState.map_width and \
		   new_target.z >= 0 and new_target.z < GameState.map_height:
			_target_position = new_target
			update_camera_position()

			EventBus.camera_moved.emit(position)

# 鼠标滚轮信号处理
func _on_mouse_wheel(direction: int):
	if RayUtil.is_mouse_over_ui():
		return

	var delta = -direction * zoom_speed

	target_distance = clamp(target_distance + delta, MIN_DISTANCE, MAX_DISTANCE)
	update_camera_position()

# 鼠标移动信号处理
func _on_mouse_moved(position: Vector2, delta: Vector2):
	if _is_rotating:
		_handle_camera_rotation(delta)

# 鼠标右键按下信号处理
func _on_mouse_right_pressed(pressed: bool):
	_is_rotating = pressed

# W键按下信号处理
func _on_key_w_pressed(pressed: bool):
	_moving_forward = pressed

# S键按下信号处理
func _on_key_s_pressed(pressed: bool):
	_moving_backward = pressed

# A键按下信号处理
func _on_key_a_pressed(pressed: bool):
	_moving_left = pressed

# D键按下信号处理
func _on_key_d_pressed(pressed: bool):
	_moving_right = pressed
