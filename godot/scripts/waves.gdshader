shader_type spatial;

// Adjust these parameters to control the wave effect
uniform float amplitude = 0.3;
uniform float frequency = 10.0;
uniform float speed = 3.0;
uniform vec2 wave_direction = vec2(0.0, 1.0); // Wave propagation direction

uniform vec4 add_color : source_color = vec4(0.0);
render_mode depth_draw_always, diffuse_burley;

void vertex() {
    // Calculate wave displacement
    float wave = sin(VERTEX.x * wave_direction.x * frequency +
                    VERTEX.z * wave_direction.y * frequency +
                    TIME * speed);

	float wave2 = sin(VERTEX.x * frequency * 0.8 + TIME * speed * 1.2 + 1.0);
	VERTEX.y += (wave + wave2) * amplitude * 0.5;

    //Add slight offset to normals for better lighting
    NORMAL = normalize(NORMAL + vec3(0.0, wave * 0.2, 0.0));
}

void fragment() {
    ALBEDO = add_color.rgb;
	ALPHA = add_color.a;
	ROUGHNESS = 0.4;
	METALLIC = 0.5;
}
