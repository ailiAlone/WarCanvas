# GPU_computing_example.gd
extends MainLoop  

var rd: RenderingDevice
var shader: RID 
var pipeline: RID 
var buffer: RID 
var uniform_set: RID 

var input: PackedFloat32Array 
var output: PackedFloat32Array

#测试运行该文件， godot --script path\to\GPU_computing_example.gd
# 小tips: 
	#在 ide中 修改.glsl的内容，但是输出没有改变，可能说明 缓存没有变，应当使得godot获取焦点，重新编译着色器
# other: 如果无论如何都无法成功运行该示例文件，请联系作者 邮箱：3493591842@qq.com 买买提艾力·阿不来提
func _initialize() -> void:
	print("=== GPU Compute Shader Test ===")
	
	# Create a local rendering device.
	print("步骤 1: 创建RenderingDevice...")
	rd = RenderingServer.create_local_rendering_device()
	if rd == null:
		print("❌ 无法创建RenderingDevice")

		return
	print("✅ RenderingDevice创建成功")
	
	# Load GLSL shader
	print("步骤 2: 加载着色器文件...")
	var shader_file_path := "res://gpu_compute_example/compute_example.glsl" #该文件为 将输入数据乘以2的着色器文件
	
	if not FileAccess.file_exists(shader_file_path):
		print("❌ 着色器文件不存在: " + shader_file_path)
		return
	print("✅ 着色器文件存在")
	
	var shader_file := load(shader_file_path)
	if shader_file == null:
		print("❌ 无法加载着色器文件")
		return
	print("✅ 着色器文件加载成功")
	print("着色器类型: ", typeof(shader_file))
	
	# Get SPIRV from shader resource
	print("步骤 3: 获取SPIRV字节码...")
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	if shader_spirv == null:
		print("❌ 无法获取SPIRV字节码")
		return
	print("✅ SPIRV字节码获取成功")
	
	# Create shader from SPIRV
	print("步骤 4: 从SPIRV创建着色器...")
	shader = rd.shader_create_from_spirv(shader_spirv)
	if shader == null or not shader:
		print("❌ 无法从SPIRV创建着色器")
		return
	print("✅ 着色器创建成功")
	
	# Prepare our data. We use floats in the shader, so we need 32 bit.
	print("步骤 5: 准备输入数据...")
	input = PackedFloat32Array([8, 2, 1, 5, 7, 6, 7, 8, 9, 10])
	var input_bytes := input.to_byte_array()
	print("输入数据大小: ", input_bytes.size(), " 字节")
	print("输入数据: ", input)
	
	# Create a storage buffer that can hold our float values.
	# Each float has 4 bytes (32 bit) so 10 x 4 = 40 bytes
	print("步骤 6: 创建存储缓冲区...")
	buffer = rd.storage_buffer_create(input_bytes.size(), input_bytes)
	if buffer == null:
		print("❌ 无法创建存储缓冲区")
		return
	print("✅ 存储缓冲区创建成功")
	
	# Create a uniform to assign the buffer to the rendering device
	print("步骤 7: 创建Uniform...")
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = 0 # this needs to match the "binding" in our shader file
	uniform.add_id(buffer)
	uniform_set = rd.uniform_set_create([uniform], shader, 0) # the last parameter (the 0) needs to match the "set" in our shader file
	if uniform_set == null:
		print("❌ 无法创建UniformSet")
		return
	print("✅ Uniform创建成功")
	
	# Create a compute pipeline
	print("步骤 8: 创建计算管线...")
	pipeline = rd.compute_pipeline_create(shader)
	if pipeline == null:
		print("❌ 无法创建计算管线")
		return
	print("✅ 计算管线创建成功")
	

func _process(_delta):
	var group_x = ceili(float(input.size()) / 2)
	# Execute compute shader
	print("步骤 9: 执行计算...")
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, group_x, 1, 1)
	rd.compute_list_end()
	print("✅ 计算命令已提交")
	
	# Submit to GPU and wait for sync
	print("步骤 10: 等待GPU完成...")
	rd.submit()
	rd.sync()
	print("✅ GPU计算完成")
	
	# Read back the data from the buffer
	print("步骤 11: 读取结果...")
	var output_bytes := rd.buffer_get_data(buffer)
	if output_bytes == null or output_bytes.size() == 0:
		print("❌ 无法读取输出数据")
	
	output = output_bytes.to_float32_array()
	print("=== 结果 ===")
	print("Input:  ", input)
	print("Output: ", output)
	
	# Verify results
	print("=== 验证 ===")
	var all_match = true
	for i in range(input.size()):
		var diff = abs(input[i] * 2 - output[i])
		if diff > 0.001:
			all_match = false
			print("❌ 索引 %d 不匹配: 输入=%f, 输出=%f, 差异=%f" % [i, input[i], output[i], diff])
	
	if all_match:
		print("✅ 所有结果匹配！GPU计算正常工作")
	else:
		print("⚠️  部分结果不匹配")
	
	return true #MainLoop 中 _process 方法返回 true 结束主循环

func _finalize() -> void:
	print("=== 测试完成 ===")
	_cleanup_resources()

# 清理GPU资源
func _cleanup_resources():
	print("=== 清理GPU资源 ===")
	# 请按依赖关系反向清理：先清理依赖其他资源的对象
	if pipeline.is_valid():
		rd.free_rid(pipeline)
		print("✅ 计算管线已清理")
	else:
		print("⚠️ 计算管线已无效")
	
	# 2. 清理uniform_set（依赖buffer）
	if uniform_set.is_valid():
		rd.free_rid(uniform_set)
		print("✅ UniformSet已清理")
	else:
		print("⚠️ UniformSet已无效")
	
	# 3. 清理buffer（独立资源）
	if buffer.is_valid():
		rd.free_rid(buffer)
		print("✅ 存储缓冲区已清理")
	else:
		print("⚠️ 存储缓冲区已无效")
	
	# 4. 清理shader（可能被pipeline引用）
	if shader.is_valid():
		rd.free_rid(shader)
		print("✅ 着色器已清理")
	else:
		print("⚠️ 着色器已无效")
	
	# 5. 最后清理RenderingDevice本身
	if rd:
		rd.free()
		print("✅ RenderingDevice已清理")
		rd = null  # 设为null避免后续访问
	
	print("✅ GPU资源清理完毕")
