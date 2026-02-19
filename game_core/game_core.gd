extends Node3D

# 引用地形生成器
@onready var gpu_terrain = $GPU_Terrain
@onready var ui = $UI

func _init() -> void:
	UnitData.WeaponInfo.load_all_weapon_info()
	BuildingData._ensure_initialized()
	RecipeData.ensure_recipes_loaded()
	ItemData.ensure_item_templates_loaded()

func _ready():
	gpu_terrain.init_blank_terrain({
		"map_width": GameState.map_width,
		"map_height": GameState.map_height,
	},false)
	
	# 从全局状态获取初始化数据
	var init_data = GameState.get_game_init_data()

	GameState.init_gamestate(self,GameState.WorldMode.RUNNING,init_data["map_path"])
	$Camera3D.reset()
		
	# 初始化玩家
	_initialize_players(init_data["player_configs"])
	
	#开始新游戏
	Turn._init()

func _initialize_players(player_configs):
		
	for index in player_configs.size():
		var config = player_configs[index]
		var settlement = HeadquarterManager.create_settlement(config.is_player)
		var grid = GameState.grid_manager.get_grid_by_map(config.init_position.x, config.init_position.y)

		# 如果是玩家控制的定居点，设置玩家ID
		if settlement._is_player:
			GameState.player_id = settlement._id
		
		# 生成初始建筑
		for building_id in config.initial_buildings:
			settlement.generate_building(building_id, grid, 0)
	
	if GameState.game_init_data["debug_mode"]:
		$UI/MenuUI.init_debug_list()
	else:
		$UI/MenuUI.debug_list.hide()
	
