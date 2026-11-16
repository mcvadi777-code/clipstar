// Обводка: второй проход с вывернутыми гранями (cull_front), раздутый по нормалям.
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque;

uniform vec4 outline_color : source_color = vec4(0.169, 0.118, 0.247, 1.0);
uniform float thickness : hint_range(0.0, 0.1) = 0.012;

void vertex() {
	VERTEX += NORMAL * thickness;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
