extends Node3D

@onready var sub_viewport: SubViewport = $SubViewport
@onready var sprite_3d: Sprite3D = $Sprite3D
@onready var battalion_badge_ui: Control = $SubViewport/BattalionBadgeUI
@onready var margin_container: MarginContainer = $SubViewport/BattalionBadgeUI/MarginContainer

var _battalion: Battalion

# 初始化方法，接收battalion参数并设置UI文本
func initialize(battalion: Battalion):
	if battalion == null:
		return
	
	_battalion = battalion
	update_info()


# 更新营队信息显示
func update_info():
	if _battalion == null:
		return
	
	# 设置UI名称
	battalion_badge_ui.set_name_label("营队")
	
	# 设置UI兵力
	if _battalion.unit != null and _battalion.unit.info != null:
		battalion_badge_ui.set_strength_label("兵力:" + str(_battalion.unit.info.armySize))
	else:
		battalion_badge_ui.set_strength_label("兵力:0")
