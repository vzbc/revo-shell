import QtQuick
import "../../"

// General-purpose Earth globe: perspective ray-sphere camera, quaternion Arcball
// drag-rotation, scroll-zoom, and a spatial-grid-accelerated point-marker
// renderer. A consumer feeds it `points` (people, machines, whatever)
// and reads back which point is under the cursor.
// Point objects only need numeric `lat`/`lon` fields, any other fields
// (name, active flag, ...) are opaque to this component and simply handed
// back verbatim via `hoveredPoint` for the consumer to do with as it likes.

// Note: Claude Code has helped with writing the mouse navigation code.

Item {
    id: root

    // Public input API
    property var points: [] // [{lat, lon, ...}]
    property var arcs: [] // [{lat0, lon0, lat1, lon1}], up to 8 rendered

    property color oceanDeep: "#B3A388"
    property color oceanColor: "#E0D4BE"
    property color landColor: "#E8C99A"
    property color landColor2: "#D9A468"
    property color landColor3: "#8B6240"
    property color inkColor: "#3d2c1e"
    property color arcColor: "#FFB97C"

    // Initial camera look-at target, applied once at Component.onCompleted,
    // a consumer that wants to center on example the local user's own location
    // computes that lat/lon itself and passes it in here.
    property real initialLat: 50.0
    property real initialLon: 10.0

    // Extra one-shot roll (degrees) applied on top of the initialLat/Lon
    // look-at, around the same local forward axis as the 180-degree roll
    // correction below. Basically used for pretty framing.
    property real tiltDeg: 0

    property alias camDist: globe.camDist

    // Decorative-background mode: disables Arcball drag/zoom (for a globe
    // sitting behind other UI, drag/scroll should reach whatever's on top)
    // and spins it at a constant rate around the fixed world-up axis.
    property bool interactive: true
    property bool autoRotate: false
    property real autoRotateSpeedDegPerSec: 6

    // Public output API (hover state, written internally)

    property int hoveredIndex: -1
    property var hoveredPoint: hoveredIndex >= 0 && hoveredIndex < root.points.length ? root.points[hoveredIndex] : null
    property real hoverX: 0
    property real hoverY: 0

    // Point marker spatial grid (see the point section in globe.frag.
    // Points are binned by lat/lon into a grid. The shader picks each pixel's
    // cell and scans only that cell + neighbours.
    // The grid is object-space, so it rebuilds ONLY when `points` changes.
    //
    // Two textures back it (both use the same row-major addressing:
    // paint at (idx%width, floor(idx/width)), sample via mod/floor,
    // textureMirroring left at its default):
    //   - bodyCanvas: 1 texel per point, cell-sorted, 12-bit lat + 12-bit lon
    //     packed into R+G+B (alpha seems unusable, Qt premultiplies).
    //     ~5km max quantisation error
    //   - headerCanvas: 2 texels per cell, texel 2c = start index into body
    //     (16-bit R+G), texel 2c+1 = count (16-bit). 16-bit each so a dense
    //     cell never overflows its field (the shader still caps its inner loop
    //     at MAX_CELL_COUNT=1024, above the ~747 densest cell observed at
    //     2deg/10240pts, a denser cell than that wants clustering).
    readonly property real _gridCellDeg: 2
    readonly property int _gridCols: 180 // 360 / cellDeg
    readonly property int _gridRows: 90 // 180 / cellDeg

    // Bin `points` into the grid: a cell-sorted body array + a per-cell
    // {start,count} header. Rebuilds only when `points` changes.
    readonly property var _grid: {
        var cols = root._gridCols, rows = root._gridRows, cd = root._gridCellDeg;
        var pts = root.points;
        var cellOf = function (p) {
            var la = Math.floor((p.lat + 90) / cd);
            if (la >= rows)
                la = rows - 1;
            if (la < 0)
                la = 0;
            var lo = Math.floor((p.lon + 180) / cd);
            if (lo >= cols)
                lo = cols - 1;
            if (lo < 0)
                lo = 0;
            return la * cols + lo;
        };
        var body = pts.slice().sort(function (a, b) {
            return cellOf(a) - cellOf(b);
        });
        var header = new Array(cols * rows);
        for (var i = 0; i < header.length; i++)
            header[i] = {
                start: 0,
                count: 0
            };
        for (var j = 0; j < body.length; j++) {
            var c = cellOf(body[j]);
            if (header[c].count === 0)
                header[c].start = j;
            header[c].count++;
        }
        return {
            body: body,
            header: header
        };
    }

    Image {
        id: earthElevationImg
        source: "globeshader/assets/earth_elevation.png"
        visible: false
        smooth: true
        mipmap: true
    }

    Image {
        id: earthWatermaskImg
        source: "globeshader/assets/earth_watermask.png"
        visible: false
        smooth: true
        mipmap: true
    }

    Canvas {
        id: bodyCanvas
        width: 2048 // 1 texel/point, 10240 cap => 5 rows
        height: 5
        visible: false

        property var gridData: root._grid
        onGridDataChanged: requestPaint()
        Component.onCompleted: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            var b = root._grid.body;
            for (var i = 0; i < b.length; i++) {
                var latQ = Math.round((b[i].lat + 90) / 180 * 4095); // 12-bit
                var lonQ = Math.round((b[i].lon + 180) / 360 * 4095); // 12-bit
                var R = latQ >> 4;
                var G = ((latQ & 0xF) << 4) | (lonQ >> 8);
                var B = lonQ & 0xFF;
                ctx.fillStyle = Qt.rgba(R / 255, G / 255, B / 255, 1); // alpha pinned at 1
                ctx.fillRect(i % width, Math.floor(i / width), 1, 1);
            }
            bodyTexture.scheduleUpdate();
        }
    }

    Canvas {
        id: headerCanvas
        width: 2048 // 2 texels/cell, 180x90=16200 cells => 32400 texels => 16 rows
        height: 16
        visible: false

        property var gridData: root._grid
        onGridDataChanged: requestPaint()
        Component.onCompleted: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height); // empty cells stay 0 -> count 0 -> skipped
            var h = root._grid.header;
            for (var c = 0; c < h.length; c++) {
                var cnt = h[c].count;
                if (cnt === 0)
                    continue;
                var s = h[c].start;
                var si = 2 * c, ci = 2 * c + 1;
                ctx.fillStyle = Qt.rgba((s >> 8) / 255, (s & 0xFF) / 255, 0, 1);
                ctx.fillRect(si % width, Math.floor(si / width), 1, 1);
                ctx.fillStyle = Qt.rgba((cnt >> 8) / 255, (cnt & 0xFF) / 255, 0, 1);
                ctx.fillRect(ci % width, Math.floor(ci / width), 1, 1);
            }
            headerTexture.scheduleUpdate();
        }
    }

    ShaderEffectSource {
        id: bodyTexture
        sourceItem: bodyCanvas
        hideSource: true
        smooth: false
        live: false
    }

    ShaderEffectSource {
        id: headerTexture
        sourceItem: headerCanvas
        hideSource: true
        smooth: false
        live: false
    }

    ShaderEffect {
        id: globe
        anchors.fill: parent

        property real aspect: width / height
        // Dolly-zoom camera distance (sphere has radius 1, so this must stay
        // > 1 or the camera ends up inside the globe).
        property real camDist: 2.6
        readonly property real _minCamDist: 1.05
        readonly property real _maxCamDist: 6.0
        // Fixed lens, computed once, zoom is just a dolly (camDist), never
        // a change of FOV. Passed through as a uniform so the JS hit-testing
        // below is guaranteed to use the exact same value as the shader.
        readonly property real fovDeg: 46
        readonly property real tanHalfFov: Math.tan(fovDeg * Math.PI / 360)
        // quaternion (x, y, z, w), set once at load (see Component.onCompleted
        // below) to face `initialLat`/`initialLon`. Composed via Arcball from
        // then on (press-time reference point + orientation, recomputed fresh
        // each move).
        property vector4d orientation: Qt.vector4d(0, 0, 0, 1)
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

        // Kinetic release:
        // While dragging, _velVec tracks a short exponentially-smoothed window
        // of angular velocity (camera-space axis * rad/sec, from frame-to-frame
        // deltas, NOT the full press-to-now delta pressPoint/updateArcballRotation
        // use, since that would average in the whole drag instead of just the
        // flick at the end). On release that window is frozen into
        // flingAxis/flingSpeed and the FrameAnimation below spins the globe
        // down via friction. Because flingAxis is fixed for the whole coast
        // (never recomputed from new screen positions), repeatedly
        // right-multiplying by it is just one rotation split across frames.
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

        property color oceanDeep: root.oceanDeep
        property color oceanColor: root.oceanColor
        property color landColor: root.landColor
        property color landColor2: root.landColor2
        property color landColor3: root.landColor3
        property color inkColor: root.inkColor
        property color arcColor: root.arcColor
        property int arcCount: Math.min(root.arcs.length, 8)
        property vector4d arc0: globe._arcVec(0)
        property vector4d arc1: globe._arcVec(1)
        property vector4d arc2: globe._arcVec(2)
        property vector4d arc3: globe._arcVec(3)
        property vector4d arc4: globe._arcVec(4)
        property vector4d arc5: globe._arcVec(5)
        property vector4d arc6: globe._arcVec(6)
        property vector4d arc7: globe._arcVec(7)

        function _arcVec(i) {
            if (i >= root.arcs.length)
                return Qt.vector4d(0, 0, 0, 0);
            var a = root.arcs[i];
            return Qt.vector4d(a.lat0, a.lon0, a.lat1, a.lon1);
        }

        property variant earthmap: earthElevationImg
        property variant watermask: earthWatermaskImg
        property variant pointsTex: bodyTexture
        property variant headerTex: headerTexture
        property real pointsTexWidth: bodyCanvas.width
        property real pointsTexHeight: bodyCanvas.height
        property real headerTexWidth: headerCanvas.width
        property real headerTexHeight: headerCanvas.height
        property int gridCols: root._gridCols
        property int gridRows: root._gridRows
        property real cellDeg: root._gridCellDeg

        fragmentShader: "globeshader/globe.qsb"

        // Same lat/lon -> sphere-direction convention as latLonToSphere() in
        // globe.frag, kept in sync by hand since one's GLSL and one's JS.
        function latLonToVec(latDeg, lonDeg) {
            var lat = latDeg * Math.PI / 180, lon = lonDeg * Math.PI / 180;
            return {
                x: Math.cos(lat) * Math.cos(lon),
                y: Math.sin(lat),
                z: Math.cos(lat) * Math.sin(lon)
            };
        }

        // Shortest-arc only fixes yaw+pitch (which point faces the camera),
        // it leaves an arbitrary, uncontrolled ROLL depending on where the
        // target is. This builds an orthonormal (right, up, forward) basis that
        // keeps world-north aligned with screen-up, then converts that basis
        // to a quaternion.
        function quatLookAt(latDeg, lonDeg) {
            var fwd = latLonToVec(latDeg, lonDeg); // already unit length
            var worldUp = {
                x: 0,
                y: 1,
                z: 0
            }; // north pole direction

            // near the poles, fwd and worldUp are (near-)parallel and cross()
            // degenerates, fall back to an arbitrary reference axis there
            var dot = fwd.x * worldUp.x + fwd.y * worldUp.y + fwd.z * worldUp.z;
            if (Math.abs(dot) > 0.999)
                worldUp = {
                    x: 1,
                    y: 0,
                    z: 0
                };

            // right = normalize(cross(worldUp, fwd))
            var rx = worldUp.y * fwd.z - worldUp.z * fwd.y;
            var ry = worldUp.z * fwd.x - worldUp.x * fwd.z;
            var rz = worldUp.x * fwd.y - worldUp.y * fwd.x;
            var rlen = Math.sqrt(rx * rx + ry * ry + rz * rz);
            rx /= rlen;
            ry /= rlen;
            rz /= rlen;

            // up = cross(fwd, right), already unit length (fwd, right unit + perpendicular)
            var ux = fwd.y * rz - fwd.z * ry;
            var uy = fwd.z * rx - fwd.x * rz;
            var uz = fwd.x * ry - fwd.y * rx;

            // rotation matrix columns are (right, up, forward), converted to
            // a quaternion via the standard trace-based method (branches to
            // avoid dividing by a near-zero term, whichever diagonal entry is
            // largest)
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
            return Qt.vector4d(qx, qy, qz, qw);
        }

        Component.onCompleted: {
            // 180 degree roll correction
            // Assigning this just worked. I don't know why. But it did.
            var lookAt = quatLookAt(root.initialLat, root.initialLon);
            var roll180 = Qt.vector4d(0, 0, 1, 0);
            var tiltRad = root.tiltDeg * Math.PI / 180;
            var tiltQuat = {
                w: Math.cos(tiltRad / 2),
                x: 0,
                y: 0,
                z: Math.sin(tiltRad / 2)
            };
            var result = quatMul(quatMul(lookAt, roll180), tiltQuat);
            var mag = Math.sqrt(result.w * result.w + result.x * result.x + result.y * result.y + result.z * result.z);
            orientation = Qt.vector4d(result.x / mag, result.y / mag, result.z / mag, result.w / mag);
        }

        function quatMul(a, b) {
            return {
                w: a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z,
                x: a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
                y: a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
                z: a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w
            };
        }
        function quatConj(q) {
            return {
                w: q.w,
                x: -q.x,
                y: -q.y,
                z: -q.z
            };
        }

        // QML needs to know what is under the cursor. Using the exact same math
        // the shader uses to place rp.
        function rotateVecByQuat(v, q) {
            var qv = {
                x: q.x,
                y: q.y,
                z: q.z
            };
            var t = {
                x: qv.y * v.z - qv.z * v.y + q.w * v.x,
                y: qv.z * v.x - qv.x * v.z + q.w * v.y,
                z: qv.x * v.y - qv.y * v.x + q.w * v.z
            };
            var c2 = {
                x: qv.y * t.z - qv.z * t.y,
                y: qv.z * t.x - qv.x * t.z,
                z: qv.x * t.y - qv.y * t.x
            };
            return {
                x: v.x + 2 * c2.x,
                y: v.y + 2 * c2.y,
                z: v.z + 2 * c2.z
            };
        }

        // Mirrors globe.frag's ray-sphere intersection exactly (same
        // aspect/camDist/tanHalfFov terms). The ray direction and the
        // optimized b/closestApproachSq form are bit-for-bit identical to the
        // shader, so a hit test here lines up with what's actually rendered
        // at any camera distance. Returns null if the ray misses the sphere
        // entirely.
        function raySphereHit(px, py, dist, clampToSilhouette) {
            var dx = px, dy = py, dz = -1.0;
            var dlen = Math.sqrt(dx * dx + dy * dy + dz * dz);
            dx /= dlen;
            dy /= dlen;
            dz /= dlen;
            var b = dist * dz;
            var closestApproachSq = dist * dist - b * b;
            if (closestApproachSq > 1.0) {
                if (!clampToSilhouette)
                    return null;
                closestApproachSq = 1.0;
            }
            var t = -b - Math.sqrt(Math.max(1.0 - closestApproachSq, 0.0));
            return {
                x: dx * t,
                y: dy * t,
                z: dist + dz * t
            };
        }

        function screenToObjectDir(mx, my) {
            var u = mx / width, v = my / height;
            var px = (u * 2 - 1) * aspect * tanHalfFov;
            var py = (v * 2 - 1) * tanHalfFov;
            var hit = raySphereHit(px, py, camDist, false);
            if (!hit)
                return null;
            return rotateVecByQuat(hit, orientation);
        }

        // Nearest dot within the marker's own halo radius (see the dotScale-
        // scaled 0.075 halo term in globe.frag, mirrored here so hover
        // detection matches the actual rendered/perspective-compensated
        // marker size at any camDist).
        function findHoveredPointIndex(mx, my) {
            var dir = screenToObjectDir(mx, my);
            if (!dir)
                return -1;
            var pts = root.points;
            var dotScale = Math.min((camDist - 1.0) / 1.6, 0.85);
            var haloRadius = 0.075 * dotScale;
            var best = -1, bestAng = haloRadius;
            for (var i = 0; i < pts.length; i++) {
                // quantise to the body texture's 12-bit grid before comparing
                var qlat = Math.round((pts[i].lat + 90) / 180 * 4095) / 4095 * 180 - 90;
                var qlon = Math.round((pts[i].lon + 180) / 360 * 4095) / 4095 * 360 - 180;
                var pv = latLonToVec(qlat, qlon);
                var dot = Math.max(-1, Math.min(1, dir.x * pv.x + dir.y * pv.y + dir.z * pv.z));
                var ang = Math.acos(dot);
                if (ang < bestAng) {
                    bestAng = ang;
                    best = i;
                }
            }
            return best;
        }

        // Arcball reference point: the ray-sphere hit (clamped to the
        // silhouette when the cursor strays off the globe mid-drag, so a
        // drag that started on the globe keeps tracking smoothly instead of
        // going undefined). Using the perspective hit point here is what makes
        // a drag grab the exact point under the cursor and keep it there,
        // since the projected sphere gets bigger on screen as camDist shrinks.
        function projectToSphere(mx, my) {
            var px = ((mx / width) * 2 - 1) * aspect * tanHalfFov;
            var py = ((my / height) * 2 - 1) * tanHalfFov;
            return raySphereHit(px, py, camDist, true);
        }

        function beginArcballDrag(mx, my) {
            pressOrientation = {
                w: orientation.w,
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

            var result = quatMul(pressOrientation, quatConj(dq));
            var mag = Math.sqrt(result.w * result.w + result.x * result.x + result.y * result.y + result.z * result.z);
            orientation = Qt.vector4d(result.x / mag, result.y / mag, result.z / mag, result.w / mag);

            // Frame-to-frame (not press-to-now) velocity sample for the release fling
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
                var alpha = 0.35; // smoothing weight toward the newest sample
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
                    // Held still this sample, relax toward zero so pausing
                    // before letting go (an actual stop) doesn't still
                    // launch a coast the way a flick would.
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

        // Called on release: freezes the smoothed drag-velocity window into
        // a fixed axis/speed for the coast FrameAnimation below.
        function endArcballDrag() {
            // _velVec only gets updated inside updateArcballRotation, which
            // only runs when positionChanged fires, so if the cursor holds
            // completely still before release, no event fires, no relax-to-
            // zero step runs, and _velVec is left stuck at whatever it was
            // from the last movement (however long ago that was). We guard
            // it here instead, if the cursor's been still for a while, treat
            // it as a stop, regardless of what _velVec still says!
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
            // Below this it reads as an intentional slow drag rather than a
            // flick.
            if (speed > 0.4) {
                flingAxis = {
                    x: v.x / speed,
                    y: v.y / speed,
                    z: v.z / speed
                };
                // Cap so one noisy huge instantaneous sample can't launch an
                // absurdly fast spin.
                flingSpeed = Math.min(speed, 14);
            }
        }

        // Our pretty spinny spin animation :)
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
                    w: globe.orientation.w,
                    x: globe.orientation.x,
                    y: globe.orientation.y,
                    z: globe.orientation.z
                };
                var result = globe.quatMul(delta, cur);
                var mag = Math.sqrt(result.w * result.w + result.x * result.x + result.y * result.y + result.z * result.z);
                globe.orientation = Qt.vector4d(result.x / mag, result.y / mag, result.z / mag, result.w / mag);
            }
        }

        // Post-release coast: spins around the fixed flingAxis captured at
        // release, decaying flingSpeed via friction each frame until it
        // settles. Composing successive small rotations about the SAME
        // fixed axis onto the live orientation is safe.
        FrameAnimation {
            running: globe.flingSpeed > 0.0005 && !dragArea.pressed
            onTriggered: {
                var angle = globe.flingSpeed * frameTime;
                var half = angle / 2;
                var ax = globe.flingAxis;
                var dq = {
                    w: Math.cos(half),
                    x: ax.x * Math.sin(half),
                    y: ax.y * Math.sin(half),
                    z: ax.z * Math.sin(half)
                };
                var cur = {
                    w: globe.orientation.w,
                    x: globe.orientation.x,
                    y: globe.orientation.y,
                    z: globe.orientation.z
                };
                var result = globe.quatMul(cur, globe.quatConj(dq));
                var mag = Math.sqrt(result.w * result.w + result.x * result.x + result.y * result.y + result.z * result.z);
                globe.orientation = Qt.vector4d(result.x / mag, result.y / mag, result.z / mag, result.w / mag);

                globe.flingSpeed *= Math.pow(0.005, frameTime);
                if (globe.flingSpeed < 0.05)
                    globe.flingSpeed = 0;
            }
        }
    }

    Rectangle {
        anchors.centerIn: parent
        visible: globe.status === ShaderEffect.Error
        width: Math.min(parent.width - 32, 360)
        height: warningColumn.implicitHeight + 24
        radius: 8
        color: "#2a1414"
        border.color: "#a33"
        border.width: 1

        Column {
            id: warningColumn
            anchors.centerIn: parent
            width: parent.width - 24
            spacing: 6

            Text {
                width: parent.width
                text: I18n.t("globe2d.shaderFailedTitle")
                color: "#f0d0d0"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
            Text {
                width: parent.width
                text: I18n.t("globe2d.shaderFailedDetail", [globe.log !== "" ? "\n" + globe.log : ""])
                color: "#d0a0a0"
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true

        onPressed: mouse => {
            root.hoveredIndex = -1;
            var p = mapToItem(globe, mouse.x, mouse.y);
            globe.beginArcballDrag(p.x, p.y);
        }
        onPositionChanged: mouse => {
            var p = mapToItem(globe, mouse.x, mouse.y);
            if (pressed) {
                globe.updateArcballRotation(p.x, p.y);
                return;
            }
            root.hoveredIndex = globe.findHoveredPointIndex(p.x, p.y);
            root.hoverX = mouse.x;
            root.hoverY = mouse.y;
        }
        onReleased: globe.endArcballDrag()
        onCanceled: globe.endArcballDrag()
        onExited: root.hoveredIndex = -1
        onWheel: wheel => {
            // Same scroll-direction convention as before (scroll up = zoom
            // in), but zooming in now means dollying the camera closer
            // (dividing camDist) and not scaling up an orthographic
            // disc. Multiplicative either way, so steps shrink in absolute
            // terms as camDist shrinks, finer control automatically as you
            // approach the surface, no separate non-linear curve needed.
            var factor = 1.0 + wheel.angleDelta.y * 0.001;
            globe.camDist = Math.max(globe._minCamDist, Math.min(globe._maxCamDist, globe.camDist / factor));
        }
    }
}
