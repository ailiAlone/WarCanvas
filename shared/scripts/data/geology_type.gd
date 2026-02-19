extends Resource

class_name GeologyType

# 地形类型颜色映射类，用于存储和管理不同地形类型对应的颜色

# 地形类型颜色定义
const GEOLOGY_TYPE_COLORS = {
	"TYPE_EMPTY": Color(0.5, 0.5, 0.5, 0.3),  	# 空 (灰色半透明)
	"TYPE_LIGHT_GRASS": Color(0.5, 1, 0.5, 1),  # 青草地（绿色半透明）
	"TYPE_DARK_GRASS": Color(0.2, 0.8, 0.2, 1),	# 沃草地（绿色半透明）
	"TYPE_WASTELAND": Color(0.8, 0.4, 0.2, 0.3),# 荒地（白色半透明）
	"TYPE_WATER": Color(0.0, 0.0, 1.0, 0.3),   	# 水（蓝色半透明）
	"TYPE_SAND": Color(1.0, 1.0, 0.0, 0.3),    	# 沙地（黄色半透明）
	"TYPE_MOUNTAIN": Color(0.8, 0.8, 0.8, 0.3), # 山地（灰色半透明）
	"TYPE_SNOW": Color(1, 1, 1, 0.3),   		# 雪地（白色半透明）
}

# 获取默认地质类型 
static func get_default_geology_type() -> String:
	return "TYPE_EMPTY"

static var current_geology_type: String = "TYPE_EMPTY"

# 设置当前地质类型
static func set_current_geology_type(geology_type: String):
	current_geology_type = geology_type

# 获取当前地质类型
static func get_current_geology_type() -> String:
	return current_geology_type

# 获取地形类型对应的颜色
static func get_color_for_type(geology_type: String) -> Color:
	if GEOLOGY_TYPE_COLORS.has(geology_type):
		return GEOLOGY_TYPE_COLORS[geology_type]
	else:
		return GEOLOGY_TYPE_COLORS["TYPE_EMPTY"]
		
# 获取所有地质类型
static  func get_all_geology_types() -> Array:
	return GEOLOGY_TYPE_COLORS.keys()
