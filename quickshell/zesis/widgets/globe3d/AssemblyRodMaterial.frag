// Color is computed in the vertex shader (AssemblyRodMaterial.vert) and
// interpolated here via the vColor VARYING.
VARYING vec4 vColor;

void MAIN()
{
    BASE_COLOR = vColor;
    ROUGHNESS = roughness;
}
