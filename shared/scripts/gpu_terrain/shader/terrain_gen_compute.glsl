#[compute]
#version 450

layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

layout(set = 0, binding = 0) buffer HeightMap {
    float heights[];
}
height_buffer;

layout(set = 0, binding = 1) buffer Params {
    float map_width;
    float map_height;
    float seed;
    float elevation_scale;
    float frequency;
    float octaves;
    float persistence;
    float lacunarity;
}
params;

vec2 GRAD[8] = vec2[](
    vec2(1, 1), vec2(-1, 1), vec2(1, -1), vec2(-1, -1),
    vec2(1, 0), vec2(-1, 0), vec2(0, 1), vec2(0, -1)
);

float fade(float t) {
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

float lerp(float a, float b, float t) {
    return a + t * (b - a);
}

float grad(int hash, float x, float y) {
    int idx = hash & 7;
    return dot(GRAD[idx], vec2(x, y));
}

// 梯度噪声（真正的 Perlin 噪声，无周期性）
float hash_int(int x, int y) {
    uint ux = uint(int(x));
    uint uy = uint(int(y));
    uint h = ux * 374761393u + uy * 668265263u + uint(int(params.seed)) * 127u;
    h ^= h >> 13u;
    h *= 1274126177u;
    return float(h) / 4294967295.0;
}

float grad_noise(float x, float y) {
    vec2 p = vec2(x, y);
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    int ix = int(i.x);
    int iy = int(i.y);
    
    float g00 = hash_int(ix, iy) * 2.0 - 1.0;
    float g10 = hash_int(ix + 1, iy) * 2.0 - 1.0;
    float g01 = hash_int(ix, iy + 1) * 2.0 - 1.0;
    float g11 = hash_int(ix + 1, iy + 1) * 2.0 - 1.0;
    
    float v00 = dot(vec2(g00, g00), f);
    float v10 = dot(vec2(g10, g10), f - vec2(1.0, 0.0));
    float v01 = dot(vec2(g01, g01), f - vec2(0.0, 1.0));
    float v11 = dot(vec2(g11, g11), f - vec2(1.0, 1.0));
    
    return mix(mix(v00, v10, u.x), mix(v01, v11, u.x), u.y);
}

float perlin(float x, float y) {
    return grad_noise(x, y);
}

float fractal_brownian_motion(float x, float y) {
    // 直接对每个坐标采样，不使用锚点
    int octaves = int(params.octaves);
    float amplitude = 1.0;
    float freq = params.frequency;
    float total = 0.0;
    
    for (int i = 0; i < octaves; i++) {
        // 使用新哈希噪声，直接基于世界坐标
        float n = perlin(x * freq + params.seed, y * freq + params.seed * 0.5);
        total += n * amplitude;
        amplitude *= params.persistence;
        freq *= params.lacunarity;
    }
    
    return clamp(total, -1.0, 1.0);
}

void main() {
    int x = int(gl_GlobalInvocationID.x);
    int y = int(gl_GlobalInvocationID.y);
    
    if (x >= int(params.map_width) || y >= int(params.map_height)) {
        return;
    }
    
    int idx = y * int(params.map_width) + x;
    
    // 直接对 (x, y) 采样，每个像素独立
    float h = fractal_brownian_motion(float(x), float(y));
    h *= params.elevation_scale;
    
    height_buffer.heights[idx] = h;
}
