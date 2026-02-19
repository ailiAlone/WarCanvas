extends Node3D

@onready var sub_viewport: SubViewport = $SubViewport
@onready var sprite_3d: Sprite3D = $Sprite3D
@onready var settlement_badge_ui: Control = $SubViewport/SettlementBadgeUI
@onready var margin_container: MarginContainer = $SubViewport/SettlementBadgeUI/MarginContainer

var _settlement: Settlement = null
# 初始化方法，接收_settlement参数并设置UI文本
func initialize(settlement: Settlement):
	_settlement = settlement
	# settlement对象有一个id属性
	settlement_badge_ui.set_name_label("定居点" + str(settlement._id))

	update_badge()

func update_badge():
	#获取buildings中core最高的且已经完成建造的buildin的position
	var max_core_value = 1
	var pos = Vector3.ZERO
	for building in _settlement.buildings:
		if building.building_info.core_value > max_core_value and building.is_finished:
			max_core_value = building.building_info.core_value
			pos = building.position
	# 更新UI文本
	settlement_badge_ui.set_population_label(
		"人口:" + str(_settlement.population.get_total_population()) +
		"军力:" + str(_settlement.population.get_idle_military())
		)

	# 如果找到最高core值的建筑，更新Sprite3D的position
	if pos != Vector3.ZERO:
		position = pos + Vector3(0, 12, 0)
