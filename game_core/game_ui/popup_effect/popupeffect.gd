class_name PopupEffect
extends Control

@onready var label = $MarginContainer/Label
@onready var anim_player = $AnimationPlayer

## 单独测试用
# func _ready():
	# label.text = "新资源"
	# label.modulate = Color.YELLOW

	# anim_player.play("popup")
	
# 在3D世界位置显示效果
func show_at_3d_position(text: String, world_3d_pos: Vector3, color: Color = Color.WHITE):
	label.text = text
	label.modulate = color
	
	# 将3D世界坐标转换为2D屏幕坐标
	var screen_pos = get_viewport().get_camera_3d().unproject_position(world_3d_pos)
	position = screen_pos
	
	# 播放动画
	anim_player.play("popup")
	await anim_player.animation_finished
	queue_free()

func show_damage(amount: int, world_pos: Vector3, is_critical: bool = false):
	var color = Color.RED
	var text = str(amount)
	
	if is_critical:
		color = Color(1, 0.5, 0)  # 橙色
		text = "!" + text + "!"
		# 可以播放不同的动画
		$AnimationPlayer.play("popup_critical")
	
	show_at_3d_position(text, world_pos + Vector3(0, 1.5, 0), color)

func show_resource_gain(resource_name: String, amount: int, world_pos: Vector3):
	var text = "%s +%d" % [resource_name, amount]
	show_at_3d_position(text, world_pos + Vector3(0, 1.0, 0), Color.GREEN)  # 绿色表示获得

func show_resource_loss(resource_name: String, amount: int, world_pos: Vector3):
	var text = "%s -%d" % [resource_name, amount]
	show_at_3d_position(text, world_pos + Vector3(0, 1.0, 0), Color.RED)    # 红色表示消耗
