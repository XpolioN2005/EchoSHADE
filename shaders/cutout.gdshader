shader_type canvas_item;

uniform vec4 base_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform int num_points = 1;
uniform vec2 points[16];
uniform float radius = 50.0;
uniform float smoothness = 5.0;
uniform vec2 rect_size;

void fragment() {
    vec4 final_color = base_color;
    vec2 frag_pos = SCREEN_UV * rect_size;

    for (int i = 0; i < num_points; i++) {
        float dist = distance(frag_pos, points[i]);

        if (dist < radius) {
            // alpha = 0 at center, 1 at edge of radius
            float alpha = smoothstep(radius-smoothness, radius, dist); 
            final_color.a *= alpha;
        }
    }

    COLOR = final_color;
}
