// Every instance here shares the exact same canonical mesh (RodGeometry),
// so there is no per-vertex UV1 to reconstruct a per-rod world
// direction from, since UV1 is identical for every instance. The per-rod
// world direction is fed in via INSTANCE_DATA.xyz (packed by
// GeodesicRodLayout.rodTargets(), assigned to ScatterInstancing.customData
// in QML), a per-instance value a shared/instanced mesh has no other way
// to carry.
//
// The push direction is the OPPOSITE kind of value: `localUpAxis` (bound
// to RodGeometry.upAxis) is a single CONSTANT direction, identical in the
// canonical mesh's own local/object space for every instance, each
// instance's own rotation (already baked in by AssemblyTest.qml to align
// that axis onto this rod's target direction) carries a local push
// along it to the correct world-radial direction automatically.
//
// EXACT-FIT CORRECTION: the rigid direction+tangent alignment alone only
// gets a rod's shape approximately right, real geodesic faces aren't
// exactly congruent, so a shared canonical mesh rotated into place leaves
// visible gaps. AssemblyLayout::applyAssemblyData (native C++, congeries
// repo's assemblylayout.cpp) precomputes, per rod, the LOCAL-space offset
// each of the canonical mesh's 3 corners needs so that after this
// instance's own rigid rotation carries it into world space, it lands
// exactly on that rod's vertex position, and writes it straight into
// the FloatTextureData GPU buffer bound here as `correctionMap` (not
// ScatterInstancing's fixed customData/color slots, which have no room
// left) keyed by (INSTANCE_INDEX, cornerIndex). QML (AssemblyGlobeView.qml)
// only calls applyAssemblyData and binds the resulting texture. `cornerIndex`
// (which of the 3 corners a given vertex record came from, base cap,
// top cap, and both rings of each side quad all reuse the same 3 underlying
// positions, see RodRecord::cornerIndex) rides in UV0.y here instead of the
// per-rod phase buildGeodesicRodMesh's shader uses that slot for,
// RodGeometry has no per-vertex use for phase, it already travels
// per-instance via INSTANCE_DATA.w. Scaling by `assembleT` fades the
// correction in exactly as the rod animates into place, and costs nothing
// while scattered (t=0 makes it a no-op, same category of vertex-texture-fetch
// this project already relies on in GeodesicGlobeMaterial.vert at far higher
// vertex counts with no measured cost)
//
// We are capped at 16384. For some reason. SO, AssemblyTest.qml instead
// reflows the flat "cornerIndex*rodCount + INSTANCE_INDEX" sequence into a
// correctionTexWidth-wide grid, this reverses that same reflow.
//
// COLOR: Qt's own fixed-function pipeline already multiplies BASE_COLOR by
// INSTANCE_COLOR automatically for every instanced CustomMaterial, see
// libQt6Quick3DRuntimeRender.so
// (`qt_diffuseColor = qt_customBaseColor * qt_vertColor;` where
// `qt_vertColor *= qt_instanceColor;`), regardless of whether this shader
// ever references INSTANCE_COLOR itself.
// If we DO set vColor to INSTANCE_COLOR here (which I did because it made
// sense at the time) applied it a SECOND time on top of that automatic
// multiply, squaring the color, which made every channel darker/more
// saturated than intended.
VARYING vec4 vColor;

// computeRippleBump()/rodHeightFrac()/kBaseHeightFrac below are duplicated
// in DotMaterial.vert
const float kBaseHeightFrac = 0.015;

float computeRippleBump(vec3 dir, vec3 sourceDir, float startTime, float currentTime, float speed, float sharpness)
{
    float dist = acos(clamp(dot(dir, sourceDir), -1.0, 1.0));
    float elapsed = max(0.0, currentTime - startTime);
    float rippleRadius = elapsed * speed;

    float ringWidth = 3.14159265 / (4.0 * max(1.0, sharpness));
    float distFromRing = abs(dist - rippleRadius);
    float bump = clamp(1.0 - distFromRing / ringWidth, 0.0, 1.0);
    bump = pow(bump, 1.5);

    const float attackTime = 0.3;
    bump *= clamp(elapsed / attackTime, 0.0, 1.0);

    float decay = exp(-rippleRadius * 1.5);
    bump *= decay;

    return bump;
}

