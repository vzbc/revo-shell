#version 440
// Siri / Apple Intelligence screen-edge light — macOS 27 (26A428)
//
// Port of SiriUICore.framework default.metallib (AIR, metalfe-32023.921.5):
//   IntelligentLightMacFrag   colour field from 6 moving lights
//   EdgeLightFragment         flame mask along the screen edge (+ burst)
//   maskForEdgeLight          continuous-corner edge distance + flame profile
// CoreAnimation uses the EdgeLight layer (RG16F) as the mask of the
// IntelligentLight layer; with contrast = 1 both mask channels are equal,
// so the mask is applied as alpha here. All constants are the shader's own.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    // --- SUICIntelligentLightFragUniforms
    vec4 lightsA;            // lights[0].xy, lights[1].xy
    vec4 lightsB;            // lights[2], lights[3]
    vec4 lightsC;            // lights[4], lights[5]
    float lightLevel;        // half at [1]: mix(2.5, 3.5, lightLevel)
    // --- SUICIntelligentLightVertUniforms
    vec2 lightScale;         // (1.5, 1.5*h/w) landscape
    vec2 lightOffset;
    // --- SUICEdgeLightVertUniforms
    vec2 noiseScale;         // (0.5, 0.5*h/w) landscape
    vec3 noiseOffset;
    // --- SUICEdgeLightFragUniforms
    vec2 burstCenter;
    vec2 direction;
    float directionRadius;
    float falloffScale;
    float time;              // seconds since animateOn (burst < 9.9 s)
    float noiseRotation;
    float defaultFlameOpacity;
    // --- SUICEdgeLightLayoutInfo
    vec2 resolution;
    float yxRatio;
    float screenRadiusRatio;
    float flameScaleDucked;
    float burstOpacity;
    float contrast;
    float visibility;        // CA layer opacity (on/off animation)
};

layout(binding = 1) uniform sampler2D noiseAtlas;   // 80x80x40 R8, 8x5 slices

// texture3d<half> sample with linear filtering, repeat addressing
float noise3D(vec3 p)
{
    p = fract(p);
    float z = p.z * 40.0 - 0.5;
    float z0 = floor(z);
    float fz = z - z0;
    float s0 = mod(z0, 40.0), s1 = mod(z0 + 1.0, 40.0);
    vec2 cell = vec2(80.0 / 640.0, 80.0 / 400.0);
    vec2 uv = p.xy * (78.0 / 80.0) + 1.0 / 80.0;             // stay inside the tile
    vec2 t0 = (vec2(mod(s0, 8.0), floor(s0 / 8.0)) + uv) * cell;
    vec2 t1 = (vec2(mod(s1, 8.0), floor(s1 / 8.0)) + uv) * cell;
    return mix(texture(noiseAtlas, t0).r, texture(noiseAtlas, t1).r, fz);
}

vec3 intelligentLight(vec2 xy)
{
    float k = mix(2.5, 3.5, lightLevel);
    vec3 a = vec3(distance(lightsA.xy, xy), distance(lightsA.zw, xy), distance(lightsB.xy, xy));
    vec3 b = vec3(distance(lightsB.zw, xy), distance(lightsC.xy, xy), distance(lightsC.zw, xy));
    vec3 s = (pow(2.0 - a, vec3(2.0)) + pow(2.0 - b, vec3(2.0))) * k;
    vec3 c = s.x * vec3(1.0, 0.176514, 0.333252)
           + s.y * vec3(0.250977, 1.0, 0.639160)
           + s.z * vec3(0.0, 0.478027, 1.0);
    c = pow(max(c * 0.0299988, 0.0), vec3(0.454590));
    float L = dot(c, vec3(0.212646, 0.715332, 0.0722046));
    c = mix(vec3(L), c, 3.0);
    c = min(c, 0.700195) + max(c - 0.700195, 0.0) * 0.300049;
    return c;
}

