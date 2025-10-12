shader_type canvas_item;

uniform vec4 base_color = vec4(1.0, 0.0, 0.0, 0.7); // color of the oval
uniform vec2 rect_size = vec2(100.0, 100.0);        // node size from GDScript
uniform vec2 radius = vec2(650.0, 400.0);           // horizontal and vertical radius
uniform float smoothness = 100.0;                   // softness of edges

void fragment() {
    vec2 frag_pos = UV * rect_size;

    // Center of the rectangle
    vec2 center = rect_size * 0.5;

    // Compute normalized distance along each axis
    vec2 d = (frag_pos - center) / radius;

    // Distance in ellipse space
    float dist = length(d);

    // Smooth alpha: 1 at center, 0 at edge
    float alpha = smoothstep(1.0 - smoothness / max(radius.x, radius.y), 1.0, dist);
	alpha *= 0.6;
    COLOR = vec4(base_color.rgb, base_color.a * alpha);
}
