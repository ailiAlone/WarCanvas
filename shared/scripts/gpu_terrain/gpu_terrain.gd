extends MeshInstance3D
class_name GPU_Terrain

enum EditMode { FLATTEN = 0, RAISE = 1, LOWER = 2, SCULPT = 3, SMOOTH = 4 }

# ===== 配置参数 =====
@export_category("地图设置")
@export var map_width: int = 500
@export var map_height: int = 500
@export var cell_size: float = 1.0
const COMPUTE_LOCAL_SIZE: int = 16

@export_category("高度设置")
@export var elevation_scale: float = 20.0
@export var frequency: float = 0.007
@export var octaves: int = 4
@export var persistence: float = 0.7
@export var lacunarity: float = 1.6
@export var seed_value: int = 1341

@export_category("编辑设置")
@export var edit_mode: EditMode = EditMode.FLATTEN
@export var terrain_editable: bool = true

#数据
var _height_byte_data: PackedByteArray
var _height_float_data: PackedFloat32Array

# ===== 子系统 =====
var _renderer: Terrain_Renderer
var _generator: Terrain_Generator
var _editor: Terrain_Editer

# ===== 状态 =====
var _rd: RenderingDevice
var _height_buffer: RID

# 仅用于初始化地形（生成空白地形） 主要设置 尺寸 和 是否可以编辑
# 
# 初始化地形，包括生成器、渲染器、编辑器和高度缓冲区
func init_blank_terrain(params:Dictionary = {},editable:bool = false):
	_initialize_subsystems(editable)

	set_params(params)

	_height_byte_data = PackedByteArray()
	_height_byte_data.resize(map_width * map_height * 4)  # float = 4 bytes

	_height_float_data = PackedFloat32Array()
	_height_float_data.resize(map_width * map_height)  # float = 4 bytes
	
	# 相当于传入了一片空白的高度图
	_renderer.update_heightmap_texture(_height_byte_data)
	_renderer.update_heightmap_collision(_height_float_data)

func _initialize_subsystems(editable:bool):
	_rd = RenderingServer.create_local_rendering_device()

	_renderer = Terrain_Renderer.new(self)
	
	terrain_editable = editable
	if terrain_editable:
		_editor = Terrain_Editer.new(_rd)

	_generator = Terrain_Generator.new(_rd)

# 设置全部参数 同时会初始化高度缓冲区
func set_params(params: Dictionary):

	params["map_width"] = params.get("map_width",map_width)
	params["map_height"] = params.get("map_height",map_height)
	params["cell_size"] = params.get("cell_size",cell_size)
	params["elevation_scale"] = params.get("elevation_scale",elevation_scale)
	params["frequency"] = params.get("frequency",frequency)
	params["octaves"] = params.get("octaves",octaves)
	params["persistence"] = params.get("persistence",persistence)
	params["lacunarity"] = params.get("lacunarity",lacunarity)
	params["seed_value"] = params.get("seed_value",seed_value)

	map_width = params["map_width"]
	map_height = params["map_height"]
	cell_size = params["cell_size"]
	elevation_scale = params["elevation_scale"]
	frequency = params["frequency"]
	octaves = params["octaves"]
	persistence = params["persistence"]
	lacunarity = params["lacunarity"]
	seed_value = params["seed_value"]

	_renderer._setup(params)
	position = Vector3(map_width * cell_size / 2, 0, map_height * cell_size / 2)
	# $StaticBody3D/CollisionShape3D.position =  Vector3(map_width * cell_size / 2, 0, map_height * cell_size / 2)
	if not _height_buffer.is_valid():
		_rd.free_rid(_height_buffer)

	_height_buffer = _create_height_buffer()
	_generator._setup(_height_buffer, params)
	if terrain_editable:
		_editor._setup(_height_buffer, params)

func _create_height_buffer() -> RID:
	var size = map_width * map_height
	var empty_data = PackedByteArray()
	empty_data.resize(size * 4)  # float = 4 bytes
	
	var buffer = _rd.storage_buffer_create(empty_data.size(), empty_data)
	
	return buffer

# 应用数据到渲染器
func update():
	_height_byte_data = _rd.buffer_get_data(_height_buffer)
	_renderer.update_heightmap_texture(_height_byte_data)
	_height_float_data = _height_byte_data.to_float32_array()
	_renderer.update_heightmap_collision(_height_float_data)

func get_height_at(x: int, y: int) -> float:
	"""根据坐标获取高度值
	
	参数:
		x: 宽度方向坐标
		y: 高度方向坐标
	
	返回:
		float: 该坐标处的高度值，如果坐标无效返回 0.0
	"""
	if x < 0 or x >= map_width or y < 0 or y >= map_height:
		return 0.0
	
	var index = y * map_width + x
	
	# 优先使用预计算的 _height_float_data
	if _height_float_data and index < _height_float_data.size():
		return _height_float_data[index]
	
	return 0.0

func get_heightmap() -> PackedFloat32Array:
	return _height_float_data

# 获取高度图数据（用于保存）
func get_heightmap_data() -> PackedByteArray:
	return _height_byte_data

# 加载高度图数据（用于加载）
func load_heightmap_data(heightmap_data: PackedByteArray):
	_height_byte_data = heightmap_data
	_height_float_data = _height_byte_data.to_float32_array()
	_renderer.update_heightmap_texture(_height_byte_data)
	_renderer.update_heightmap_collision(_height_float_data)

# 获取种子值（用于保存）
func get_seed_value() -> int:
	return seed_value

# 设置种子值（用于加载）
func set_seed_value(new_seed: int):
	seed_value = new_seed

func _exit_tree() -> void:
	_cleanup_resources()

func _cleanup_resources():
	# 释放子系统资源
	if _editor:
		_editor._cleanup()
	if _generator:
		_generator._cleanup()
	if _renderer:
		_renderer._cleanup()
	
	# 释放主 Buffer
	if _rd and _height_buffer.is_valid():
		_rd.free_rid(_height_buffer)
		_height_buffer = RID()
	
	# 释放 RenderingDevice（必须在所有 RID 释放后）
	if _rd:
		_rd.free_rid(_rd)
		_rd = null

func _free():
	_cleanup_resources()
