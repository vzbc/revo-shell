#version 310 es
// Liquid-glass fragment shader — Qt ShaderEffect variant (individual uniforms).
// Fixed: all power() calls replaced with pow() for GLSL ES 3.00 compliance.
// Sampler named backdropTexture — bound from QML property variant.
// Shader logic (SDF, refraction, chroma, RGSS, AO, rim, specular, sheen,
// shadow) unchanged from the original liquid-glass port.
precision highp float;

// ── Explicit sampler (bound from QML property variant backdropTexture) ──
uniform highp sampler2D backdropTexture;

// ── Individual uniforms (Qt ShaderEffect auto-binds these from QML) ──
uniform highp float resolution_x;
uniform highp float resolution_y;
uniform highp float pointer_x;
uniform highp float pointer_y;
uniform highp float intensity;
uniform highp float corner_radius;
uniform highp float max_z;
uniform highp float displacement_scale;
uniform highp float edge_smoothing;
uniform highp float profile_shape_n;
uniform highp float ior;
uniform highp float chroma_strength;
uniform highp float blur_strength;
uniform highp float tint_strength;
uniform highp float tint_r;
uniform highp float tint_g;
uniform highp float tint_b;
uniform highp float specular_intensity;
uniform highp float rim_width;
uniform highp float rim_intensity;
uniform highp float rim_directional_power;
uniform highp float rim_power;
uniform highp float rim_light_color_intensity;
uniform highp float sheen_intensity;
uniform highp float shininess;
uniform highp float surface_light_enabled;
uniform highp float ao_intensity;
uniform highp float ao_radius;
uniform highp float light_angle_deg;
uniform highp float mouse_radius;
uniform highp float bg_glow_intensity;
uniform highp float shadow_radius;
uniform highp float shadow_intensity;
uniform highp float shadow_max_radius;
uniform highp float padding;
uniform highp float isDock;
uniform highp float glass_opacity;
uniform highp float brightness;
uniform highp float contrast;
uniform highp float saturation;

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

float sdRoundRect(vec2 p, vec2 b, float r) {
    vec2 d = abs(p) - b + vec2(r);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - r;
}
float normalizedDepth(float d, vec2 b, float r) {
    float maxDepth = max(r, 1.0);
    float interiorDepth = max(-d, 0.0);
    return clamp(interiorDepth / maxDepth, 0.0, 1.0);
}
float profileHeight(float t, float zScale) {
    float n = max(profile_shape_n, 1.01);
    float invT = clamp(1.0 - t, 0.0, 1.0);
    float inner = max(1.0 - pow(invT, n), 0.0);
    return pow(inner, 1.0 / n) * zScale;
}
float getHeight(vec2 p, vec2 b, float r, float zScale) {
    float d = sdRoundRect(p, b, r);
    float smoothZone = max(edge_smoothing, 1.0);
    if (d > smoothZone) return 0.0;
    float t = normalizedDepth(d, b, r);
    float h = profileHeight(t, zScale);
    float fade = 1.0 - smoothstep(-smoothZone, smoothZone, d);
    return h * fade;
}
float gradientStep(vec2 resolution) {
    float minRes = max(min(resolution.x, resolution.y), 1.0);
    return clamp(minRes / 560.0, 0.45, 1.20);
}
vec2 heightGradient(vec2 p, vec2 b, float r, float zScale, vec2 resolution) {
    float e = gradientStep(resolution);
    float hR = getHeight(p + vec2(e, 0.0), b, r, zScale);
    float hL = getHeight(p - vec2(e, 0.0), b, r, zScale);
    float hB = getHeight(p + vec2(0.0, e), b, r, zScale);
    float hT = getHeight(p - vec2(0.0, e), b, r, zScale);
    return vec2((hR - hL) / (2.0 * e), (hB - hT) / (2.0 * e));
}
vec3 getNormal(vec2 gradH) {
    return normalize(vec3(-gradH.x, -gradH.y, 1.0));
}
vec2 getDisplacement(float d, vec3 normal, vec2 resolution) {
    if (d > 0.0) return vec2(0.0);
    vec3 viewDir = vec3(0.0, 0.0, -1.0);
    float eta = 1.0 / max(ior, 1.001);
    vec3 refractedRay = refract(viewDir, normal, eta);
    if (length(refractedRay) < 0.0001) return vec2(0.0);
    float minRes = max(min(resolution.x, resolution.y), 1.0);
    float thicknessNorm = displacement_scale / minRes;
    float safe_z = max(-refractedRay.z, 0.15);
    vec2 displacement = (refractedRay.xy / safe_z) * thicknessNorm;
    float max_disp = 0.30;
    if (length(displacement) > max_disp) displacement = normalize(displacement) * max_disp;
    return displacement;
}
vec2 stabilizedUV(vec2 candidate, vec2 fallback) {
    vec2 clamped = clamp(candidate, vec2(0.001), vec2(0.999));
    float edgeDist = min(min(candidate.x, candidate.y), min(1.0 - candidate.x, 1.0 - candidate.y));
    float keep = smoothstep(-0.04, 0.03, edgeDist);
    return mix(fallback, clamped, keep);
}
vec3 applySCB(vec3 color, float b, float c, float s) {
    color *= b;
    color = mix(vec3(0.5), color, c);
    float luma = dot(color, vec3(0.299, 0.587, 0.114));
    color = mix(vec3(luma), color, s);
    return max(color, 0.0);
}

