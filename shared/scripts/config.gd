extends Node

var terrain_cell_size: float = 1.0
var terrain_chunk_size: int = 16

var grating_cell_size: float = 1.0
var grating_chunk_size: int = 4

var brush_segments: int = 64
var brush_size: float = 4.0
var brush_strength: float = 1.0

#基本网格、单元网格绘制
var show_basic_grating: bool = false
var show_chunk_grating: bool = false
var show_rounded_grating: bool = true

# 文件配置
var map_file_filter: String = "*.map ; 地图文件"
var map_file_extension: String = ".map"

#在此分配 GPU 描述符集（Descriptor Set） 在此分配 务必匹配
var GPU_SET_Arrangement: Dictionary = {
	"terrain_gen_compute": 0,
	"terrain_edit_compute": 1,
}
