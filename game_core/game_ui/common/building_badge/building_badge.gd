extends Node3D

@onready var sub_viewport: SubViewport = $SubViewport
@onready var sprite_3d: Sprite3D = $Sprite3D
@onready var building_badge_ui: Control = $SubViewport/BuildingBadgeUI
@onready var margin_container: MarginContainer = $SubViewport/BuildingBadgeUI/MarginContainer
var _building: Building

# 初始化方法，接收building参数并设置UI文本
func initialize(building: Building):
	if building == null:
		return
	_building = building
	update_info()


# 更新建筑信息显示
func update_info():
	if _building == null:
		return
	
	var info_text = ""
	
	# 添加建筑名称
	info_text += _building.building_info.name

	# 检查建筑是否完成建造
	if not _building.is_finished:
		# 添加建造状态信息
		info_text += "\n建造中（" + str(_building.health) + "/" + str(_building.building_info.max_health) + "）"
	
	# 设置UI文本
	building_badge_ui.set_text(info_text)
