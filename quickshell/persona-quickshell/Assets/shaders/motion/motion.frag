#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float speed;
};
layout(binding = 1) uniform sampler2D source;

void main() {
    vec2 uv = qt_TexCoord0;

    // Scroll right-to-left: subtract time so the image drifts leftward
    uv.x = fract(uv.x - time * speed);

    fragColor = texture(source, uv) * qt_Opacity;
}
