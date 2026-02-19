class_name Settlement
extends Headquarter

# 存储所有建筑的数组
var buildings: Array[Building] = []

var badge: Node3D = null

var governance_statuses: Dictionary = {
	"normal":{"active":true},								# 正常运作
	"restoring_order":{"active":false,"source":null},		# 进驻后正在创建秩序
	"under_siege":{"active":false},							# 被围城
	"partially_occupied":{"active":false},					# 部分失守（城门/兵营等）
	"clearing_resistance":{"active":false,"sources":{}},	# 正在肃清残余抵抗
	"abandoned":{"active":false},							# 空城状态（领主逃亡，全部人口和部分资源被带走）
	"rebellion":{"active":false,"level":0},					# 人口叛乱
	"anarchy":{"active":false},								# 无政府状态
}

var settlement_badge_scene = preload("res://game_core/game_ui/common/settlement_badge/settlement_badge.tscn")

func _init(player_id:int,is_player:bool = false):
	super(player_id,is_player)

func _ready():
	await generate_badge()

func generate_building(building_id: String, grid: Grid,constructer_count: int):
	var building_info = BuildingData.get_building_by_id(building_id)
	if building_info == null:
		push_error("错误：未找到ID为 %s 的建筑信息" % building_id)
		return
	var building = Building.new(building_info,grid,self,constructer_count)
	# 添加到场景树中
	add_child(building)
	# 设置建造施工场地
	building.create_construction_site()	

func get_generate_Battalion_grids() -> Array[Grid]:
	var neighbor_grids: Array[Grid] = []
	for building in buildings:
		# 只统计已经建成的建筑
		if not building.is_finished:
			continue
		var grids = GridUtils.get_grids_by_expansion(building.occupy_grid, 1)
		for grid in grids:
			if grid not in neighbor_grids and grid.holding_node3D == null:
				neighbor_grids.append(grid)
	return neighbor_grids

# 重写总部回合开始方法
func on_turn_start():
	# 调用父类方法
	super.on_turn_start()
	await get_tree().process_frame
	if badge != null:
		badge.update_badge()

func get_generate_building_grids() -> Array[Grid]:
	var neighbor_grids: Array[Grid] = []
	for building in buildings:
		# 只统计已经建成的且core值大于1的建筑
		if building.is_finished and building.building_info.core_value > 1:
			var grids = GridUtils.get_grids_by_expansion(building.occupy_grid, 2)
			for grid in grids:
				if grid not in neighbor_grids:
					neighbor_grids.append(grid)
	
	return neighbor_grids

func get_local_market() -> Dictionary:
	var local_market = {}
	for item_template in ItemData.get_all_item_templates():
		#获取每一种物品的供需率
		var demand_supply_rate = 1
		if production.supply_demand[item_template.id]["supply"] > 0:
			demand_supply_rate = production.supply_demand[item_template.id]["demand"] / production.supply_demand[item_template.id]["supply"]
			# 限制供需 对价格的影响率在(0.33, 3)范围内
			demand_supply_rate = clamp(demand_supply_rate, 0.33, 3)

		local_market[item_template.id] = {
			"price": item_template.base_price * demand_supply_rate
		}

	return local_market

func update_occypied_grids():
	# 先释放所有旧的占用
	GameState.grid_manager.free_grid_owner(_id)
	# 更新所有新的占用
	for grid in get_generate_building_grids():
		grid.set_owner_headquarter_id(_id)
	
	var battalion_grids = get_generate_Battalion_grids()
	for grid in battalion_grids:
		grid.set_owner_headquarter_id(_id)

#生成基础信息窗口
func generate_badge() -> void:
	badge = settlement_badge_scene.instantiate()
	add_child(badge)
	# 确保节点已添加到场景树后再调用set_building
	await get_tree().process_frame
	badge.initialize(self)

func get_buildings_is_finished_by_category(building_category: String) -> Array[Building]:
	var building_list: Array[Building] = []
	for building in buildings:
		if building.building_info.category == building_category and building.is_finished:
			building_list.append(building)
	return building_list

func get_buildings_is_not_finished_by_category(building_category: String) -> Array[Building]:
	var building_list: Array[Building] = []
	for building in buildings:
		if building.building_info.category == building_category and not building.is_finished:
			building_list.append(building)
	return building_list

func get_buildings_is_finished_by_id(building_id: String) -> Array[Building]:
	var building_list: Array[Building] = []
	for building in buildings:
		if building.building_info.id == building_id and building.is_finished:
			building_list.append(building)
	return building_list

func get_buildings_is_not_finished_by_id(building_id: String) -> Array[Building]:
	var building_list: Array[Building] = []
	for building in buildings:
		if building.building_info.id == building_id and not building.is_finished:
			building_list.append(building)
	return building_list
