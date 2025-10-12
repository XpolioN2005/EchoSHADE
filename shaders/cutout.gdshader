shader_type canvas_item;

uniform vec4 base_color = vec4(1.0,1.0,1.0,1.0);
uniform vec2 rect_size = vec2(100.0, 100.0); // send from GDScript
uniform float radius = 100.0;                 // in pixels
uniform float smoothness = 5.0;              // in pixels

void fragment() {
    // UV scaled to node size
    vec2 frag_pos = UV * rect_size;

    // center of the rect
    vec2 center = rect_size * 0.5;

    float dist = distance(frag_pos, center);
    float alpha = 1.0 - smoothstep(radius, radius- smoothness, dist);

    COLOR = vec4(base_color.rgb, base_color.a * alpha);
}
