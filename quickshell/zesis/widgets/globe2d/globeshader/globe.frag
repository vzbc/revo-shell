#version 440

// Claude Code has been used extensively in the writing and creation of this shader.
// It was a GREAT help in research, understanding the math, debugging and brainstorming.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float aspect;
    float camDist; // camera distance from the sphere center (radius 1) along +Z, a
    // dolly. Zooming in shrinks this toward the surface instead.
    float tanHalfFov; // tan(vertical FOV / 2) - fixed camera lens, computed once on the QML
    // side and passed through so JS hit-testing can stay bit-for-bit in sync with this
    // shader's projection.
    vec4 orientation; // quaternion (x, y, z, w) - globe orientation, avoids gimbal lock nonsense
    vec4 oceanDeep;
    vec4 oceanColor;
    vec4 landColor;
    vec4 landColor2;
    vec4 landColor3;
    vec4 inkColor;
    vec4 arcColor;
    int arcCount;
    vec4 arc0;
    vec4 arc1;
    vec4 arc2;
    vec4 arc3;
    vec4 arc4;
    vec4 arc5;
    vec4 arc6;
    vec4 arc7;
    float pointsTexWidth; // body texture (1 texel/point, cell-sorted)
    float pointsTexHeight;
    float headerTexWidth; // header texture (2 texels/cell: start, count)
    float headerTexHeight;
    int gridCols; // lat/lon grid dimensions (360/cellDeg, 180/cellDeg)
    int gridRows;
    float cellDeg; // grid cell size in degrees
} ubuf;

layout(binding = 1) uniform sampler2D earthmap;
layout(binding = 2) uniform sampler2D watermask;
layout(binding = 3) uniform sampler2D pointsTex; // body: cell-sorted point positions
layout(binding = 4) uniform sampler2D headerTex; // per-cell (start, count) into body

#define PI 3.14159265359

// 3D value noise, sampled directly on the sphere's direction vector instead of
// a 2D lat/lon unwrap. A lat/lon unwrap has a hard seam at +-180 longitude
// which shows up as a visible annoying crease in every noise-driven layer,
// sampling in 3D has no cut, so there is nothing to seam.
// This also means every texture (continents, grain) is baked onto the sphere's
// actual surface and rotates with it.
float hash3(vec3 p) {
    p = fract(p * vec3(443.897, 441.423, 437.195));
    p += dot(p, p.yzx + 19.19);
    return fract((p.x + p.y) * p.z);
}

float noise3(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float n000 = hash3(i + vec3(0.0, 0.0, 0.0));
    float n100 = hash3(i + vec3(1.0, 0.0, 0.0));
    float n010 = hash3(i + vec3(0.0, 1.0, 0.0));
    float n110 = hash3(i + vec3(1.0, 1.0, 0.0));
    float n001 = hash3(i + vec3(0.0, 0.0, 1.0));
    float n101 = hash3(i + vec3(1.0, 0.0, 1.0));
    float n011 = hash3(i + vec3(0.0, 1.0, 1.0));
    float n111 = hash3(i + vec3(1.0, 1.0, 1.0));
    float nx00 = mix(n000, n100, f.x);
    float nx10 = mix(n010, n110, f.x);
    float nx01 = mix(n001, n101, f.x);
    float nx11 = mix(n011, n111, f.x);
    float nxy0 = mix(nx00, nx10, f.y);
    float nxy1 = mix(nx01, nx11, f.y);
    return mix(nxy0, nxy1, f.z);
}

float fbm3(vec3 p) {
    float v = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 5; i++) {
        v += amp * noise3(p);
        p *= 2.0;
        amp *= 0.5;
    }
    return v;
}

vec3 latLonToSphere(float lat, float lon) {
    return vec3(cos(lat) * cos(lon), sin(lat), cos(lat) * sin(lon));
}

// Rotate a vector by a quaternion (x,y,z,w), the standard trackball/arcball
// approach. The globe's orientation is one quaternion, composed incrementally
// from drag deltas on the QML side. Euler yaw/pitch locks up when pitch nears
// +-90 (two axes collapse together), a quaternion has no degenerate orientation.
// This is what avoids the Gimbal lock issue.
vec3 rotateByQuat(vec3 v, vec4 q) {
    vec3 qv = q.xyz;
    return v + 2.0 * cross(qv, cross(qv, v) + q.w * v);
}

