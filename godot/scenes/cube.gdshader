shader_type spatial;
render_mode unshaded, cull_disabled, blend_add;

// Collapse parameters
uniform float collapse_speed = 1.0;
uniform float collapse_progress : hint_range(0.0, 1.0) = 0.0;
uniform vec3 collapse_direction = vec3(0.0, -1.0, 0.0);
uniform float randomness = 0.5;
uniform float edge_glow = 2.0;

// Visual parameters
uniform vec4 albedo : source_color = vec4(1.0, 0.5, 0.2, 1.0);
uniform sampler2D noise_tex : source_color;

void vertex() {
    // Get original vertex position
    vec3 original_pos = VERTEX;

    // Calculate collapse factor with noise variation
    float noise = texture(noise_tex, UV * 2.0).r * randomness;
    float collapse_factor = clamp(collapse_progress + (TIME * collapse_speed * 0.1), 0.0, 1.0);

    // Calculate displacement direction
    vec3 dir = normalize(collapse_direction + vec3(noise - 0.5, noise * 0.3, noise - 0.2));

    // Displace vertices
    VERTEX = original_pos + dir * collapse_factor * 2.0;

    // Create crumbling effect
    VERTEX *= 1.0 - smoothstep(0.7, 1.0, collapse_factor);
}

void fragment() {
    // Edge detection using normal dot view
    vec3 normal = normalize(NORMAL);
    vec3 view_dir = vec3(0.0,0.0,1.0);
    float edge = 1.0 - abs(dot(normal, view_dir));

    // Disintegration effect
    float disintegrate = smoothstep(0.7, 1.0, collapse_progress);
    float alpha = 1.0 - disintegrate;

    // Combine effects
    vec3 emission = albedo.rgb * edge_glow * (edge + disintegrate * 2.0);

    ALBEDO = albedo.rgb * alpha;
    EMISSION = emission;
    ALPHA = alpha;

    // Fade out completely when collapsed
    ALPHA *= 1.0 - smoothstep(0.95, 1.0, collapse_progress);
}