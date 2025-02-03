shader_type spatial;

uniform float time_speed: hint_range(0.0, 10.0, 1.0) = 2.0;
uniform float minFrequency: hint_range(0.0, 10.0, 1.0) = 2.0;
uniform float maxFrequency: hint_range(0.0, 10.0, 1.0) = 8.0;
uniform float minAmplitude: hint_range(0.0, 1.0, 0.1) = 0.1;
uniform float maxAmplitude: hint_range(0.0, 1.0, 0.1) = 0.3;
const float top = 2.0;
const float bottom = -2.0;

uniform vec4 color : source_color = vec4(0.0);

void vertex() {
	// Called for every vertex the material is visible on.
	//VERTEX.y += sin(TIME * 5.0 + VERTEX.z * 10.0) * 0.1;
	float normalizedY = clamp((VERTEX.y + top) / (top * 2.0), 0.0, 1.0);
	// normalizedY is assumed to be in the range [0, 1], change to highlight extremes
	float distanceFromCentre = abs(normalizedY - 0.5) * 2.0;
	float freq = mix(minFrequency, maxFrequency, distanceFromCentre);
	float amp = mix(minAmplitude, maxAmplitude, 1.0 - distanceFromCentre);
	VERTEX.x += sin(TIME * time_speed + VERTEX.y * freq) * amp;
}

void fragment() {
	// Called for every pixel the material is visible on.
	ALBEDO.rgb = color.rgb;
	ALPHA = color.a;
}