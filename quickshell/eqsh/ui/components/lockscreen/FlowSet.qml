import QtQuick

// Animated artwork layer for the lock-screen artwork wallpaper (LockSurface):
// blurred copies of the cover turn and breathe slowly while `playing`.
Item {
	id: fs
	property url src
	property bool playing: false
	readonly property bool ready: base.status === Image.Ready
	anchors.fill: parent
	Image {
		id: base
		anchors.centerIn: parent
		width: parent.width * 1.25; height: width
		source: fs.src; sourceSize.width: 256
		fillMode: Image.PreserveAspectCrop; asynchronous: true; smooth: true
		SequentialAnimation on scale {
			loops: Animation.Infinite; paused: !fs.playing
			NumberAnimation { from: 1.0; to: 1.12; duration: 9000; easing.type: Easing.InOutSine }
			NumberAnimation { from: 1.12; to: 1.0; duration: 9000; easing.type: Easing.InOutSine }
		}
	}
	Repeater {
		model: [
			{ x: 0.18, y: 0.20, s: 0.95, d: 38000, dir: 1,  o: 0.85 },
			{ x: 0.82, y: 0.30, s: 0.85, d: 47000, dir: -1, o: 0.80 },
			{ x: 0.30, y: 0.85, s: 1.05, d: 56000, dir: 1,  o: 0.75 },
			{ x: 0.78, y: 0.88, s: 0.75, d: 33000, dir: -1, o: 0.70 }
		]
		delegate: Image {
			required property var modelData
			required property int index
			width: fs.width * modelData.s; height: width
			x: fs.width * modelData.x - width / 2
			y: fs.height * modelData.y - height / 2
			source: fs.src; sourceSize.width: 256
			fillMode: Image.PreserveAspectCrop; asynchronous: true; smooth: true
			opacity: modelData.o
			rotation: index * 90
			RotationAnimator on rotation {
				from: index * 90; to: index * 90 + 360 * modelData.dir
				duration: modelData.d; loops: Animation.Infinite
				paused: !fs.playing
			}
		}
	}
}
