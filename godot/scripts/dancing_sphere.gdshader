// NOTE: Shader automatically converted from Godot Engine 4.3.stable's StandardMaterial3D.

shader_type spatial;
render_mode depth_draw_always, diffuse_burley, blend_mix;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

uniform sampler2D texture_emission : source_color, hint_default_black, filter_linear_mipmap, repeat_enable;
uniform vec4 emission : source_color;
uniform float emission_energy : hint_range(0.0, 100.0, 0.01);

// Light projection parameters
uniform float light_intensity : hint_range(1.0, 10.0) = 2.0;
uniform float edge_softness : hint_range(0.0, 2.0) = 0.5;
uniform float core_size : hint_range(0.1, 0.9) = 0.3;
uniform float transparency : hint_range(0.0, 1.0) = 0.7;

// Ring parameters
uniform float ring_count : hint_range(1.0, 20.0) = 6.0;
uniform float ring_thickness : hint_range(0.01, 2.0) = 0.05;
uniform float ring_intensity : hint_range(0.0, 1.0) = 0.7;

// Tadpole shape parameters
uniform float head_size : hint_range(0.3, 0.8) = 0.5;
uniform float tail_length : hint_range(0.5, 10.0) = 1.5;
uniform float tail_taper : hint_range(0.1, 1.0) = 0.3;

// Wave distortion parameters
uniform float wave_amplitude : hint_range(0.0, 1.0) = 0.2;
uniform float wave_frequency : hint_range(0.5, 10.0) = 3.0;
uniform float wave_speed : hint_range(0.1, 5.0) = 1.0;
uniform float tail_wave_multiplier : hint_range(1.0, 5.0) = 2.5; // How much stronger the tail waves are

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;

	// Tadpole shape transformation
	// Determine if this vertex is part of the head or tail based on its X position
	float head_boundary = head_size;

	// Get normalized x position (assuming sphere is centered at origin)
	// This works because the sphere's vertices range from -1 to 1 in each dimension
	float normalized_pos_x = VERTEX.x * 0.5 + 0.5; // Convert from -1,1 to 0,1 range

	// Calculate stretch factor based on position
	float stretch_factor = 0.0;
	float tail_pos = 0.0; // Will be used for wave amplitude scaling

	if (normalized_pos_x < head_boundary) {
		// Head part - keep round
		stretch_factor = 0.0;
		tail_pos = 0.0;
	} else {
		// Tail part - stretch based on distance from head boundary
		tail_pos = (normalized_pos_x - head_boundary) / (1.0 - head_boundary);
		stretch_factor = tail_pos * tail_length;

		// Apply tapering to the tail (gets thinner toward the end)
		float taper_factor = 1.0 - (tail_pos * (1.0 - tail_taper));
		VERTEX.y *= taper_factor;
		VERTEX.z *= taper_factor;
	}

	// Apply stretching to create the tail
	VERTEX.x += stretch_factor;

	// Apply sine wave distortion - differently to head and tail
	// Calculate the normalized height (Y position) of the vertex
	float height_factor = abs(VERTEX.y);

	// Create time-based wave effect along X-axis
	float wave_phase = VERTEX.x * wave_frequency + TIME * wave_speed;
	float wave_value = sin(wave_phase) * wave_amplitude;

	// Calculate the wave amplitude modifier based on position in tadpole
	// Use progressive scaling - head has normal amplitude, tail has increased amplitude
	float position_wave_scale = 1.0;

	if (normalized_pos_x >= head_boundary) {
		// In tail section - scale up the wave amplitude
		// Progressive increase: starts at 1.0 at head boundary, goes up to tail_wave_multiplier at end
		position_wave_scale = 1.0 + (tail_wave_multiplier) * VERTEX.x;
	}

	// Apply stronger distortion to top/bottom, less in middle
	// And apply the position-based scaling for head vs tail
	VERTEX.y += wave_value * height_factor * position_wave_scale;

	// Also apply a smaller complementary wave to the Z axis for a more organic feel
	VERTEX.z += wave_value * height_factor * 1.3 * position_wave_scale;
}

void fragment() {
	vec2 base_uv = UV;

	// Calculate distance from center for radial effect (in local model space)
	float distance_from_center = length(NORMAL);

	// Create gradient falloff for light effect
	float falloff = smoothstep(core_size, 1.0, distance_from_center * edge_softness);
	float light_factor = 1.0 - falloff;

	// Calculate ring pattern
	// Use dot product of UP vector with NORMAL to determine position on sphere
	float sphere_height = dot(NORMAL, vec3(0.0, 1.0, 0.0)) * 0.5 + 0.5;
	// Create rings based on height
	float ring_pattern = sin(sphere_height * 3.14159 * ring_count) * 0.5 + 0.5;
	// Make the pattern sharper to create distinct rings
	ring_pattern = smoothstep(0.5, ring_thickness, ring_pattern);
	// Invert to get black rings
	ring_pattern = 1.0 - ring_pattern * ring_intensity;

	// Base color and texture
	vec4 albedo_tex = texture(texture_albedo, base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb * ring_pattern;

	// Enhanced transparency - combine the edge falloff with the overall transparency
	float alpha_value = mix(transparency, 0.0, falloff);
	ALPHA = alpha_value * ring_pattern;

	// Metallic and roughness properties

	METALLIC = 0.0; // Reduce metallic for more light-like appearance
	SPECULAR = 1.5; // Enhance specular for light effect
	ROUGHNESS = 2.0; // Lower roughness for more light-like appearance

}
