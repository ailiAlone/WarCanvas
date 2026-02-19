extends HBoxContainer

@onready var grid_pos_label = $PositionGrid
@onready var grid_geology_label = $GridGeology
@onready var grid_height_label = $GridHeight
@onready var grid_tree_density_label = $TreeDensity

func _ready():
	update_labels()
	# 连接信号
	EventBus.grid_pointed.connect(_on_update_pointing_grid)

# 处理指向网格更新信号
func _on_update_pointing_grid(grid: Grid):
	grid_pos_label.text = "Grid Position: (%d, %d)" % [grid.chunk_x, grid.chunk_y]
	grid_geology_label.text = "Grid Geology: %s" % grid.grid_type
	grid_height_label.text = "Grid Height: %.2f" % grid.height
	grid_tree_density_label.text = "Tree Density: %.2f" % grid.tree_density

# 批量更新所有标签
func update_labels():
	grid_pos_label.text = "Grid Position: (%d, %d)" % [0, 0]
	grid_geology_label.text = "Terrain Type: TYPE_EMPTY"
	grid_height_label.text = "Height: 0.0"
	grid_tree_density_label.text = "Tree Density: 0.0"
