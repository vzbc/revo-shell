import QtQuick
import QtQuick3D
import QtQuick3D.Helpers
import Congeries
import "RealStarField.js" as RealStars

// The 3D globe engine: instanced rod prisms (RodGeometry + ScatterInstancing
// + AssemblyLayout + FloatTextureData) that can float apart and reassemble on
// trigger, with Arcball drag-rotation, wheel-zoom, and scanner/ripple
// effect modes. Also a sound mode, because why not??
//
// Every instance is its final rod from the start, it just starts at a
// random floating spawn transform and lerps/nlerps to its true target
// position+orientation on trigger. One canonical rod mesh (RodGeometry) is
// shared across all instances, AssemblyLayout.applyAssemblyData() (native
// C++, see that class) computes each rod's target position, its full
// 3-DOF alignment rotation onto RodGeometry's own upAxis/refTangent, a
// random spawn transform, and the exact-fit per-corner correction texture
// data, feeding all of it directly into scatter/correctionTexData via
// their native setters Only ScatterInstancing.t changes per frame during
// the animation itself.

// Squirrel Modeller:
// Shoutout to my math teacher at DTU (Denmarks Technical University)
// (person will stay anonymous) for explaining the math behind virtually all
// of this. Without you, this was just a pipe-dream. I apoligize for the many,
// many hours spent questioning you.
// Also my dad, who came up with the distortion idea for the prisms, which
// allowed me to only use a singular batch for drawing all instances.

