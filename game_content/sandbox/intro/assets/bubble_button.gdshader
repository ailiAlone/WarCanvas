// bubble_button.gdshader
shader_type canvas_item;

uniform float bubble_radius : hint_range(0.0, 0.5) = 0.4;
uniform vec4 bubble_color : source_color = vec4(0.4, 0.7, 1.0, 0.9);
uniform float time_speed : hint_range(0.0, 5.0) = 2.5;
uniform float intensity : hint_range(0.0, 3.0) = 2.0;

void fragment() {
    vec2 uv = UV;
    vec4 color = texture(TEXTURE, uv);
    
    // 创建圆形遮罩
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(uv, center);
    float circle_mask = smoothstep(0.5, 0.45, dist);
    
    // 泡泡动画
    float time = TIME * time_speed;
    float wave1 = sin(uv.x * 25.0 + time * 3.0) * 0.15;
    float wave2 = cos(uv.y * 20.0 + time * 2.5) * 0.12;
    
    // 边缘光晕 - 增强效果
    float edge = smoothstep(0.0, bubble_radius, length(uv - center));
    vec4 bubble_effect = bubble_color * (1.0 - edge) * 1.2;
    
    // 泡泡上升效果 - 更明显的气泡
    float bubble_y = fract(uv.y - time * 0.8);
    float bubble_x = fract(uv.x - time * 0.6);
    float bubble1 = smoothstep(0.0, 0.25, bubble_y) * 
                    smoothstep(0.4, 0.25, bubble_y);
    float bubble2 = smoothstep(0.0, 0.2, bubble_x) * 
                    smoothstep(0.3, 0.2, bubble_x);
    
    // 添加更多动态气泡
    float bubble3 = sin(time * 5.0 + uv.x * 8.0) * 0.5 + 0.5;
    float bubble4 = cos(time * 4.0 + uv.y * 10.0) * 0.5 + 0.5;
    float bubble5 = sin(time * 3.0 + uv.y * 7.0) * 0.5 + 0.5;
    float bubble6 = cos(time * 3.5 + uv.x * 9.0) * 0.5 + 0.5;
    
    // 组合所有效果
    vec4 bubble_rise = bubble_color * (bubble1 * 0.7 + bubble2 * 0.5 + bubble3 * 0.4 + bubble4 * 0.3 + bubble5 * 0.2 + bubble6 * 0.15);
    
    // 应用圆形遮罩
    vec4 final_color = mix(color, bubble_color, (bubble1 + bubble2 + bubble3 * 0.5 + bubble4 * 0.4 + bubble5 * 0.3 + bubble6 * 0.2) * 0.7) + bubble_effect + bubble_rise;
    COLOR = final_color * circle_mask;
}