float maskForEdgeLight(vec2 p, float yx, float rr, float fs, float flameScale, float n)
{
    p.y *= yx;
    vec2 b = vec2(1.0, yx);
    float r = rr * 1.18921;                       // f0x3F9837F0
    vec2 q = abs(p) - b + r;
    float d;
    if (min(q.x, q.y) < 0.0) {
        d = max(q.x, q.y) - r;
    } else {
        vec2 uv = vec2(abs(q.x - q.y), q.y - r + q.x) / r;
        float v = (uv.y + 0.5) * 0.666504;
        float u2 = uv.x * uv.x;
        float h = pow(sqrt(abs(v * v * v + u2)) + uv.x, 0.333252);
        h += 1e-7;
        float t = h - v / h;
        vec2 cp = vec2(t, (1.0 - t * t) * 0.5);
        float dist = length(uv - cp) * sign(uv.y - cp.y);
        d = rr * 0.840896 * dist;                 // f0x3F5744FC
    }
    float m = max(0.0, d * -flameScale);
    float A = n * fs;
    float t78 = clamp(pow(4.0 - 2.0 * A, (m - 0.05 * A) * -60.0), 0.0, 1.0);
    float c79 = mix(0.7, 1.2, fs);
    float t83 = pow(2.0, (c79 * 90.0 - 120.0) * m);
    float t89 = t83 - c79 * 0.05 * max(0.0, 1.0 - 4.0 * m);
    float g = n + 0.7;
    float a2 = pow(t78 * 0.8, 2.0);
    float t98 = sqrt(a2 / (1.0 + a2)) * g;
    float b2 = t89 * t89;
    return 2.0 * n * sqrt(b2 / (b2 + 1.0)) + t98;
}

void main()
{
    vec2 uv = qt_TexCoord0;                               // top-left origin, like Metal
    vec2 np = uv * 2.0 - 1.0;                             // normalizedPosition
    vec3 tex = vec3(uv * noiseScale + noiseOffset.xy, noiseOffset.z);
    vec2 nc = noiseOffset.xy + noiseScale * 0.5;          // noiseCenter

    // rotate the noise lookup around its centre
    float cr = cos(noiseRotation), sr = sin(noiseRotation);
    vec2 dn = tex.xy - nc;
    vec2 rp = nc + vec2(cr * dn.x - sr * dn.y, sr * dn.x + cr * dn.y);
    float n = noise3D(vec3(rp, tex.z));

    float burst = 0.0;
    float flameOpacity = defaultFlameOpacity;
    if (time < 9.9) {                                     // f0x411E6666
        vec2 q = uv - 0.5;
        q.y = q.y * resolution.y / resolution.x;
        float amp = max(0.0, pow(1.0 - pow((time - 0.0833130) * 0.5, 2.0), 15.0) * 0.333008) * 2.0;
        float k = (length(q - burstCenter) - time * 7.19921) * 3.0;
        float w = 1.0;
        if (k >= 0.0) {
            float e = max(0.0, 1.0 - k * k);
            w = e * e;
        }
        flameOpacity = (amp + 1.0) * w;
        burst = w * amp;
    }

    vec2 dd = np - direction;
    dd.y *= yxRatio;
    float dir = clamp(directionRadius - dot(dd * dd, vec2(0.150024)), 0.0, 1.0);

    float mask = maskForEdgeLight(np, yxRatio, screenRadiusRatio, falloffScale * dir,
                                  flameScaleDucked, n);
    float o = (clamp(mask, 0.0, 1.0) * flameOpacity + burstOpacity * burst) * 0.8;
    float alpha = min(1.09961, n * n * 1.7 * flameOpacity * falloffScale + 0.6) * o;
    alpha = clamp(alpha, 0.0, 1.0) * visibility * qt_Opacity;

    vec2 xy = (uv - 0.5) * lightScale + lightOffset;      // IntelligentLightVert
    vec3 col = intelligentLight(xy);
    fragColor = vec4(col * alpha, alpha);
}
