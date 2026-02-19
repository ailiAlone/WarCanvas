extends Node

var grid_manager: GridManager = null

var map_width: int = 100
var map_height: int = 100
var cell_size: float = 1.0   # 点与点之间的距离，1.0f

var _world_node:Node3D = null
var _world_mode: WorldMode = WorldMode.STANDBY

# 玩家ID，默认为1
var player_id: int = -1

enum WorldMode{
	STANDBY,
	RUNNING,
	MAP_EDIT,
	DEBUG
}

func reset_size(p_map_width: int, p_map_height: int, p_cell_size: float):
	map_width = p_map_width
	map_height = p_map_height
	cell_size = p_cell_size

func init_gamestate(world_node:Node3D,world_mode:WorldMode,map_path:String = ""):
	_world_node = world_node
	_world_mode = world_mode

	RayUtil.reset(_world_node.get_viewport(),world_node.ui)

		
	grid_manager = GridManager.new()

	if _world_mode == WorldMode.RUNNING:
		if map_path == "":
			push_error("未指定地图文件路径！！！")
			return
		load_map_data(map_path)

# 暂时将数据存储在这里，以后将会移动到正确的位置
# 存储游戏初始化数据
var game_init_data = {
	"map_path": "res://data/map_data/test5.map",
	"debug_mode": true,
	"player_configs": [
		{
			"ID": 1,
			"is_player": true,
			# "init_position": Vector2i(41,12),
			"init_position": Vector2i(38,43),
			"initial_buildings": ["MEDIUM_HOUSE"]
		},
		{
			"ID": 2,
			"is_player": false,
			"init_position": Vector2i(38,50),
			"initial_buildings": ["MEDIUM_HOUSE"]
		}
	],
}

# 设置游戏初始化数据
func set_game_init_data(data:Dictionary):
	game_init_data = data

# 获取游戏初始化数据
func get_game_init_data() -> Dictionary:
	return game_init_data


func get_world_node():
	return _world_node

# 检查指定玩家ID是否是友方玩家
func is_friendly_player(check_player_id: int) -> bool:
	# 如果是当前玩家，则视为友方
	for headquarter in HeadquarterManager.headquarters.to_array_from_head():
		if headquarter._id == player_id:
			if headquarter.friend_relations.has(check_player_id):
				return true
	
	# 这里可以添加更多友方判断逻辑，例如：
	# - 检查是否是盟友
	# - 检查外交关系等
	# 目前简单实现：只有当前玩家是友方，其他都是敌方
	return false

# 测试函数，在地图编辑中被调用
func test():
	var map_data = {
		"map_width": 256,
		"map_height": 256,
		"cell_size": cell_size,
	}
	_world_node.gpu_terrain._initialize_subsystems(false)
	_world_node.gpu_terrain.set_params({
		"map_width": map_data["map_width"],
		"map_height": map_data["map_height"],
		"cell_size": map_data["cell_size"],
		"seed_value": randi() % 10000 +1000
	})
	print("种子: %d" % _world_node.gpu_terrain.seed_value)

	_world_node.gpu_terrain._generator.generate_terrain()
	_world_node.gpu_terrain.update()
	var height_map_float_data: PackedFloat32Array = _world_node.gpu_terrain.get_heightmap()
		
	var grids = GridUtils.generate_grid_by_heightmap(height_map_float_data, Vector2(map_data["map_width"], map_data["map_height"]), cell_size, _world_node.gpu_terrain.elevation_scale)
	map_data["grids"] = grids

	map_width = map_data["map_width"]
	map_height = map_data["map_height"]
	cell_size = map_data["cell_size"]

	grid_manager.load_from_data(map_data)

# 加载数据（简化版本）
func load_map_data(file_path: String) -> bool:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("无法打开文件: ", file_path)
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("JSON解析失败: ", parse_result)
		return false
	
	var data: Dictionary = json.get_data()
	
	# 设置基础参数
	map_width = data["map_width"]
	map_height = data["map_height"]
	cell_size = data["cell_size"]
	var elevation_scale = data.get("elevation_scale", 10.0)
	
	# 加载高度图数据到GPU_Terrain

	var heightmap_bytes = Marshalls.base64_to_raw(data["heightmap_data"])
	_world_node.gpu_terrain.set_params({
		"map_width": map_width,
		"map_height": map_height,
		"cell_size": cell_size,
		"elevation_scale": elevation_scale,
	})
	_world_node.gpu_terrain.load_heightmap_data(heightmap_bytes)
	_world_node.gpu_terrain.set_seed_value(data["seed_value"])
	
	# 加载网格数据
	if not grid_manager.load_from_data(data):
		return false
	
	return true

# 保存数据
# 保存数据（简化版本）
func save_map_data(file_path: String) -> bool:
	# 获取GPU_Terrain的高度图数据
	var heightmap_data = ""
	if _world_node.gpu_terrain:
		var heightmap_bytes = _world_node.gpu_terrain.get_heightmap_data()
		heightmap_data = Marshalls.raw_to_base64(heightmap_bytes)
	
	# 获取网格数据
	var grids_data = grid_manager.get_save_data()
	
	# 获取种子值
	var seed_value = 42  # 默认值
	if _world_node.gpu_terrain:
		seed_value = _world_node.gpu_terrain.seed_value
	
	# 合并数据
	var final_data = {
		"godot_version": "4.4.1",
		"map_width": map_width,
		"map_height": map_height,
		"cell_size": cell_size,
		"elevation_scale": _world_node.gpu_terrain.elevation_scale,
		"seed_value": seed_value,
		"heightmap_data": heightmap_data,
		"grids": grids_data
	}
	
	var json_string = JSON.stringify(final_data, "\t")
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		print("无法创建文件: ", file_path)
		return false
	
	file.store_string(json_string)
	file.close()
	
	print("成功保存地图数据到: ", file_path)
	return true
	
# 地图文件为JSON格式，包含以下字段（简化版本）：
# 开发时所用godot版本："godot_version": "4.4.1"
# 地图宽度："map_width": 500
# 地图高度："map_height": 500
# 单元格大小："cell_size": 1.0
# 高度缩放："elevation_scale": 10.0
# 随机种子："seed_value": 42
# 高度图数据（Base64编码）："heightmap_data": "base64_encoded_data"
# 网格数据数组："grids": [
#     {
#         "chunk_x": 0,              # 区块X坐标
#         "chunk_z": 0,              # 区块Z坐标
#         "tree_density": 0.6,       # 树木密度
#         "grid_type": "TYPE_DARK_GRASS", # 网格类型
#         "owner_id": -1             # 归属势力ID
#     },
#     ...
# ]
