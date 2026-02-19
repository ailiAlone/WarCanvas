extends Control

@onready var terrain_sub_container = $"TerrainSubMenu"
@onready var geology_sub_container = $"GeologySubMenu"
@onready var grid_sub_container = $"GridSubMenu"

# 文件对话框
@onready var file_dialog = $"FileDialog"
# 重置选项对话框
@onready var reset_dialog = $"ResetOptionsPopup"

func show_terrain_sub_container():
	terrain_sub_container.show()
	geology_sub_container.hide()
	grid_sub_container.hide()

func show_geology_sub_container():
	geology_sub_container.show()
	terrain_sub_container.hide()
	grid_sub_container.hide()

func show_grid_sub_container():
	grid_sub_container.show()
	terrain_sub_container.hide()
	geology_sub_container.hide()

func show_reset_dialog():
	reset_dialog.show()

# 设置文件操作类型为保存，并显示文件对话框
func show_save_dialog():
	file_dialog.current_file_operation = FileDialogUI.FileOperation.SAVE
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.title = "保存地图"
	file_dialog.popup_centered_ratio()

# 设置文件操作类型为加载，并显示文件对话框
func show_load_dialog():
	file_dialog.current_file_operation = FileDialogUI.FileOperation.LOAD
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.title = "加载地图"
	file_dialog.popup_centered_ratio()
