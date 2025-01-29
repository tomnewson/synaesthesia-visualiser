shader_type spatial;
render_mode unshaded, cull_disabled;

// Uniforms
uniform float overallSpeed = 0.2;
uniform float width = 0.5;
uniform vec4 lineColor: source_color = vec4(0.25, 0.5, 1.0, 0.0);
uniform float scale = 5.0;

// Constants
const float gridSmoothWidth = 0.015;
const float axisWidth = 0.05;
const float majorLineWidth = 0.025;
const float minorLineWidth = 0.0125;
const float majorLineFrequency = 5.0;
const float minorLineFrequency = 1.0;
const float lineAmplitude = 1.0;
const float warpFrequency = 0.0;
const float warpAmplitude = 0.0;
const float offsetFrequency = 0.2;
const float minOffsetSpread = 2.0;
const float maxOffsetSpread = 6.0;
const int linesPerGroup = 10;

// Function macros
#define drawCircle(P, r, U) smoothstep(r + gridSmoothWidth, r, length(U - (P)))
#define drawSmoothLine(P, w, t) smoothstep((w) / 2.0, 0.0, abs(P - (t)))
#define drawCrispLine(P, w, t) smoothstep(gridSmoothWidth, 0.0, abs(P - (w) / 2.0 - (t)))
#define drawPeriodicLine(f, w, t) drawCrispLine(f / 2.0, w, abs(mod(t, f) - f / 2.0))

float minLineWidth() { return 0.2 * (1.0 + 5.0 * width); }
float maxLineWidth() { return 1.0 * (1.0 + 5.0 * width); }
float lineSpeed() { return 1.0 * overallSpeed; }
float warpSpeed() { return 0.2 * overallSpeed; }
float offsetSpeed() { return 1.33 * overallSpeed; }

float random(float t) {
    return (cos(t) + cos(t * 1.3 + 1.3) + cos(t * 1.4 + 1.4)) / 3.0;
}

float getPlasmaY(float x, float horizontalFade, float offset) {
    return random(x * 0.6 + TIME * lineSpeed()) * horizontalFade * lineAmplitude + offset;
}

void fragment() {
    // Convert UV to normalized space coordinates
    vec2 uvOld = UV * 2.0 - 1.0;
	vec2 uv = vec2(uvOld.y, uvOld.x);
    vec2 space = uv * scale;
    
    // Fade effects
    float horizontalFade = 1.0 - (cos(uv.x * 6.28) * 0.5 + 0.5);
    float verticalFade = 1.0 - (cos(uv.y * 6.28) * 0.5 + 0.5);
    
    // Warp space
    space.y += random(space.x * warpFrequency + TIME * warpSpeed()) * warpAmplitude * (0.5 + horizontalFade);
    space.x += random(space.y * warpFrequency + TIME * warpSpeed() + 2.0) * warpAmplitude * horizontalFade;
    
    vec4 lines = vec4(0.0);
    
    // Draw lines
    for(int l = 0; l < linesPerGroup; l++) {
        float normalizedLineIndex = float(l) / float(linesPerGroup);
        float offsetTime = TIME * offsetSpeed();
        float offsetPosition = float(l) + space.x * offsetFrequency;
        float rand = random(offsetPosition + offsetTime) * 0.5 + 0.5;
        float halfWidth = mix(minLineWidth(), maxLineWidth(), rand * horizontalFade) / 2.0;
        float offset = random(offsetPosition + offsetTime * (1.0 + normalizedLineIndex)) * mix(minOffsetSpread, maxOffsetSpread, horizontalFade);
        float linePosition = getPlasmaY(space.x, horizontalFade, offset);
        
        // Line drawing
        float line = drawSmoothLine(linePosition, halfWidth, space.y) / 2.0 
                   + drawCrispLine(linePosition, halfWidth * 0.15, space.y);
        
        // Circle drawing
        float circleX = mod(float(l) + TIME * lineSpeed(), 25.0) - 12.0;
        vec2 circlePosition = vec2(circleX, getPlasmaY(circleX, horizontalFade, offset));
        float circle = drawCircle(circlePosition, 0.01, space) * 4.0;
        
        lines += (line + circle) * lineColor * rand;
    }
    
    // Set final color with transparency
    ALBEDO = lines.rgb * lineColor.a;
    ALPHA = lines.a;
}