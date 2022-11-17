shader_type spatial;
render_mode blend_mix, specular_toon, diffuse_toon, cull_disabled, particle_trails;

uniform vec4 lightning_color: source_color = vec4(0.82, 0.88, 0.0, 1);
uniform vec4 emission_color: source_color = vec4(0.82, 0.88, 0.0, 1);
uniform float emission_intensity = 2.0;

uniform float size = 0.05;
uniform float width = 0.1;
uniform float speed = 1.35;
uniform float cycle = 1.5;
uniform float flash_ratio = 0.0;
uniform float time_shift = 7.0;
uniform float time_scale = 2.0;

uniform float bolt_ends_affect= 0.5;
uniform float bolt_modulation = 0.5;
uniform float bolt_position = 0.5;
uniform float bolt_angularity = 2.0;

uniform sampler2D alpha_mask_texture;
uniform vec2 alpha_direction = vec2(1, 1);
uniform float alpha = 0.1;
uniform float alpha_time = 0.5;

uniform sampler2D alpha_mask_texture2;
uniform vec2 alpha_direction2 = vec2(-1, -1);
uniform float alpha2 = 0.1;
uniform float alpha_time2 = 0.5;

uniform sampler2D displacement_texture;
uniform vec2 displacement_direction = vec2(1, 1);
uniform float displacement_strength = 0.5;
uniform float displacement_time = 0.5;

uniform sampler2D displacement_texture2;
uniform vec2 displacement_direction2 = vec2(-1, -1);
uniform float displacement_strength2 = 0.5;
uniform float displacement_time2 = 0.5;

void vertex() {
	vec2 displacement_based_pan = vec2(0.2, 1.0) * (-TIME * displacement_time) + displacement_time;
	vec2 displacement_uv_direction = UV * displacement_direction;
	vec4 displacement = texture(displacement_texture, displacement_uv_direction + displacement_based_pan);
	
	vec2 displacement_based_pan2 = vec2(0.2, 1.0) * (-TIME * displacement_time2) + displacement_time2;
	vec2 displacement_uv_direction2 = UV * displacement_direction2;
	vec4 displacement2 = texture(displacement_texture2, displacement_uv_direction2 + displacement_based_pan2);
	
	VERTEX += (displacement.rgb * displacement_strength) * (displacement2.rgb * displacement_strength2) * NORMAL;
	
	mat4 mat_world = mat4(
			normalize(INV_VIEW_MATRIX[0]) * length(MODEL_MATRIX[0]),
			normalize(INV_VIEW_MATRIX[1]) * length(MODEL_MATRIX[0]),
			normalize(INV_VIEW_MATRIX[2]) * length(MODEL_MATRIX[2]),
			MODEL_MATRIX[3]);
	mat_world *= mat4(
			vec4(cos(INSTANCE_CUSTOM.x), -sin(INSTANCE_CUSTOM.x), 0.0, 0.0), 
			vec4(sin(INSTANCE_CUSTOM.x), cos(INSTANCE_CUSTOM.x), 0.0, 0.0),
			vec4(0.0, 0.0, 1.0, 0.0),
			vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat_world;
}

float rand(float x) {
	return fract(sin(x) * 100000.0);
}

void fragment() {
	vec2 alpha_mask_based_pan = vec2(0.2, 1.0) * (-TIME * alpha_time) + alpha_time;
	vec2 alpha_mask_uv_direction = alpha_direction * UV;
	vec4 alpha_mask = texture(alpha_mask_texture, alpha_mask_uv_direction + alpha_mask_based_pan);
	
	vec2 alpha_mask_based_pan2 = vec2(0.2, 1.0) * (-TIME * alpha_time2) + alpha_time2;
	vec2 alpha_mask_uv_direction2 = alpha_direction2 * UV;
	vec4 alpha_mask2 = texture(alpha_mask_texture2, alpha_mask_uv_direction2 + alpha_mask_based_pan2);
	
	float bolt = abs(mod( UV.x * cycle + ((TIME * time_scale) + time_shift) * speed * -1.0, 0.5) - 0.25) - 0.125;
	bolt *= width;
	bolt *=  (bolt_ends_affect - abs(UV.x - bolt_modulation)) * bolt_angularity; 
	
	float wave = abs(UV.x - bolt_position + bolt);
	wave = 1. - step(size * .5, wave);
	
	float flashing = step(rand(TIME) * flash_ratio, .5);
	wave *= flashing;
	
	vec4 display = lightning_color * vec4(wave);
	
	ALBEDO = COLOR.rgb * display.rgb;
	ALPHA = COLOR.a * display.a * round((alpha + 0.5) * alpha_mask.r) * round((alpha2 + 0.5) * alpha_mask2.r);
//	ALPHA = COLOR.a * display.a;
	EMISSION = emission_color.rgb * emission_intensity;
	ALPHA_SCISSOR_THRESHOLD = 0.1;
}
