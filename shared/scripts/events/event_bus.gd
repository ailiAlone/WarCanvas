extends Node

signal new_turn_started(turn_number: int)
signal new_headquarter_started(headquarter: Headquarter)
signal settlement_occupied(settlement: Settlement)
signal all_headquarter_finished_turn()
signal pass_turn()
signal open_menu()
signal close_menu()

signal grid_pointed(grid: Grid)
signal grid_selected(grid:Grid)

signal paint_highlight(new_list: Array[Grid])
signal clean_highlight()

signal camera_moved(pos:Vector3)

# 系统菜单切换信号
signal system_menu_toggled()
# 帮助菜单切换信号
signal help_menu_toggled()
