shader_type canvas_item;

uniform float wave_strength : hint_range(0.0, 0.1) = 0.02;
uniform float wave_frequency : hint_range(0.0, 50.0) = 20.0;
uniform float tint_strength : hint_range(0.0, 1.0) = 0.2;
uniform vec4 tint_color : source_color = vec4(0.0, 0.4, 0.7, 1.0);

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

void fragment() {
    // Get the screen UV coordinates.
    vec2 uv = SCREEN_UV;
    // Apply a wavy distortion based on sine/cosine and the built-in TIME uniform.
    uv.y += sin(uv.x * wave_frequency + TIME) * wave_strength;
    uv.x += cos(uv.y * wave_frequency + TIME) * wave_strength;
    // Sample the underlying screen texture using the distorted UVs.
    vec4 screen_tex = texture(SCREEN_TEXTURE, uv);
    // Mix in a blue tint to simulate underwater lighting.
    COLOR = mix(screen_tex, tint_color, tint_strength);
}
