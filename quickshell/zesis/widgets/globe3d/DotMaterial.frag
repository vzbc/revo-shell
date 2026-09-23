// Soft emissive dot: tiny hot core + gaussian-ish halo, written to
// EMISSIVE_COLOR over a black BASE_COLOR so the scene light never
// touches it. Runs through the SHADED pipeline. Unshaded rendered
// nothing at all for some reason.
//
// The output is HDR (dotIntensity pushes past 1.0) and the material
// blends One/One (additive), so overlapping dots SUM: a dense cluster
// climbs past the glow pass's HDR threshold (glowHDRMinimumValue) where
// a lone dot barely grazes it, that's what makes bloom read as
// density.
VARYING vec2 vUV;
VARYING float vSeed;

// Cheap hash-without-sine (Dave Hoskins), one instance seed in, a stable
// pseudo-random vec3 in [0,1) out.
vec3 hash13(float p)
{
    vec3 p3 = fract(vec3(p) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xxy + p3.yzz) * p3.zyx);
}

// Geometric (log-scale) interpolation. First thought that came to mind
// that should look "realistic".
float logMix(float a, float b, float t)
{
    return a * pow(b / a, t);
}

void MAIN()
{
    vec2 d = vUV * 2.0 - 1.0;
    float r2 = dot(d, d);
    float r = sqrt(r2);
    float halo = exp(-r2 * 5.0) * clamp(1.0 - r, 0.0, 1.0);
    float core = 1.0 - smoothstep(0.0, 0.35, r);
    float shape = halo * 0.6 + core;

    // colorVariety 0 = every instance is exactly dotColor.
    // >0 blends toward a per-instance random color computed
    // from vSeed alone.
    vec3 rand3 = hash13(vSeed);
    vec3 blueStar = vec3(0.5, 0.7, 1.0);
    vec3 whiteStar = vec3(1.0, 1.0, 1.0);
    vec3 purpleStar = vec3(0.75, 0.55, 1.0);
    vec3 randomColor = rand3.x < 0.5 ? mix(blueStar, whiteStar, rand3.x * 2.0) : mix(whiteStar, purpleStar, (rand3.x - 0.5) * 2.0);
    randomColor *= logMix(0.15, 1.0, rand3.y);
    vec3 color = mix(dotColor.rgb, randomColor, clamp(colorVariety, 0.0, 1.0));

    BASE_COLOR = vec4(0.0, 0.0, 0.0, 1.0);
    ROUGHNESS = 1.0;
    EMISSIVE_COLOR = color * (dotIntensity * shape * dotFade);
}