// ── cheap in-shader box blur (7-tap H + 7-tap V) ──
vec3 blur7(sampler2D tex, vec2 uv, vec2 res, float radius) {
    float step = radius / res.x;
    vec2 off = vec2(step, 0.0);
    vec3 acc = texture(tex, uv).rgb * 0.25;
    acc += texture(tex, uv - off * 3.0).rgb * 0.10;
    acc += texture(tex, uv - off * 2.0).rgb * 0.15;
    acc += texture(tex, uv - off).rgb * 0.20;
    acc += texture(tex, uv + off).rgb * 0.20;
    acc += texture(tex, uv + off * 2.0).rgb * 0.15;
    acc += texture(tex, uv + off * 3.0).rgb * 0.10;
    float vstep = radius / res.y;
    vec2 voff = vec2(0.0, vstep);
    vec3 vacc = acc * 0.25;
    vacc += texture(tex, uv - voff * 3.0).rgb * 0.10;
    vacc += texture(tex, uv - voff * 2.0).rgb * 0.15;
    vacc += texture(tex, uv - voff).rgb * 0.20;
    vacc += texture(tex, uv + voff).rgb * 0.20;
    vacc += texture(tex, uv + voff * 2.0).rgb * 0.15;
    vacc += texture(tex, uv + voff * 3.0).rgb * 0.10;
    return vacc;
}

