shader_type spatial;
render_mode skip_vertex_transform;

uniform sampler2D noise_texture;
uniform float height_scale = 20.0;
uniform int map_width = 500;
uniform int map_height = 500;
uniform float cell_size = 1.0;

varying vec3 world_position;

void vertex() {
	// 计算世界位置
	vec2 uv_pos = vec2(float(VERTEX_ID % map_width) / float(map_width), 
	                   float(VERTEX_ID / map_width) / float(map_height));
	
	float height = texture(noise_texture, uv_pos).r * height_scale;
	
	world_position = vec3(uv_pos.x * map_width * cell_size, height, uv_pos.y * map_height * cell_size);
	
	// 输出顶点位置（跳过变换模式）
	POSITION = vec4(world_position, 1.0);
}

void fragment() {
	// 从噪声纹理获取高度
	vec2 uv = SCREEN_UV;
	float height = texture(noise_texture, uv).r * height_scale;
	
	// 基于高度的颜色混合
	vec3 water = vec3(0.0, 0.0, 0.8);
	vec3 sand = vec3(1.0, 1.0, 0.6);
	vec3 light_grass = vec3(0.5, 1.0, 0.5);
	vec3 dark_grass = vec3(0.2, 0.8, 0.2);
	vec3 wasteland = vec3(0.8, 0.5, 0.3);
	vec3 mountain = vec3(0.7, 0.7, 0.7);
	
	vec3 final_color;
	
	if (height < -5.0) {
		final_color = water;
	} else if (height < 0.0) {
		final_color = mix(water, sand, (height + 5.0) / 5.0);
	} else if (height < 2.0) {
		final_color = mix(sand, light_grass, height / 2.0);
	} else if (height < 8.0) {
		final_color = mix(light_grass, dark_grass, (height - 2.0) / 6.0);
	} else if (height < 15.0) {
		final_color = mix(dark_grass, wasteland, (height - 8.0) / 7.0);
	} else {
		final_color = mix(wasteland, mountain, min((height - 15.0) / 10.0, 1.0));
	}
	
	ALBEDO = final_color;
}