// Current radial extrusion fraction (ADDITIVE on top of the base
// meshRadius, a rod's actual resting outer radius is
// radius*(1+heightFrac)) for a rod/dot at unit direction `dir`, given the
// live effectMode/ripple/audio state.
float rodHeightFrac(vec3 dir, float time, float effectMode, float waveSpeed, float waveNumber, vec3 ripple0Dir, float ripple0Time, vec3 ripple1Dir, float ripple1Time, vec3 ripple2Dir, float ripple2Time, vec3 ripple3Dir, float ripple3Time, vec3 ripple4Dir, float ripple4Time, vec3 ripple5Dir, float ripple5Time, vec3 ripple6Dir, float ripple6Time, vec3 ripple7Dir, float ripple7Time, float audioIntensity, float audioBandCount, sampler2D audioLevelsMap, float heightSteps, float waveAmplitude, float heightExaggeration, float assembleT)
{
    float bump = 0.0;
    if (effectMode > 0.5 && effectMode < 1.5) {
        float angle = atan(dir.y, dir.x);
        float sweepAngle = time * waveSpeed;
        float angularDist = angle - sweepAngle;
        angularDist = mod(angularDist + 3.14159265, 2.0 * 3.14159265) - 3.14159265;
        bump = max(0.0, cos(angularDist));
        bump = pow(bump, max(1.0, waveNumber));
    }

    bump = max(bump, computeRippleBump(dir, ripple0Dir, ripple0Time, time, waveSpeed, waveNumber));
    bump = max(bump, computeRippleBump(dir, ripple1Dir, ripple1Time, time, waveSpeed, waveNumber));
    bump = max(bump, computeRippleBump(dir, ripple2Dir, ripple2Time, time, waveSpeed, waveNumber));
    bump = max(bump, computeRippleBump(dir, ripple3Dir, ripple3Time, time, waveSpeed, waveNumber));
    bump = max(bump, computeRippleBump(dir, ripple4Dir, ripple4Time, time, waveSpeed, waveNumber));
    bump = max(bump, computeRippleBump(dir, ripple5Dir, ripple5Time, time, waveSpeed, waveNumber));
    bump = max(bump, computeRippleBump(dir, ripple6Dir, ripple6Time, time, waveSpeed, waveNumber));
    bump = max(bump, computeRippleBump(dir, ripple7Dir, ripple7Time, time, waveSpeed, waveNumber));

    if (audioIntensity > 0.001) {
        float audioAngle = atan(dir.y, dir.x);
        float audioFrac = audioAngle / (2.0 * 3.14159265) + 0.5;
        int audioBand = clamp(int(audioFrac * audioBandCount), 0, int(audioBandCount) - 1);
        float audioLevel = texelFetch(audioLevelsMap, ivec2(audioBand, 0), 0).r;
        bump = max(bump, audioLevel * audioIntensity);
    }

    float bumpQuantized = round(bump * heightSteps) / heightSteps;
    float wave = bumpQuantized * waveAmplitude;

    return max(0.001, kBaseHeightFrac + wave * heightExaggeration * assembleT);
}