void main() {
    vec2 resolution = vec2(resolution_x, resolution_y);
    vec2 uv = qt_TexCoord0;
    vec2 pixel_coord = uv * resolution;
    vec2 local_pos = pixel_coord - resolution * 0.5;
    float edgeFeather = max(edge_smoothing, 0.75);
    vec2 actual_size = resolution - vec2(padding * 2.0);
    vec2 box_size = max(actual_size * 0.5, vec2(1.0));
    float d = sdRoundRect(local_pos, box_size, corner_radius);
    float outsideTransition = smoothstep(-edgeFeather, edgeFeather, d);
    float insideMask = 1.0 - outsideTransition;
    float outsideMask = outsideTransition;

    // ── dynamic light angle: mouse-driven (default 55° when mouse exits) ──
    float lightAngleRad = radians(light_angle_deg);

    // directional drop shadow
    vec2 lightDir2D = vec2(cos(lightAngleRad), -sin(lightAngleRad));
    vec2 shadowDir = -lightDir2D;
    vec2 outwardDir = normalize(local_pos + vec2(1e-4));
    float lightAlignment = max(dot(outwardDir, shadowDir), 0.0);
    float dirRadius = 0.85 + lightAlignment * 0.15;
    float dirIntensity = 0.85 + lightAlignment * 0.15;
    float maxRadius = max(shadow_max_radius, 5.0);
    float effectiveRadius = min(shadow_radius * dirRadius, maxRadius);
    float radiusEnable = smoothstep(0.0, 0.75, shadow_radius);
    float effectiveIntensity = shadow_intensity * dirIntensity * radiusEnable;
    float safeRadius = max(effectiveRadius, 0.001);
    float umbra_t = clamp(d / max(safeRadius * 0.40, 0.5), 0.0, 1.0);
    float umbra = (1.0 - umbra_t) * 0.80;
    float penumbra_t = clamp(d / safeRadius, 0.0, 1.0);
    float penumbraFade = 1.0 - penumbra_t;
    float penumbraEase = penumbraFade * penumbraFade * penumbraFade * (penumbraFade * (penumbraFade * 6.0 - 15.0) + 10.0);
    float penumbra = penumbraEase * 0.55;
    float shadowAlpha = clamp((umbra + penumbra) * outsideMask * effectiveIntensity, 0.0, 1.0);
    float boundsFade = 1.0 - smoothstep(maxRadius * 0.85, maxRadius, d);
    float boundsMask = boundsFade * boundsFade * boundsFade * (boundsFade * (boundsFade * 6.0 - 15.0) + 10.0);
    shadowAlpha *= boundsMask;
    shadowAlpha *= 1.0 - step(maxRadius, d);
    vec3 shadowColor = vec3(0.03, 0.04, 0.08);

    // ── backdrop: blur when blur_strength > 0 ──
    float minRes = max(min(resolution.x, resolution.y), 1.0);
    vec3 backdrop;
    if (blur_strength > 0.0) {
        float blurRadius = blur_strength * (minRes / 560.0) * 22.0;
        blurRadius = clamp(blurRadius, 0.0, 28.0);
        backdrop = blur7(backdropTexture, uv, resolution, blurRadius);
    } else {
        backdrop = texture(backdropTexture, uv).rgb;
    }

    vec2 gradH = heightGradient(local_pos, box_size, corner_radius, max_z, resolution);
    vec3 normal = getNormal(gradH);
    vec2 disp = getDisplacement(d, normal, resolution);
    float edgeDampen = smoothstep(0.0, edgeFeather * 3.0, -d);
    disp *= edgeDampen;
    vec2 refractedUv = stabilizedUV(uv + disp, uv);
    vec2 chromaDir = length(disp) > 0.00001 ? normalize(disp) : vec2(0.0);
    vec2 chromaVec = chromaDir * (chroma_strength / minRes) * edgeDampen;
    vec2 uvR = stabilizedUV(refractedUv + chromaVec, refractedUv);
    vec2 uvG = refractedUv;
    vec2 uvB = stabilizedUV(refractedUv - chromaVec, refractedUv);
    float edgeProximity = 1.0 - smoothstep(0.0, edgeFeather * 4.0, -d);
    float aa_spread = mix(0.75, 2.5, edgeProximity);
    vec2 texel = vec2(aa_spread) / resolution;
    vec2 off1 = vec2(0.375, -0.125) * texel;
    vec2 off2 = vec2(0.125, 0.375) * texel;
    vec2 off3 = vec2(-0.375, 0.125) * texel;
    vec2 off4 = vec2(-0.125, -0.375) * texel;
    vec2 margin = vec2(1.2) / resolution;
    #define SAFE(u) clamp(u, margin, 1.0 - margin)
    vec3 refractedRgb = vec3(
        (texture(backdropTexture, SAFE(uvR + off1)).r + texture(backdropTexture, SAFE(uvR + off2)).r + texture(backdropTexture, SAFE(uvR + off3)).r + texture(backdropTexture, SAFE(uvR + off4)).r) * 0.25,
        (texture(backdropTexture, SAFE(uvG + off1)).g + texture(backdropTexture, SAFE(uvG + off2)).g + texture(backdropTexture, SAFE(uvG + off3)).g + texture(backdropTexture, SAFE(uvG + off4)).g) * 0.25,
        (texture(backdropTexture, SAFE(uvB + off1)).b + texture(backdropTexture, SAFE(uvB + off2)).b + texture(backdropTexture, SAFE(uvB + off3)).b + texture(backdropTexture, SAFE(uvB + off4)).b) * 0.25
    );
    vec3 adjustedRefracted = applySCB(refractedRgb, brightness, contrast, saturation);
    vec3 refracted = adjustedRefracted;
    vec3 tintColor = vec3(tint_r, tint_g, tint_b);
    vec3 insideBaseColor = mix(refracted, tintColor, tint_strength);
    vec3 baseColor = insideBaseColor;

    // inner AO
    float aoMask = 1.0 - smoothstep(0.0, max(ao_radius, 0.001), -d);
    baseColor *= (1.0 - aoMask * ao_intensity);

    vec3 lightDir = normalize(vec3(cos(lightAngleRad), sin(lightAngleRad), 0.38));
    vec3 viewDir = vec3(0.0, 0.0, 1.0);
    vec3 reflectDir = reflect(-lightDir, normal);
    float response = 1.0;
    float safeRimWidth = max(rim_width, 0.001);
    float edgeBand = (1.0 - smoothstep(0.0, safeRimWidth, abs(d))) * step(0.0005, rim_width);
    float rimDot = 1.0 - max(dot(normal, viewDir), 0.0);
    float rimFresnel = pow(max(rimDot, 0.0), max(rim_power, 0.001));
    float lightMask = pow(abs(dot(normal, lightDir)), max(rim_directional_power, 1.0));
    float rimShape = mix(pow(edgeBand, 0.85), rimFresnel, 0.55) * edgeBand;
    float finalRimLight = rimShape * lightMask * rim_intensity * rim_light_color_intensity;
    finalRimLight *= response;
    float specularDot = max(dot(reflectDir, viewDir), 0.0);
    float specularLight = pow(specularDot, max(shininess, 1.0));
    specularLight *= specular_intensity * response;
    float specMask = mix(0.25, 1.0, insideMask) * clamp(edgeBand + insideMask * 0.65, 0.0, 1.0);
    specularLight *= specMask;
    float idleRim = edgeBand * 0.008;
    float sheenFacing = max(dot(normal, lightDir), 0.0);
    float surfaceSheen = pow(sheenFacing, 1.65);
    surfaceSheen *= mix(1.0, 0.55, edgeBand);
    vec3 sheenColor = vec3(1.0) * surfaceSheen * sheen_intensity;
    float alpha = insideMask;
    vec3 addedLight = (vec3(specularLight + finalRimLight + idleRim) + sheenColor) * surface_light_enabled;
    vec3 litColor = baseColor + addedLight - (baseColor * addedLight);
    float maxChannel = max(litColor.r, max(litColor.g, litColor.b));
    if (maxChannel > 1.0) litColor /= maxChannel;
    litColor = max(litColor, 0.0);

    float insideAlpha = alpha * glass_opacity;
    float shadowContribution = shadowAlpha * (1.0 - insideAlpha);
    vec3 finalRgb = litColor * insideAlpha + shadowColor * shadowContribution;
    float finalAlpha = insideAlpha + shadowContribution;
    fragColor = vec4(finalRgb, finalAlpha);
}
