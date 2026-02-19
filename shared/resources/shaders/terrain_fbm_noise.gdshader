shader_type spatial;
render_mode blend_mix, cull_disabled;

// ========== 噪声参数 ==========
uniform float noise_scale = 20.0; // 噪声缩放
uniform int fbm_octaves = 4; // FBM叠加层数
uniform float fbm_persistence = 0.5; // 每层振幅衰减系数
uniform float fbm_lacunarity = 2.0; // 每层频率倍数

// ========== 颜色调整参数 ==========
uniform float color_variation_min = 0.75; // 最小颜色亮度系数
uniform float color_variation_max = 1.25; // 最大颜色亮度系数
uniform float hue_shift_amount = 0.05; // 色相偏移量
uniform float saturation_variation = 0.15; // 饱和度变化量
uniform float roughness_value = 0.8; // 表面粗糙度

varying float vertex_noise; // 将顶点噪声传递给片元着色器

// ========== 数学工具函数 ==========

// 伪随机函数 - 基于坐标生成确定性的随机值
float random(vec2 st) {
	return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// 平滑缓动函数 - 5次多项式，比标准smoothstep更平滑
vec2 smoothstep_5(vec2 t) {
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

// ========== 噪声函数 ==========

// 基础2D噪声函数 - 使用双线性插值
float noise(vec2 st) {
	vec2 i = floor(st);
	vec2 f = fract(st);

	// 获取四个角的随机值
	float a = random(i);
	float b = random(i + vec2(1.0, 0.0));
	float c = random(i + vec2(0.0, 1.0));
	float d = random(i + vec2(1.0, 1.0));

	// 使用平滑插值
	vec2 u = smoothstep_5(f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// 分形布朗运动（FBM）- 叠加多层噪声产生自然纹理
// 参数：
//   st - 输入坐标
//   octaves - 叠加层数
//   persistence - 振幅衰减系数
//   lacunarity - 频率倍数
float fbm(vec2 st, int octaves, float persistence, float lacunarity) {
	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 1.0;
	
	for (int i = 0; i < octaves; i++) {
		value += amplitude * noise(st * frequency);
		amplitude *= persistence;
		frequency *= lacunarity;
	}
	
	return value;
}

// ========== 颜色处理函数 ==========

// RGB转HSV
vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// HSV转RGB
vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// 根据噪声值调整颜色亮度
// 参数：
//   base_color - 基础颜色
//   noise_value - 噪声值（0.0-1.0）
//   min_factor - 最小亮度系数
//   max_factor - 最大亮度系数
vec3 apply_color_variation(vec3 base_color, float noise_value, float min_factor, float max_factor) {
	return mix(base_color * min_factor, base_color * max_factor, noise_value);
}

// 应用色相、饱和度和亮度变化
vec3 apply_hsv_variation(vec3 base_color, float noise_value, float hue_shift, float sat_variation, float brightness_min, float brightness_max) {
	vec3 hsv = rgb2hsv(base_color);
	
	// 色相偏移（基于噪声值）
	float hue_offset = (noise_value - 0.5) * hue_shift * 2.0;
	hsv.x = fract(hsv.x + hue_offset);
	
	// 饱和度变化
	float sat_offset = (noise_value - 0.5) * sat_variation * 2.0;
	hsv.y = clamp(hsv.y + sat_offset, 0.0, 1.0);
	
	// 亮度变化
	float brightness_factor = mix(brightness_min, brightness_max, noise_value);
	hsv.z *= brightness_factor;
	
	return hsv2rgb(hsv);
}

// ========== 着色器主函数 ==========

void vertex() {
	// 使用FBM分形噪声计算顶点噪声值
	// 基于世界坐标确保同一顶点在所有三角形中噪声值相同
	vertex_noise = fbm(vec2(VERTEX.x, VERTEX.z) * noise_scale, fbm_octaves, fbm_persistence, fbm_lacunarity);
}

void fragment() {
	vec3 base_color = COLOR.rgb;
	
	vec3 final_color = apply_hsv_variation(base_color, vertex_noise, hue_shift_amount, saturation_variation, color_variation_min, color_variation_max);

	ALBEDO = final_color;
	ROUGHNESS = roughness_value;
}
