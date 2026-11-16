// Задняя стена-фон: вертикальный градиент из палитры и мягкий узор точек. Без освещения.
shader_type spatial;
render_mode unshaded, cull_back;

uniform vec4 top_color : source_color = vec4(1.0, 0.957, 0.902, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.655, 0.545, 0.98, 1.0);
uniform vec4 dot_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float dot_scale = 26.0;
uniform float dot_alpha : hint_range(0.0, 1.0) = 0.12;

void fragment() {
	float t = smoothstep(0.0, 1.0, UV.y);
	vec3 base = mix(top_color.rgb, bottom_color.rgb, t);
	vec2 cell = fract(UV * vec2(dot_scale * 2.0, dot_scale)) - 0.5;
	float d = 1.0 - smoothstep(0.12, 0.16, length(cell));
	ALBEDO = mix(base, dot_color.rgb, d * dot_alpha);
}
