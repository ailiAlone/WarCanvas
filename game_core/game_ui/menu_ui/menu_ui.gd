extends PanelContainer
class_name MenuUI

@export_category("回合按钮")
@export var icon_player_turn: Texture2D  # 玩家回合图标
@export var icon_enemy_turn: Texture2D   # 非玩家回合图标

@export_category("菜单按钮")
@export var icon_close_menu: Texture2D  # 关闭菜单图标
@export var icon_open_menu: Texture2D  # 打开菜单图标

# 菜单事项
@onready var governance_button = $HBoxContainer/MarginContainer/MenuItems/GovernanceButton
@onready var build_button = $HBoxContainer/MarginContainer/MenuItems/BuildButton
@onready var battalion_button = $HBoxContainer/MarginContainer/MenuItems/BattalionButton
@onready var resource_button = $HBoxContainer/MarginContainer/MenuItems/ResourceButton
@onready var basic_resource= $HBoxContainer/MarginContainer/MenuItems/BasicResource
@onready var trading_button = $HBoxContainer/MarginContainer/MenuItems/TradingButton
@onready var assignment_button = $HBoxContainer/MarginContainer/MenuItems/AssignmentButton
@onready var toggle_button = $HBoxContainer/MarginContainer/MenuItems/ToggleButton
@onready var expedition_button = $HBoxContainer/MarginContainer/MenuItems/ExpeditionButton
@onready var end_turn_button = $HBoxContainer/MarginContainer/MenuItems/EndTurn
# 具体内容
@onready var governance_menu = $HBoxContainer/ScrollContainer/ContentArea/GovernanceMenu
@onready var build_menu = $HBoxContainer/ScrollContainer/ContentArea/BuildingMenu
@onready var battalion_menu = $HBoxContainer/ScrollContainer/ContentArea/BattalionMenu
@onready var resource_menu = $HBoxContainer/ScrollContainer/ContentArea/ResourceMenu
@onready var trading_menu = $HBoxContainer/ScrollContainer/ContentArea/TradingMenu
@onready var assignment_menu = $HBoxContainer/ScrollContainer/ContentArea/AssignmentMenu
@onready var expedition_menu = $HBoxContainer/ScrollContainer/ContentArea/ExpeditionMenu

#debug 列表
@onready var debug_list = $HBoxContainer/MarginContainer/MenuItems/DebugList

var is_menu_open: bool = false

var _headquarter: Headquarter = null  # 当前总部
var current_menu = null # 当前显示的菜单

func _ready():
	# 连接按钮信号
	governance_button.pressed.connect(_switch_menu.bind(governance_menu))
	build_button.pressed.connect(_switch_menu.bind(build_menu))
	battalion_button.pressed.connect(_switch_menu.bind(battalion_menu))
	resource_button.pressed.connect(_switch_menu.bind(resource_menu))
	trading_button.pressed.connect(_switch_menu.bind(trading_menu))
	assignment_button.pressed.connect(_switch_menu.bind(assignment_menu))
	expedition_button.pressed.connect(_switch_menu.bind(expedition_menu))
	toggle_button.pressed.connect(toggle_menu)
	end_turn_button.pressed.connect(_on_passturn_button_pressed)

	EventBus.close_menu.connect(close_menu)
	EventBus.new_headquarter_started.connect(_on_new_headquarter_started)

	# 连接鼠标点击信号
	InputManager.mouse_left_pressed.connect(_on_mouse_left_pressed)

# 绑定总部到菜单
func _bind_headquarter(headquarter: Headquarter):
	_headquarter = headquarter

	# 初始化所有菜单的关联对象
	governance_menu.set_headquarter(_headquarter)
	build_menu.set_settlement(_headquarter as Settlement)
	battalion_menu.set_headquarter(_headquarter)
	resource_menu.set_headquarter(_headquarter)
	assignment_menu.set_headquarter(_headquarter)
	
	# 交易菜单需要特殊处理
	if _headquarter is Settlement:
		expedition_menu.set_headquarter(_headquarter)
		trading_menu.set_local_market((_headquarter as Settlement).get_local_market(),_headquarter)
		trading_button.show()
		expedition_button.show()
		build_button.show()
	else:
		trading_button.hide()
		expedition_button.hide()
		build_button.hide()

	# 连接库存变化信号
	_headquarter.inventory_changed.connect(_update_ui)
	_headquarter.production_line_changed.connect(_update_ui)

