#version 440
layout(location = 0) in vec2 texCoord;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    float time;
    float flowStrength;
    float speed;
    float frequency;
};
layout(binding = 1) uniform sampler2D source;
layout(binding = 2) uniform sampler2D normalMap;
layout(binding = 3) uniform sampler2D depthMask;

void main() {
    float t = time * speed;
    float mask = smoothstep(0.15, 0.6, texture(depthMask, texCoord).r);
    vec2 normalUV = texCoord * frequency + vec2(t * 0.13, t * 0.07);
    vec2 normalOffset = (texture(normalMap, normalUV).rg * 2.0 - 1.0) * flowStrength * mask;
    vec2 distortedUV = texCoord + normalOffset;
    fragColor = texture(source, distortedUV) * qt_Opacity;
}