float hash11(float p)
{
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

void MAIN()
{
    vec3 dir = normalize(INSTANCE_DATA.xyz);

    // Hemisphere cull: collapse this whole rod to a single point (all 3
    // triangle corners -> the same VERTEX) when it faces away from the
    // camera, so its triangles have zero screen area and the rasterizer
    // discards them for free.
    //
    // Uses THIS instance's actual current position
    // (INSTANCE_MODEL_MATRIX's translation, aka ScatterInstancing's
    // spawn->target lerp at the current t), not `dir` above, `dir` is the
    // rod's fixed FINAL target direction and stays wrong-side-blind
    // whenever the current position hasn't caught up to it yet (scattered
    // cloud, mid-assemble flight, exploded burst). Reads world position
    // directly off INSTANCE_MODEL_MATRIX with no MODEL_MATRIX multiply
    // because the globe's own Model is kept at identity (the camera orbits
    // instead), same identity-Model assumption `dir` above already relies
    // on to skip reconstructing a "world" direction of its own.
    // Only engages once the globe is fully assembled (and not flattened).
    if (assembleT >= 0.999 && flattenT <= 0.001) {
        vec3 instancePos = INSTANCE_MODEL_MATRIX[3].xyz;
        vec3 outward = normalize(instancePos);
        float facing = dot(outward, normalize(camPosition - instancePos));
        if (facing < -0.06) {
            VERTEX = vec3(0.0);
            vColor = vec4(1.0);
            return;
        }
    }

    int texW = int(correctionTexWidth);

    // The exact-fit correction map below was baked for the GLOBE target
    // only (closing gaps between adjacent, non-congruent geodesic faces).
    int cornerIndex = int(UV0.y);
    int correctionIndex = cornerIndex * int(rodCount) + INSTANCE_INDEX;
    ivec2 correctionCoord = ivec2(correctionIndex % texW, correctionIndex / texW);
    vec3 correction = texelFetch(correctionMap, correctionCoord, 0).xyz;
    VERTEX = VERTEX + correction * assembleT * (1.0 - flattenT);

    // Scattered-float drift. Offset added in LOCAL space, so each instance's
    // own (spawn->target nlerp'd) rotation carries it toward a different
    // world direction, that's what makes the drift read as chaotic/organic
    // Fades out via (1-assembleT) so it never fights the exact-fit correction
    // above once assembled.
    float seed = float(INSTANCE_INDEX);
    vec3 driftPhase = vec3(hash11(seed * 12.9898), hash11(seed * 78.233 + 11.0), hash11(seed * 37.719 + 23.0)) * 6.28318530718;
    vec3 driftFreq = vec3(0.6) + vec3(hash11(seed * 3.14 + 5.0), hash11(seed * 9.13 + 7.0), hash11(seed * 5.71 + 9.0)) * 0.8;
    vec3 drift = vec3(sin(time * driftSpeed * driftFreq.x + driftPhase.x), sin(time * driftSpeed * driftFreq.y + driftPhase.y), sin(time * driftSpeed * driftFreq.z + driftPhase.z));
    VERTEX = VERTEX + drift * driftAmplitude * (1.0 - assembleT);

    // effectMode 0 ("none", the default) leaves bump at 0.0, just the flat
    // kBaseHeightFrac surface below. 1 is the scanner sweep, 2 gates
    // whether CLICKING spawns a ripple (AssemblyGlobeView.handleClick).
    // Ripples run in EVERY mode. Besides click ripples, a ripple spawns
    // wherever a NEW community dot appears (AssemblyGlobeView._rebuildDots),
    // and that feedback shouldn't depend on which effect the user happens to
    // have selected. Audio-reactive is ADDITIVE on top too.
    float ringFlag = UV0.x; // 0 = base ring (stays put), 1 = top ring (extrudes), still baked per-vertex
    float heightFrac = rodHeightFrac(dir, time, effectMode, waveSpeed, waveNumber, ripple0Dir, ripple0Time, ripple1Dir, ripple1Time, ripple2Dir, ripple2Time, ripple3Dir, ripple3Time, ripple4Dir, ripple4Time, ripple5Dir, ripple5Time, ripple6Dir, ripple6Time, ripple7Dir, ripple7Time, audioIntensity, audioBandCount, audioLevelsMap, heightSteps, waveAmplitude, heightExaggeration, assembleT);

    vec3 up = normalize(localUpAxis);
    VERTEX = VERTEX + up * (radius * heightFrac * ringFlag);

    if (closeHeightGaps > 0.5) {
        vec3 alongUp = dot(VERTEX, up) * up;
        vec3 tangential = VERTEX - alongUp;
        float flare = heightFrac * flareGain * ringFlag;
        VERTEX = alongUp + tangential * (1.0 + flare);
    }

    vColor = vec4(1.0);
}
