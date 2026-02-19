class_name UnitData

enum ArmorType{
	NONE,	#无甲
	LIGHT,	#轻甲
	HEAVY	#重甲
}

enum ShieldType{
	NONE,			#无盾
	WOOD_SHIELD,	#木盾
	IRON_SHIELD		#铁盾
}

class WeaponInfo:
	var id: String = ""
	var name: String = ""
	var model_path: String = ""
	var attackDistance: int = 0
	var isDualHolding: bool = false
	var damage: int = 0
	var armorPiercing: ArmorType = ArmorType.NONE
	var shieldBreaking: ShieldType = ShieldType.NONE

	static var weaponInfoList:Dictionary = {}

	static func load_all_weapon_info():
		# 从CSV文件读取武器数据
		var csv_file = FileAccess.open("res://shared/resources/weapons/weapons.csv", FileAccess.READ)
		if csv_file == null:
			push_error("错误：无法打开武器CSV文件")
			return
		
		# 读取CSV头
		var headers = csv_file.get_csv_line()
		
		# 读取每一行数据
		while !csv_file.eof_reached():
			var line = csv_file.get_csv_line()
			if line.size() < headers.size() or line[0] == "":
				continue
				
			# 解析CSV数据
			var id = line[0]  # ID
			var model_path = line[1]  # ModelPath
			var attack_distance = int(line[2]) if line[2] != "" else 1  # Attack_Distance
			var dual_holding = line[3].to_lower() == "true"  # DualHolding
			var armor_piercing = line[4]  # ArmorPiercing
			var shield_breaking = line[5]  # ShieldBreaking
			
			# 创建武器信息
			var weapon_info = WeaponInfo.new()
			weapon_info.id = id
			weapon_info.name = Locale.get_text(id)  # 从翻译管理器获取名称，如果没有翻译则使用ID
			weapon_info.model_path = model_path
			weapon_info.attackDistance = attack_distance
			weapon_info.isDualHolding = dual_holding
			weapon_info.damage = 10  # 默认伤害值，可以根据需要调整
			
			# 处理护甲穿透类型
			match armor_piercing:
				"LIGHT":
					weapon_info.armorPiercing = ArmorType.LIGHT
				"HEAVY":
					weapon_info.armorPiercing = ArmorType.HEAVY
				_:
					weapon_info.armorPiercing = ArmorType.NONE
			
			# 处理盾牌破坏类型
			match shield_breaking:
				"WOOD_SHIELD":
					weapon_info.shieldBreaking = ShieldType.WOOD_SHIELD
				"IRON_SHIELD":
					weapon_info.shieldBreaking = ShieldType.IRON_SHIELD
				_:
					weapon_info.shieldBreaking = ShieldType.NONE
			
			# 添加到武器信息列表
			weaponInfoList[weapon_info.id] = weapon_info
		
		csv_file.close()
		
		# 如果CSV中没有数据，添加一个默认武器
		if weaponInfoList.is_empty():
			var weapon_info = WeaponInfo.new()
			weapon_info.id = "SWORD"
			weapon_info.name = "剑"
			weapon_info.model_path = "res://shared/resources/weapons/weapon_models/sword/sword.fbx"
			weapon_info.attackDistance = 1
			weapon_info.isDualHolding = false
			weapon_info.damage = 10
			weapon_info.armorPiercing = ArmorType.NONE
			weapon_info.shieldBreaking = ShieldType.NONE
			weaponInfoList[weapon_info.id] = weapon_info

	static func get_weapon_info(weapon_id: String) -> WeaponInfo:
		return weaponInfoList.get(weapon_id, null)

	static func get_all_weapon_info() -> Array:
		return weaponInfoList.values()

