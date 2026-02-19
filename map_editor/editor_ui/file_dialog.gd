extends FileDialog
class_name FileDialogUI
# 文件操作类型
enum FileOperation { SAVE, LOAD }
var current_file_operation: FileOperation

func _ready():
	file_selected.connect(on_file_selected)
	filters = PackedStringArray([Config.map_file_filter])

# 文件选择回调
# 根据当前文件操作类型执行保存或加载地图操作
# @param file_path 选择的文件路径
func on_file_selected(file_path: String):
	match current_file_operation:
		FileOperation.SAVE:
			GameState.save_map_data(file_path)
		FileOperation.LOAD:
			GameState.load_map_data(file_path)

	
