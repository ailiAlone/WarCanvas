#[compute]
#version 450

layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

// 高度图（读写）
layout(set = 1, binding = 0) buffer HeightMap {
    float heights[];
}
height_buffer;

layout(set = 1, binding = 1) buffer Params {
    float center_x;
    float center_y;
    float radius;
    float strength;
    float mode;
    float map_width;
    float map_height;
}
params;

float get_height(int x, int y) {
    if (x < 0 || x >= int(params.map_width) || y < 0 || y >= int(params.map_height)) {
        return 0.0;
    }
    return height_buffer.heights[y * int(params.map_width) + x];
}

void main() {
    ivec2 coord = ivec2(gl_GlobalInvocationID.xy);
    
    if (coord.x >= int(params.map_width) || coord.y >= int(params.map_height)) {
        return;
    }
    
    float dist = distance(vec2(coord.x, coord.y), vec2(params.center_x, params.center_y));
    
    if (dist < params.radius) {
        float influence = 1.0 - (dist / params.radius);
        
        float current_h = get_height(coord.x, coord.y);
        float new_h = current_h;
        
        if (int(params.mode) == 0) {
            // 平整到指定高度 (mix)
            new_h = mix(current_h, params.strength, influence);
        } else if (int(params.mode) == 1) {
            // 抬高地形 (add)
            new_h = current_h + params.strength * influence;
        } else if (int(params.mode) == 2) {
            // 降低地形 (subtract)
            new_h = current_h - params.strength * influence;
        } else if (int(params.mode) == 3) {
            // 放大/压缩 (multiply)
            new_h = current_h * (1.0 + params.strength * influence);
        } else if (int(params.mode) == 4) {
            // 平滑地形 (3x3 平均)
            float total = 0.0;
            float count = 0.0;
            
            for (int dz = -1; dz <= 1; dz++) {
                for (int dx = -1; dx <= 1; dx++) {
                    total += get_height(coord.x + dx, coord.y + dz);
                    count += 1.0;
                }
            }
            
            float average = total / count;
            new_h = current_h + (average - current_h) * influence;
        }
        
        height_buffer.heights[coord.y * int(params.map_width) + coord.x] = new_h;
    }
}