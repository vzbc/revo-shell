// Soft emissive star point: tiny hot core + gaussian-ish halo, written to
// EMISSIVE_COLOR over a black BASE_COLOR so the scene light never touches
// it. Same shape math as DotMaterial.frag, but color/brightness come from
// per-instance catalog data (vColor/vIntensity, see StarMaterial.vert).
VARYING vec2 vUV;
VARYING vec4 vColor;
VARYING float vIntensity;

void MAIN()
{
    vec2 d = vUV * 2.0 - 1.0;
    float r2 = dot(d, d);
    float r = sqrt(r2);
    float halo = exp(-r2 * 5.0) * clamp(1.0 - r, 0.0, 1.0);
    float core = 1.0 - smoothstep(0.0, 0.35, r);
    float shape = halo * 0.6 + core;

    BASE_COLOR = vec4(0.0, 0.0, 0.0, 1.0);
    ROUGHNESS = 1.0;
    EMISSIVE_COLOR = vColor.rgb * (vIntensity * shape);
}
