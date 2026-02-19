extends Node3D

@onready var sub_viewport: SubViewport = $SubViewport
@onready var sprite_3d: Sprite3D = $Sprite3D
@onready var expedition_badge_ui: Control = $SubViewport/ExpeditionBadgeUI
@onready var margin_container: MarginContainer = $SubViewport/ExpeditionBadgeUI/MarginContainer

var _expedition: Expedition

# 初始化方法，接收expedition参数并设置UI文本
func initialize(expedition: Expedition):
	if expedition == null:
		return
	
	_expedition = expedition
	update_info()


# 更新军队信息显示
func update_info():
	if _expedition == null:
		return
	
	# 设置UI名称
	expedition_badge_ui.set_name_label("远征")
	
	# 设置UI人口
	expedition_badge_ui.set_population_label("人口:" + str(_expedition.population.get_total_population()))


	position += Vector3(0, 12, 0)
