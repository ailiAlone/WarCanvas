extends VBoxContainer

var editor_state_manager: EditorStateManager

@onready var settingGeology = $SettingGeology
@onready var settingForrest = $SettingForrest

func _ready():
	if not editor_state_manager:
		editor_state_manager = EditorStateManager.get_instance()
	settingForrest.pressed.connect(on_setting_forrest_pressed)

	for geology_type in GeologyType.get_all_geology_types():
		var button = Button.new()
		button.text = geology_type
		button.pressed.connect(on_setting_geology_pressed.bind(geology_type))
		add_child(button)

func on_setting_geology_pressed(geology_type: String):
	if not editor_state_manager:
		editor_state_manager = EditorStateManager.get_instance()
	editor_state_manager.change_state(EditorStateManager.EditorState.GRID_GEOLOGY)
	GeologyType.set_current_geology_type(geology_type)
	editor_state_manager.update_state_label()

func on_setting_forrest_pressed():
	if not editor_state_manager:
		editor_state_manager = EditorStateManager.get_instance()
	editor_state_manager.change_state(EditorStateManager.EditorState.GRID_FORREST)
