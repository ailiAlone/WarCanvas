extends Node

# 编辑器状态管理器
# 负责管理地图编辑器的各种状态和模式切换

class_name EditorStateManager

static func get_instance() -> EditorStateManager:
	if instance:
		return instance
	instance = EditorStateManager.new()
	return instance

static var instance: EditorStateManager = null

# 编辑器状态枚举
enum EditorState { 
	SELECT,
	TERRAIN_RAISE, TERRAIN_LOWER,TERRAIN_SMOOTH,
	GEOLOGY,
	GRID_FORREST,GRID_GEOLOGY,
	OBJECT,
	NULL }

# 当前编辑器状态
var current_state: EditorState = EditorState.NULL

var state_label: Label = null
# 切换编辑器状态
# 
# @param new_state 新的编辑器状态
func change_state(new_state: EditorState):
	if new_state == current_state:
		return
	# 设置新状态
	current_state = new_state
	update_state_label()
	
# 获取当前状态
func get_current_state() -> EditorState:
	return current_state

# 检查是否在特定状态
func is_in_state(state: EditorState) -> bool:
	return current_state == state

func update_state_label():
	if state_label:
		state_label.text = "当前编辑状态：\n" + get_state_name()

# 获取状态名称
func get_state_name() -> String:
	match current_state:
		EditorState.SELECT:
			return "选择"
		EditorState.TERRAIN_RAISE:
			return "地形编辑-抬升"
		EditorState.TERRAIN_LOWER:
			return "地形编辑-降低"
		EditorState.TERRAIN_SMOOTH:
			return "地形编辑-平滑"
		EditorState.GEOLOGY:
			return "地质编辑：" + GeologyType.get_current_geology_type()
		EditorState.GRID_FORREST:
			return "网格编辑-森林"
		EditorState.GRID_GEOLOGY:
			return "网格编辑-地质:" + GeologyType.get_current_geology_type()
		EditorState.OBJECT:
			return "对象放置"
		EditorState.NULL:
			return "无"
		_:
			return "未知"

func is_terrain_edit_state() -> bool:
	return is_in_state(EditorState.TERRAIN_RAISE) or is_in_state(EditorState.TERRAIN_LOWER) or is_in_state(EditorState.TERRAIN_SMOOTH)

func is_geology_edit_state() -> bool:
	return is_in_state(EditorState.GEOLOGY)

func is_grid_edit_state() -> bool:
	return is_in_state(EditorState.GRID_FORREST) or is_in_state(EditorState.GRID_GEOLOGY)
