import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Material
import QtQuick.Effects
import QtQuick.Controls.Fusion
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell
import qs.ui.controls.auxiliary
import qs.ui.controls.advanced

import qs.ui.advanced.shader
import qs.ui.advanced.shader.glass

import qs.ui.controls.providers
import qs.ui.controls.primitives
import qs.config
import qs.core.system
import qs.services
import qs.ui.components.panel
import qs

Rectangle {
	id: root
	required property LockContext context
	required property var screen
	readonly property ColorGroup colors: Window.active ? palette.active : palette.inactive
	property string wallpaperImage: Config.lockScreen.useCustomWallpaper ? Config.lockScreen.customWallpaperPath : Config.wallpaper.path

	function unlock() {
		if (fadeOutAnim.running)
			return;
		fadeOutAnim.start();
		scaleAnim.start();
		scaleAnim2.start();
		scaleAnim3.start();
	}

	PropertyAnimation {
		id: fadeOutAnim
		target: locksur
		property: "opacity"
		to: 0
		duration: Config.lockScreen.fadeDuration
		onStopped: {
			if (root.context) root.context.unlocked();
		}
	}
	PropertyAnimation {
		id: scaleAnim
		target: contentItem
		property: "scale"
		to: Config.general.reduceMotion ? 1 : Config.lockScreen.zoom
		duration: Config.lockScreen.zoomDuration
		easing.type: Easing.InOutQuad
	}
	PropertyAnimation {
		id: scaleAnim2
		target: contentItem
		property: "opacity"
		to: 0
		duration: Config.lockScreen.zoomDuration
		easing.type: Easing.InOutQuad
	}
	PropertyAnimation {
		id: scaleAnim3
		target: backgroundImageBlur
		property: "scale"
		to: 1
		duration: Config.lockScreen.fadeDuration / 1.5
		easing.type: Easing.InOutQuad
	}

	opacity: 0;
	color: "transparent"

	Behavior on opacity {
		NumberAnimation { duration: Config.lockScreen.fadeDuration; easing.type: Easing.InOutQuad }
	}

	Component.onCompleted: {
		root.opacity = 1;
	}

	BackgroundImage {
		id: backgroundImage
		source: wallpaperImage
		opacity: 1
		visible: true
		anchors.fill: parent
		Rectangle {
			id: backgroundImageDim
			anchors.fill: parent
			color: Config.lockScreen.dimColor
			opacity: Config.lockScreen.dimOpacity
		}
	}

	MultiEffect {
		id: backgroundImageBlur
		anchors.fill: backgroundImage
		source: backgroundImage
		blurEnabled: true
		autoPaddingEnabled: false
		blur: 0
		blurMax: 64 * Config.lockScreen.blurStrength
		blurMultiplier: 1
		scale: 1
		layer.enabled: true
		Component.onCompleted: {
			backgroundImageBlur.scale = Config.general.reduceMotion ? 1 : Config.lockScreen.zoom;
			backgroundImageBlur.blur = Config.lockScreen.blur;
		}
		Behavior on scale {
			NumberAnimation { duration: Config.lockScreen.zoomDuration; easing.type: Easing.InOutQuad }
		}
		Behavior on blur {
			NumberAnimation { duration: Config.lockScreen.zoomDuration; easing.type: Easing.InOutQuad }
		}
	}

	Item {
		id: contentItem
		anchors.fill: parent
		scale: Config.general.reduceMotion ? 1 : Config.lockScreen.zoom
		property alias transformY: trans.y
		transform: Translate {
			id: trans
			y: Config.general.reduceMotion ? 0 : -50
			Behavior on y {
				NumberAnimation { duration: Config.lockScreen.clockZoomDuration*2; easing.type: Easing.InOutQuad }
			}
		}
		opacity: Config.general.reduceMotion ? 1 : 0
		readonly property bool showInteractive: {
			Config.lockScreen.useFocusedScreen ? ((CompositorService.isHyprland ? Hyprland.focusedMonitor.name : NiriService.currentOutput) == screen?.name) :
			Config.lockScreen.mainScreen != "" ? Config.lockScreen.mainScreen == screen.name :
			Config.lockScreen.interactiveScreens.includes(screen.name)
		}
		onShowInteractiveChanged: {
			if (showInteractive) {
				contentItem.scale = 1;
				contentItem.opacity = 1;
			} else {
				contentItem.scale = Config.general.reduceMotion ? 1 : Config.lockScreen.zoom;
				contentItem.opacity = 0;
			}
		}
		Component.onCompleted: {
			contentItem.scale = 1;
			contentItem.opacity = 1;
			trans.y = 0;
		}
		Behavior on scale {
			NumberAnimation { duration: Config.lockScreen.clockZoomDuration; easing.type: Easing.InOutQuad }
		}
		Behavior on opacity {
			NumberAnimation { duration: Config.lockScreen.clockZoomDuration; easing.type: Easing.InOutQuad }
		}

		MultiEffect {
			id: mediaBackgroundBlur
			anchors.fill: contentItem
			source: backgroundImageBlur
			blurEnabled: true
			autoPaddingEnabled: false
			blur: 0.1
			blurMax: 64 * Config.lockScreen.blurStrength
			blurMultiplier: 1
		}
		PropertyAnimation {
			target: mediaBackgroundBlur
			property: "blur"
			from: 0
			to: 0.5
			duration: 2000
			id: mediaGlassShow1Animation
		}
		ShaderEffectSource {
			id: mediaBlurSource
			sourceItem: mediaBackgroundBlur
			sourceRect: Qt.rect(
				mediaGlass.x,
				mediaGlass.y,
				mediaGlass.width,
				mediaGlass.height
			)
			hideSource: true
			live: true
			visible: false
		}

		ShaderEffectSource {
			id: clockBlurSource
			anchors {
				left: clock.left
				top: clock.top
				right: clock.right
				bottom: clock.bottom
			}
			sourceItem: backgroundImage
			sourceRect: Qt.rect(clock.x, clock.y, clock.width, clock.height)
			hideSource: false
			live: true
			samples: 128
		}

		MultiEffect {
			id: clockBlur
			anchors.centerIn: clock
			width: clock.width
			height: clock.height
			source: clockBlurSource
			blurEnabled: true
			blur: 1
			blurMax: 64
			blurMultiplier: 1.2
			brightness: 0.4
			autoPaddingEnabled: false
			maskEnabled: true
			maskSource: clock
			maskSpreadAtMin: 0.1
			maskThresholdMin: 0.1
			antialiasing: true
		}

		Label {
			id: clock

			anchors {
				horizontalCenter: parent.horizontalCenter
				top: parent.top
				topMargin: 100
			}

			renderType: Text.NativeRendering
			color: "#33ffffff"
			font.family: Fonts.sFProRoundedRegular.family
			font.pointSize: 80
			font.weight: 900
			layer.enabled: true
			layer.smooth: true

			//text: root.context.currentText == "" ? Time.getTime(Config.lockScreen.timeFormat) : root.context.currentText
			text: Time.getTime(Config.lockScreen.timeFormat)
		}

		CFClippingRect {
			id: mediaGlass
			anchors.bottom: inputArea.top
			anchors.horizontalCenter: inputArea.horizontalCenter
			anchors.bottomMargin: 80
			width: 460
			height: 250
			radius: 34
			GlassMaterial {
				id: mediaGlassInternal
				anchors.fill: parent
				visible: MusicPlayerProvider.isAvailable
				opacity: contentItem.opacity == 1 ? 1 : 0
				Behavior on opacity {
					NumberAnimation { duration: 400 }
				}
				Behavior on width {
					NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 3 }
				}
				pos: Qt.point(1, 1)
				size: Qt.point(458, 248)
				source: mediaBlurSource
				blurSource: mediaBlurSource
				bloomSource: mediaBlurSource
				glassRefractionDim: 30
				glassRefractionMag: 0
				property real rimLightOpacity: 0.0
				rimLightColor: Qt.vector4d(1, 1, 1, rimLightOpacity)
				ParallelAnimation {
					id: mediaGlassShow2Animation
					PropertyAnimation {
						target: mediaGlassInternal
						property: "glassRefractionMag"
						from: 0
						to: 100
						duration: 1000
					}
					PropertyAnimation {
						target: mediaGlassInternal
						property: "rimLightOpacity"
						from: 0
						to: 0.15
						duration: 1000
					}
				}
				Component.onCompleted: {
					mediaGlassShow1Animation.restart()
					mediaGlassShow2Animation.restart()
				}
				glassRefractionAberration: 10
				radius: 30
				//glassTintColor: Qt.alpha(AccentColor.preferredAccentTextColor == "white" ? "#1e1e1e" : "#ffffff", 0.5)
			}	
		}

		Loader {
			active: MusicPlayerProvider.isAvailable
			enabled: MusicPlayerProvider.isAvailable
			visible: MusicPlayerProvider.isAvailable
			anchors.fill: mediaGlass
			anchors.margins: 22
			Component.onDestruction: MusicPlayerProvider.lyricsWanted = false
			Item {
				id: mediaRoot
				anchors.fill: parent
				// layout unit: 1.0 at a 150 px tall bubble (MacLock uses height/1200)
				readonly property real u: Math.max(0.6, height / 150)
				readonly property var pl: MusicPlayerProvider.activePlayer

				// cover art (MacLock style: rounded square, note while loading, tap to expand)
				ClippingRectangle {
					id: art
					anchors.left: parent.left
					anchors.leftMargin: 16 * u
					anchors.top: parent.top
					anchors.topMargin: 14 * u
					width: 58 * u
					height: width
					radius: 11 * u
					color: Qt.rgba(1, 1, 1, 0.12)
					Image {
						id: coverImg
						anchors.fill: parent
						fillMode: Image.PreserveAspectCrop
						source: MusicPlayerProvider.thumbnail
						smooth: true
						mipmap: true
						asynchronous: true
					}
					Rectangle {
						anchors.fill: parent
						radius: parent.radius
						color: "transparent"
						border.width: 1
						border.color: Qt.rgba(1, 1, 1, 0.14)
					}
					TapHandler { onTapped: parent.artMode = !parent.artMode }
					HoverHandler { cursorShape: Qt.PointingHandCursor }
					Text {
						anchors.centerIn: parent
						text: "\u266A"
						font.pixelSize: 24 * u
						color: Qt.rgba(1, 1, 1, 0.6)
						visible: coverImg.status !== Image.Ready
					}
				}

				// title + artist
				Column {
					id: txtCol
					anchors.left: art.right
					anchors.leftMargin: 14 * u
					anchors.right: parent.right
					anchors.rightMargin: 14 * u
					anchors.verticalCenter: art.verticalCenter
					spacing: 2 * u
					CFText {
						width: parent.width
						text: MusicPlayerProvider.title
						elide: Text.ElideRight
						font.weight: 600
						font.pixelSize: 15 * u
					}
					Text {
						width: parent.width
						text: MusicPlayerProvider.artist
						color: Qt.rgba(1, 1, 1, 0.66)
						elide: Text.ElideRight
						font.weight: 400
						font.pixelSize: 13 * u
					}
				}

				// scrubber (time / bar / remaining)
				Item {
					id: scrub
					anchors.left: parent.left
					anchors.leftMargin: 16 * u
					anchors.right: parent.right
					anchors.rightMargin: 16 * u
					anchors.top: txtCol.bottom
					anchors.topMargin: 12 * u
					height: 16 * u
					readonly property real len: MusicPlayerProvider.duration || 0
					readonly property real frac: len > 0 ? Math.max(0, Math.min(1, MusicPlayerProvider.position / len)) : 0
					function fmt(sec) { var s = Math.max(0, Math.floor(sec)); return Math.floor(s / 60) + ":" + ("0" + (s % 60)).slice(-2); }
					CFText {
						id: tL
						anchors.left: parent.left
						anchors.verticalCenter: parent.verticalCenter
						text: scrub.fmt(MusicPlayerProvider.position)
						color: Qt.rgba(1, 1, 1, 0.6)
						font.pixelSize: 11 * u
					}
					CFText {
						id: tR
						anchors.right: parent.right
						anchors.verticalCenter: parent.verticalCenter
						text: scrub.len > 0 ? "-" + scrub.fmt(scrub.len - MusicPlayerProvider.position) : "--:--"
						color: Qt.rgba(1, 1, 1, 0.6)
						font.pixelSize: 11 * u
					}
					Item {
						id: bar
						anchors.left: tL.right
						anchors.leftMargin: 10 * u
						anchors.right: tR.left
						anchors.rightMargin: 10 * u
						anchors.verticalCenter: parent.verticalCenter
						height: 5 * u
						Rectangle { anchors.fill: parent; radius: height / 2; color: Qt.rgba(1, 1, 1, 0.22) }
						Rectangle {
							height: parent.height; radius: height / 2
							width: Math.max(height, parent.width * scrub.frac)
							color: Qt.rgba(1, 1, 1, 0.88)
							Behavior on width { NumberAnimation { duration: 480; easing.type: Easing.Linear } }
						}
						MouseArea {
							anchors.fill: parent; anchors.margins: -8
							hoverEnabled: true
							cursorShape: Qt.PointingHandCursor
							onClicked: mouse => {
								if (scrub.len > 0 && parent.pl) {
									parent.pl.position = Math.max(0, Math.min(1, mouse.x / bar.width)) * scrub.len;
								}
							}
						}
					}
				}

				// transport controls + lyrics button (MacLock layout)
				Row {
					anchors.horizontalCenter: parent.horizontalCenter
					anchors.top: scrub.bottom
					anchors.topMargin: 10 * u
					spacing: 26 * u
					Repeater {
						model: ["prev", "play", "next"]
						delegate: Item {
							required property string modelData
							readonly property bool big: modelData === "play"
							width: (big ? 38 : 32) * mediaRoot.u
							height: 34 * mediaRoot.u
							Rectangle {
								anchors.centerIn: parent
								width: 40 * mediaRoot.u; height: width; radius: width / 2
								color: Qt.rgba(1, 1, 1, tma.containsMouse ? 0.12 : 0)
								scale: tma.containsMouse ? 1 : 0.6
								Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutQuint } }
							}
							Button {
								anchors.centerIn: parent
								width: (big ? 38 : 32) * mediaRoot.u
								height: 34 * mediaRoot.u
								background: Item {}
								icon {
									width: (big ? 26 : 22) * mediaRoot.u
									height: width
									color: "#ffffff"
									source: parent.modelData === "prev" ? Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/music/backward.svg")
										: parent.modelData === "next" ? Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/music/forward.svg")
										: (MusicPlayerProvider.isPlaying ? Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/music/pause.svg") : Qt.resolvedUrl(Quickshell.shellDir + "/media/icons/music/play.svg"))
								}
							}
							MouseArea {
								id: tma
								anchors.fill: parent; anchors.margins: -4
								hoverEnabled: true
								cursorShape: Qt.PointingHandCursor
								onClicked: {
									if (parent.modelData === "prev") MusicPlayerProvider.previous();
									else if (parent.modelData === "next") MusicPlayerProvider.next();
									else MusicPlayerProvider.togglePlay();
								}
							}
						}
					}
				}

				// lyrics button (Apple's quote bubble) — right of the controls
				Item {
					id: lyrBtn
					anchors.right: parent.right
					anchors.rightMargin: 14 * u
					anchors.top: scrub.bottom
					anchors.topMargin: 12 * u
					width: 32 * u; height: 34 * u
					property bool active: parent.lyricsOn
					Rectangle {
						anchors.centerIn: parent
						width: 30 * u; height: width; radius: 9 * u
						color: lyrBtn.active ? Qt.rgba(1, 1, 1, 0.92) : Qt.rgba(1, 1, 1, lyrMa.containsMouse ? 0.14 : 0)
						scale: lyrMa.pressed ? 0.88 : 1
						Behavior on color { ColorAnimation { duration: 220 } }
						Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutQuint } }
						Canvas {
							id: quoteIcon
							anchors.centerIn: parent
							width: 18 * u; height: width
							property color ink: lyrBtn.active ? "#1c1c1e" : "white"
							onInkChanged: requestPaint()
							onWidthChanged: requestPaint()
							onPaint: {
								var c = getContext("2d"); c.reset();
								var s = width / 18; c.scale(s, s);
								c.fillStyle = ink; c.strokeStyle = ink; c.lineWidth = 1.5; c.lineJoin = "round";
								c.beginPath();
								c.moveTo(4.5, 2.5); c.lineTo(13.5, 2.5); c.arcTo(16, 2.5, 16, 5, 2.5); c.lineTo(16, 10.5); c.arcTo(16, 13, 13.5, 13, 2.5);
								c.lineTo(8, 13); c.lineTo(4.6, 15.8); c.lineTo(4.6, 13); c.arcTo(2, 13, 2, 10.5, 2.5); c.lineTo(2, 5); c.arcTo(2, 2.5, 4.5, 2.5, 2.5);
								c.closePath(); c.stroke();
								function q(x) { c.beginPath(); c.arc(x, 7, 1.35, 0, Math.PI * 2); c.fill(); c.beginPath(); c.moveTo(x + 1.2, 7); c.quadraticCurveTo(x + 1.3, 9.6, x - 0.6, 10.4); c.stroke(); }
								q(6.6); q(10.8);
							}
						}
					}
					MouseArea {
						id: lyrMa
						anchors.fill: parent; anchors.margins: -4
						hoverEnabled: true
						cursorShape: Qt.PointingHandCursor
						onClicked: {
							parent.lyricsOn = !parent.lyricsOn;
							MusicPlayerProvider.lyricsWanted = parent.lyricsOn;
						}
					}
				}

				// ── lyrics overlay (MacLock Apple-Music style) ──
				property bool lyricsOn: false
				property bool artMode: false
				Connections {
					target: MusicPlayerProvider
					function onLyricsWantedChanged() {
						if (!MusicPlayerProvider.lyricsWanted && parent.lyricsOn) parent.lyricsOn = false;
					}
				}
				Rectangle {
					id: lyricsOverlay
					anchors.fill: parent
					radius: 15
					color: Qt.rgba(0, 0, 0, 0.45)
					visible: parent.lyricsOn
					clip: true
					readonly property real lyrTarget: {
						var L = MusicPlayerProvider.lyricsLines;
						if (!MusicPlayerProvider.lyricsSynced || L.length === 0) return -height * 0.30;
						var p = MusicPlayerProvider.position + 0.25, c = -1;
						for (var i = 0; i < L.length; i++) { if (L[i].t <= p) c = i; else break; }
						var it = c >= 0 ? lyrRep.itemAt(c) : null;
						return it ? it.y - height * 0.30 : -height * 0.30;
					}
					Column {
						id: lyrCol
						width: parent.width
						spacing: 8 * u
						Repeater {
							id: lyrRep
							model: MusicPlayerProvider.lyricsLines
							delegate: Item {
								id: ln
								required property var modelData
								required property int index
								readonly property int rel: {
									var L = MusicPlayerProvider.lyricsLines;
									if (!MusicPlayerProvider.lyricsSynced || L.length === 0) return 0;
									var p = MusicPlayerProvider.position + 0.25, c = -1;
									for (var i = 0; i < L.length; i++) { if (L[i].t <= p) c = i; else break; }
									return index - c;
								}
								readonly property bool cur: MusicPlayerProvider.lyricsSynced && index === lyrRep.currentIndex
								readonly property bool gap: (modelData.text || "") === ""
								width: lyrCol.width
								height: gap ? 14 * u : lt.implicitHeight
								transform: Translate {
									id: lnTr
									y: -lyricsOverlay.lyrTarget
									Behavior on y { NumberAnimation { duration: 500 + Math.max(0, Math.min(8, ln.rel)) * 20; easing.type: Easing.OutQuint } }
								}
								opacity: !MusicPlayerProvider.lyricsSynced ? 0.9 : (cur ? 1 : (Math.abs(rel) === 1 ? 0.42 : 0.26))
								Behavior on opacity { NumberAnimation { duration: 380 } }
								Text {
									id: lt
									visible: !ln.gap
									width: parent.width
									text: ln.modelData.text
									wrapMode: Text.WordWrap
									color: "white"
									font.family: Fonts.sFProDisplayRegular.family
									font.pixelSize: 15 * u
									font.weight: Font.Bold
									lineHeight: 1.08
									transformOrigin: Item.Left
									scale: ln.cur || !MusicPlayerProvider.lyricsSynced ? 1 : 0.965
									Behavior on scale { NumberAnimation { duration: 420; easing.type: Easing.OutQuint } }
									layer.enabled: MusicPlayerProvider.lyricsSynced && !ln.cur && Math.abs(ln.rel) <= 6
									layer.sourceRect: Qt.rect(-12, -8, width + 24, height + 16)
									layer.effect: MultiEffect { blurEnabled: true; blurMax: 16; blur: Math.min(0.55, 0.14 * Math.abs(ln.rel)) }
								}
								Row {
									visible: ln.gap
									anchors.verticalCenter: parent.verticalCenter
									spacing: 4 * u
									Repeater {
										model: 3
										delegate: Rectangle {
											required property int index
											width: 5 * u; height: width; radius: width / 2
											color: "white"
											opacity: ln.cur ? 0.95 : 0.35
											SequentialAnimation on scale {
												running: ln.cur; loops: Animation.Infinite
												PauseAnimation { duration: index * 160 }
												NumberAnimation { from: 0.7; to: 1.15; duration: 520; easing.type: Easing.InOutSine }
												NumberAnimation { from: 1.15; to: 0.7; duration: 520; easing.type: Easing.InOutSine }
											}
										}
									}
								}
								readonly property real shownY: y + lnTr.y
								readonly property bool inBand: shownY + height > lyricsOverlay.height * 0.20 && shownY < lyricsOverlay.height * 0.74
								MouseArea {
									anchors.fill: parent
									enabled: ln.inBand && MusicPlayerProvider.lyricsSynced && MusicPlayerProvider.activePlayer.canSeek
									cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
									onClicked: { MusicPlayerProvider.activePlayer.seek(ln.modelData.t); }
								}
								HoverHandler { enabled: ln.inBand && MusicPlayerProvider.lyricsSynced; cursorShape: Qt.PointingHandCursor }
							}
						}
					}
					layer.enabled: true
					layer.effect: ShaderEffect {
						fragmentShader: Qt.resolvedUrl("fade.frag.qsb")
						property real fadeTop: 0.24
						property real fadeBottom: 0.30
					}
					Text {
						anchors.centerIn: parent
						horizontalAlignment: Text.AlignHCenter
						visible: MusicPlayerProvider.lyricsLines.length === 0
						text: {
							if (MusicPlayerProvider.lyricsState === "loading") return "Loading lyrics\u2026";
							if (MusicPlayerProvider.lyricsState === "offline") return "Lyrics are unavailable right now";
							if (MusicPlayerProvider.lyricsState === "none") return "No lyrics for this song";
							return "No lyrics";
						}
						color: Qt.rgba(1, 1, 1, 0.55)
						font.family: Fonts.sFProDisplayRegular.family
						font.pixelSize: 10 * u
						font.weight: Font.DemiBold
					}
				}
			}
		}


		ShaderEffectSource {
			id: dateClockBlurSource
			sourceItem: backgroundImage
			sourceRect: Qt.rect(dateClock.x, dateClock.y, dateClock.width, dateClock.height)
			hideSource: false
			live: true
		}

		MultiEffect {
			id: dateClockBlur
			anchors.centerIn: dateClock
			width: dateClock.width
			height: dateClock.height
			source: dateClockBlurSource
			blurEnabled: true
			blur: 1
			blurMax: 64
			blurMultiplier: 1.2
			autoPaddingEnabled: false
			maskEnabled: true
			maskSource: dateClock
		}

		Label {
			id: dateClock

			anchors {
				horizontalCenter: parent.horizontalCenter
				top: parent.top
				topMargin: 75
			}

			renderType: Text.NativeRendering
			color: "#aaffffff"
			font.family: Fonts.sFProRounded.family
			font.pointSize: 18
			font.weight: Font.Bold

			text: {Time.getTime(Config.lockScreen.dateFormat)}
		}

		Rectangle {
			id: batteryIndicator
			anchors {
				top: parent.top
				right: parent.right
				topMargin: 20
				rightMargin: 60
			}
			Battery {}
		}

		Rectangle {
			id: wifiIndicator
			anchors {
				top: parent.top
				right: parent.right
				topMargin: 20
				rightMargin: 30
			}
			Wifi {}
		}

		ColumnLayout {
			id: inputArea
			anchors {
				horizontalCenter: parent.horizontalCenter
				bottom: parent.bottom
				bottomMargin: 20
			}

			width: parent.width

			Text {
				Layout.alignment: Qt.AlignHCenter
				text: Config.lockScreen.userNote
				color: "#fff"
				font.pointSize: 12
				font.weight: Font.Normal
				Layout.bottomMargin: 10
				layer.enabled: true
				layer.effect: MultiEffect {
					shadowEnabled: true
					shadowColor: "#000000"
				}
			}

			ClippingRectangle {
				id: avatarContainer
				width: Config.lockScreen.avatarSize
				height: Config.lockScreen.avatarSize
				radius: 50
				clip: true
				visible: Config.lockScreen.showAvatar

				Layout.alignment: Qt.AlignHCenter

				Image {
					anchors.fill: parent
					source: Config.account.avatarPath
					fillMode: Image.PreserveAspectCrop
					opacity: 0.95
				}
			}

			RowLayout {
				id: passwordBoxLayout
				Layout.alignment: Qt.AlignHCenter
				Item {
					Layout.alignment: Qt.AlignHCenter
					width: 200
					height: 35
					Text {
						text: Config.account.name
						width: 200
						height: 35
						visible: Config.lockScreen.showName
						font.pointSize: 12
						verticalAlignment: Text.AlignVCenter
						horizontalAlignment: Text.AlignHCenter
						color: "#fff"
						opacity: passwordBoxContainer.opacity == 0 ? 1 : 0
						Behavior on opacity {
							NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
						}
					}
					Backdrop {
						id: sourceBackdrop
						sourceItem: backgroundImageBlur
						sourceX: inputArea.x+passwordBoxLayout.x+passwordBoxContainer.x
						sourceY: inputArea.y+passwordBoxLayout.y+passwordBoxContainer.y+contentItem.transformY
						sourceW: passwordBoxContainer.width
						sourceH: passwordBoxContainer.height
						hideSource: true
						visible: false
					}
					//BackdropBlur {
					//	id: passwordBoxBlur
					//	anchors.centerIn: passwordBoxContainer
					//	width: passwordBoxContainer.width
					//	height: passwordBoxContainer.height
					//	clipRadius: 100
					//	opacity: 1
					//	blur: 0.2
					//	contrast: 0.1
					//	brightness: 0.14
					//	source: sourceBackdrop
					//	anchors.fill: parent
					//}
					Backdrop {
						id: blurSourceBackdrop
						sourceItem: sourceBackdrop
						hideSource: true
						visible: false
					}
					Item {
						id: passwordBoxContainer
						width: 200
						height: 35
						opacity: 0
						Behavior on opacity {
							NumberAnimation { duration: 100; easing.type: Easing.InOutQuad }
						}
						GlassMaterial {
							anchors.fill: parent
							pos: Qt.point(1, 1)
							size: Qt.point(198, 33)
							radius: 16.5
							glassRefractionDim: 20
							glassRefractionMag: 20
							glassRefractionAberration: 10
							opacity: parent.opacity
							source: sourceBackdrop
							blurSource: sourceBackdrop
							bloomSource: sourceBackdrop
						}
						SequentialAnimation {
							id: wiggleAnim
							running: false
							loops: 1
							PropertyAnimation { target: passwordBoxContainer; property: "x"; to: passwordBoxContainer.x - 10; duration: 100; easing.type: Easing.InOutQuad }
							PropertyAnimation { target: passwordBoxContainer; property: "x"; to: passwordBoxContainer.x + 10; duration: 100; easing.type: Easing.InOutQuad }
							PropertyAnimation { target: passwordBoxContainer; property: "x"; to: passwordBoxContainer.x - 7; duration: 100; easing.type: Easing.InOutQuad }
							PropertyAnimation { target: passwordBoxContainer; property: "x"; to: passwordBoxContainer.x + 7; duration: 100; easing.type: Easing.InOutQuad }
							PropertyAnimation { target: passwordBoxContainer; property: "x"; to: passwordBoxContainer.x; duration: 100; easing.type: Easing.InOutQuad }
						}
						TextField {
							id: passwordBox
							anchors.left: parent.left
							anchors.verticalCenter: parent.verticalCenter

							background: Rectangle {
								color: "transparent"
								anchors.fill: parent
								CFText {
									anchors.fill: parent
									verticalAlignment: Text.AlignVCenter
									text: passwordBox.text == "" ? root.context.showFailure ? Translation.tr("Incorrect Password") : Translation.tr("Enter Password") : ""
									color: root.context.showFailure ? '#aaaaaa' : '#bbdedede'
									anchors.leftMargin: 10
									font.weight: 600
								}
							}
							color: "#a0ffffff";

							implicitWidth: 170
							implicitHeight: 35
							padding: 10
							font.pixelSize: 12
							font.family: Fonts.sFProDisplayRegular.family
							renderType: Text.NativeRendering

							selectionColor: '#50ffffff'
							selectedTextColor: '#a0ffffff'

							focus: true
							enabled: !root.context.unlockInProgress
							echoMode: TextInput.Password
							inputMethodHints: Qt.ImhSensitiveData

							onTextChanged: {
								root.context.currentText = this.text;
								passwordBoxContainer.opacity = 1;
							}

							onAccepted: root.context.tryUnlock();

							Connections {
								target: root.context

								function onCurrentTextChanged() {
									passwordBox.text = root.context.currentText;
								}

								function onShowFailureChanged() {
									if (root.context.showFailure) {
										wiggleAnim.start();
									}
								}
							}
						}
						CFRing {
							id: ring
							anchors {
								right: parent.right
								rightMargin: 4
								verticalCenter: parent.verticalCenter
							}
							size: 27
							lineWidth: 2
							opacity: passwordBox.text == "" ? 0 : 1
							color: "#a0ffffff"
							CFVI {
								anchors.centerIn: parent
								size: 15
								color: "#a0ffffff"
								icon: "arrow-right.svg"
							}
						}
					}
				}
			}

			CFText {
				Layout.alignment: Qt.AlignHCenter
				horizontalAlignment: Text.AlignHCenter
				text: Config.lockScreen.usageInfo
				color: "#88ffffff"
				width: 180
				Layout.preferredWidth: 180
				wrapMode: Text.WordWrap
				font.pointSize: 9
				font.weight: 600
				Layout.topMargin: 0
			}
		}
	}
}
