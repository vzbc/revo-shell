import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.ui.controls.providers

// Sapphire-style info pills under the lock-screen clock: weather (temp, sky,
// high/low), the next calendar event, air quality and "keeping awake".
// Data comes from lockinfo.py (Open-Meteo, Evolution calendar, idle inhibitors).
Row {
	id: pills
	property var info: null
	readonly property var w: info ? info.weather : null
	readonly property var ev: info ? info.event : null
	spacing: 12
	height: 40

	Process {
		id: proc
		command: ["python3", "-I", Qt.resolvedUrl("lockinfo.py").toString().replace("file://", "")]
		stdout: StdioCollector {
			onStreamFinished: { try { pills.info = JSON.parse(text) } catch (e) {} }
		}
	}
	Timer { interval: 60000; running: true; repeat: true; triggeredOnStart: true; onTriggered: proc.running = true }

	function sky(wx) {
		if (!wx) return "cloud"
		const c = wx.code
		if (c === 0 || c === 1) return wx.isDay ? "sun" : "nightm"
		if (c === 2) return "cloudsun"
		if (c === 3) return "cloud"
		if (c === 45 || c === 48) return "fog"
		if (c >= 95) return "storm"
		if ((c >= 71 && c <= 77) || c === 85 || c === 86) return "snow"
		return "rain"
	}
	function aqiColor(a) {
		return a <= 50 ? "#30D158" : a <= 100 ? "#FFD60A" : a <= 150 ? "#FF9F0A" : a <= 200 ? "#FF453A" : "#BF5AF2"
	}

	component Pill: Rectangle {
		id: pl
		default property alias content: inner.data
		height: 40
		width: inner.implicitWidth + 36
		radius: 20
		color: Qt.rgba(1, 1, 1, 0.12)
		border.width: 1.5
		border.color: Qt.rgba(1, 1, 1, 0.18)
		opacity: 0
		Component.onCompleted: opacity = 1
		Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
		Row {
			id: inner
			anchors.centerIn: parent
			spacing: 10
		}
	}
	component Ico: Image {
		property string name
		width: 20; height: 20
		anchors.verticalCenter: parent ? parent.verticalCenter : undefined
		source: name ? Qt.resolvedUrl("icons/" + name + ".png") : ""
		sourceSize: Qt.size(64, 64)
		smooth: true; mipmap: true
	}
	component Lbl: Text {
		anchors.verticalCenter: parent ? parent.verticalCenter : undefined
		color: Qt.rgba(1, 1, 1, 0.92)
		font.family: Fonts.sFProRounded.family
		font.pixelSize: 16
		font.weight: Font.DemiBold
	}

	// weather
	Pill {
		visible: !!pills.w
		Ico { name: pills.sky(pills.w) }
		Lbl { text: pills.w ? Math.round(pills.w.temp) + "°" : ""; font.pixelSize: 19; font.weight: Font.Bold }
		Lbl { text: pills.w ? "H:" + Math.round(pills.w.hi) + "°  L:" + Math.round(pills.w.lo) + "°" : ""; opacity: 0.7; font.pixelSize: 14 }
	}
	// next event
	Pill {
		visible: !!pills.ev
		Ico { name: "calendar" }
		Lbl {
			text: pills.ev ? pills.ev.title : ""
			width: Math.min(implicitWidth, 260); elide: Text.ElideRight
		}
		Lbl {
			text: !pills.ev ? "" : pills.ev.ongoing ? "Now" : pills.ev.minutes < 60 ? "in " + pills.ev.minutes + " min" : pills.ev.start
			opacity: 0.7; font.pixelSize: 14
		}
	}
	// air quality
	Pill {
		visible: !!pills.w && pills.w.aqi !== null && pills.w.aqi !== undefined
		Rectangle { width: 10; height: 10; radius: 5; anchors.verticalCenter: parent.verticalCenter; color: pills.w ? pills.aqiColor(pills.w.aqi || 0) : "white" }
		Lbl { text: pills.w ? "AQI " + Math.round(pills.w.aqi || 0) : "" }
	}
	// sunrise / sunset (whichever comes next)
	Pill {
		visible: !!pills.w && !!pills.w.sunrise
		readonly property string hm: Qt.formatTime(new Date(), "HH:mm")
		readonly property bool rise: !!pills.w && (hm < pills.w.sunrise || hm > pills.w.sunset)
		Ico { name: parent && parent.parent && parent.parent.rise ? "sunrise" : "sunset" }
		Lbl { text: !pills.w ? "" : (hm < pills.w.sunrise || hm > pills.w.sunset) ? pills.w.sunrise : pills.w.sunset
			readonly property string hm: Qt.formatTime(new Date(), "HH:mm") }
	}
	// keeping awake (an idle inhibitor is held)
	Pill {
		visible: !!pills.info && pills.info.awake === true
		Ico { name: "awake" }
		Lbl { text: "Awake" }
	}
}
