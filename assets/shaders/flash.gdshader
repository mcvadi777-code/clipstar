// Вспышка камеры: белый экран, гаснущий от центра к краям.
shader_type canvas_item;

uniform float amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float d = length(UV - vec2(0.5)) * 1.6;
	COLOR = vec4(1.0, 1.0, 1.0, amount * (1.0 - d * 0.5));
}
