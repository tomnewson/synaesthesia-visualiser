shader_type spatial;

void vertex() {
	// Called for every vertex the material is visible on.
	VERTEX.y += sin(TIME * 5.0 + VERTEX.x * 10.0) * 0.1;
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec3 color;
	color.r = (sin(TIME * 6.0 + VERTEX.x * 10.0) + 1.0) * 0.5;
	color.g = (sin(TIME * 7.0 + VERTEX.x * 10.0) + 1.0) * 0.5;
	color.b = (sin(TIME * 8.0 + VERTEX.x * 10.0) + 1.0) * 0.5;
	ALBEDO = color;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
