shader_type canvas_item;

// 最多支持8个顶点的多边形
uniform vec2 points[8];
uniform int point_count : hint_range(3, 8) = 3;

// 判断点是否在多边形内（射线法）
bool point_in_polygon(vec2 pt, vec2 polygon[8], int count) {
    bool inside = false;

    for (int i = 0, j = count - 1; i < count; j = i++) {
        vec2 vi = polygon[i];
        vec2 vj = polygon[j];

        // 检查边与水平射线的交点
        if (((vi.y > pt.y) != (vj.y > pt.y)) &&
            (pt.x < (vj.x - vi.x) * (pt.y - vi.y) / (vj.y - vi.y) + vi.x)) {
            inside = !inside;
        }
    }

    return inside;
}

void fragment() {
    vec2 uv = UV;

    if (point_in_polygon(uv, points, point_count)) {
        COLOR = texture(TEXTURE, uv);
    } else {
        discard;
    }
}