class UnitInfo:
	var name: String = ""
	var armySize: int = 0
	var basic_speed: float = 0.0
	var basic_attack: int = 0
	var basic_defense: int = 0
	var basic_ATK_range: int =0
	var basic_vision_range: int = 0
	var weapon_info: WeaponInfo = null
	var armor: ArmorType = ArmorType.NONE
	var shield: ShieldType = ShieldType.NONE
	var has_mount: bool = false

	# 武器类型与武器路径的映射
	var weapon_scene_paths = {
		"SPEAR": "res://shared/resources/weapons/weapon_models/spear/spear.tscn",
		"BOW": "res://shared/resources/weapons/weapon_models/short_bow/short_bow.tscn",
		"STONE_AXE": "res://shared/resources/weapons/weapon_models/stone_axe/stone_axe.tscn",
		"SWORD": "res://shared/resources/weapons/weapon_models/sword/sword.tscn",
		"PIKE": "res://shared/resources/weapons/weapon_models/spear/spear.tscn",
		"IRON_AXE": "res://shared/resources/weapons/weapon_models/iron_axe/iron_axe.tscn",
		"LONGBOW": "res://shared/resources/weapons/weapon_models/long_bow/long_bow.tscn",
		"CROSSBOW": "res://shared/resources/weapons/weapon_models/cross_bow/cross_bow.tscn"
	}

	# 护甲类型与身体路径的映射
	var body_scene_path = {
		"with_mount": {
			ArmorType.NONE: "res://shared/resources/bodies/cloth_soldier/cloth_soldier.tscn",
			ArmorType.LIGHT: "res://shared/resources/bodies/leather_soldier/leather_soldier.tscn",
			ArmorType.HEAVY: "res://shared/resources/bodies/iron_soldier/iron_soldier.tscn"
		},
		"without_mount": {
			ArmorType.NONE: "res://shared/resources/bodies/cloth_soldier/cloth_soldier.tscn",
			ArmorType.LIGHT: "res://shared/resources/bodies/leather_soldier/leather_soldier.tscn",
			ArmorType.HEAVY: "res://shared/resources/bodies/iron_soldier/iron_soldier.tscn"
		}
	}

	# 盾牌类型与护盾路径的映射
	var shield_scene_paths = {
		ShieldType.WOOD_SHIELD: "res://shared/resources/shield_models/wood_shield/shield_round.tscn",
		ShieldType.IRON_SHIELD: "res://shared/resources/shield_models/iron_shield/shield_heater.tscn"
	}

	func _init(p_armySize: int, p_weapon_id: String, p_armor: ArmorType, p_shield: ShieldType, p_has_mount: bool,p_name: String = ""):
		armySize = p_armySize
		weapon_info = WeaponInfo.get_weapon_info(p_weapon_id)
		armor = p_armor
		shield = p_shield
		has_mount = p_has_mount
		name = p_name if p_name != "" else get_default_name()

		if weapon_info != null:
			basic_attack = get_basic_attack()
			basic_ATK_range = weapon_info.attackDistance
		basic_defense = get_basic_defense()
		basic_speed = get_basic_speed()
		basic_vision_range = get_basic_vision_range()

	# 加载单位模型场景
	func load_unit_model_scene() -> Node3D:
		var temp_scene: PackedScene = PackedScene.new()
		var base_scene = null
		if has_mount:
			base_scene = load("res://shared/resources/unit_scene_bases/cavalry_base.tscn")
		else:
			base_scene = load("res://shared/resources/unit_scene_bases/soldier_base.tscn")
		
		var base_scene_instance:Node3D = base_scene.instantiate()

		# 获取各个附加点节点
		var body_attach = base_scene_instance.get_node("BodyAttach")
		var weapon_attach = base_scene_instance.get_node("WeaponAttach")
		var shield_attach = base_scene_instance.get_node("ShieldAttach")
		
		if has_mount:
			body_attach.add_child(load(body_scene_path["with_mount"][armor]).instantiate())
		else:
			body_attach.add_child(load(body_scene_path["without_mount"][armor]).instantiate())
		
		if weapon_info != null:
			weapon_attach.add_child(load(weapon_scene_paths[weapon_info.id]).instantiate())
		
		if shield != ShieldType.NONE:
			shield_attach.add_child(load(shield_scene_paths[shield]).instantiate())

		temp_scene.pack(base_scene_instance)
		return base_scene_instance

	# 基础攻击力
	func get_basic_attack() -> int:
		var attack = weapon_info.damage
		#非双持，且无盾牌，攻击力提升1.5倍
		if shield == ShieldType.NONE and not weapon_info.isDualHolding:
			attack *= 1.5

		return attack

	# 基础防御力
	func get_basic_defense() -> int:
		var defense = 0
		
		match armor:
			ArmorType.NONE:
				defense = 0
			ArmorType.LIGHT:
				defense += 1
			ArmorType.HEAVY:
				defense += 2
		
		match shield:
			ShieldType.NONE:
				defense += 0
			ShieldType.WOOD_SHIELD:
				defense += 1
			ShieldType.IRON_SHIELD:
				defense += 2
		
		return defense
		
	# 基础移动速度
	func get_basic_speed() -> float:
		var speed = 5

		if has_mount:
			speed *= 2
			
		return speed

	# 基础视野范围
	func get_basic_vision_range() -> int:
		return 10

	func get_default_name() -> String:
		if weapon_info != null:
			return weapon_info.name + "兵队"
		else:
			return "部队"
		

func _init():
	WeaponInfo.load_all_weapon_info()
