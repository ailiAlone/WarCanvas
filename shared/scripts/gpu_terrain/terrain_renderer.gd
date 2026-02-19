class_name Terrain_Renderer

var _mesh: PlaneMesh
var _material_override: ShaderMaterial
var _mesh_instance: MeshInstance3D

var _heightmap_texture: ImageTexture
var _height_map: HeightMapShape3D
var _params: Dictionary

func _init(mesh_instance: MeshInstance3D):
	_mesh_instance = mesh_instance
	_mesh = mesh_instance.mesh as PlaneMesh
	_material_override = mesh_instance.material_override as ShaderMaterial
	_height_map = mesh_instance.get_node("StaticBody3D/CollisionShape3D").shape as HeightMapShape3D

func _setup(params:Dictionary):
	_params = params

	var map_width = params["map_width"]
	var map_height = params["map_height"]
	var cell_size = params["cell_size"]
	var elevation_scale = params["elevation_scale"]
	
	# 设置网格大小和子网格数量
	_mesh.size = Vector2(map_width * cell_size, map_height * cell_size)
	_mesh.subdivide_width = map_width - 1
	_mesh.subdivide_depth = map_height - 1

	_heightmap_texture = _material_override.get_shader_parameter("height_map")

	# 设置网格实例的材质参数
	_material_override.set_shader_parameter("elevation_scale", elevation_scale)
	_material_override.set_shader_parameter("terrain_size", Vector2(map_width * cell_size, map_height * cell_size))

	var byte_array = PackedByteArray()
	byte_array.resize(map_width * map_height * 4)
	
	# 必须先用 set_image 初始化高度图纹理，然后再用 update
	_heightmap_texture.set_image(
		Image.create_from_data(
		_params["map_width"], 
		_params["map_height"], 
		false, 
		Image.FORMAT_RF,
		byte_array
	))

	_height_map.map_width = map_width
	_height_map.map_depth = map_height

	
func update_heightmap_texture(heightmap: PackedByteArray):
	var image = Image.create_from_data(
		_params["map_width"], 
		_params["map_height"], 
		false, 
		Image.FORMAT_RF,
		heightmap
	)
	
	_heightmap_texture.update(image)

func update_heightmap_collision(heightmap: PackedFloat32Array):
	_height_map.map_data = heightmap

func _cleanup():
	_heightmap_texture = null
	_params.clear()
