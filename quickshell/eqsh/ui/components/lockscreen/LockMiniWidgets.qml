import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.config
import qs.ui.controls.providers

// Sapphire-style mini widgets under the media panel: headphone battery
// (UPower), Do Not Disturb and the running timer (Atoll). The Mac's own
// battery is already shown at the top right, so it has no tile here.
Row {
	id: mw
	property var atoll: null           // Atoll heartbeat (state.json) when it runs
	spacing: 14
	height: 58

	readonly property var bat: UPower.displayDevice
	readonly property real batPct: bat && bat.isPresent ? Math.round(bat.percentage <= 1 ? bat.percentage * 100 : bat.percentage) : -1
	readonly property bool charging: bat ? (bat.state === UPowerDeviceState.Charging || bat.state === UPowerDeviceState.FullyCharged) : false
	readonly property var phones: {
		const out = []
		const ds = UPower.devices.values
		for (let i = 0; i < ds.length; i++) {
			const d = ds[i]
			if (d.type === UPowerDeviceType.Headphones || d.type === UPowerDeviceType.Headset) {
				const p = d.percentage
				out.push({ name: d.model || "Headphones", pct: Math.round(p <= 1 ? p * 100 : p) })
			}
		}
		return out
	}

	// Do Not Disturb lives in the mac shell's settings (focus.dnd / focus.sleep)
	property bool dnd: false
	FileView {
		path: Quickshell.env("HOME") + "/.config/quickshell/macos/userconfig.json"
		watchChanges: true
		onFileChanged: reload()
		onLoaded: {
			try { const f = (JSON.parse(text()) || {}).focus || {}; mw.dnd = f.dnd === true || f.sleep === true } catch (e) { mw.dnd = false }
		}
	}
	readonly property var timer: atoll && atoll.timer && atoll.timer.active ? atoll.timer : null

	component Tile: Item {
		id: t
		property real value: -1            // 0..100, -1 = no ring
		property color ring: "white"
		property string icon
		property string label
		width: 58; height: 58
		opacity: 0
		Component.onCompleted: opacity = 1
		Behavior on opacity { NumberAnimation { duration: 420 } }
		Rectangle {
			anchors.fill: parent; radius: width / 2
			color: Qt.rgba(1, 1, 1, 0.12)
			border.width: 1.5; border.color: Qt.rgba(1, 1, 1, 0.18)
		}
		Shape {
			anchors.fill: parent
			visible: t.value >= 0
			preferredRendererType: Shape.CurveRenderer
			ShapePath {
				strokeColor: Qt.rgba(1, 1, 1, 0.15); strokeWidth: 4; fillColor: "transparent"
				PathAngleArc { centerX: 29; centerY: 29; radiusX: 23; radiusY: 23; startAngle: 0; sweepAngle: 360 }
			}
			ShapePath {
				strokeColor: t.ring; strokeWidth: 4; fillColor: "transparent"; capStyle: ShapePath.RoundCap
				PathAngleArc {
					centerX: 29; centerY: 29; radiusX: 23; radiusY: 23; startAngle: -90
					sweepAngle: 360 * Math.max(0, Math.min(100, t.value)) / 100
					Behavior on sweepAngle { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
				}
			}
		}
		Column {
			anchors.centerIn: parent
			spacing: 0
			Image {
				anchors.horizontalCenter: parent.horizontalCenter
				visible: t.icon !== ""
				width: t.label ? 15 : 22; height: width
				source: t.icon ? Qt.resolvedUrl("icons/" + t.icon + ".png") : ""
				sourceSize: Qt.size(64, 64); smooth: true; mipmap: true
			}
			Text {
				anchors.horizontalCenter: parent.horizontalCenter
				visible: t.label !== ""
				text: t.label
				color: Qt.rgba(1, 1, 1, 0.92)
				font.family: Fonts.sFProRounded.family; font.pixelSize: 12; font.weight: Font.Bold
			}
		}
	}

	Repeater {
		model: mw.phones
		delegate: Tile {
			required property var modelData
			value: modelData.pct
			ring: modelData.pct <= 20 ? "#FF453A" : "white"
			icon: "headphones"
			label: modelData.pct + "%"
		}
	}
	Tile {
		visible: mw.dnd
		icon: "moon"
		ring: "#5E5CE6"
	}
	Tile {
		visible: !!mw.timer
		value: mw.timer && mw.timer.total > 0 ? 100 * mw.timer.left / mw.timer.total : -1
		ring: "#FF9F0A"
		icon: "timer"
		label: {
			if (!mw.timer) return ""
			const s = Math.max(0, mw.timer.left), m = Math.floor(s / 60)
			return m + ":" + String(s % 60).padStart(2, "0")
		}
	}
}
