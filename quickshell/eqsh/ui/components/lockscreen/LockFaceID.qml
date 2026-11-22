import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io

// Face ID on the lock screen, shown in a Dynamic Island at the top centre.
// Uses Sapphire for Linux's engine (~/.config/quickshell/sapphire/scripts/faceid.py)
// and its settings (~/.config/sapphire/settings.json):
//   lockFaceId: "off" | "enter" (recognised → press Enter, no password) | "instant"
// Island states: idle (closed padlock) → scanning (Face ID glyph) →
// success (green check, then open padlock + "Press Enter") / fail (shake).
Item {
	id: fid
	property var context: null
	property bool interactive: true          // only the focused screen uses the camera
	readonly property string home: Quickshell.env("HOME")
	readonly property string engine: home + "/.config/quickshell/sapphire/scripts/faceid.py"

	// ---------------------------------------------------------- settings
	property string mode: "off"
	property bool hasProfile: false
	FileView {
		path: fid.home + "/.config/sapphire/settings.json"
		watchChanges: true
		onFileChanged: reload()
		onLoaded: {
			try {
				const s = JSON.parse(text())
				fid.hasProfile = (s.faceIdProfiles || []).length > 0 && s.faceIdEnabled === true
				fid.mode = s.lockFaceId || "enter"
			} catch (e) { fid.mode = "off" }
		}
	}
	readonly property bool enabled: mode !== "off" && hasProfile && interactive

	// ------------------------------------------------------------- state
	property string state_: "idle"           // idle | scanning | success | ready | fail
	property int fails: 0
	property int frame: 0
	visible: enabled || state_ !== "idle"

	function scan() {
		if (!enabled || proc.running || state_ === "success" || state_ === "ready") return
		state_ = "scanning"
		proc.command = ["python3", "-I", engine, "verify", "10"]
		proc.running = true
	}
	// any activity (typing, pointer, click on the island) rescans after a failure
	function poke() { if (state_ === "idle" && fails > 0) scan() }
	onEnabledChanged: if (enabled) startDelay.restart(); else { proc.running = false; state_ = "idle" }
	Timer { id: startDelay; interval: 700; onTriggered: fid.scan() }
	// stop the camera and put its gain back even if the scan was cut short
	Component.onDestruction: {
		proc.running = false
		if (enabled) Quickshell.execDetached(["sh", "-c", "sleep 0.5; python3 -I \"$1\" restore", "sh", engine])
	}

	Process {
		id: proc
		// engine missing / crashed: don't sit on "scanning"
		onExited: if (fid.state_ === "scanning") { fid.fails++; fid.state_ = "fail"; failTimer.restart() }
		stdout: SplitParser {
			onRead: (line) => {
				let o; try { o = JSON.parse(line) } catch (e) { return }
				fid.frame++
				if (o.result === "match") {
					fid.state_ = "success"
					if (fid.context) fid.context.faceVerified = true
					afterSuccess.restart()
				} else if (o.result) {
					fid.fails++
					fid.state_ = "fail"
					failTimer.restart()
				}
			}
		}
	}
	Timer {
		id: afterSuccess; interval: 750
		onTriggered: {
			if (fid.mode === "instant" && fid.context) fid.context.faceUnlock()
			else fid.state_ = "ready"
		}
	}
	Timer {
		id: failTimer; interval: 1100
		onTriggered: {
			fid.state_ = "idle"
			if (fid.fails < 2) fid.scan()            // one automatic retry, then wait for activity
		}
	}
	HoverHandler { onPointChanged: fid.poke() }

	// ------------------------------------------------------------ island
	readonly property real iw: state_ === "scanning" || state_ === "success" || state_ === "fail" ? 140
		: state_ === "ready" ? (mode === "instant" ? 124 : readyRow.implicitWidth + 44) : 124
	readonly property real ih: state_ === "scanning" || state_ === "success" || state_ === "fail" ? 136 : 34
	readonly property real ir: ih > 60 ? 46 : 17

	Item {
		id: island
		anchors.horizontalCenter: parent.horizontalCenter
		y: 0
		width: fid.iw; height: fid.ih
		Behavior on width { SpringAnimation { spring: 3.4; damping: 0.32; epsilon: 0.3 } }
		Behavior on height { SpringAnimation { spring: 3.4; damping: 0.32; epsilon: 0.3 } }
		property real shakeX: 0
		transform: Translate { x: island.shakeX }
		SequentialAnimation {
			running: fid.state_ === "fail"
			NumberAnimation { target: island; property: "shakeX"; to: -14; duration: 60 }
			NumberAnimation { target: island; property: "shakeX"; to: 12; duration: 80 }
			NumberAnimation { target: island; property: "shakeX"; to: -8; duration: 70 }
			NumberAnimation { target: island; property: "shakeX"; to: 5; duration: 60 }
			NumberAnimation { target: island; property: "shakeX"; to: 0; duration: 60 }
		}

		// black island with flared top corners
		Shape {
			id: isl
			anchors.fill: parent
			preferredRendererType: Shape.CurveRenderer
			readonly property real t: 7
			readonly property real b: Math.min(fid.ir, height / 2, (width - 2 * t) / 2)
			ShapePath {
				fillColor: "black"; strokeWidth: -1
				startX: 0; startY: 0
				PathQuad { x: 7; y: 7; controlX: 7; controlY: 0 }
				PathLine { x: 7; y: island.height - isl.b }
				PathQuad { x: 7 + isl.b; y: island.height; controlX: 7; controlY: island.height }
				PathLine { x: island.width - 7 - isl.b; y: island.height }
				PathQuad { x: island.width - 7; y: island.height - isl.b; controlX: island.width - 7; controlY: island.height }
				PathLine { x: island.width - 7; y: 7 }
				PathQuad { x: island.width; y: 0; controlX: island.width - 7; controlY: 0 }
				PathLine { x: 0; y: 0 }
			}
		}
		MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { fid.fails = Math.max(fid.fails, 1); fid.poke() } }

		// compact: padlock
		Image {
			anchors.centerIn: parent
			visible: fid.ih < 60 && fid.state_ !== "ready"
			width: 15; height: 15
			source: Qt.resolvedUrl("icons/lock.png"); sourceSize: Qt.size(64, 64); smooth: true; mipmap: true
		}
		// ready: open padlock + hint
		Row {
			id: readyRow
			anchors.centerIn: parent
			visible: fid.state_ === "ready"
			spacing: 9
			Image { width: 15; height: 15; anchors.verticalCenter: parent.verticalCenter
				source: Qt.resolvedUrl("icons/unlock.png"); sourceSize: Qt.size(64, 64); smooth: true; mipmap: true }
			Text {
				visible: fid.mode !== "instant"
				anchors.verticalCenter: parent.verticalCenter
				text: "Press Enter to unlock"
				color: "white"; font.family: "SF Pro Text"; font.pixelSize: 13; font.weight: Font.DemiBold
			}
		}

		// expanded: Face ID glyph / check
		Item {
			id: glyphBox
			anchors.centerIn: parent
			width: 64; height: 64
			visible: fid.ih > 60
			opacity: fid.ih > 110 ? 1 : 0
			Behavior on opacity { NumberAnimation { duration: 160 } }
			readonly property color ink: fid.state_ === "success" ? "#30D158" : fid.state_ === "fail" ? "#FF453A" : "white"
			property real checkP: fid.state_ === "success" ? 1 : 0
			Behavior on checkP { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
			// scanning: brackets breathe
			property real pulse: 1
			SequentialAnimation on pulse {
				running: fid.state_ === "scanning"; loops: Animation.Infinite
				NumberAnimation { from: 1; to: 0.88; duration: 520; easing.type: Easing.InOutSine }
				NumberAnimation { from: 0.88; to: 1; duration: 520; easing.type: Easing.InOutSine }
			}
			Canvas {
				id: cv
				anchors.fill: parent
				property color ink: glyphBox.ink
				property real p: glyphBox.checkP
				property real pulse: glyphBox.pulse
				onInkChanged: requestPaint(); onPChanged: requestPaint(); onPulseChanged: requestPaint()
				onPaint: {
					const g = getContext("2d"); g.reset()
					const w = width, s = w / 74
					g.strokeStyle = ink; g.lineWidth = 4.2 * s; g.lineCap = "round"; g.lineJoin = "round"
					// corner brackets (the Face ID frame), pulled in while scanning
					const m = (1 - pulse) * 10 * s + 4 * s, L = 16 * s, r = 10 * s
					const corners = [[m, m, 1, 1], [w - m, m, -1, 1], [m, w - m, 1, -1], [w - m, w - m, -1, -1]]
					for (const c of corners) {
						g.beginPath()
						g.moveTo(c[0], c[1] + c[3] * L)
						g.lineTo(c[0], c[1] + c[3] * r)
						g.quadraticCurveTo(c[0], c[1], c[0] + c[2] * r, c[1])
						g.lineTo(c[0] + c[2] * L, c[1])
						g.stroke()
					}
					if (p < 0.5) {
						// face: eyes, nose, smile (fades out as the check draws)
						g.globalAlpha = 1 - p * 2
						g.beginPath(); g.moveTo(27 * s, 28 * s); g.lineTo(27 * s, 33 * s); g.stroke()
						g.beginPath(); g.moveTo(47 * s, 28 * s); g.lineTo(47 * s, 33 * s); g.stroke()
						g.beginPath(); g.moveTo(37 * s, 28 * s); g.lineTo(37 * s, 40 * s); g.quadraticCurveTo(37 * s, 42 * s, 34 * s, 42 * s); g.stroke()
						g.beginPath(); g.moveTo(27 * s, 49 * s); g.quadraticCurveTo(37 * s, 56 * s, 47 * s, 49 * s); g.stroke()
						g.globalAlpha = 1
					}
					if (p > 0) {
						// check mark drawing in
						const pts = [[24, 38], [33, 47], [51, 28]]
						const t = Math.min(1, p)
						g.beginPath(); g.moveTo(pts[0][0] * s, pts[0][1] * s)
						const seg1 = Math.min(1, t * 2), seg2 = Math.max(0, t * 2 - 1)
						g.lineTo((pts[0][0] + (pts[1][0] - pts[0][0]) * seg1) * s, (pts[0][1] + (pts[1][1] - pts[0][1]) * seg1) * s)
						if (seg2 > 0) g.lineTo((pts[1][0] + (pts[2][0] - pts[1][0]) * seg2) * s, (pts[1][1] + (pts[2][1] - pts[1][1]) * seg2) * s)
						g.lineWidth = 5 * s; g.stroke()
					}
				}
			}
			// scanning: a ring of dots sweeping around the glyph
			Item {
				anchors.centerIn: parent
				width: 104; height: 104
				visible: fid.state_ === "scanning"
				RotationAnimator on rotation { from: 0; to: 360; duration: 1400; loops: Animation.Infinite; running: fid.state_ === "scanning" }
				Repeater {
					model: 24
					delegate: Rectangle {
						required property int index
						readonly property real a: index / 24 * Math.PI * 2
						width: 3.2; height: 3.2; radius: 1.6
						x: 52 + Math.cos(a) * 48 - 1.6; y: 52 + Math.sin(a) * 48 - 1.6
						color: "white"; opacity: 0.12 + 0.88 * (index / 24)
					}
				}
			}
		}
	}
}