// near-binary threshold, antialiased over ~1 texel only, "wet-on-dry" glazing:
// paint applied after the layer beneath it has "dried" keeps a clean, high-contrast
// edge. Aka use this for edges between different color families (like the coastline).
float crispStep(float threshold, float value) {
    float w = max(fwidth(value), 0.0015) * 1.2;
    return smoothstep(threshold - w, threshold + w, value);
}

// wide soft threshold "wet-on-wet": paint applied while the layer beneath is
// still wet diffuses and blends into it. Use this within a color family (tonal
// steps of the same ocean/land).
float softStep(float threshold, float value, float width) {
    return smoothstep(threshold - width, threshold + width, value);
}

void main() {
    // Perspective camera at (0, 0, camDist) looking down -Z at a unit sphere
    // centered on the origin. p is the point on the image plane one
    // unit in front of the camera, scaled by the lens' half-FOV tangent.
    vec2 p = (qt_TexCoord0 * 2.0 - 1.0) * vec2(ubuf.aspect, 1.0) * ubuf.tanHalfFov;
    vec3 rd = normalize(vec3(p, -1.0));

    // Optimized ray-sphere intersection for a ray from (0,0,camDist) toward
    // rd against a unit sphere at the origin. With the ray direction already
    // normalized and oc = rayOrigin - sphereCenter = (0,0,camDist), the
    // standard quadratic collapses to b = dot(oc,rd) and
    // closestApproachSq = dot(oc,oc) - b^2 (squared perpendicular distance
    // from the sphere center to the ray line).
    float b = ubuf.camDist * rd.z;
    float closestApproachSq = ubuf.camDist * ubuf.camDist - b * b;
    float r = sqrt(max(closestApproachSq, 0.0));

    float edgeAA = fwidth(r);
    float discMask = 1.0 - smoothstep(1.0 - edgeAA, 1.0 + edgeAA, r);
    if (discMask <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }

    float t = -b - sqrt(max(1.0 - closestApproachSq, 0.0));
    vec3 pos = vec3(0.0, 0.0, ubuf.camDist) + t * rd; // point on the unit sphere, view space

    vec3 rp = rotateByQuat(pos, ubuf.orientation);

    // facing = cosine of the angle between the surface normal (=pos, since
    // the sphere is centered at the origin) and the direction back to the
    // camera.
    float facing = max(dot(pos, normalize(vec3(0.0, 0.0, ubuf.camDist) - pos)), 0.0);

    // seamless object-space coordinate: rp is already the point on the unit
    // sphere in the globe's own (rotating) frame, so sample noise directly
    // from it!
    vec3 base = rp * 3.0;

    // paper "hand tremor": low-frequency wobble, applied to the map lookup
    // coordinate (below)
    vec3 paperWarp = vec3(fbm3(base * 0.4 + 50.0), fbm3(base * 0.4 + 80.0), fbm3(base * 0.4 + 130.0)) - 0.5;

    // World elevation: equirectangular lookup into a Earth bump map.
    // The map's u=0/u=1 edges are authored to match (same meridian), so the
    // texture content is continuous across the antimeridian. The sampler is
    // NOT actually GL_REPEAT, though, these are plain QML Image textures fed to
    // a ShaderEffect, which the pipeline binds ClampToEdge (a plain Image can't
    // set the wrap mode). That leaves only a residual ~half-texel clamp error
    // exactly on the antimeridian. The visible SEAM is a separate problem, the
    // atan() UV discontinuity blowing up the mip derivative (fixed just below).
    float lat = asin(clamp(rp.y, -1.0, 1.0));
    float lon = atan(rp.z, rp.x);
    vec2 mapUV = vec2(0.5 + lon / (2.0 * PI), 0.5 - lat / PI);
    mapUV += paperWarp.xy * 0.006;

    // ANTIMERIDIAN SEAM FIX!!! atan() above is discontinuous at +-180 lon, so
    // mapUV.x jumps ~1.0 in a single pixel as a surface point crosses that
    // meridian. Mip level is chosen from the screen-space derivative of the
    // UV, and that one-pixel jump makes the derivative explode -> the hardware
    // picks the coarsest mip -> a blurred vertical smear down the antimeridian
    // (most visible at the poles, where every meridian converges, aka the
    // Antarctica seam). Compute the derivatives ourselves and subtract the
    // artificial full-texture jump out of the longitude component, then sample
    // with an explicit gradient so mipmapping stays correct across the seam.
    // Latitude (asin) is continuous, so only .x is unwrapped. Real derivative
    // growth toward the poles is left intact.
    vec2 dUVdx = dFdx(mapUV);
    vec2 dUVdy = dFdy(mapUV);
    if (abs(dUVdx.x) > 0.5) dUVdx.x -= sign(dUVdx.x);
    if (abs(dUVdy.x) > 0.5) dUVdy.x -= sign(dUVdy.x);

    // The elevation bump map has, what I assume to be, per-texel noise
    // (JPEG grain / subtle bathymetric shading) that sits RIGHT at the ocean's
    // own baseline value,so a hard threshold would flicker it on/off across
    // open ocean. Because why would the author make the ocean bumpy and not flat?
    // The solution is that we use a purpose-built land/water mask (clean, ~binary,
    // vector-derived) for the land/ocean decision, and keep the noisy elevation
    // data only for internal land shading bands.
    float waterMaskRaw = textureGrad(watermask, mapUV, dUVdx, dUVdy).r;
    float landMask = crispStep(0.5, 1.0 - waterMaskRaw);

    float elevation = textureGrad(earthmap, mapUV, dUVdx, dUVdy).r;
    // normalize against this map's ocean-floor baseline (not always exactly 0,
    // depends on how the source bump map was leveled)
    const float oceanBaseline = 0.090;
    elevation = max(0.0, (elevation - oceanBaseline) / (1.0 - oceanBaseline));

    // second warped sample for pigment/pooling variation
    float warpDetail = fbm3(base * 1.8 + vec3(paperWarp.z) + 4.2);

    const float washAlpha = 0.82;
    vec3 col = ubuf.oceanColor.rgb;
    col = mix(col, ubuf.landColor.rgb, landMask * washAlpha);
    col = mix(col, ubuf.landColor2.rgb, landMask * softStep(0.06, elevation, 0.03) * washAlpha);
    col = mix(col, ubuf.landColor3.rgb, landMask * softStep(0.26, elevation, 0.08) * washAlpha);

    // ocean has no usable bathymetry in the elevation map (it's flat noise at
    // the baseline), so its depth variation is procedural instead, smooth by
    // construction
    float oceanWash = fbm3(base * 0.9 + 30.0);
    col = mix(col, ubuf.oceanDeep.rgb, (1.0 - landMask) * oceanWash * 0.6);
    col = mix(col, ubuf.inkColor.rgb, landMask * smoothstep(0.6, 0.85, warpDetail) * 0.12);

    // Granulation, sampled in the same seamless object-space so the paper grain
    // is baked onto the globe's surface and rotates with it, NOT fixed to the
    // screen/camera
    float grainCoarse = (noise3(rp * 90.0) - 0.5) * 0.05;
    float grainFine = (noise3(rp * 480.0) - 0.5) * 0.045;
    float fiber = (noise3(rp * vec3(30.0, 300.0, 30.0)) - 0.5) * 0.03;
    col += grainCoarse + grainFine + fiber;

    float rim = pow(1.0 - facing, 1.5);
    col = mix(col, ubuf.inkColor.rgb, rim * 0.35);

    vec4 arcs[8];
    arcs[0] = ubuf.arc0;
    arcs[1] = ubuf.arc1;
    arcs[2] = ubuf.arc2;
    arcs[3] = ubuf.arc3;
    arcs[4] = ubuf.arc4;
    arcs[5] = ubuf.arc5;
    arcs[6] = ubuf.arc6;
    arcs[7] = ubuf.arc7;

    for (int i = 0; i < ubuf.arcCount; i++) {
        vec4 a = arcs[i];
        vec3 p1 = latLonToSphere(radians(a.x), radians(a.y));
        vec3 p2 = latLonToSphere(radians(a.z), radians(a.w));
        vec3 planeNormal = normalize(cross(p1, p2));

        float d = abs(dot(rp, planeNormal));
        float core = 1.0 - smoothstep(0.0, 0.008, d);
        float bloom = (1.0 - smoothstep(0.0, 0.05, d)) * 0.4;

        float angTotal = acos(clamp(dot(p1, p2), -1.0, 1.0));
        float angToP1 = acos(clamp(dot(rp, p1), -1.0, 1.0));
        float angToP2 = acos(clamp(dot(rp, p2), -1.0, 1.0));
        float within = step(angToP1 + angToP2, angTotal + 0.015);

        // painted stroke instead of a neon line: wash the arc color into the
        // surface via mix rather than pure additive glow, with a stroke-width
        // wobble so it doesn't read as a perfectly uniform digital line.
        float strokeNoise = noise3(rp * 20.0 + float(i) * 13.0);
        float strength = clamp((core + bloom) * mix(0.6, 1.0, strokeNoise), 0.0, 1.0) * within;
        col = mix(col, ubuf.arcColor.rgb, strength);
    }

    // Point markers (people/machines sharing rough location) via a SPATIAL
    // GRID, not a loop over every point. Points are binned by lat/lon into a
    // grid (object space, so orientation-independent, the grid is baked on the
    // QML side only when the point DATA changes). This pixel reuses its own
    // lat/lon (already computed above for mapUV) to pick a cell, then scans
    // only that cell + neighbours instead of all N points.
    // CPU-verified: ~12-20 points examined per pixel instead of thousands
    // (245-418x fewer). The two lat/lon-grid gotchas handled below
    // (longitude wraps / latitude doesn't, the polar meridian-convergence lon
    // widening).
    //
    // Two textures: `pointsTex` is the body (1 texel/point, cell-sorted,
    // 12-bit lat + 12-bit lon packed into R+G+B: ~5km max error, quantised
    // identically on the hit-test side so render/hover agree). `headerTex` is
    // 2 texels per cell: texel 2c = start index into body (16-bit R+G), texel
    // 2c+1 = count.
    //
    // Loop bounds are compile-time constants with dynamic `break`s (required
    // under the GLSL ES 1.00 target, harmless on desktop 330). MAX_LAT_RANGE=3
    // covers ceil(haloDeg/cellDeg) for cellDeg=2 (halo <=3.65deg -> <=2, +1
    // headroom), MAX_LON_CELLS=181 covers a full ring of gridCols=180;
    // MAX_CELL_COUNT=1024 covers the densest observed stress cell (~747 at
    // 2deg/10240pts), a cell denser than that wants #3 clustering, not a
    // bigger bound.
    #define MAX_LAT_RANGE 3
    #define MAX_LON_CELLS 181
    #define MAX_CELL_COUNT 1024

    float dotScale = min((ubuf.camDist - 1.0) / 1.6, 0.85);
    float cosHaloMax = cos(0.075 * dotScale); // cheap per-point reject
    float haloDeg = (0.075 * dotScale) * 180.0 / PI;

    // this pixel's grid cell (lat/lon in degrees, lat/lon in radians were
    // computed above for the earth-map lookup)
    float latDeg = lat * 180.0 / PI;
    float lonDeg = lon * 180.0 / PI;
    int qLa = int(floor((latDeg + 90.0) / ubuf.cellDeg));
    int qLo = int(floor((lonDeg + 180.0) / ubuf.cellDeg));
    qLa = clamp(qLa, 0, ubuf.gridRows - 1);
    int latRange = int(ceil(haloDeg / ubuf.cellDeg));

    for (int dLa = -MAX_LAT_RANGE; dLa <= MAX_LAT_RANGE; dLa++) {
        if (dLa < -latRange || dLa > latRange)
            continue;
        int la = qLa + dLa;
        if (la < 0 || la >= ubuf.gridRows) // latitude does NOT wrap
            continue;

        // Longitude span of a haloDeg great-circle grows ~1/cos(lat) toward the
        // poles, use the band edge nearest the pole (largest |lat| -> widest
        // span) so we never under-scan and miss a point.
        float bandLoLat = float(la) * ubuf.cellDeg - 90.0;
        float bandHiLat = float(la + 1) * ubuf.cellDeg - 90.0;
        float worstLat = max(abs(bandLoLat), abs(bandHiLat));
        float cosW = cos(min(89.9, worstLat) * PI / 180.0);
        int lonRange;
        if (cosW < 1e-4 || haloDeg / cosW >= 180.0)
            lonRange = ubuf.gridCols;
        else
            lonRange = int(ceil((haloDeg / cosW) / ubuf.cellDeg));
        // scanning more than half the ring == scan the whole ring (avoids
        // double-visiting wrapped cells and keeps the loop within MAX_LON_CELLS)
        bool wholeRing = (2 * lonRange + 1 >= ubuf.gridCols);

        for (int dLo = 0; dLo < MAX_LON_CELLS; dLo++) {
            int lo;
            if (wholeRing) {
                if (dLo >= ubuf.gridCols)
                    break;
                lo = dLo;
            } else {
                if (dLo > 2 * lonRange)
                    break;
                lo = int(mod(float(qLo - lonRange + dLo), float(ubuf.gridCols))); // longitude WRAPS
            }

            int c = la * ubuf.gridCols + lo;
            float hStart = float(2 * c);
            float hCount = float(2 * c + 1);
            vec2 uvS = vec2(mod(hStart, ubuf.headerTexWidth) + 0.5, floor(hStart / ubuf.headerTexWidth) + 0.5)
                    / vec2(ubuf.headerTexWidth, ubuf.headerTexHeight);
            vec2 uvC = vec2(mod(hCount, ubuf.headerTexWidth) + 0.5, floor(hCount / ubuf.headerTexWidth) + 0.5)
                    / vec2(ubuf.headerTexWidth, ubuf.headerTexHeight);
            vec4 sData = texture(headerTex, uvS);
            vec4 cData = texture(headerTex, uvC);
            int start = int(floor(sData.r * 255.0 + 0.5)) * 256 + int(floor(sData.g * 255.0 + 0.5));
            int count = int(floor(cData.r * 255.0 + 0.5)) * 256 + int(floor(cData.g * 255.0 + 0.5));

            for (int k = 0; k < MAX_CELL_COUNT; k++) {
                if (k >= count)
                    break;
                float bi = float(start + k);
                vec2 uvB = vec2(mod(bi, ubuf.pointsTexWidth) + 0.5, floor(bi / ubuf.pointsTexWidth) + 0.5)
                        / vec2(ubuf.pointsTexWidth, ubuf.pointsTexHeight);
                vec4 d = texture(pointsTex, uvB);
                float R = floor(d.r * 255.0 + 0.5);
                float G = floor(d.g * 255.0 + 0.5);
                float B = floor(d.b * 255.0 + 0.5);
                float latQ = R * 16.0 + floor(G / 16.0); // 12-bit lat
                float lonQ = mod(G, 16.0) * 256.0 + B; // 12-bit lon
                float plat = (latQ / 4095.0) * 180.0 - 90.0;
                float plon = (lonQ / 4095.0) * 360.0 - 180.0;
                vec3 ppos = latLonToSphere(radians(plat), radians(plon));

                float cosd = dot(rp, ppos);
                if (cosd < cosHaloMax)
                    continue;
                float pd = acos(clamp(cosd, -1.0, 1.0));

                float core = 1.0 - smoothstep(0.0, 0.028 * dotScale, pd);
                float ringBand = (1.0 - smoothstep(0.028 * dotScale, 0.038 * dotScale, pd)) - core;
                float halo = (1.0 - smoothstep(0.0, 0.075 * dotScale, pd)) * 0.25;

                col = mix(col, ubuf.inkColor.rgb, clamp(ringBand, 0.0, 1.0) * 0.8);
                col = mix(col, ubuf.arcColor.rgb, clamp(core + halo, 0.0, 1.0));
            }
        }
    }

    fragColor = vec4(col, 1.0) * discMask * ubuf.qt_Opacity;
}
