shader_type canvas_item;

uniform float dissolve_value : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 color = texture(TEXTURE, UV);

	// 双层伪随机噪声，模拟溶解效果
	vec2 uv1 = floor(UV * 25.0);
	vec2 uv2 = floor(UV * 50.0);
	float r1 = fract(sin(dot(uv1, vec2(12.9898, 78.233))) * 43758.5453);
	float r2 = fract(sin(dot(uv2, vec2(78.233, 12.9898))) * 43758.5453) * 0.5;
	float noise = (r1 + r2) / 1.5;

	float edge_width = 0.08;

	if (noise > dissolve_value + edge_width) {
		discard;
	} else if (noise > dissolve_value) {
		float edge_t = (noise - dissolve_value) / edge_width;
		color.rgb = mix(vec3(1.0, 0.35, 0.0), color.rgb, edge_t);
		color.a *= edge_t;
		COLOR = color;
	} else {
		COLOR = color;
	}
}