Item {
    id: root

    property int frequency: 64
    property real meshRadius: 100.0
    readonly property real spawnMinRadius: meshRadius * 2.0
    readonly property real spawnMaxRadius: meshRadius * 4.0

    // assembleT drives scatter.t directly, the spawn/ target position+rotation
    // arrays themselves live only in ScatterInstancing (pushed once per
    // buildTargets() call)
    property real assembleT: 0.0 // 0 = scattered, 1 = assembled
    property int rodCount: 0 // set by buildTargets()
    property int correctionTexWidth: 4096

    // Decoding the elevation/watermask PNGs fresh every buildTargets()
    // call measured at ~59ms of the total on my setup.
    property bool useImageCache: AssemblyTestSettings.useImageCache

    // GPU% scaled with screen coverage, at ~82k separate rod prisms, they
    // expose FAR more silhouette edges than one continuous mesh would,
    // so MSAA's per-edge supersampling IS a hot spot.
    property string aaMode: AssemblyTestSettings.aaMode // "Off" | "Medium" | "High" | "VeryHigh"

    // Shader-driven scanner-sweep wave, here every instance reads its own world
    // direction back via INSTANCE_DATA (see AssemblyRodMaterial.vert) instead
    // of reconstructing it from UV1, since every instance shares one identical
    // canonical mesh.
    property real time: 0.0
    property real heightExaggeration: 1.0
    property real waveAmplitude: 0.2
    property real waveSpeed: 1.5
    property real waveNumber: 6.0
    property real heightSteps: 20.0

    // Idle float for scattered rods (fades out as assembleT -> 1, see the
    // drift block in AssemblyRodMaterial.vert)
    property real driftAmplitude: 18.0
    property real driftSpeed: 0.4

    // Blended ON TOP OF the spawn/assemble pose in ScatterInstancing
    // (native, see congeries/scatterinstancing.cpp). 0 = whatever
    // scatter/assemble is currently showing, 1 = every rod standing
    // upright on the flat equirectangular map. Meant to be driven
    // from the assembled (assembleT=1) state.
    property real flattenT: 0.0

    property int effectMode: 0 // 0 = none (flat, colors only), 1 = scanner (sweeping band), 2 = ripple (click to trigger)

    // Emissive location dots pinned to the assembled globe's surface
    // ([{lat, lon, ...}], extra fields opaque, same shape Globe.qml's 2D
    // `points` API takes). Rendered as instanced camera-facing billboard
    // quads (see DotMaterial.vert/frag) blending additively.
    property var points: [] // [{lat, lon, ...}]
    property real dotSize: 10.0
    property real dotIntensity: 3.0
    property color dotColor: "#ff9640"

    property color oceanColor: "#e0d4be"

    // The land elevation gradient: an arbitrary-length, ascending-by-
    // elevation list of {elevation, color}. A land rod gets the color of
    // the first entry whose `elevation` exceeds its own normalized
    // elevation (0..1), or the LAST entry's color if none does, see
    // AssemblyLayout::applyAssemblyData's doc comment (congeries repo) for
    // the exact rule.
    property var landLevels: [
        {
            elevation: 0.06,
            color: "#e8c99a"
        },
        {
            elevation: 0.26,
            color: "#d9a468"
        },
        {
            elevation: 1.0,
            color: "#8b6240"
        }
    ]
    // Just above the rods' resting tops (1 + _baseHeightFrac) so no z-fight.
    readonly property real dotAltitude: 1.02

    readonly property real dotFade: 1.0 - flattenT
    readonly property bool dotsVisible: assembleT == 1.0 && points.length > 0 && dotFade > 0.001

    property bool dotsFollowRodHeight: true

    // When false rods keep flat, rigid piston tops, and neighbors at different
    // heights leave a visible crack between them. When true each rod ALSO
    // flares its own top ring outward tangentially, by an amount
    // proportional to its own height. In short, this does exactly what the
    // variable says. Closes gaps.
    property bool closeHeightGaps: true
    property real flareGain: 1.0

    property bool starsEnabled: true
    property int starCount: 12000
    property real starFieldRadius: 6000.0
    property real starSize: 30.0
    property real starIntensity: 0.75

    // RealStarField.js is HYG catalog data (~9000 something stars, mag<=6.5,
    // brightest-first) baked by scripts/build_starfield.py. unit-sphere
    // positions + per-star color (B-V -> blackbody RGB) + a magnitude-derived
    // size/intensity curve. starCount acts as an N-brightest cutoff into
    // that sorted list.
    function _buildStarField() {
        var n = Math.min(root.starCount, RealStars.STAR_COUNT);
        var r = root.starFieldRadius;
        var srcPos = RealStars.POSITIONS;
        var positions = new Array(n * 3);
        for (var i = 0; i < n * 3; i++)
            positions[i] = srcPos[i] * r;

        starScatter.positions = positions;
        starScatter.colors = RealStars.COLORS.slice(0, n * 4);
        starScatter.customData = RealStars.CUSTOM_DATA.slice(0, n * 4);
    }
    onStarCountChanged: root._buildStarField()
    onStarFieldRadiusChanged: root._buildStarField()

    property bool glowEnabled: true
    property real glowStrength: 1.0
    property real glowIntensity: 0.01
    property real glowBloom: 0.2
    property real glowHDRMin: 3.0

    // Dev knob for the DirectionalLight. Because it messes up the entire
    // scene with a higher bloom.
    property real lightBrightness: 1.0

    property real rodRoughness: 0.0

    // Holds the dots at roughly constant SCREEN size across zoom
    // (perspective: screen size ~ worldSize / distance-to-surface, so
    // worldSize must scale WITH distance). Normalized to dotSize exactly
    // at the default camDist. Also what keeps density-additivity
    // when zoomed out. Fixed-world-size dots would shrink
    // subpixel and cluster brightness would collapse.
    readonly property real _dotSurfaceDist: meshRadius * dotAltitude
    readonly property real dotWorldSize: dotSize * Math.max(0.03, (camDist - _dotSurfaceDist) / (500 - _dotSurfaceDist))

    // The camera's world right/up axes, for the dot billboards
    // (DotMaterial.vert spans each quad on these instead of its own mesh
    // orientation so it always faces the orbiting camera).
    readonly property vector3d camRight: {
        var v = root.rotateVecByQuat({
            x: 1,
            y: 0,
            z: 0
        }, root._camOrientationObj);
        return Qt.vector3d(v.x, v.y, v.z);
    }
    readonly property vector3d camUp: {
        var v = root.rotateVecByQuat({
            x: 0,
            y: 1,
            z: 0
        }, root._camOrientationObj);
        return Qt.vector3d(v.x, v.y, v.z);
    }

    property bool rippleOnNewPoints: true
    // lat,lon-keyed set of the previously rendered points, null until
    // the first _rebuildDots() has run.>
    property var _prevPointKeys: null

    // Flat [x,y,z, ...] array pushed to dotScatter whenever `points`
    // changes, a one-time marshalling cost per data change (fineish even at
    // 10k+), nothing here runs per frame so we are PROBABLY fine~
    onPointsChanged: root._rebuildDots()
    function _rebuildDots() {
        var r = root.meshRadius * root.dotAltitude;
        var pts = root.points;
        var flat = new Array(pts.length * 3);
        var keys = {};
        var freshDirs = [];
        var hadPrev = root._prevPointKeys !== null && Object.keys(root._prevPointKeys).length > 0;
        for (var i = 0; i < pts.length; i++) {
            var v = root.latLonToVec(pts[i].lat, pts[i].lon);
            flat[i * 3] = v.x * r;
            flat[i * 3 + 1] = v.y * r;
            flat[i * 3 + 2] = v.z * r;
            var k = pts[i].lat.toFixed(4) + "," + pts[i].lon.toFixed(4);
            keys[k] = true;
            if (hadPrev && !root._prevPointKeys[k] && freshDirs.length < root.maxRipples)
                freshDirs.push(v);
        }
        root._prevPointKeys = keys;
        dotScatter.positions = flat;

        if (root.rippleOnNewPoints && freshDirs.length > 0) {
            var updated = root.ripples.slice();
            for (var j = 0; j < freshDirs.length; j++)
                updated.push({
                    dir: freshDirs[j],
                    time: root.time
                });
            while (updated.length > root.maxRipples)
                updated.shift();
            root.ripples = updated;
        }
    }

    // Audio-reactive layer, additive on top of whichever effectMode is
    // active, see AssemblyRodMaterial.vert's `bump = max(bump, audioLevel
    // * audioIntensity)`. AudioSpectrumAnalyzer (native, PipeWire capture
    // + FFT) only runs its capture thread while `active` is true, so leaving
    // this off costs nothing.
    property bool audioReactiveEnabled: false
    property real audioIntensity: 0.6
    readonly property int audioBandCount: 64

    // Read-only render stats, surfaced for consumers that want to show them
    // (devs give a shit, community doesn't bother).
    readonly property int drawCallCount: view3d.renderStats.drawCallCount
    readonly property int drawVertexCount: view3d.renderStats.drawVertexCount

    // Up to maxRipples independent ripples (each {dir, time}, in the mesh's
    // own LOCAL space, same convention as INSTANCE_DATA's per-rod direction
    // below).
    readonly property int maxRipples: 8
    property var ripples: [] // [{dir: {x,y,z}, time: real}, ...]

    function rippleDirAt(i) {
        return i < ripples.length ? Qt.vector3d(ripples[i].dir.x, ripples[i].dir.y, ripples[i].dir.z) : Qt.vector3d(1, 0, 0);
    }
    function rippleTimeAt(i) {
        return i < ripples.length ? ripples[i].time : -1000.0; // far in the past = no ripple shows yet
    }

    // Mirrors Globe.qml's (2D) interactive/autoRotate API
    property bool interactive: true
    property bool autoRotate: false
    property real autoRotateSpeedDegPerSec: 6

    // World-space Arcball
    // We just keep the globe's own model at identity, and orbit the camera
    // instead. Because otherwise we would be spinning every instance's rotation
    // which would get us nowhere.

    // Note: the camera's world orientation needs to be `conjugate(orientation)`,
    // not `orientation` itself, see `camOrientation` below for the derivation
    property quaternion orientation: Qt.quaternion(1, 0, 0, 0)
    property var pressOrientation: ({
            w: 1,
            x: 0,
            y: 0,
            z: 0
        })
    property var pressPoint: ({
            x: 0,
            y: 0,
            z: 1
        })

    // Kinetic release, ported from Globe2D.qml's fling/coast
    property var _velVec: ({
            x: 0,
            y: 0,
            z: 0
        })
    property var _lastSamplePoint: null
    property real _lastSampleTime: 0
    property var flingAxis: ({
            x: 0,
            y: 1,
            z: 0
        })
    property real flingSpeed: 0 // rad/sec, decays to 0 via friction

    function quatMul(a, b) {
        return {
            w: a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z,
            x: a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
            y: a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
            z: a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w
        };
    }

    // Used to convert a click point from the fixed screen/world frame
    // projectToSphere() returns into the mesh's own LOCAL (pre-rotation)
    // space, since the vertex shader's `dir` is read straight from
    // INSTANCE_DATA in that same local space, see handleClick().
    function rotateVecByQuat(v, q) {
        var uvx = q.y * v.z - q.z * v.y;
        var uvy = q.z * v.x - q.x * v.z;
        var uvz = q.x * v.y - q.y * v.x;
        var uuvx = q.y * uvz - q.z * uvy;
        var uuvy = q.z * uvx - q.x * uvz;
        var uuvz = q.x * uvy - q.y * uvx;
        return {
            x: v.x + 2 * (uvx * q.w + uuvx),
            y: v.y + 2 * (uvy * q.w + uuvy),
            z: v.z + 2 * (uvz * q.w + uuvz)
        };
    }

    function conjugateQuat(q) {
        return {
            w: q.w,
            x: -q.x,
            y: -q.y,
            z: -q.z
        };
    }

    // Default camera target on open Europe
    readonly property real defaultFocusLat: 50.0
    readonly property real defaultFocusLon: 10.0

    // Real-world lat/lon -> world direction. Inverts the lon/lat <- t.direction
    // mapping AssemblyLayout::applyAssemblyData (assemblylayout.cpp) uses to
    // pick a texture color for each already-fixed rod direction, so this
    // has to match it exactly, x negation included. Btw that's not a typo/mirror
    // of geography, it's counteracting QtQuick3D handedness quirk that only
    // applies to a 3D scene like this one, Globe.qml's own latLonToVec
    // (flat ray-marched shader) does NOT have this negation, so do NOT
    // copy between the two. You've been warned!!
    // Fun fact 1: I wasted approximately 5 hours debugging this quirk :)
    // Fun fact 2: I hated every second of it.
    function latLonToVec(latDeg, lonDeg) {
        var lat = latDeg * Math.PI / 180, lon = lonDeg * Math.PI / 180;
        return {
            x: -Math.cos(lat) * Math.cos(lon),
            y: Math.sin(lat),
            z: Math.cos(lat) * Math.sin(lon)
        };
    }

    function quatLookAt(latDeg, lonDeg) {
        var fwd = root.latLonToVec(latDeg, lonDeg);
        var worldUp = {
            x: 0,
            y: 1,
            z: 0
        };

        var dot = fwd.x * worldUp.x + fwd.y * worldUp.y + fwd.z * worldUp.z;
        if (Math.abs(dot) > 0.999)
            worldUp = {
                x: 1,
                y: 0,
                z: 0
            };

        var rx = worldUp.y * fwd.z - worldUp.z * fwd.y;
        var ry = worldUp.z * fwd.x - worldUp.x * fwd.z;
        var rz = worldUp.x * fwd.y - worldUp.y * fwd.x;
        var rlen = Math.sqrt(rx * rx + ry * ry + rz * rz);
        rx /= rlen;
        ry /= rlen;
        rz /= rlen;

        var ux = fwd.y * rz - fwd.z * ry;
        var uy = fwd.z * rx - fwd.x * rz;
        var uz = fwd.x * ry - fwd.y * rx;

        var m00 = rx, m01 = ux, m02 = fwd.x;
        var m10 = ry, m11 = uy, m12 = fwd.y;
        var m20 = rz, m21 = uz, m22 = fwd.z;
        var trace = m00 + m11 + m22;
        var qx, qy, qz, qw, s;
        if (trace > 0) {
            s = 0.5 / Math.sqrt(trace + 1.0);
            qw = 0.25 / s;
            qx = (m21 - m12) * s;
            qy = (m02 - m20) * s;
            qz = (m10 - m01) * s;
        } else if (m00 > m11 && m00 > m22) {
            s = 2.0 * Math.sqrt(1.0 + m00 - m11 - m22);
            qw = (m21 - m12) / s;
            qx = 0.25 * s;
            qy = (m01 + m10) / s;
            qz = (m02 + m20) / s;
        } else if (m11 > m22) {
            s = 2.0 * Math.sqrt(1.0 + m11 - m00 - m22);
            qw = (m02 - m20) / s;
            qx = (m01 + m10) / s;
            qy = 0.25 * s;
            qz = (m12 + m21) / s;
        } else {
            s = 2.0 * Math.sqrt(1.0 + m22 - m00 - m11);
            qw = (m10 - m01) / s;
            qx = (m02 + m20) / s;
            qy = (m12 + m21) / s;
            qz = 0.25 * s;
        }
        return {
            w: qw,
            x: qx,
            y: qy,
            z: qz
        };
    }

    // Keep the Model fixed at identity and orbits the CAMERA by
    // conjugate(orientation)
    // So in other words, where Globe.qml wants Q*(0,0,1) == fwd (its camera's
    // forward axis maps onto the target), THIS needs the inverse mapping,
    // Q*fwd == (0,0,1) (the target direction maps onto the axis the orbiting
    // camera ends up centered on), conjugating quatLookAt()'s result flips
    // which way it maps.
    function defaultViewOrientation() {
        var look = root.quatLookAt(root.defaultFocusLat, root.defaultFocusLon);
        return root.conjugateQuat(look);
    }

    property real camDist: 500

    // Off-axis camera shift, for consumers that need to frame the sphere
    // off-center (COUGH COUGH, (BackgroundGlobe)). Expressed as a fraction
    // of camDist. Translating the camera sideways while leaving its rotation
    // unchanged (still aimed the same absolute direction) is what shifts the
    // sphere's apparent position in frame, actual camera parallax, woooowieee.
    property real cameraShiftXFrac: 0.0
    property real cameraShiftYFrac: 0.0

    readonly property var _camOrientationObj: root.conjugateQuat({
        w: root.orientation.scalar,
        x: root.orientation.x,
        y: root.orientation.y,
        z: root.orientation.z
    })
    property quaternion camOrientation: Qt.quaternion(_camOrientationObj.w, _camOrientationObj.x, _camOrientationObj.y, _camOrientationObj.z)

    // Orbits on a sphere of radius camDist. The cameraShiftXFrac/YFrac
    // offset (see above) is added AFTER that, in the camera's own right/up
    // plane, and is NOT compensated for by re-aiming.
    readonly property vector3d camPosition: {
        var p = root.rotateVecByQuat({
            x: 0,
            y: 0,
            z: root.camDist
        }, root._camOrientationObj);
        var shiftAmount = root.camDist;
        return Qt.vector3d(p.x + root.camRight.x * root.cameraShiftXFrac * shiftAmount + root.camUp.x * root.cameraShiftYFrac * shiftAmount, p.y + root.camRight.y * root.cameraShiftXFrac * shiftAmount + root.camUp.y * root.cameraShiftYFrac * shiftAmount, p.z + root.camRight.z * root.cameraShiftXFrac * shiftAmount + root.camUp.z * root.cameraShiftYFrac * shiftAmount);
    }

    // Project a widget-local mouse position onto the globe with a
    // perspective ray-cast, against a canonical camera pose fixed at
    // (0,0,camDist) with identity orientation.
    function projectToSphere(mx, my) {
        var camPos = {
            x: 0,
            y: 0,
            z: root.camDist
        };
        var halfFovY = (camera.fieldOfView * Math.PI / 180) / 2;
        var aspect = root.width / root.height;
        var tanY = Math.tan(halfFovY);
        var tanX = tanY * aspect;

        var ndcX = (mx / root.width) * 2 - 1;
        var ndcY = 1 - (my / root.height) * 2;

        var dx = ndcX * tanX, dy = ndcY * tanY, dz = -1;
        var dlen = Math.sqrt(dx * dx + dy * dy + dz * dz);
        var dir = {
            x: dx / dlen,
            y: dy / dlen,
            z: dz / dlen
        };

        var hit = root.raySphereHitOrNearest({
            origin: camPos,
            dir: dir
        }, root.clickHitRadius);
        var hlen = Math.sqrt(hit.x * hit.x + hit.y * hit.y + hit.z * hit.z);
        return {
            x: hit.x / hlen,
            y: hit.y / hlen,
            z: hit.z / hlen
        };
    }

    function beginArcballDrag(mx, my) {
        pressOrientation = {
            w: orientation.scalar,
            x: orientation.x,
            y: orientation.y,
            z: orientation.z
        };
        pressPoint = projectToSphere(mx, my);

        flingSpeed = 0;
        _velVec = {
            x: 0,
            y: 0,
            z: 0
        };
        _lastSamplePoint = pressPoint;
        _lastSampleTime = Date.now();
    }

    function updateArcballRotation(mx, my) {
        var cur = projectToSphere(mx, my);
        var p0 = pressPoint, p1 = cur;

        var dot = Math.max(-1.0, Math.min(1.0, p0.x * p1.x + p0.y * p1.y + p0.z * p1.z));
        var axis = {
            x: p0.y * p1.z - p0.z * p1.y,
            y: p0.z * p1.x - p0.x * p1.z,
            z: p0.x * p1.y - p0.y * p1.x
        };
        var axisLen = Math.sqrt(axis.x * axis.x + axis.y * axis.y + axis.z * axis.z);

        var dq;
        if (axisLen < 1e-8) {
            dq = {
                w: 1,
                x: 0,
                y: 0,
                z: 0
            };
        } else {
            var angle = Math.acos(dot);
            var s = Math.sin(angle / 2) / axisLen;
            dq = {
                w: Math.cos(angle / 2),
                x: axis.x * s,
                y: axis.y * s,
                z: axis.z * s
            };
        }

        var result = quatMul(dq, pressOrientation);
        var mag = Math.sqrt(result.w * result.w + result.x * result.x + result.y * result.y + result.z * result.z);
        orientation = Qt.quaternion(result.w / mag, result.x / mag, result.y / mag, result.z / mag);

        // Copy paste from Globe2D.qml
        var now = Date.now();
        var dt = (now - _lastSampleTime) / 1000;
        if (dt > 0.001 && _lastSamplePoint) {
            var q0 = _lastSamplePoint, q1 = cur;
            var sdot = Math.max(-1.0, Math.min(1.0, q0.x * q1.x + q0.y * q1.y + q0.z * q1.z));
            var sax = {
                x: q0.y * q1.z - q0.z * q1.y,
                y: q0.z * q1.x - q0.x * q1.z,
                z: q0.x * q1.y - q0.y * q1.x
            };
            var salen = Math.sqrt(sax.x * sax.x + sax.y * sax.y + sax.z * sax.z);
            var sangle = Math.acos(sdot);
            var alpha = 0.35;
            if (salen > 1e-6 && sangle > 1e-6) {
                var instVel = {
                    x: (sax.x / salen) * sangle / dt,
                    y: (sax.y / salen) * sangle / dt,
                    z: (sax.z / salen) * sangle / dt
                };
                _velVec = {
                    x: _velVec.x * (1 - alpha) + instVel.x * alpha,
                    y: _velVec.y * (1 - alpha) + instVel.y * alpha,
                    z: _velVec.z * (1 - alpha) + instVel.z * alpha
                };
            } else {
                _velVec = {
                    x: _velVec.x * (1 - alpha),
                    y: _velVec.y * (1 - alpha),
                    z: _velVec.z * (1 - alpha)
                };
            }
        }
        _lastSamplePoint = cur;
        _lastSampleTime = now;
    }

    function endArcballDrag() {
        var stillMs = Date.now() - _lastSampleTime;
        if (stillMs > 80) {
            _velVec = {
                x: 0,
                y: 0,
                z: 0
            };
        }

        var v = _velVec;
        var speed = Math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
        if (speed > 0.4) {
            flingAxis = {
                x: v.x / speed,
                y: v.y / speed,
                z: v.z / speed
            };
            flingSpeed = Math.min(speed, 14);
        }
    }

    // Perspective ray-cast from the camera through the clicked pixel,
    // for handleClick(). We use the camera's position/orientation/FOV,
    // so it stays correct at any zoom.
    function screenRay(mx, my) {
        var camPos = root.camPosition;
        var right = rotateVecByQuat({
            x: 1,
            y: 0,
            z: 0
        }, root._camOrientationObj);
        var up = rotateVecByQuat({
            x: 0,
            y: 1,
            z: 0
        }, root._camOrientationObj);
        var fwd = rotateVecByQuat({
            x: 0,
            y: 0,
            z: -1
        }, root._camOrientationObj);

        var halfFovY = (camera.fieldOfView * Math.PI / 180) / 2;
        var aspect = root.width / root.height;
        var tanY = Math.tan(halfFovY);
        var tanX = tanY * aspect;

        var ndcX = (mx / root.width) * 2 - 1;
        var ndcY = 1 - (my / root.height) * 2;

        var dx = fwd.x + right.x * ndcX * tanX + up.x * ndcY * tanY;
        var dy = fwd.y + right.y * ndcX * tanX + up.y * ndcY * tanY;
        var dz = fwd.z + right.z * ndcX * tanX + up.z * ndcY * tanY;
        var len = Math.sqrt(dx * dx + dy * dy + dz * dz);

        return {
            origin: camPos,
            dir: {
                x: dx / len,
                y: dy / len,
                z: dz / len
            }
        };
    }

    // Nearest intersection of `ray` with a sphere of `radius` centered on
    // the origin, or null if the ray misses it entirely (click landed off
    // the globe's silhouette).
    function raySphereHit(ray, radius) {
        var o = ray.origin, d = ray.dir;
        var b = 2 * (o.x * d.x + o.y * d.y + o.z * d.z);
        var c = o.x * o.x + o.y * o.y + o.z * o.z - radius * radius;
        var disc = b * b - 4 * c;
        if (disc < 0)
            return null;
        var t = (-b - Math.sqrt(disc)) / 2;
        if (t < 0)
            return null;
        return {
            x: o.x + d.x * t,
            y: o.y + d.y * t,
            z: o.z + d.z * t
        };
    }

    // Same as raySphereHit(), but falls back to the closest point ON the
    // sphere to the ray's line when the ray misses entirely, instead of
    // null. Used by projectToSphere() so dragging the cursor out past the
    // globe's edge still rotates instead of freezing dead the moment the
    // ray stops actually touching the sphere.
    function raySphereHitOrNearest(ray, radius) {
        var hit = raySphereHit(ray, radius);
        if (hit)
            return hit;
        var o = ray.origin, d = ray.dir;
        var t = Math.max(0, -(o.x * d.x + o.y * d.y + o.z * d.z));
        var px = o.x + d.x * t, py = o.y + d.y * t, pz = o.z + d.z * t;
        var len = Math.sqrt(px * px + py * py + pz * pz) || 1;
        return {
            x: px / len * radius,
            y: py / len * radius,
            z: pz / len * radius
        };
    }

    // Rod tops sit proud of meshRadius even at rest: AssemblyRodMaterial.vert
    // extrudes by radius * heightFrac, and heightFrac is baseHeightFrac
    // whenever no ripple bump is currently passing through a given
    // rod, which is true almost everywhere almost all the time.
    // Good luck keeping 0._baseHeightFrac which is now a magic number in sync :)
    readonly property real _baseHeightFrac: 0.015
    readonly property real clickHitRadius: root.meshRadius * (1.0 + root._baseHeightFrac)

    // Ripple mode only, a CLICK triggers a new ripple at the clicked point
    function handleClick(mx, my) {
        if (effectMode !== 2)
            return;
        var hit = raySphereHit(screenRay(mx, my), root.clickHitRadius);
        if (!hit)
            return;

        var len = Math.sqrt(hit.x * hit.x + hit.y * hit.y + hit.z * hit.z);
        var localDir = {
            x: hit.x / len,
            y: hit.y / len,
            z: hit.z / len
        };

        var updated = ripples.slice();
        updated.push({
            dir: localDir,
            time: time
        });
        if (updated.length > maxRipples)
            updated.shift(); // we just drop the oldest for now
        ripples = updated;
    }

    RodGeometry {
        id: rodGeom
        frequency: root.frequency
        radius: root.meshRadius
    }

    // Per-instance exact-fit correction, keyed by INSTANCE_INDEX in
    // AssemblyRodMaterial.vert (read via texelFetch, the built-in table
    // has no room left, so this rides alongside it as a separate texture
    // instead). Reflowed into a correctionTexWidth-wide grid by
    // AssemblyLayout.applyAssemblyData() (native C++) for that speeeeeeed.
    FloatTextureData {
        id: correctionTexData
    }

    // Computes target position+rotation, random spawn transforms, and the
    // exact-fit correction texture data, feeding all of it directly into
    // scatter/correctionTexData via native C++ setters, see buildTargets().
    AssemblyLayout {
        id: assemblyLayout
    }

    // Live audio-frequency-band levels, refreshed by AudioSpectrumAnalyzer
    // (native C++: PipeWire monitor capture -> FFT -> log bands -> this
    // texture) independently of the instance buffer.
    FloatTextureData {
        id: audioLevelsTexData
    }

    AudioSpectrumAnalyzer {
        id: audioSpectrum
        active: root.audioReactiveEnabled
        bandCount: root.audioBandCount
        levelsTexture: audioLevelsTexData
    }

    // Recomputes every rod's target transform AND rolls fresh random spawn
    // transforms.
    // Fun fact: This used to be a loop (quaternion math + per-corner
    // correction ~500 lines removed here) that measured ~570ms of a ~770ms
    // total open time at 81,920 rods.
    function buildTargets() {
        var timerStart = Date.now();
        // Shares the 2D shader globe's elevation/watermask textures, no
        // duplicating them (see widgets/globe2d/globeshader/assets)
        root.rodCount = assemblyLayout.applyAssemblyData(scatter, correctionTexData, root.frequency, root.meshRadius, root.spawnMinRadius, root.spawnMaxRadius, root.correctionTexWidth, Qt.resolvedUrl("../globe2d/globeshader/assets/earth_elevation.png"), Qt.resolvedUrl("../globe2d/globeshader/assets/earth_watermask.png"), root.oceanColor, root.landLevels, root.useImageCache);
        console.log("buildTargets: TOTAL " + (Date.now() - timerStart) + "ms");
        // Setting root.assembleT (not scatter.t directly) ON PURPOSE,
        // scatter.t is a declarative binding to it, assigning scatter.t
        // imperatively here would sever that binding.
        root.assembleT = 0.0;
    }

    function triggerScatter() {
        assembleAnim.stop();
        root.assembleT = 0.0;
    }
    function triggerAssemble() {
        assembleAnim.from = root.assembleT;
        assembleAnim.to = 1.0;
        assembleAnim.start();
    }
    function triggerReScatter() {
        root.buildTargets();
    }
    function triggerBlowUp() {
        assembleAnim.stop();
        explodeAnim.stop();
        explodeOut.from = root.assembleT;
        explodeAnim.start();
    }
    function triggerFlattenToggle() {
        flattenAnim.stop();
        flattenAnim.from = root.flattenT;
        flattenAnim.to = root.flattenT > 0.5 ? 0.0 : 1.0;
        flattenAnim.start();
    }

    function setFlattenT(v) {
        flattenAnim.stop();
        root.flattenT = v;
    }

    // Fired once buildTargets() has finished its initial run. Consumers
    // that need to decide the starting pose (Globe3DPanel.qml choosing
    // scattered-then-assemble vs. already-assembled) MUST hook this!!
    signal ready

    Component.onCompleted: {
        var startOrientation = root.defaultViewOrientation();
        root.orientation = Qt.quaternion(startOrientation.w, startOrientation.x, startOrientation.y, startOrientation.z);
        buildTargets();
        root._buildStarField();
        root.ready();
    }

    View3D {
        id: view3d
        anchors.fill: parent

        Component.onCompleted: renderStats.extendedDataCollectionEnabled = true

        // ExtendedSceneEnvironment for its built-in glow/bloom pass:
        // the dots output HDR colors (dotIntensity > 1, see
        // DotMaterial.frag) and this blooms whatever ends up bright,
        // which after additive blending means dense clusters bloom
        // hardest.
        environment: ExtendedSceneEnvironment {
            clearColor: "#120d08" // update me to a theme variable or something, delete comment
            backgroundMode: SceneEnvironment.Color
            antialiasingMode: root.aaMode === "Off" ? SceneEnvironment.NoAA : SceneEnvironment.MSAA
            antialiasingQuality: root.aaMode === "VeryHigh" ? SceneEnvironment.VeryHigh : root.aaMode === "Medium" ? SceneEnvironment.Medium : SceneEnvironment.High

            glowEnabled: root.glowEnabled && root.dotsVisible
            glowStrength: root.glowStrength
            glowIntensity: root.glowIntensity
            glowBloom: root.glowBloom
            glowQualityHigh: true
            glowUseBicubicUpscale: true
            glowBlendMode: ExtendedSceneEnvironment.GlowBlendMode.Additive
            glowLevel: ExtendedSceneEnvironment.GlowLevel.One | ExtendedSceneEnvironment.GlowLevel.Two | ExtendedSceneEnvironment.GlowLevel.Three
            glowHDRMinimumValue: root.glowHDRMin
        }

        PerspectiveCamera {
            id: camera
            position: root.camPosition
            rotation: root.camOrientation
            clipNear: 5
        }

        // Rigged to orbit WITH the camera. Otherwise we can't see shit on
        // one side of the globe. Could be a cool effect if we add lights
        // or effects or something else.
        Node {
            rotation: root.camOrientation

            DirectionalLight {
                eulerRotation: Qt.vector3d(-30, -30, 0)
                brightness: root.lightBrightness
            }
        }

        Model {
            geometry: rodGeom
            instancing: ScatterInstancing {
                id: scatter
                t: root.assembleT
                flattenT: root.flattenT
            }
            materials: CustomMaterial {
                property real time: root.time
                property real heightExaggeration: root.heightExaggeration
                property real waveAmplitude: root.waveAmplitude
                property real waveSpeed: root.waveSpeed
                property real waveNumber: root.waveNumber
                property real heightSteps: root.heightSteps
                property real driftAmplitude: root.driftAmplitude
                property real driftSpeed: root.driftSpeed
                property real flattenT: root.flattenT
                property real radius: root.meshRadius
                property real roughness: root.rodRoughness
                property real assembleT: root.assembleT
                property real rodCount: root.rodCount
                property real correctionTexWidth: root.correctionTexWidth
                property vector3d localUpAxis: rodGeom.upAxis
                property real closeHeightGaps: root.closeHeightGaps ? 1.0 : 0.0
                property real flareGain: root.flareGain
                property vector3d camPosition: root.camPosition
                property real effectMode: root.effectMode
                property vector3d ripple0Dir: root.rippleDirAt(0)
                property real ripple0Time: root.rippleTimeAt(0)
                property vector3d ripple1Dir: root.rippleDirAt(1)
                property real ripple1Time: root.rippleTimeAt(1)
                property vector3d ripple2Dir: root.rippleDirAt(2)
                property real ripple2Time: root.rippleTimeAt(2)
                property vector3d ripple3Dir: root.rippleDirAt(3)
                property real ripple3Time: root.rippleTimeAt(3)
                property vector3d ripple4Dir: root.rippleDirAt(4)
                property real ripple4Time: root.rippleTimeAt(4)
                property vector3d ripple5Dir: root.rippleDirAt(5)
                property real ripple5Time: root.rippleTimeAt(5)
                property vector3d ripple6Dir: root.rippleDirAt(6)
                property real ripple6Time: root.rippleTimeAt(6)
                property vector3d ripple7Dir: root.rippleDirAt(7)
                property real ripple7Time: root.rippleTimeAt(7)
                property TextureInput correctionMap: TextureInput {
                    texture: Texture {
                        textureData: correctionTexData
                        minFilter: Texture.Nearest
                        magFilter: Texture.Nearest
                        generateMipmaps: false
                        mipFilter: Texture.None
                    }
                }
                property real audioBandCount: root.audioBandCount
                property real audioIntensity: root.audioReactiveEnabled ? root.audioIntensity : 0.0
                property TextureInput audioLevelsMap: TextureInput {
                    texture: Texture {
                        textureData: audioLevelsTexData
                        minFilter: Texture.Nearest
                        magFilter: Texture.Nearest
                        generateMipmaps: false
                        mipFilter: Texture.None
                    }
                }
                vertexShader: "AssemblyRodMaterial.vert"
                fragmentShader: "AssemblyRodMaterial.frag"
            }
        }

        // The emissive location dots: one shared "#Rectangle" quad
        // stamped out per point (positions fed by _rebuildDots(), pure
        // translations, identity rotations are what let DotMaterial.vert
        // billboard in local space, see its header comment). One/One
        // additive blending both marks the material transparent (drawn
        // after the opaque rods, depth-tested against them, so the globe
        // itself still occludes far-side dots) and makes overlapping dots
        // sum into concentrated brightness for the glow pass above.
        Model {
            source: "#Rectangle"
            visible: root.dotsVisible
            instancing: ScatterInstancing {
                id: dotScatter
            }
            materials: CustomMaterial {
                // Shaded (default) mode
                // APPARENTLY with unshaded, the rods just don't show!
                // "Emissive" comes from writing EMISSIVE_COLOR with a
                // black BASE_COLOR.
                sourceBlend: CustomMaterial.One
                destinationBlend: CustomMaterial.One
                depthDrawMode: Material.NeverDepthDraw
                cullMode: Material.NoCulling
                property vector3d camRight: root.camRight
                property vector3d camUp: root.camUp
                property real dotSize: root.dotWorldSize
                property real dotIntensity: root.dotIntensity
                property color dotColor: root.dotColor
                property real dotFade: root.dotFade
                property real colorVariety: 0.0

                property real followRodHeight: root.dotsFollowRodHeight ? 1.0 : 0.0
                property real radius: root.meshRadius
                property real time: root.time
                property real effectMode: root.effectMode
                property real waveSpeed: root.waveSpeed
                property real waveNumber: root.waveNumber
                property real waveAmplitude: root.waveAmplitude
                property real heightSteps: root.heightSteps
                property real heightExaggeration: root.heightExaggeration
                property real assembleT: root.assembleT
                property vector3d ripple0Dir: root.rippleDirAt(0)
                property real ripple0Time: root.rippleTimeAt(0)
                property vector3d ripple1Dir: root.rippleDirAt(1)
                property real ripple1Time: root.rippleTimeAt(1)
                property vector3d ripple2Dir: root.rippleDirAt(2)
                property real ripple2Time: root.rippleTimeAt(2)
                property vector3d ripple3Dir: root.rippleDirAt(3)
                property real ripple3Time: root.rippleTimeAt(3)
                property vector3d ripple4Dir: root.rippleDirAt(4)
                property real ripple4Time: root.rippleTimeAt(4)
                property vector3d ripple5Dir: root.rippleDirAt(5)
                property real ripple5Time: root.rippleTimeAt(5)
                property vector3d ripple6Dir: root.rippleDirAt(6)
                property real ripple6Time: root.rippleTimeAt(6)
                property vector3d ripple7Dir: root.rippleDirAt(7)
                property real ripple7Time: root.rippleTimeAt(7)

                property real audioBandCount: root.audioBandCount
                property real audioIntensity: root.audioReactiveEnabled ? root.audioIntensity : 0.0
                property TextureInput audioLevelsMap: TextureInput {
                    texture: Texture {
                        textureData: audioLevelsTexData
                        minFilter: Texture.Nearest
                        magFilter: Texture.Nearest
                        generateMipmaps: false
                        mipFilter: Texture.None
                    }
                }
                vertexShader: "DotMaterial.vert"
                fragmentShader: "DotMaterial.frag"
            }
        }

        // Background star field
        Model {
            source: "#Rectangle"
            visible: root.starsEnabled
            instancing: ScatterInstancing {
                id: starScatter
            }
            materials: CustomMaterial {
                sourceBlend: CustomMaterial.One
                destinationBlend: CustomMaterial.One
                depthDrawMode: Material.NeverDepthDraw
                cullMode: Material.NoCulling
                property vector3d camRight: root.camRight
                property vector3d camUp: root.camUp
                property real dotSize: root.starSize
                property real dotIntensity: root.starIntensity
                vertexShader: "StarMaterial.vert"
                fragmentShader: "StarMaterial.frag"
            }
        }
    }

    FrameAnimation {
        running: true
        onTriggered: root.time += frameTime
    }

    NumberAnimation {
        id: assembleAnim
        target: root
        property: "assembleT"
        duration: 2500
        easing.type: Easing.InOutCubic
    }

    // ScatterInstancing's spawn->target lerp (position = spawn + (target -
    // spawn) * t, see congeries/scatterinstancing.cpp) is never clamped to
    // [0,1], driving assembleT well below 0 extrapolates PAST the spawn
    // point. We just a burst out to a very negative t and a slow settle back
    // to the normal scattered rest state (t=0). Nice side effect of it.
    SequentialAnimation {
        id: explodeAnim

        NumberAnimation {
            id: explodeOut
            target: root
            property: "assembleT"
            to: -0.5
            duration: 500
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root
            property: "assembleT"
            to: 0.0
            duration: 2200
            easing.type: Easing.OutCubic
        }
    }

    NumberAnimation {
        id: flattenAnim
        target: root
        property: "flattenT"
        duration: 2000
        easing.type: Easing.InOutCubic
    }

    // Composes a small world-Y-axis delta onto the LEFT of the current
    // orientation each frame, same `quatMul(delta, cur)` convention dragArea's
    // own updateArcballRotation() already uses for its drag delta.
    FrameAnimation {
        running: root.autoRotate && !dragArea.pressed
        onTriggered: {
            var angleRad = root.autoRotateSpeedDegPerSec * Math.PI / 180 * frameTime;
            var half = angleRad / 2;
            var delta = {
                w: Math.cos(half),
                x: 0,
                y: Math.sin(half),
                z: 0
            };
            var cur = {
                w: root.orientation.scalar,
                x: root.orientation.x,
                y: root.orientation.y,
                z: root.orientation.z
            };
            var result = root.quatMul(delta, cur);
            var mag = Math.sqrt(result.w * result.w + result.x * result.x + result.y * result.y + result.z * result.z);
            root.orientation = Qt.quaternion(result.w / mag, result.x / mag, result.y / mag, result.z / mag);
        }
    }

    FrameAnimation {
        running: root.flingSpeed > 0.0005 && !dragArea.pressed
        onTriggered: {
            var angle = root.flingSpeed * frameTime;
            var half = angle / 2;
            var ax = root.flingAxis;
            var dq = {
                w: Math.cos(half),
                x: ax.x * Math.sin(half),
                y: ax.y * Math.sin(half),
                z: ax.z * Math.sin(half)
            };
            var cur = {
                w: root.orientation.scalar,
                x: root.orientation.x,
                y: root.orientation.y,
                z: root.orientation.z
            };
            var result = root.quatMul(dq, cur);
            var mag = Math.sqrt(result.w * result.w + result.x * result.x + result.y * result.y + result.z * result.z);
            root.orientation = Qt.quaternion(result.w / mag, result.x / mag, result.y / mag, result.z / mag);

            root.flingSpeed *= Math.pow(0.005, frameTime);
            if (root.flingSpeed < 0.05)
                root.flingSpeed = 0;
        }
    }

    // Declared BEFORE any control overlay a consumer adds as a LATER sibling
    // of this whole component, so that overlay wins input hit-testing over
    // this full-size MouseArea.
    MouseArea {
        id: dragArea
        anchors.fill: parent
        enabled: root.interactive

        property real pressX: 0
        property real pressY: 0
        property bool moved: false

        onPressed: mouse => {
            pressX = mouse.x;
            pressY = mouse.y;
            moved = false;
            root.beginArcballDrag(mouse.x, mouse.y);
        }
        onPositionChanged: mouse => {
            if (!pressed)
                return;
            if (Math.abs(mouse.x - pressX) > 4 || Math.abs(mouse.y - pressY) > 4)
                moved = true;
            root.updateArcballRotation(mouse.x, mouse.y);
        }
        onReleased: mouse => {
            root.endArcballDrag();
            if (!moved)
                root.handleClick(mouse.x, mouse.y);
        }
        onCanceled: root.endArcballDrag()
        onWheel: wheel => {
            var factor = 1.0 + wheel.angleDelta.y * 0.001;
            root.camDist = Math.max(115, Math.min(2000, root.camDist / factor));
        }
    }
}
