extends Control

var selected_option = -1
var options = [
	{
		"title": "农牧据点",
		"subtitle": "常规发展路线",
		"description": "平原发展，以农业、畜牧、骑兵为核心",
		"details": "• 初期：耕种、放牧 • 中期：驯马、农产品加工 • 后期：强大骑兵、粮食帝国",
		"image_path": "res://game_content/sandbox/intro/assets/images/pastoral_base_concept.png"
	},  
	{
		"title": "林矿据点",
		"subtitle": "常规发展路线", 
		"description": "山林发展，以伐木、采矿、制造业为核心",
		"details": "• 初期：伐木、狩猎 • 中期：采矿、冶炼 • 后期：军工业、防御工事",
		"image_path": "res://game_content/sandbox/intro/assets/images/forest_base_concept.png"
	},
	{
		"title": "河海据点",
		"subtitle": "常规发展路线",
		"description": "沿海发展，以渔业、贸易、航海为核心",
		"details": "• 初期：捕鱼、晒盐 • 中期：造船、港口 • 后期：远洋贸易、海军",
		"image_path": "res://game_content/sandbox/intro/assets/images/coastal_base_concept.png"
	},
	{
		"title": "军事据点",
		"subtitle": "非常规功能路线",
		"description": "纯粹的军事要塞，以防御和进攻为核心",
		"warning": "注意：资源消耗巨大",
		"details": "• 军事特化路线 • 强大的攻防能力• 需要后方补给",
		"image_path": "res://game_content/sandbox/intro/assets/images/fortress_base_concept.png"
	},
	{
		"title": "商业据点",
		"subtitle": "非常规功能路线",
		"description": "纯粹的贸易中心，以商业和金融为核心",
		"warning": "注意：缺乏自给能力",
		"details": "• 经济特化路线 • 依赖与其他据点贸易 • 金钱就是力量",
		"image_path": "res://game_content/sandbox/intro/assets/images/commercial_base_concept.png"
	},
	{
		"title": "地下据点",
		"subtitle": "非常规功能路线", 
		"description": "隐蔽的地下城市，以隐秘和特殊资源为核心",
		"warning": "注意：发展受限",
		"details": "• 隐秘行动路线 • 独特地下资源 • 易守难攻但扩张困难",
		"image_path": "res://game_content/sandbox/intro/assets/images/underground_base_concept.png"
	}
]

@onready var fullscreen_texture_rect = $MarginContainer/VBoxContainer/HexagonContainer/FullScreenTextureRect
@onready var detail_label = $MarginContainer/VBoxContainer/MarginContainer2/VBoxContainer/HBoxContainer/Detail_Label

func _ready():
	#绑定按钮点击事件
	# 1-6 选项 按钮
	$MarginContainer/VBoxContainer/HexagonContainer/TextureRect.pressed.connect(_on_button_pressed.bind(0))
	$MarginContainer/VBoxContainer/HexagonContainer/TextureRect2.pressed.connect(_on_button_pressed.bind(1))
	$MarginContainer/VBoxContainer/HexagonContainer/TextureRect3.pressed.connect(_on_button_pressed.bind(2))
	$MarginContainer/VBoxContainer/HexagonContainer/TextureRect4.pressed.connect(_on_button_pressed.bind(3))
	$MarginContainer/VBoxContainer/HexagonContainer/TextureRect5.pressed.connect(_on_button_pressed.bind(4))
	$MarginContainer/VBoxContainer/HexagonContainer/TextureRect6.pressed.connect(_on_button_pressed.bind(5))

	# 确认按钮
	$MarginContainer/VBoxContainer/MarginContainer2/VBoxContainer/HBoxContainer/StartButton.pressed.connect(_on_start_button_pressed)
	
	# 返回主菜单按钮
	$MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/ReturnToMainMenuButton.pressed.connect(_on_return_to_main_menu_button_pressed)
	
	# 确保初始时隐藏全屏图片
	fullscreen_texture_rect.hide()

func _on_button_pressed(option: int):
	if option == selected_option:
		selected_option = -1
	else:
		selected_option = option

	if selected_option != -1:
		fullscreen_texture_rect.texture = load(options[selected_option].image_path)
		#显示全屏图片
		fullscreen_texture_rect.show()
		#更新详情标签
		detail_label.text = options[selected_option].title + " - " + options[selected_option].subtitle + "\n" + options[selected_option].description + "\n" + options[selected_option].details
	else:
		#隐藏全屏图片
		fullscreen_texture_rect.hide()
		#清空详情标签
		detail_label.text = ""

func _on_start_button_pressed():
	if selected_option == -1:
		return
	
	var option = options[selected_option]
	
	# 设置游戏初始化数据
	var init_data = {
		"map_path": "res://data/map_data/test5.map",
		"debug_mode": true,
		"player_configs": [
			{
				"ID": 1,
				"is_player": true,
				"init_position": Vector2i(41,12),
				"initial_buildings": ["MEDIUM_HOUSE"]
			},
			{
				"ID": 2,
				"is_player": false,
				"init_position": Vector2i(38,50),
				"initial_buildings": ["MEDIUM_HOUSE"]
			}
		]
	}
	
	# 保存初始化数据到全局状态
	GameState.set_game_init_data(init_data)
	
	# 切换到游戏核心场景
	get_tree().change_scene_to_file("res://game_core/game_core.tscn")

func _on_return_to_main_menu_button_pressed():
	# 返回主菜单场景
	# 假设主菜单场景位于 res://game_core/main_menu/main_menu.tscn
	# 如果您的主菜单场景在其他位置，请相应修改路径
	get_tree().change_scene_to_file("res://game_content/main_menu/main_menu.tscn")
