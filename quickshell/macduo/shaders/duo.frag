#version 440

// Mac-Duo depth effect — Linux/Qt port of the original Metal fragment shader.
// Each screen pixel maps back into the picture through the inverse perspective,
// samples a Gaussian mip level chosen by the blur wanted at that height, fades
// toward black where the kernel reaches past the picture edge (equivalent of
// the original's black padded margin), then applies the smoothstep dimming.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 column0;      // screen → picture matrix, column 0 (xyz)
    vec4 column1;
    vec4 column2;
    vec4 screenVec;    // screen size in points, max mip level, unused
    vec4 blurVec;      // blur strength, blur floor, max radius (px), unused
    vec4 dimVec;       // dim strength, dim floor, dim reach, max dim
} ubuf;

layout(binding = 1) uniform sampler2D picture;

void main() {
    vec2 screenSize = ubuf.screenVec.xy;
    float maxLevel = ubuf.screenVec.z;

    float blurStrength = ubuf.blurVec.x;
    float blurFloor = ubuf.blurVec.y;
    float maxRadius = ubuf.blurVec.z;

    float dimStrength = ubuf.dimVec.x;
    float dimFloor = ubuf.dimVec.y;
    float dimReach = ubuf.dimVec.z;
    float maxDim = ubuf.dimVec.w;

    // qt_TexCoord0 is y-down; geometry works in points with y up (hinge at 0).
    vec2 screenPoint = vec2(qt_TexCoord0.x * screenSize.x,
                            (1.0 - qt_TexCoord0.y) * screenSize.y);

    mat3 screenToPicture = mat3(ubuf.column0.xyz, ubuf.column1.xyz, ubuf.column2.xyz);
    vec3 mapped = screenToPicture * vec3(screenPoint, 1.0);
    if (abs(mapped.z) < 1e-6) {
        fragColor = vec4(0.0, 0.0, 0.0, ubuf.qt_Opacity);
        return;
    }
    vec2 picturePoint = mapped.xy / mapped.z;

    vec2 unit = picturePoint / screenSize;
    if (unit.x < 0.0 || unit.x > 1.0 || unit.y < 0.0 || unit.y > 1.0) {
        fragColor = vec4(0.0, 0.0, 0.0, ubuf.qt_Opacity);
        return;
    }

    float height = clamp(picturePoint.y / screenSize.y, 0.0, 1.0);
    float blur = blurStrength * (blurFloor + (1.0 - blurFloor) * height);
    float kernel = max(blur * maxRadius, 1.0);
    float lod = clamp(log2(kernel), 0.0, maxLevel);

    vec2 texCoord = vec2(unit.x, 1.0 - unit.y);
    vec3 colour = textureLod(picture, texCoord, lod).rgb;

    // The original samples a picture laid on a black margin, so its blur
    // reaches real black at every edge. Fade toward black by kernel reach
    // instead of smearing the clamped edge texels.
    vec2 toEdge = min(unit, 1.0 - unit) * screenSize;
    float edgeDist = min(toEdge.x, toEdge.y);
    colour *= smoothstep(0.0, 1.0, edgeDist / kernel);

    float spread = smoothstep(0.0, max(dimReach, 0.02), height);
    float fade = dimStrength * (dimFloor + (1.0 - dimFloor) * spread);
    // The sample is linear light in the original (sRGB texture); raising the
    // factor to 2.2 keeps the dimming a fraction of the encoded brightness.
    colour *= pow(1.0 - maxDim * fade, 2.2);

    // Premultiplied for Qt Quick's default blending; qt_Opacity is the fade.
    fragColor = vec4(colour, 1.0) * ubuf.qt_Opacity;
}
