shader_type canvas_item;
render_mode unshaded;

uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform float line_density = 220.0;
uniform float speed = 90.0;
uniform float thickness = 0.22;

float hash1(float n) {
	return fract(sin(n) * 43758.5453123);
}

void fragment() {
	float y = UV.y * line_density;
	float line_id = floor(y);
	float local = fract(y);

	float rnd = hash1(line_id);
	float anim = hash1(line_id + floor(TIME * speed));

	float line = smoothstep(thickness, 0.0, abs(local - 0.5));
	float intensity = mix(0.15, 1.0, step(0.6, rnd));
	intensity *= mix(0.7, 1.1, anim);

	float alpha = strength * line * intensity;

	COLOR = vec4(vec3(1.0), alpha);
}