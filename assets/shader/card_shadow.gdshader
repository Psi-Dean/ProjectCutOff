shader_type canvas_item;

uniform float alpha : hint_range(0.0, 1.0) = 0.35;
uniform bool selected = false;
uniform vec4 selected_color : source_color = vec4(1.0, 0.9, 0.5, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a <= 0.001) {
		discard;
	}

	vec3 tint = selected ? selected_color.rgb : vec3(0.0, 0.0, 0.0);
	COLOR = vec4(tint, tex.a * alpha);
}
