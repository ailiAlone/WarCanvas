class_name Headquarter
extends Node

signal population_changed
signal buildings_changed
signal inventory_changed
signal production_line_changed

var _id: int = -1

var _is_player: bool = false
# 作战部列表
var battalions: Array[Battalion] =[]
# 人口系统
var population: Population = null
# 生产系统
var production: Production = null
# 资源系统
var inventory: ItemStock = null

var friend_relations: Dictionary = {}

func _init(player_id:int,is_player:bool = false,data:Dictionary = {}):
	# 初始化id
	_id = player_id
	_is_player = is_player
	# 初始化资源系统
	if data != {} and "inventory" in data:
		inventory = ItemStock.new(self,data["inventory"],data["money"])
	else:
		inventory = ItemStock.new(self)  # 初始金钱和食物
	# 初始化一些基本物品
	_initialize_starting_items()  #  # 初始金钱和食物

	if data != {} and "population" in data and "military" in data:
		population = Population.new(self,data["population"],data["military"])
	else:
		population = Population.new(self,120,30)
	# 初始化生产系统
	production = Production.new(self)

# 总部回合开始
func on_turn_start():
	production.on_turn_start()
	population.on_turn_start()
	
	if not _is_player:
		# AI回合：执行AI逻辑并等待回合结束
		await get_tree().create_timer(0.5).timeout
		await AIStrategy.execute_ai_turn(self)
	else:
		# 玩家回合：等待玩家操作结束
		print("开始玩家回合 - 总部ID: ", _id)
		# 玩家回合需要等待玩家手动结束回合
		# 这里不需要额外的等待逻辑，因为玩家会通过UI手动结束回合
	

func generate_battalion(unit_info:UnitData.UnitInfo,grid:Grid):
	var battalion = Battalion.new(unit_info,self,grid)
	# 添加到battalions数组中
	battalions.append(battalion)
	add_child(battalion)
	# 调用generate_model方法生成模型
	battalion.unit.generate_model()

func get_generate_Battalion_grids() -> Array[Grid]:
	push_error("headquarter %d ,未重写get_generate_Battalion_grids()函数",_id)
	return []

# 初始化起始物品
func _initialize_starting_items():
	# 添加一些基本资源
	inventory.set_item_quantity("WHEAT", 200)
	inventory.set_item_quantity("MEAT", 100)
	inventory.set_item_quantity("WOOD", 100)
	inventory.set_item_quantity("PLANK", 40)
	inventory.set_item_quantity("STONE_ORE", 30)
	inventory.set_item_quantity("STONE_BRICK", 30)
