// Toon-шейдер ClipStar: жёсткая градация в 3 тона (тень / полутон / свет), цветная тень,
// ободок (rim) с освещённой стороны и необязательное свечение. Работает в GL Compatibility.
shader_type spatial;
render_mode cull_back, specular_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
// Цвет, к которому уходит тень (не чёрный — так сцена выглядит «мультяшно»).
uniform vec4 shade_color : source_color = vec4(0.36, 0.25, 0.55, 1.0);
uniform float mid_threshold : hint_range(0.0, 1.0) = 0.12;
uniform float light_threshold : hint_range(0.0, 1.0) = 0.55;
uniform float band_softness : hint_range(0.0, 0.2) = 0.02;
uniform float mid_tone : hint_range(0.0, 1.0) = 0.55;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.22;
uniform float emission_strength : hint_range(0.0, 4.0) = 0.0;

void fragment() {
	ALBEDO = albedo.rgb;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	EMISSION = albedo.rgb * emission_strength;
}

void light() {
	float ndl = dot(NORMAL, LIGHT) * ATTENUATION;
	float mid = smoothstep(mid_threshold - band_softness, mid_threshold + band_softness, ndl);
	float full = smoothstep(light_threshold - band_softness, light_threshold + band_softness, ndl);
	float tone = mix(0.0, mid_tone, mid) + (1.0 - mid_tone) * full;
	vec3 tint = mix(shade_color.rgb * 0.45, vec3(1.0), tone);
	DIFFUSE_LIGHT += tint * LIGHT_COLOR / PI;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0) * step(0.05, ndl);
	SPECULAR_LIGHT += rim * rim_strength * LIGHT_COLOR / PI;
}
