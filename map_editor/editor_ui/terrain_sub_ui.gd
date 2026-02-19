extends VBoxContainer

var editor_state: EditorStateManager

@onready var protrusion_button = $ProtrusionButton
@onready var depression_button = $DepressionButton
@onready var flatten_terrain_button = $FlattenButton

func _ready():
	if not editor_state:
		editor_state = EditorStateManager.get_instance()

	# 连接地形子菜单按钮信号
	protrusion_button.pressed.connect(on_protrusion_button_pressed)
	depression_button.pressed.connect(on_depression_button_pressed)
	flatten_terrain_button.pressed.connect(on_flatten_terrain_button_pressed)

func on_protrusion_button_pressed():
	if not editor_state:
		editor_state = EditorStateManager.get_instance()
	editor_state.change_state(EditorStateManager.EditorState.TERRAIN_RAISE)

func on_depression_button_pressed():
	if not editor_state:
		editor_state = EditorStateManager.get_instance()
	editor_state.change_state(EditorStateManager.EditorState.TERRAIN_LOWER)

func on_flatten_terrain_button_pressed():
	if not editor_state:
		editor_state = EditorStateManager.get_instance()
	editor_state.change_state(EditorStateManager.EditorState.TERRAIN_SMOOTH)
