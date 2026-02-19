shader_type spatial;

uniform sampler2D height_map;
uniform vec2 terrain_size;
uniform float elevation_scale;

// 可调节的噪音参数（添加到uniform部分）
const float noise_scale = 0.7;
const float noise_strength = 0.4;
const float detail_scale = 1.4;
const float detail_strength = 0.24;

// 噪音函数 - 增加地面细节
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    // 四个角落的哈希值
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    // 平滑插值
    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
           (c - a) * u.y * (1.0 - u.x) +
           (d - b) * u.x * u.y;
}

// 分形布朗运动 - 多层级噪音
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;

    // 添加多个噪音层
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }

    return value;
}

void vertex() {
    float h = texture(height_map, UV).r;

    vec3 pos = VERTEX;
    pos.y = h;

    VERTEX = pos;
}

void fragment() {
    float h = texture(height_map, UV).r;

    // 计算世界坐标用于噪音
    vec2 world_pos = UV * terrain_size;

    // 添加细节噪音（基于高度调整强度）
    float detail_noise = fbm(world_pos * noise_scale) * noise_strength;  // 低频细节
    float micro_noise = fbm(world_pos * detail_scale) * detail_strength;  // 高频细节

    // 应用噪音到颜色计算
    float final_noise = detail_noise + micro_noise;

    // 固定颜色定义（12个颜色）
    vec3 color_deep_water = vec3(0.0, 0.1, 0.4);
    vec3 color_water = vec3(0.0, 0.3, 0.8);
    vec3 color_sand = vec3(0.9, 0.8, 0.3);
    vec3 color_wetland = vec3(0.7, 0.8, 0.4);
    vec3 color_light_grass = vec3(0.35, 0.75, 0.25);   // 调整浅绿
    vec3 color_grass = vec3(0.3, 0.7, 0.2);           // 保持标准绿
    vec3 color_dark_grass = vec3(0.25, 0.65, 0.18);   // 调整深绿
    vec3 color_hill = vec3(0.6, 0.65, 0.4);
    vec3 color_light_rock = vec3(0.7, 0.7, 0.6);
    vec3 color_rock = vec3(0.5, 0.5, 0.5);
    vec3 color_dark_rock = vec3(0.4, 0.4, 0.4);
    vec3 color_snow = vec3(0.95, 0.95, 1.0);

    // 固定阈值（12个阈值，对应12个颜色）
    float t_deep_water = -1.0 * elevation_scale;
    float t_water = -0.8 * elevation_scale;
    float t_shallow = -0.4 * elevation_scale;
    float t_sand = -0.3 * elevation_scale;
    float t_wetland = -0.25 * elevation_scale;
    float t_light_grass = -0.2 * elevation_scale;
    float t_grass = 0.0 * elevation_scale;
    float t_dark_grass = 0.05 * elevation_scale;
    float t_hill = 0.3 * elevation_scale;
    float t_light_rock = 0.4 * elevation_scale;
    float t_rock = 0.5 * elevation_scale;
    float t_dark_rock = 0.6 * elevation_scale;
    float t_snow = 0.7 * elevation_scale;

    vec3 base_color;

    // 基础颜色选择（原有逻辑）
    if (h > t_snow) {
        base_color = color_snow;
    } else if (h > t_dark_rock) {
        float mix_t = smoothstep(t_dark_rock, t_snow, h);
        base_color = mix(color_dark_rock, color_snow, mix_t);
    } else if (h > t_rock) {
        float mix_t = smoothstep(t_rock, t_dark_rock, h);
        base_color = mix(color_rock, color_dark_rock, mix_t);
    } else if (h > t_light_rock) {
        float mix_t = smoothstep(t_light_rock, t_rock, h);
        base_color = mix(color_light_rock, color_rock, mix_t);
    } else if (h > t_hill) {
        float mix_t = smoothstep(t_hill, t_light_rock, h);
        base_color = mix(color_hill, color_light_rock, mix_t);
    } else if (h > t_dark_grass) {
        float mix_t = smoothstep(t_dark_grass, t_hill, h);
        base_color = mix(color_dark_grass, color_hill, mix_t);
    } else if (h > t_grass) {
        float mix_t = smoothstep(t_grass, t_dark_grass, h);
        base_color = mix(color_grass, color_dark_grass, mix_t);
    } else if (h > t_light_grass) {
        float mix_t = smoothstep(t_light_grass, t_grass, h);
        base_color = mix(color_light_grass, color_grass, mix_t);
    } else if (h > t_wetland) {
        float mix_t = smoothstep(t_wetland, t_light_grass, h);
        base_color = mix(color_wetland, color_light_grass, mix_t);
    } else if (h > t_sand) {
        float mix_t = smoothstep(t_sand, t_wetland, h);
        base_color = mix(color_sand, color_wetland, mix_t);
    } else if (h > t_shallow) {
        float mix_t = smoothstep(t_shallow, t_sand, h);
        base_color = mix(color_water, color_sand, mix_t);
    } else if (h > t_water) {
        float mix_t = smoothstep(t_water, t_shallow, h);
        base_color = mix(color_water, color_water, mix_t);
    } else if (h > t_deep_water) {
        float mix_t = smoothstep(t_deep_water, t_water, h);
        base_color = mix(color_deep_water, color_water, mix_t);
    } else {
        base_color = color_deep_water;
    }

    // 应用噪音到最终颜色
    vec3 final_color = base_color + vec3(final_noise) * 0.3;

    ALBEDO = final_color;
    ROUGHNESS = 0.85 + final_noise * 0.1;  // 噪音也影响粗糙度
    METALLIC = 0.0;
}