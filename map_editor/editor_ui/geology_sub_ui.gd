extends VBoxContainer

var editor_state_manager: EditorStateManager

func _ready():
	editor_state_manager = EditorStateManager.get_instance()
	# 获取地质类型颜色映射中的所有key并创建按钮
	for geology_type in GeologyType.get_all_geology_types():
		var button = Button.new()
		button.text = geology_type
		button.pressed.connect(on_geology_type_button_pressed.bind(geology_type))
		add_child(button)

func on_geology_type_button_pressed(geology_type: String):
	# 设置编辑状态
	editor_state_manager.change_state(EditorStateManager.EditorState.GEOLOGY)
	# 设置地形类型
	GeologyType.set_current_geology_type(geology_type)
	# 更新状态标签
	editor_state_manager.update_state_label()
