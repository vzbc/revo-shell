// Camera-facing billboard for the emissive location dots
// (AssemblyGlobeView.qml's dot Model).
// Geometry is the "#Rectangle" primitive stamped out once per point
// by a second ScatterInstancing whose per-instance transform is a pure
// translation.
//
// followRodHeight (AssemblyGlobeView.dotsFollowRodHeight, gateable in the
// settings UI since it costs extra per-dot ALU). When on, lifts the dot
// radially by the rod's current excursion above its resting height.
//
// computeRippleBump()/rodHeightFrac()/kBaseHeightFrac are duplicated.
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

VARYING vec2 vUV;
VARYING float vSeed;

void MAIN()
{
    vUV = UV0;
    vSeed = float(INSTANCE_INDEX);
    vec3 billboard = (camRight * VERTEX.x + camUp * VERTEX.y) * (dotSize / 100.0);

    vec3 radialLift = vec3(0.0);
    if (followRodHeight > 0.5) {
        vec3 dir = normalize(INSTANCE_MODEL_MATRIX[3].xyz);
        float heightFrac = rodHeightFrac(dir, time, effectMode, waveSpeed, waveNumber, ripple0Dir, ripple0Time, ripple1Dir, ripple1Time, ripple2Dir, ripple2Time, ripple3Dir, ripple3Time, ripple4Dir, ripple4Time, ripple5Dir, ripple5Time, ripple6Dir, ripple6Time, ripple7Dir, ripple7Time, audioIntensity, audioBandCount, audioLevelsMap, heightSteps, waveAmplitude, heightExaggeration, assembleT);

        radialLift = dir * radius * (heightFrac - kBaseHeightFrac);
    }

    VERTEX = billboard + radialLift;
}
