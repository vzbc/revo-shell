// Camera-facing billboard for the background star field
// (AssemblyGlobeView.qml's star Model). Same billboard math as
// DotMaterial.vert, but size/color/brightness come from per-instance
// catalog data (INSTANCE_DATA.x = size scale, INSTANCE_DATA.y = intensity
// scale, INSTANCE_COLOR = star color, all baked by
// RealStarField.js/build_starfield.py from the HYG catalog).

VARYING vec2 vUV;
VARYING vec4 vColor;
VARYING float vIntensity;

void MAIN()
{
    vUV = UV0;
    vColor = INSTANCE_COLOR;
    vIntensity = INSTANCE_DATA.y * dotIntensity;
    VERTEX = (camRight * VERTEX.x + camUp * VERTEX.y) * (dotSize * INSTANCE_DATA.x / 100.0);
}
