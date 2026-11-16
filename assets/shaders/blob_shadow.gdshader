// Мягкая круглая тень под персонажем и пропсами (quad на полу).
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 shadow_color : source_color = vec4(0.169, 0.118, 0.247, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.45;

void fragment() {
	float d = length(UV - vec2(0.5)) * 2.0;
	ALBEDO = shadow_color.rgb;
	ALPHA = (1.0 - smoothstep(0.35, 1.0, d)) * strength;
}
