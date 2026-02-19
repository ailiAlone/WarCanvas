class_name Terrain_Editer

var _rd: RenderingDevice
var _shader: RID
var _pipeline: RID
var _height_buffer: RID
var _params_buffer: RID
var _params: Dictionary
var _edit_params: Dictionary

func _init(rd: RenderingDevice) -> void:
	_rd = rd
	var shader_file = load("res://shared/scripts/gpu_terrain/shader/terrain_edit_compute.glsl")
	if shader_file:
		var spirv = shader_file.get_spirv()
		_shader = rd.shader_create_from_spirv(spirv)
		_pipeline = rd.compute_pipeline_create(_shader)

func _setup(height_buffer: RID, params: Dictionary):
	_height_buffer = height_buffer
	_params = params

func _create_params_buffer() -> RID:
	var params = PackedFloat32Array([
		_edit_params["hit_pos"].x,
		_edit_params["hit_pos"].y,
		_edit_params["radius"],
		_edit_params["strength"],
		float(_edit_params["mode"]),
		float(_params["map_width"]),
		float(_params["map_height"])
	])

	return _rd.storage_buffer_create(params.size() * 4, params.to_byte_array())

func edit_terrain(hit_pos: Vector2, radius: float, strength: float, mode: GPU_Terrain.EditMode) -> void:
	_edit_params = {
		"hit_pos": hit_pos,
		"radius": radius,
		"strength": strength,
		"mode": mode
	}
	_params_buffer = _create_params_buffer()
	
	var uniform_height = RDUniform.new()
	uniform_height.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform_height.binding = 0
	uniform_height.add_id(_height_buffer)
	
	var uniform_params = RDUniform.new()
	uniform_params.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform_params.binding = 1
	uniform_params.add_id(_params_buffer)

	var uniform_set = _rd.uniform_set_create([uniform_height, uniform_params], _shader, Config.GPU_SET_Arrangement["terrain_edit_compute"])
	
	var group_x = ceili(float(_params["map_width"]) / GPU_Terrain.COMPUTE_LOCAL_SIZE)
	var group_y = ceili(float(_params["map_height"]) / GPU_Terrain.COMPUTE_LOCAL_SIZE)
	
	var compute_list = _rd.compute_list_begin()
	_rd.compute_list_bind_compute_pipeline(compute_list, _pipeline)
	_rd.compute_list_bind_uniform_set(compute_list, uniform_set, 1)
	_rd.compute_list_dispatch(compute_list, group_x, group_y, 1)
	_rd.compute_list_end()
	
	_rd.submit()
	
	_rd.sync()

func _cleanup():
	if _rd:
		if _shader.is_valid():
			_rd.free_rid(_shader)
			_shader = RID()
		if _pipeline.is_valid():
			_rd.free_rid(_pipeline)
			_pipeline = RID()
		if _params_buffer.is_valid():
			_rd.free_rid(_params_buffer)
			_params_buffer = RID()
