// «Bloom» для монет в UI: аддитивный мягкий ореол, пульсирует.
// Настоящий glow окружения в GL Compatibility (Godot 4.3) не поддерживается, поэтому свечение — шейдером.
shader_type canvas_item;
render_mode blend_add;

uniform vec4 glow_color : source_color = vec4(1.0, 0.82, 0.4, 1.0);
uniform float intensity : hint_range(0.0, 2.0) = 0.8;
uniform float pulse_speed = 2.5;

void fragment() {
	float d = length(UV - vec2(0.5)) * 2.0;
	float halo = pow(1.0 - clamp(d, 0.0, 1.0), 2.2);
	float pulse = 0.8 + 0.2 * sin(TIME * pulse_speed);
	COLOR = vec4(glow_color.rgb * halo * intensity * pulse, halo);
}
