// Лёгкая виньетка поверх 3D (ColorRect на CanvasLayer между сценой и UI).
shader_type canvas_item;

uniform vec4 tint : source_color = vec4(0.169, 0.118, 0.247, 1.0);
uniform float inner_radius : hint_range(0.0, 1.5) = 0.55;
uniform float outer_radius : hint_range(0.0, 2.0) = 1.15;
uniform float strength : hint_range(0.0, 1.0) = 0.45;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	uv.x *= 0.75;
	float d = length(uv) * 2.0;
	COLOR = vec4(tint.rgb, smoothstep(inner_radius, outer_radius, d) * strength);
}
