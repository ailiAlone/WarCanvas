extends Control

# 资源负载UI控制器

# UI元素引用
@onready var static_memory_label = $"StaticMemoryLabel"
@onready var dynamic_memory_label = $"DynamicMemoryLabel"
@onready var total_memory_label = $"TotalMemoryLabel"
@onready var object_count_label = $"ObjectCountLabel"
@onready var node_count_label = $"NodeCountLabel"
@onready var orphan_node_count_label = $"OrphanNodeCountLabel"
@onready var draw_calls_label = $"DrawCallsLabel"
@onready var video_memory_label = $"VideoMemoryLabel"
@onready var total_primitives_label = $"TotalPrimitivesLabel"
@onready var total_objects_label = $"TotalObjectsLabel"
@onready var total_draw_calls_label = $"TotalDrawCallsLabel"
@onready var current_device_label = $"CurrentDeviceLabel"
@onready var fps_label = $"FPSLabel"
# LOD统计相关UI元素
@onready var lod0_count_label = $"LOD0CountLabel"
@onready var lod1_count_label = $"LOD1CountLabel"
@onready var lod2_count_label = $"LOD2CountLabel"
@onready var lod3_count_label = $"LOD3CountLabel"
@onready var lod4_count_label = $"LOD4CountLabel"

# 资源负载相关
var resource_load_timer: Timer
const RESOURCE_LOAD_UPDATE_INTERVAL: float = 1.0  # 更新间隔（秒）

# 初始化UIw
func _ready():
	# 初始化资源负载更新定时器
	init_resource_load_update()

# 初始化资源负载更新d
# 
# 创建并启动资源负载更新定时器
func init_resource_load_update():
	resource_load_timer = Timer.new()
	resource_load_timer.wait_time = RESOURCE_LOAD_UPDATE_INTERVAL
	resource_load_timer.autostart = true
	resource_load_timer.one_shot = false
	add_child(resource_load_timer)
	resource_load_timer.timeout.connect(update_resource_load)

# 更新资源负载显示
# 
# 获取当前资源负载并更新UI标签和控制台输出
func update_resource_load():
	# 获取详细的内存信息
	var static_memory = Performance.get_monitor(Performance.MEMORY_STATIC)
	var dynamic_memory = Performance.get_monitor(Performance.MEMORY_STATIC_MAX)
	var total_memory = static_memory + dynamic_memory
	
	# 获取对象和节点信息
	var object_count = Performance.get_monitor(Performance.OBJECT_COUNT)
	var node_count = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var orphan_node_count = Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	
	# 获取渲染信息
	var draw_calls = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var video_memory = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)
	var total_primitives = Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	var total_objects = Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
	
	# 获取帧率信息
	var fps = Performance.get_monitor(Performance.TIME_FPS)
	
	# 更新内存信息标签
	static_memory_label.text = "静态内存: " + format_memory(static_memory)
	dynamic_memory_label.text = "可用静态内存: " + format_memory(dynamic_memory)
	total_memory_label.text = "总内存: " + format_memory(total_memory)
	
	# 更新对象和节点信息标签
	object_count_label.text = "对象数: " + str(object_count)
	node_count_label.text = "节点数: " + str(node_count)
	orphan_node_count_label.text = "孤立节点数: " + str(orphan_node_count)
	
	# 更新渲染信息标签
	draw_calls_label.text = "渲染调用: " + str(draw_calls)
	video_memory_label.text = "视频内存: " + format_memory(video_memory)
	total_primitives_label.text = "绘制图元总数: " + str(total_primitives)
	total_objects_label.text = "绘制对象总数: " + str(total_objects)
	total_draw_calls_label.text = "绘制调用总数: " + str(draw_calls)
	
	# 更新帧率信息标签
	if fps_label:
		fps_label.text = "帧率: " + str(round(fps)) + " FPS"
	
	# 更新当前设备信息标签
	current_device_label.text = "显卡: " + get_gpu_info()
	
	# 更新LOD统计信息
	#update_lod_statistics()
# 获取显卡信息
# 
# @return 显卡名称字符串
func get_gpu_info() -> String:
	# 获取渲染设备信息
	var device_info = RenderingServer.get_video_adapter_name()
	if device_info != "":
		return device_info
	else:
		return "Unknown GPU"

# 格式化内存大小显示
# 
# 将字节数转换为合适的单位（B, KB, MB, GB）
# 
# @param bytes 字节数
# @return 格式化后的内存大小字符串
func format_memory(bytes: int) -> String:
	if bytes < 1024:
		return str(bytes) + " B"
	elif bytes < 1024 * 1024:
		return str(round(bytes / 1024.0 * 100) / 100) + " KB"
	elif bytes < 1024 * 1024 * 1024:
		return str(round(bytes / (1024.0 * 1024.0) * 100) / 100) + " MB"
	else:
		return str(round(bytes / (1024.0 * 1024.0 * 1024.0) * 100) / 100) + " GB"

# 更新LOD统计信息
# 
# 统计各个LOD级别的TerrainChunk数量并更新UI标签
func update_lod_statistics():
	# 初始化LOD计数器
	var lod_counts = {
		0: 0,
		1: 0,
		2: 0,
		3: 0,
		4: 0
	}
	
	# 遍历所有地形块
	for chunk in GameState._world_node.terrain_manager.terrain_chunks.values():
		var current_lod = chunk.current_lod
		lod_counts[current_lod] += 1
	
	# 更新LOD统计信息标签
	if lod0_count_label:
		lod0_count_label.text = "LOD0级地块数: " + str(lod_counts[0])
	if lod1_count_label:
		lod1_count_label.text = "LOD1级地块数: " + str(lod_counts[1])
	if lod2_count_label:
		lod2_count_label.text = "LOD2级地块数: " + str(lod_counts[2])
	if lod3_count_label:
		lod3_count_label.text = "LOD3级地块数: " + str(lod_counts[3])	
	if lod4_count_label:
		lod4_count_label.text = "LOD4级地块数: " + str(lod_counts[4])
