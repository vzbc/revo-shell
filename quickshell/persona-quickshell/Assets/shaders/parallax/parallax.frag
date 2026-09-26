#version 440

// Based on the DepthFlow ray marching algorithm
// (c) Adapted from DepthFlow - CC BY-SA 4.0, Tremeschin

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float offsetX;           // Mouse X offset [-1, 1]
    float offsetY;           // Mouse Y offset [-1, 1]
    float parallaxStrength;  // Parallax intensity
    float aspectRatio;       // Image aspect ratio (width/height)
};

layout(binding = 1) uniform sampler2D source;     // Original image
layout(binding = 2) uniform sampler2D depthMap;   // Depth map

// Constants
const float PI = 3.14159265359;
const float TAU = 6.28318530718;


// Triangle wave for mirrored repeat 
float triangle_wave(float x, float period) {
    return 2.0 * abs(mod(2.0 * x / period - 0.5, 2.0) - 1.0) - 1.0;
}

// GLUV mirrored repeat 
vec2 gluv_mirrored_repeat(vec2 gluv, float aspect) {
    return vec2(
        aspect * triangle_wave(gluv.x, 4.0 * aspect),
        triangle_wave(gluv.y, 4.0)
    );
}

// Convert UV to GLUV space with aspect ratio
vec2 uv2gluv(vec2 uv, float aspect) {
    return vec2(
        (uv.x * 2.0 - 1.0) * aspect,
        (uv.y * 2.0 - 1.0)
    );
}

// Convert GLUV back to UV
vec2 gluv2uv(vec2 gluv, float aspect) {
    return vec2(
        (gluv.x / aspect + 1.0) * 0.5,
        (gluv.y + 1.0) * 0.5
    );
}

// DepthFlow ray marching implementation (returns final GLUV position)
vec2 depthFlowRayMarch(vec2 gluv, vec2 offset, float aspect) {
    const float height = 0.08;  // was 0.20
    const float quality = 0.7;           
    const float steady = 0.0;            

    // Quality determines step sizes
    float stepQuality = 1.0 / mix(200.0, 2000.0, quality);
    float stepProbe = 1.0 / mix(50.0, 120.0, quality);

    // Relative steady
    float relSteady = steady * height;

    // intersect = vec3(gluv, 1.0) - vec3(offset, 0.0) * (1.0/(1.0 - rel_steady))
    vec3 rayOrigin = vec3(gluv, 0.0);
    vec3 intersect = vec3(gluv, 1.0) - vec3(offset, 0.0) * (1.0 / (1.0 - relSteady));

    // Safety: guaranteed relative distance to not hit surface
    float safe = 1.0 - height;
    float walk = 0.0;
    vec2 finalGluv = gluv;

    // Main loop: Find the intersection 
    for (int stage = 0; stage < 2; stage++) {
        bool forward = (stage == 0);
        bool backward = (stage == 1);

        for (int it = 0; it < 500; it++) {
            if (forward && walk > 1.0) break;

            walk += forward ? stepProbe : -stepQuality;

            // Interpolate origin and intersect
            vec3 point = mix(rayOrigin, intersect, mix(safe, 1.0, walk));
            finalGluv = point.xy;

            // Sample depth with mirroring
            vec2 mirroredGluv = gluv_mirrored_repeat(finalGluv, aspect);
            vec2 sampleUV = gluv2uv(mirroredGluv, aspect);
            float depthValue = texture(depthMap, sampleUV).r;

            // Calculate surface height (white=foreground, black=background)
            float surface = height * depthValue;
            float ceiling = 1.0 - point.z;

            // Stop when inside the surface
            if (ceiling < surface) {
                if (forward) break;
            } else if (backward) {
                break;
            }
        }
    }

    // Return final GLUV position 
    return finalGluv;
}

void main() {
    // Get normalized texture coordinates and convert to GLUV space
    vec2 uv = qt_TexCoord0;
    vec2 gluv = uv2gluv(uv, aspectRatio);

    // Mouse offset 
    vec2 offset = vec2(offsetX, -offsetY) * parallaxStrength;

    // Perform DepthFlow ray marching 
    vec2 finalGluv = depthFlowRayMarch(gluv, offset, aspectRatio);

    // Sample the image with mirroring 
    vec2 mirroredGluv = gluv_mirrored_repeat(finalGluv, aspectRatio);
    vec2 finalUV = gluv2uv(mirroredGluv, aspectRatio);

    // Sample the image at the parallaxed position
    fragColor = texture(source, finalUV);
    fragColor.a *= qt_Opacity;
}
