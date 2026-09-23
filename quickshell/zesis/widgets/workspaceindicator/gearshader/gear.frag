#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    float time;
    float toothWidth;
    float toothDepth;
    vec4  gearColor;
    vec4  edgeColor;
    float aspect;
    float phaseOffset;
    int   teeth;
} ubuf;

#define PI 3.14159265359

float gearSDF(vec2 p, float rot, int N, float rOut, float tw, float depth) {
    float c = cos(rot), s = sin(rot);
    p = vec2(c * p.x - s * p.y, s * p.x + c * p.y);

    float rIn    = rOut * (1.0 - depth);
    float angle  = atan(p.y, p.x);
    float d      = length(p);
    float t      = fract((-angle * float(N)) / (2.0 * PI));
    float blend  = (t < tw) ? 1.0 : pow(cos(PI * (t - tw) / (1.0 - tw)), 4.0);

    return d - (rIn + (rOut - rIn) * blend);
}

vec4 renderGear(vec2 p, float rot, int N, float rOut, float tw, float depth,
                vec4 fillCol, vec4 strokeCol) {
    float d      = gearSDF(p, rot, N, rOut, tw, depth);
    float aa     = fwidth(d);
    float fill   = 1.0 - smoothstep(-aa, aa, d);
    float stroke = 1.0 - smoothstep(0.0, aa * 2.0, abs(d) - 0.008);
    return mix(fillCol, strokeCol, stroke) * fill;
}

void main() {
    vec2 uv = (qt_TexCoord0 * 2.0 - 1.0) * vec2(ubuf.aspect, 1.0);

    float rOut  = 0.55;
    float depth = ubuf.toothDepth;
    float tw    = ubuf.toothWidth;
    int   N     = ubuf.teeth;
    float rIn   = rOut * (1.0 - depth);

    // centers: tooth tip of one gear (rOut) meets valley floor of other (rIn)
    float halfSep = (rOut + rIn) * 0.5;
    vec2 p1 = uv - vec2(-halfSep, 0.0);
    vec2 p2 = uv - vec2( halfSep, 0.0);

    float rot1 = ubuf.time;
    float rot2 = -ubuf.time + ubuf.phaseOffset;  // counter-rotate; PI/N phases valley to peak at contact

    // render back gear first, then front gear composited on top
    // g1's stroke is pre-multiplied by f1, so it cannot bleed outside gear 1's boundary
    vec4 col   = renderGear(p2, rot2, N, rOut, tw, depth, ubuf.gearColor, ubuf.edgeColor);
    float d1   = gearSDF(p1, rot1, N, rOut, tw, depth);
    float aa1  = fwidth(d1);
    float f1   = 1.0 - smoothstep(-aa1, aa1, d1);
    float str1 = 1.0 - smoothstep(0.0, aa1 * 2.0, abs(d1) - 0.008);
    vec4 g1    = mix(ubuf.gearColor, ubuf.edgeColor, str1) * f1;
    col = mix(col, g1, f1);

    // hubs on top
    float l1  = length(p1);
    float l2  = length(p2);
    float hub = max(
        1.0 - smoothstep(-fwidth(l1), fwidth(l1), l1 - 0.05),
        1.0 - smoothstep(-fwidth(l2), fwidth(l2), l2 - 0.05)
    );
    col = mix(col, ubuf.edgeColor, hub);

    fragColor = col * ubuf.qt_Opacity;
}
