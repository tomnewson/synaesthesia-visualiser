// Godot 4.3, Forward+ or Mobile
shader_type spatial;
render_mode unshaded, fog_disabled;

// Main buffers
uniform sampler2D screen_texture : source_color, hint_screen_texture;
uniform sampler2D depth_texture : hint_depth_texture;
uniform sampler2D normal_rough_texture : hint_normal_roughness_texture;

// Distortion parameters
uniform sampler2D distortion_texture;
uniform float distortion_intensity: hint_range(0.0, 1.0, 0.01);
uniform bool distortion = true;

// Waves buffer from viewport
uniform sampler2D waves_buffer;

void vertex() {
    POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
    // Apply distortion
    float weighted_ds_int = distortion ? distortion_intensity * 0.05 : 0.0;
    vec2 distortedUV = SCREEN_UV + texture(distortion_texture, UV).r * weighted_ds_int;

    // Get distorted screen color
    vec4 screen = texture(screen_texture, distortedUV);

    // Get waves mask from viewport buffer
    vec4 waves = texture(waves_buffer, distortedUV);

    // Combine effects
    vec3 final_color = mix(screen.rgb, waves.rgb, waves.a);

    // Depth calculations (kept for potential future use)
    float depth_raw = texture(depth_texture, SCREEN_UV).x;
    vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_raw);
    vec4 position_view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
    position_view.xyz /= position_view.w;
    float linear_depth = -position_view.z;

    // Normal calculations (kept for potential future use)
    vec4 normal_rough = texture(normal_rough_texture, SCREEN_UV);
    vec3 normals_view_raw = normal_rough.xyz;
    vec3 normals_view_remapped = normals_view_raw.xyz * 2.0 - 1.0;
    vec3 normals_world = (INV_VIEW_MATRIX * vec4(normals_view_remapped, 0.0)).xyz;
    float roughness = normal_rough.w;

    // Output combined result
    ALBEDO.rgb = final_color;
}