class_name Expedition
extends Headquarter

var unit: Unit

func _init(player_id:int,is_player:bool = false,data:Dictionary = {}):
	super(player_id,is_player,data)

func _ready():
	pass

func on_turn_start():
	# 调用父类方法
	super.on_turn_start()

func generate_model(p_unit_info:UnitData.UnitInfo,grid:Grid):
	unit = Unit.new(p_unit_info,grid,self)
	add_child(unit)
	# 调用generate_model方法生成模型
	unit.generate_model()

func get_generate_Battalion_grids() -> Array[Grid]:
	var neighbor_grids: Array[Grid] = []
	var grids = GridUtils.get_grids_by_expansion(unit.occupy_grid, 1)
	for grid in grids:
		if grid.holding_node3D == null:
			neighbor_grids.append(grid)
	return neighbor_grids

func generate_camp()->void:
	#在当前网格生成一个营地
	var settlement = HeadquarterManager.create_settlement(_is_player)
	settlement.generate_building("CAMP_TENT", unit.occupy_grid,0)
	#设置新的定居地的数据
	
	#更新battalion的数据 遍历battalion，更新定居地的数据
	for battalion in battalions:
		settlement.battalions.append(battalion)
		battalion.headquarter = settlement
		# 将battalion节点从expedition移动到settlement
		remove_child(battalion)
		settlement.add_child(battalion)
	
	#更新population数据 - 创建新的population对象并复制数据
	settlement.population._idle_population = population.get_idle_population() + population.get_working_population()
	settlement.population._idle_military = population.get_idle_military()
	
	#更新inventory数据 - 创建新的inventory对象并复制数据
	for item_id in inventory.get_all_items():
		var quantity = inventory.get_item_quantity(item_id)
		settlement.inventory.set_item_quantity(item_id, quantity)

	#释放expedition的unit
	# 先清理网格引用
	if unit.occupy_grid != null:
		unit.occupy_grid.holding_node3D = null
	
	#结束当前回合
	CommandBus.execute_command(EndTurnCommand.new(self))


func occupy_settlement(target_settlement: Settlement)->void:
	var settlement = HeadquarterManager.create_settlement(_is_player)
	
	# 更新battalion的数据 - 遍历battalion，添加到目标定居点
	for battalion in battalions:
		settlement.battalions.append(battalion)
		battalion.headquarter = settlement
		# 将battalion节点从expedition移动到目标定居点
		remove_child(battalion)
		settlement.add_child(battalion)
	
	#遍历建筑物，添加到目标定居点
	for building in target_settlement.buildings:
		settlement.buildings.append(building)
		target_settlement.remove_child(building)
		settlement.add_child(building)
	
	# 更新population数据 - 将军队的人口和目标定居点的人口合并
	settlement.population._idle_population = population.get_idle_population() + target_settlement.population.get_idle_population() + target_settlement.population.get_working_population()
	settlement.population._idle_military += population.get_idle_military() #军事人口不合并
	
	# 更新inventory数据 - 将军队的物品添加到目标定居点
	for item_id in inventory.get_all_items():
		var quantity = inventory.get_item_quantity(item_id) + target_settlement.inventory.get_item_quantity(item_id)
		var existing_quantity = settlement.inventory.get_item_quantity(item_id) # 新定居点本应该没有任何物资，但是为了形式
		settlement.inventory.set_item_quantity(item_id, existing_quantity + quantity)
	

	# 先清理网格引用
	if unit.occupy_grid != null:
		unit.occupy_grid.holding_node3D = null
	
	# 更新网格的owner_headquarter_id
	for grid in target_settlement.get_generate_building_grids() + target_settlement.get_generate_Battalion_grids():
		grid.set_owner_headquarter_id(_id)
		
	GameState.player_id = settlement._id
	settlement.friend_relations = friend_relations

	#删除旧的headquarter
	HeadquarterManager.remove_headquarter(target_settlement)
	
	CommandBus.execute_command(EndTurnCommand.new(self))

	
