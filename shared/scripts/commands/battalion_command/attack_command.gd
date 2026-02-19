# 攻击命令
class_name AttackCommand
extends Command

var _attacker: Battalion
var _target_grid: Grid

func _init(headquarter: Headquarter, attacker: Battalion, target_grid: Grid):
	super(headquarter)
	_attacker = attacker
	_target_grid = target_grid
	
	# 设置命令属性
	name = "攻击"
	type = "battalion_command"
	detailinfo = "攻击者: " + attacker.unit.name + ", 目标位置: (" + str(target_grid.chunk_x) + ", " + str(target_grid.chunk_y) + ")"

func execute() -> void:
	super.execute()
	if status == Status.Failed:
		return
	print("执行攻击命令")
	
	# 检查攻击者和目标网格是否有效
	if _attacker == null:
		status = Status.Failed
		command_completed.emit()
		return
	
	if _target_grid == null:
		status = Status.Failed
		command_completed.emit()
		return
	
	# 检查目标网格上是否有单位
	if _target_grid.holding_node3D == null:
		status = Status.Failed
		command_completed.emit()
		return
	
	# 获取目标单位
	var target_unit = _target_grid.holding_node3D

	play_spear_wave(_attacker.unit.occupy_grid.center_point, _target_grid.center_point)


	# 执行攻击
	var damage_dealt = perform_attack(_attacker, target_unit)
	status = Status.Success
	command_completed.emit()



# 执行攻击逻辑
func perform_attack(attacker: Battalion, target: Unit) -> int:
	# 计算伤害值
	var damage = calculate_damage(attacker, target)
	
	# 应用伤害
	target.info.armySize -= damage
	
	print("对单位造成了 %d 点伤害" % [damage])
	var popup_effect = preload("res://game_core/game_ui/popup_effect/popupeffect.tscn").instantiate()
	GameState.get_world_node().add_child(popup_effect)
	# await GameState.get_world_node().get_tree().process_frame
	popup_effect.show_damage(damage, target.occupy_grid.center_point + Vector3.UP)

	# 检查目标是否被消灭
	if target.info.armySize <= 0:
		print("单位被消灭")
		handle_unit_defeat(target)
	
	# # 发出攻击事件信号
	# EventBus.emit_unit_attacked(attacker, target, damage)
	
	# 返回造成的伤害值
	return damage

# 计算伤害值
func calculate_damage(attacker: Battalion, target: Unit) -> int:
	# 基础伤害 = 攻击力 - 防御力
	var base_damage = (attacker.unit.attack - target.defense) 
	
	# 确保最小伤害为1
	base_damage = max(1, base_damage)
	
	# 添加随机因素 (0.8 ~ 1.2倍)
	var random_factor = 0.8 + randf() * 0.4
	
	# 最终伤害
	var final_damage = int(base_damage * random_factor) * attacker.unit.info.armySize
	
	return final_damage

# 处理单位被消灭的逻辑
func handle_unit_defeat(defeated_unit: Unit):
	# 从单位管理器中移除单位
	defeated_unit.queue_free()
	
	# 清除单位所在网格的引用
	if defeated_unit.occupy_grid != null:
		defeated_unit.occupy_grid.holding_node3D = null


# 播放枪阵攻击波
func play_spear_wave(from_cell_pos: Vector3, to_cell_pos: Vector3):
	# 计算攻击方向
	var attack_dir = (to_cell_pos - from_cell_pos).normalized()
	
	# 实例化粒子系统
	# 预加载粒子场景
	var spear_wave_particles = load("res://shared/resources/special_effects/spear_wave_particles.tscn")
	var particles = spear_wave_particles.instantiate()
	GameState.get_world_node().add_child(particles)
	
	particles.global_position = from_cell_pos

	particles.look_at(to_cell_pos + Vector3.UP * 2, Vector3.UP)
	particles.rotation.x -= 90.0
	
	# 发射粒子
	particles.emitting = true
	
	# 自动清理（生命周期结束后移除）
	await GameState.get_world_node().get_tree().create_timer(particles.lifetime + 0.1).timeout
	particles.queue_free()
