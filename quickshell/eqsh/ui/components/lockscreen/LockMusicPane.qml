import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.config
import qs.ui.controls.providers
import qs.core.system

// Full-screen music pane on the lock screen (after Sapphire's
// LockScreenFullScreenMusicPane): Overview / Lyrics / Queue / Devices tabs
// over the artwork wallpaper. Opened from the expand button on the media panel.
Item {
	id: pane
	property bool open: false
	property string tab: "overview"
	readonly property var pl: MusicPlayerProvider.activePlayer
	// Sapphire PaneMetrics: k scales with the screen, clamped 0.8 … 1.8
	readonly property real k: Math.min(Math.max(Math.min(width / 1440, height / 900), 0.8), 1.8)
	visible: opacity > 0.01
	opacity: open ? 1 : 0
	scale: open ? 1 : 1.04
	Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
	Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 0.9 } }
	onOpenChanged: if (open) { tab = "overview"; MusicPlayerProvider.lyricsWanted = true }

	function fmt(sec) { const s = Math.max(0, Math.floor(sec)); return Math.floor(s / 60) + ":" + ("0" + (s % 60)).slice(-2) }

	// the pane covers the lock UI (clock, pills, panel) with a live copy of the
	// wallpaper behind it, dimmed — like Sapphire covering its widget windows
	property Item backdrop: null
	ShaderEffectSource {
		anchors.fill: parent
		sourceItem: pane.backdrop
		live: pane.visible
		visible: !!pane.backdrop
	}
	Rectangle { anchors.fill: parent; color: Qt.rgba(0, 0, 0, pane.backdrop ? 0.38 : 0.7) }
	MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onWheel: (w) => w.accepted = true }

	component Ico: Image {
		property string name
		property real size: 18
		width: size; height: size
		source: name ? Qt.resolvedUrl("icons/" + name + ".png") : ""
		sourceSize: Qt.size(64, 64); smooth: true; mipmap: true
	}
	component SvgIco: Image {
		property string file
		property real size: 26
		width: size; height: size
		source: file ? Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/music/" + file) : ""
		sourceSize: Qt.size(64, 64); smooth: true
	}
	component CircleBtn: Item {
		id: cb
		property real size: 44
		property bool on: true
		signal clicked
		default property alias content: holder.data
		width: size; height: size
		opacity: on ? 1 : 0.35
		Rectangle {
			anchors.fill: parent; radius: width / 2
			color: Qt.rgba(1, 1, 1, cma.containsMouse && cb.on ? 0.16 : 0)
			scale: cma.pressed ? 0.88 : 1
			Behavior on scale { NumberAnimation { duration: 120 } }
			Behavior on color { ColorAnimation { duration: 160 } }
		}
		Item { id: holder; anchors.centerIn: parent; width: childrenRect.width; height: childrenRect.height }
		MouseArea { id: cma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (cb.on) cb.clicked() }
	}

	// ----------------------------------------------------------- top bar
	Item {
		id: topBar
		anchors.top: parent.top; anchors.topMargin: 30 * pane.k
		anchors.left: parent.left; anchors.right: parent.right
		anchors.leftMargin: 72 * pane.k; anchors.rightMargin: 72 * pane.k
		height: 44 * pane.k
		Rectangle {
			id: tabs
			anchors.centerIn: parent
			height: parent.height; radius: height / 2
			width: tabRow.width + 8 * pane.k
			color: Qt.rgba(1, 1, 1, 0.12)
			border.width: 1.5; border.color: Qt.rgba(1, 1, 1, 0.18)
			// sliding selection capsule
			Rectangle {
				id: sel
				readonly property Item cur: tabRep.count ? tabRep.itemAt(Math.max(0, ["overview", "lyrics", "queue", "devices"].indexOf(pane.tab))) : null
				x: cur ? tabRow.x + cur.x : 0
				y: 4 * pane.k
				width: cur ? cur.width : 0
				height: parent.height - 8 * pane.k
				radius: height / 2
				color: Qt.rgba(1, 1, 1, 0.9)
				Behavior on x { NumberAnimation { duration: 380; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }
				Behavior on width { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
			}
			Row {
				id: tabRow
				anchors.centerIn: parent
				Repeater {
					id: tabRep
					model: [{ id: "overview", t: "Overview", i: "overview" }, { id: "lyrics", t: "Lyrics", i: "lyrics" },
						{ id: "queue", t: "Queue", i: "queue" }, { id: "devices", t: "Devices", i: "speaker" }]
					delegate: Item {
						required property var modelData
						readonly property bool active: pane.tab === modelData.id
						width: tabLbl.implicitWidth + 50 * pane.k; height: tabs.height
						Row {
							anchors.centerIn: parent; spacing: 7 * pane.k
							Ico {
								name: modelData.i; size: 15 * pane.k; anchors.verticalCenter: parent.verticalCenter
								layer.enabled: parent.parent.active
								layer.effect: MultiEffect { colorization: 1; colorizationColor: "#1c1c1e" }
							}
							Text {
								id: tabLbl
								text: modelData.t
								color: parent.parent.active ? "#1c1c1e" : Qt.rgba(1, 1, 1, 0.85)
								font.family: Fonts.sFProDisplayRegular.family; font.pixelSize: 14 * pane.k; font.weight: Font.DemiBold
								Behavior on color { ColorAnimation { duration: 220 } }
							}
						}
						MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: pane.tab = modelData.id }
					}
				}
			}
		}
		CircleBtn {
			anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
			size: 40 * pane.k
			onClicked: pane.open = false
			Ico { name: "close"; size: 16 * pane.k }
		}
	}

	// shared artwork with a soft shadow
	component Art: Item {
		id: art
		property real size: 300
		property real corner: 0.06
		width: size; height: size
		RectangularShadow {
			anchors.fill: parent; radius: artClip.radius
			blur: 40; offset.y: 16; color: Qt.rgba(0, 0, 0, 0.4)
		}
		ClippingRectangle {
			id: artClip
			anchors.fill: parent
			radius: art.size * art.corner
			color: Qt.rgba(1, 1, 1, 0.08)
			Image {
				anchors.fill: parent
				source: MusicPlayerProvider.thumbnail
				fillMode: Image.PreserveAspectCrop
				asynchronous: true; smooth: true; mipmap: true
			}
		}
		scale: MusicPlayerProvider.isPlaying ? 1 : 0.92
		Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
	}

	Item {
		id: body
		anchors.top: topBar.bottom; anchors.topMargin: 20 * pane.k
		anchors.left: parent.left; anchors.right: parent.right
		anchors.bottom: parent.bottom; anchors.bottomMargin: 32 * pane.k
		anchors.leftMargin: 72 * pane.k; anchors.rightMargin: 72 * pane.k

		// ------------------------------------------------------- overview
		Item {
			anchors.fill: parent
			visible: opacity > 0.01
			opacity: pane.tab === "overview" ? 1 : 0
			Behavior on opacity { NumberAnimation { duration: 300 } }
			Row {
				anchors.centerIn: parent
				spacing: 64 * pane.k
				Art { id: hero; size: Math.min(pane.height * 0.44, pane.width * 0.3); anchors.verticalCenter: parent.verticalCenter }
				Column {
					anchors.verticalCenter: parent.verticalCenter
					width: Math.min(pane.width * 0.34, 560 * pane.k)
					spacing: 10 * pane.k
					Text {
						width: parent.width; elide: Text.ElideRight
						text: MusicPlayerProvider.title
						color: "white"; font.family: Fonts.sFProDisplayRegular.family
						font.pixelSize: 34 * pane.k; font.weight: Font.Bold
					}
					Text {
						width: parent.width; elide: Text.ElideRight
						text: MusicPlayerProvider.artist + (MusicPlayerProvider.album ? " — " + MusicPlayerProvider.album : "")
						color: Qt.rgba(1, 1, 1, 0.65); font.family: Fonts.sFProDisplayRegular.family; font.pixelSize: 19 * pane.k
					}
					Item { width: 1; height: 18 * pane.k }
					// scrubber
					Item {
						id: scrub
						width: parent.width; height: 26 * pane.k
						readonly property real len: MusicPlayerProvider.duration || 0
						property real dragPos: -1
						readonly property real shown: dragPos >= 0 ? dragPos : MusicPlayerProvider.exactPosition
						Rectangle {
							id: bar
							width: parent.width; height: 6 * pane.k; radius: height / 2
							color: Qt.rgba(1, 1, 1, 0.22)
							Rectangle {
								height: parent.height; radius: parent.radius
								width: scrub.len > 0 ? parent.width * Math.max(0, Math.min(1, scrub.shown / scrub.len)) : 0
								color: "white"
							}
							MouseArea {
								anchors.fill: parent; anchors.margins: -10
								cursorShape: Qt.PointingHandCursor
								function at(x) { return Math.max(0, Math.min(1, (x - 10) / bar.width)) * scrub.len }
								onPressed: (m) => { if (scrub.len > 0) scrub.dragPos = at(m.x) }
								onPositionChanged: (m) => { if (pressed && scrub.len > 0) scrub.dragPos = at(m.x) }
								onReleased: { if (scrub.dragPos >= 0 && pane.pl) pane.pl.position = scrub.dragPos; scrub.dragPos = -1 }
							}
						}
						Text {
							anchors.left: parent.left; anchors.bottom: parent.bottom
							text: pane.fmt(scrub.shown); color: Qt.rgba(1, 1, 1, 0.6)
							font.pixelSize: 12 * pane.k; font.family: Fonts.sFProDisplayRegular.family
						}
						Text {
							anchors.right: parent.right; anchors.bottom: parent.bottom
							text: scrub.len > 0 ? "-" + pane.fmt(scrub.len - scrub.shown) : "--:--"; color: Qt.rgba(1, 1, 1, 0.6)
							font.pixelSize: 12 * pane.k; font.family: Fonts.sFProDisplayRegular.family
						}
					}
					// transport
					Row {
						anchors.horizontalCenter: parent.horizontalCenter
						spacing: 22 * pane.k
						CircleBtn {
							size: 44 * pane.k; anchors.verticalCenter: parent.verticalCenter
							on: !!pane.pl && pane.pl.shuffleSupported
							onClicked: pane.pl.shuffle = !pane.pl.shuffle
							Ico { name: "shuffle"; size: 17 * pane.k; opacity: pane.pl && pane.pl.shuffle ? 1 : 0.55 }
						}
						CircleBtn {
							size: 56 * pane.k; anchors.verticalCenter: parent.verticalCenter
							onClicked: MusicPlayerProvider.previous()
							SvgIco { file: "backward.svg"; size: 30 * pane.k }
						}
						CircleBtn {
							size: 72 * pane.k; anchors.verticalCenter: parent.verticalCenter
							onClicked: MusicPlayerProvider.togglePlay()
							SvgIco { file: MusicPlayerProvider.isPlaying ? "pause.svg" : "play.svg"; size: 40 * pane.k }
						}
						CircleBtn {
							size: 56 * pane.k; anchors.verticalCenter: parent.verticalCenter
							onClicked: MusicPlayerProvider.next()
							SvgIco { file: "forward.svg"; size: 30 * pane.k }
						}
						CircleBtn {
							size: 44 * pane.k; anchors.verticalCenter: parent.verticalCenter
							on: !!pane.pl && pane.pl.loopSupported
							onClicked: pane.pl.loopState = pane.pl.loopState === MprisLoopState.None ? MprisLoopState.Playlist
								: pane.pl.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None
							Ico { name: "repeat"; size: 17 * pane.k; opacity: pane.pl && pane.pl.loopState !== MprisLoopState.None ? 1 : 0.55 }
						}
					}
					// the line being sung, when synced lyrics exist
					Text {
						width: parent.width
						visible: MusicPlayerProvider.lyricsCurrent !== ""
						text: MusicPlayerProvider.lyricsCurrent
						horizontalAlignment: Text.AlignHCenter
						wrapMode: Text.WordWrap; maximumLineCount: 2
						color: Qt.rgba(1, 1, 1, 0.8)
						font.family: Fonts.sFProDisplayRegular.family; font.pixelSize: 16 * pane.k; font.weight: Font.DemiBold
					}
				}
			}
		}

		// --------------------------------------------------------- lyrics
		Item {
			anchors.fill: parent
			visible: opacity > 0.01
			opacity: pane.tab === "lyrics" ? 1 : 0
			Behavior on opacity { NumberAnimation { duration: 300 } }
			Art {
				id: lyrArt
				size: Math.min(pane.height * 0.3, pane.width * 0.2)
				anchors.left: parent.left; anchors.leftMargin: 40 * pane.k
				anchors.verticalCenter: parent.verticalCenter
			}
			Column {
				anchors.top: lyrArt.bottom; anchors.topMargin: 20 * pane.k
				anchors.left: lyrArt.left; width: lyrArt.width
				spacing: 2
				Text { width: parent.width; elide: Text.ElideRight; text: MusicPlayerProvider.title; color: "white"; font.pixelSize: 18 * pane.k; font.weight: Font.Bold; font.family: Fonts.sFProDisplayRegular.family }
				Text { width: parent.width; elide: Text.ElideRight; text: MusicPlayerProvider.artist; color: Qt.rgba(1, 1, 1, 0.6); font.pixelSize: 15 * pane.k; font.family: Fonts.sFProDisplayRegular.family }
			}
			Item {
				id: lyrBox
				anchors.left: lyrArt.right; anchors.leftMargin: 80 * pane.k
				anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
				clip: true
				readonly property real target: {
					const c = MusicPlayerProvider.lyricsIndex
					const it = c >= 0 ? lyrList.itemAt(c) : null
					return it ? it.y - height * 0.32 : -height * 0.32
				}
				Text {
					anchors.centerIn: parent
					visible: MusicPlayerProvider.lyricsLines.length === 0
					text: MusicPlayerProvider.lyricsState === "loading" ? "Loading lyrics…"
						: MusicPlayerProvider.lyricsState === "offline" ? "Lyrics are unavailable right now" : "No lyrics for this song"
					color: Qt.rgba(1, 1, 1, 0.55); font.pixelSize: 18 * pane.k; font.family: Fonts.sFProDisplayRegular.family
				}
				Column {
					id: lyrCol
					width: parent.width
					spacing: 18 * pane.k
					transform: Translate {
						y: -lyrBox.target
						Behavior on y { NumberAnimation { duration: 560; easing.type: Easing.OutQuint } }
					}
					Repeater {
						id: lyrList
						model: MusicPlayerProvider.lyricsLines
						delegate: Text {
							required property var modelData
							required property int index
							readonly property int rel: MusicPlayerProvider.lyricsSynced ? index - MusicPlayerProvider.lyricsIndex : 0
							width: lyrCol.width
							text: modelData.text || "•  •  •"
							wrapMode: Text.WordWrap
							color: "white"
							font.family: Fonts.sFProDisplayRegular.family
							font.pixelSize: 34 * pane.k; font.weight: Font.Bold
							transformOrigin: Item.Left
							opacity: !MusicPlayerProvider.lyricsSynced ? 0.9 : rel === 0 ? 1 : Math.abs(rel) === 1 ? 0.4 : 0.22
							scale: rel === 0 || !MusicPlayerProvider.lyricsSynced ? 1 : 0.94
							Behavior on opacity { NumberAnimation { duration: 380 } }
							Behavior on scale { NumberAnimation { duration: 420; easing.type: Easing.OutQuint } }
							layer.enabled: MusicPlayerProvider.lyricsSynced && rel !== 0 && Math.abs(rel) <= 6
							layer.effect: MultiEffect { blurEnabled: true; blurMax: 20; blur: Math.min(0.6, 0.12 * Math.abs(rel)) }
							MouseArea {
								anchors.fill: parent
								enabled: MusicPlayerProvider.lyricsSynced && modelData.t >= 0 && !!pane.pl && pane.pl.canSeek
								cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
								onClicked: pane.pl.position = modelData.t
							}
						}
					}
				}
			}
		}

		// ---------------------------------------------------------- queue
		Item {
			anchors.fill: parent
			visible: opacity > 0.01
			opacity: pane.tab === "queue" ? 1 : 0
			Behavior on opacity { NumberAnimation { duration: 300 } }
			Column {
				anchors.centerIn: parent
				width: Math.min(parent.width, 640 * pane.k)
				spacing: 14 * pane.k
				Text { text: "Now Playing"; color: Qt.rgba(1, 1, 1, 0.55); font.pixelSize: 14 * pane.k; font.weight: Font.DemiBold; font.family: Fonts.sFProDisplayRegular.family }
				Rectangle {
					width: parent.width; height: 84 * pane.k; radius: 18 * pane.k
					color: Qt.rgba(1, 1, 1, 0.12); border.width: 1.5; border.color: Qt.rgba(1, 1, 1, 0.18)
					Row {
						anchors.verticalCenter: parent.verticalCenter; x: 14 * pane.k; spacing: 14 * pane.k
						Art { size: 56 * pane.k; corner: 0.18 }
						Column {
							anchors.verticalCenter: parent.verticalCenter
							Text { text: MusicPlayerProvider.title; color: "white"; font.pixelSize: 17 * pane.k; font.weight: Font.Bold; font.family: Fonts.sFProDisplayRegular.family }
							Text { text: MusicPlayerProvider.artist; color: Qt.rgba(1, 1, 1, 0.6); font.pixelSize: 14 * pane.k; font.family: Fonts.sFProDisplayRegular.family }
						}
					}
				}
				Text { text: "Up Next"; color: Qt.rgba(1, 1, 1, 0.55); font.pixelSize: 14 * pane.k; font.weight: Font.DemiBold; font.family: Fonts.sFProDisplayRegular.family }
				Text {
					width: parent.width; wrapMode: Text.WordWrap
					text: (pane.pl && pane.pl.identity ? pane.pl.identity : "This player") + " doesn't share its queue. Use next / previous to move through it."
					color: Qt.rgba(1, 1, 1, 0.5); font.pixelSize: 15 * pane.k; font.family: Fonts.sFProDisplayRegular.family
				}
				Row {
					spacing: 12 * pane.k
					CircleBtn { size: 48 * pane.k; onClicked: MusicPlayerProvider.previous(); SvgIco { file: "backward.svg"; size: 24 * pane.k } }
					CircleBtn { size: 48 * pane.k; onClicked: MusicPlayerProvider.next(); SvgIco { file: "forward.svg"; size: 24 * pane.k } }
				}
			}
		}

		// -------------------------------------------------------- devices
		Item {
			id: devTab
			anchors.fill: parent
			visible: opacity > 0.01
			opacity: pane.tab === "devices" ? 1 : 0
			Behavior on opacity { NumberAnimation { duration: 300 } }
			property var sinks: []
			property string current: ""
			property real volume: 0
			function refresh() { sinkProc.running = true }
			onVisibleChanged: if (visible) refresh()
			Process {
				id: sinkProc
				command: ["sh", "-c", "pactl -f json list sinks; echo; echo '@@'; pactl get-default-sink; wpctl get-volume @DEFAULT_AUDIO_SINK@"]
				stdout: StdioCollector {
					onStreamFinished: {
						const parts = text.split("@@")
						try {
							devTab.sinks = JSON.parse(parts[0]).map(s => ({ name: s.name, desc: s.description, port: (s.active_port || ""), bus: ((s.properties || {})["device.bus"] || "") }))
						} catch (e) { devTab.sinks = [] }
						const rest = (parts[1] || "").trim().split("\n")
						devTab.current = (rest[0] || "").trim()
						const m = (rest[1] || "").match(/([0-9.]+)/)
						devTab.volume = m ? parseFloat(m[1]) : 0
					}
				}
			}
			Process { id: setProc; onExited: devTab.refresh() }
			function choose(name) {
				setProc.command = ["sh", "-c", "pactl set-default-sink \"$1\" && for i in $(pactl list short sink-inputs | cut -f1); do pactl move-sink-input \"$i\" \"$1\"; done", "sh", name]
				setProc.running = true
			}
			Process { id: volProc }
			function setVolume(v) {
				devTab.volume = v
				volProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", v.toFixed(2)]
				volProc.running = true
			}
			Column {
				anchors.centerIn: parent
				width: Math.min(parent.width, 640 * pane.k)
				spacing: 12 * pane.k
				Text { text: "Output"; color: Qt.rgba(1, 1, 1, 0.55); font.pixelSize: 14 * pane.k; font.weight: Font.DemiBold; font.family: Fonts.sFProDisplayRegular.family }
				Repeater {
					model: devTab.sinks
					delegate: Rectangle {
						required property var modelData
						readonly property bool active: modelData.name === devTab.current
						readonly property string kind: modelData.bus === "bluetooth" || /head/i.test(modelData.desc + modelData.port) ? "headphones" : /hdmi|displayport/i.test(modelData.desc) ? "tv" : "speaker"
						width: parent.width; height: 64 * pane.k; radius: 16 * pane.k
						color: active ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, dma.containsMouse ? 0.14 : 0.08)
						border.width: active ? 1.5 : 0; border.color: Qt.rgba(1, 1, 1, 0.35)
						Behavior on color { ColorAnimation { duration: 180 } }
						Row {
							anchors.verticalCenter: parent.verticalCenter; x: 18 * pane.k; spacing: 14 * pane.k
							Ico { name: parent.parent.kind; size: 22 * pane.k; anchors.verticalCenter: parent.verticalCenter }
							Text {
								anchors.verticalCenter: parent.verticalCenter
								width: devTab.width * 0.5
								elide: Text.ElideRight
								text: modelData.desc.replace(/^.*cAVS /, "")
								color: "white"; font.pixelSize: 16 * pane.k; font.weight: Font.DemiBold; font.family: Fonts.sFProDisplayRegular.family
							}
						}
						Text {
							anchors.right: parent.right; anchors.rightMargin: 20 * pane.k; anchors.verticalCenter: parent.verticalCenter
							visible: parent.active; text: "✓"; color: "white"; font.pixelSize: 20 * pane.k
						}
						MouseArea { id: dma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: devTab.choose(modelData.name) }
					}
				}
				Item { width: 1; height: 8 * pane.k }
				Text { text: "Volume"; color: Qt.rgba(1, 1, 1, 0.55); font.pixelSize: 14 * pane.k; font.weight: Font.DemiBold; font.family: Fonts.sFProDisplayRegular.family }
				Item {
					width: parent.width; height: 28 * pane.k
					Rectangle {
						id: vbar
						anchors.verticalCenter: parent.verticalCenter
						width: parent.width; height: 8 * pane.k; radius: height / 2
						color: Qt.rgba(1, 1, 1, 0.22)
						Rectangle { height: parent.height; radius: parent.radius; width: parent.width * Math.min(1, devTab.volume); color: "white" }
					}
					MouseArea {
						anchors.fill: parent; cursorShape: Qt.PointingHandCursor
						function at(x) { return Math.max(0, Math.min(1, x / vbar.width)) }
						onPressed: (m) => devTab.setVolume(at(m.x))
						onPositionChanged: (m) => { if (pressed) devTab.setVolume(at(m.x)) }
					}
				}
			}
		}
	}
}
