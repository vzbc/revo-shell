#version 440
layout(location = 0) in vec2 texCoord;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    float time;
    float strength;
    float speed;
    float frequency;
};
layout(binding = 1) uniform sampler2D source;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void main() {
    float t = time * 0.01;
    float mask = 1.0;
    vec4 originalColor = texture(source, texCoord);
    vec3 sparkle = vec3(0.0);

    for (int i = 0; i < 80; i++) {
        float fi = float(i);
        float seed  = hash(vec2(fi, 0.3));
        float seed2 = hash(vec2(fi, 1.7));
        float seed3 = hash(vec2(fi, 2.5));
        float seed4 = hash(vec2(fi, 3.9));

        float xPos = seed;
        float fallSpeed = 4.0 + seed2 * 5.0;   // much faster
        float yPos = fract(seed3 + t * fallSpeed);

        // very slight horizontal drift (rain angle)
        xPos += (seed4 - 0.5) * 0.02 * yPos;

        vec2 starPos = vec2(xPos, yPos);
        vec2 delta   = texCoord - starPos;
        delta.x *= 16.0 / 9.0;

        // Elongate vertically to look like a raindrop streak
        vec2 stretchedDelta = vec2(delta.x * 12.0, delta.y * 1.5);
        float dist = length(stretchedDelta);
        float rawDist = length(delta);

        // Fade in at top, fade out at bottom
        float fade = smoothstep(0.0, 0.05, yPos) * (1.0 - smoothstep(0.85, 1.0, yPos));

        // Thin bright streak (elongated core)
        float core = 0.00004 / (dist * dist + 0.00001);
        core = clamp(core, 0.0, 1.0);

        // Soft tail trailing upward
        float tail = clamp(0.00002 / (abs(delta.x * 14.0) + abs(delta.y * 0.8) + 0.0008), 0.0, 1.0);
        tail *= step(delta.y, 0.0);  // only above the drop center

        // Subtle shimmer instead of twinkle
        float shimmer = 0.75 + 0.25 * sin(t * 30.0 * (1.0 + seed * 2.0) + fi);

        // Blue-white rain color
        vec3 color = mix(vec3(0.75, 0.9, 1.0), vec3(0.9, 0.95, 1.0), seed);

        sparkle += (core + tail) * fade * shimmer * color;
    }

    sparkle = clamp(sparkle, 0.0, 1.0);
    vec3 finalRGB = originalColor.rgb + sparkle * mask;
    finalRGB = clamp(finalRGB, 0.0, 1.0);
    fragColor = vec4(finalRGB, originalColor.a) * qt_Opacity;
}
