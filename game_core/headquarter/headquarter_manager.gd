extends Node3D

var headquarters: CircularLinkedList = CircularLinkedList.new()
var current_headquarter_index: int = -1

# 创建一个新的定居点
func create_settlement(is_player: bool = false) -> Settlement:
	var settlement = Settlement.new(headquarters.size(),is_player)
	headquarters.append(settlement)
	add_child(settlement)
	return settlement

func create_expedition(grid: Grid,unit_info: UnitData.UnitInfo,data:Dictionary,is_player: bool = false,player_id: int=-1) -> Expedition:
	if player_id == -1:
		player_id = headquarters.size()
	var expedition = Expedition.new(player_id,is_player,data)
	if is_player:
		GameState.player_id = expedition._id
	headquarters.append(expedition)
	add_child(expedition)
	expedition.generate_model(unit_info,grid)
	return expedition

func remove_headquarter(headquarter:Headquarter):
	headquarters.remove(headquarter)
	remove_child(headquarter)

func get_current_headquarter() -> Headquarter:
	return headquarters.current()

func get_headquarter_in_order() -> Headquarter:
	return headquarters.next()

func get_headquarter_by_id(id: int) -> Headquarter:
	for headquarter in headquarters.to_array_from_head():
		if headquarter._id == id:
			return headquarter
	return null