# 处理回合变化信号
func _on_new_headquarter_started(headquarter: Headquarter):
	# 只需要更新回合按钮状态和UI
	_update_turn_button_state(headquarter._is_player)
	if headquarter._is_player:
		_bind_headquarter(headquarter)
		# 玩家回合：更新UI
		_update_ui()
		
	
# 更新回合按钮状态
func _update_turn_button_state(is_player_turn: bool):
	if is_player_turn:
		# 玩家回合：亮红色，可点击
		end_turn_button.modulate = Color(1.0, 0.1, 0.1)  # 亮红色
		end_turn_button.disabled = false
		# 添加特殊标志，比如在按钮文本前添加一个图标
		end_turn_button.icon = icon_player_turn
	else:
		# 非玩家回合：暗红色，不可点击
		end_turn_button.modulate = Color(0.5, 0.1, 0.1)  # 暗红色
		end_turn_button.disabled = true
		# 更改特殊标志
		end_turn_button.icon = icon_enemy_turn

func _update_button_styles(selected_menu: String = ""):
	# 重置所有按钮样式
	governance_button.modulate = Color.WHITE
	build_button.modulate = Color.WHITE
	battalion_button.modulate = Color.WHITE
	resource_button.modulate = Color.WHITE
	trading_button.modulate = Color.WHITE
	assignment_button.modulate = Color.WHITE
	
	# 高亮选中的按钮
	match selected_menu:
		"":	
			pass
		"GovernanceMenu":
			governance_button.modulate = Color.GREEN
		"BuildingMenu":
			build_button.modulate = Color.GREEN
		"BattalionMenu":
			battalion_button.modulate = Color.GREEN
		"ResourceMenu":
			resource_button.modulate = Color.GREEN
		"TradingMenu":
			trading_button.modulate = Color.GREEN
		"AssignmentMenu":
			assignment_button.modulate = Color.GREEN

func _update_ui():
	basic_resource.text = "货币: " + str(_headquarter.inventory.get_money()) + "\n" + "食物: " + str(_headquarter.inventory.get_food())
	assignment_menu.update()
	if _headquarter is Settlement:
		trading_menu.update()
		build_menu.update()
	resource_menu.update()
	battalion_menu.update_item_inventory()

func toggle_menu():
	if is_menu_open:
		close_menu()
	else:
		_switch_menu(resource_menu)

func _switch_menu(new_menu: VBoxContainer):
	if current_menu == new_menu :
		return
	# 修改当前菜单为新菜单
	if current_menu != null:
		current_menu.hide()
	new_menu.show()
	current_menu = new_menu
	is_menu_open = true
	toggle_button.icon = icon_close_menu
	_update_button_styles(new_menu.name)

func close_menu():
	if current_menu != null:
		current_menu.hide()

	current_menu = null
	is_menu_open = false
	toggle_button.icon = icon_open_menu
	_update_button_styles()

func _on_passturn_button_pressed():
	close_menu()
	CommandBus.execute_command(EndTurnCommand.new(_headquarter))

func init_debug_list():
	# 初始化调试列表 包含各个 headquarter 选择后，绑定对应的headquarter
	for headquarter in HeadquarterManager.headquarters.to_array_from_head():
		var item = Button.new()
		item.text = "Headquarter " + str(headquarter._id)
		item.pressed.connect(_bind_headquarter.bind(headquarter))
		debug_list.add_child(item)

# 处理鼠标左键点击事件
func _on_mouse_left_pressed(pressed: bool):
	if pressed and is_menu_open:
		# 获取鼠标位置
		var mouse_pos = get_viewport().get_mouse_position()
		
		# 检查鼠标是否在MenuUI之外
		if not get_global_rect().has_point(mouse_pos):
			# 检查鼠标是否在任何子菜单之外
			var is_clicking_submenu = false
			
			# 检查所有子菜单
			var sub_menus = [governance_menu, build_menu, battalion_menu, resource_menu, trading_menu, assignment_menu]
			for menu in sub_menus:
				if menu.visible and menu.get_global_rect().has_point(mouse_pos):
					is_clicking_submenu = true
					break
			
			# 如果点击位置在MenuUI和所有子菜单之外，则关闭菜单
			if not is_clicking_submenu:
				close_menu()
