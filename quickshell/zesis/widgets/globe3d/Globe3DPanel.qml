pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../"
import "../shared"

// User-facing pane for the instanced-rod 3D globe
Item {
    id: root

    // Location dots ([{lat, lon, ...}]), fed by the embedding panel
    // (CommunityPanel via Globe3DGate.panelPoints)
    property var points: []

    property int _pendingFrequency: Globe3DService.rodFrequency

    function _formatCount(n) {
        var s = Math.round(n).toString();
        var out = "";
        for (var i = 0; i < s.length; i++) {
            if (i > 0 && (s.length - i) % 3 === 0)
                out += ",";
            out += s[i];
        }
        return out;
    }

    function _commitRodFrequency() {
        engine.frequency = root._pendingFrequency;
        Globe3DService.writeRodFrequency(root._pendingFrequency);
        engine.triggerReScatter();
    }

    AssemblyGlobeView {
        id: engine
        anchors.fill: parent
        frequency: Globe3DService.rodFrequency
        points: root.points
        glowEnabled: Globe3DService.glowEnabled
        dotsFollowRodHeight: Globe3DService.dotsFollowRodHeight
        closeHeightGaps: Globe3DService.closeHeightGaps

        // The shatter->assemble intro plays once per quickshell process,
        // then every later open this session starts already "loaded".
        // Hooked on `ready`, it must run strictly after engine's own
        // buildTargets() has reset assembleT to 0.0, and onCompleted
        // ordering between siblings isn't guaranteed to give us that.
        onReady: {
            if (Globe3DService.hasAssembledThisSession) {
                engine.assembleT = 1.0;
            } else {
                engine.triggerAssemble();
                Globe3DService.hasAssembledThisSession = true;
            }
        }
    }

    // Bottom-left (for now): inside CommunityPanel the top-left corner
    // belongs to the shared Location sharing card, this card holds only
    // the 3D-globe-specific controls. Tbh, tis is but filled with junk,
    // crept in, slowly comsuing the screen.
    // I really need someone competent in UI design to overhaul this.
    Rectangle {
        id: settingsCard
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: UIScale.spacingMd
        width: Math.round(280 * UIScale.value)
        height: settingsColumn.implicitHeight + UIScale.spacingMd * 2
        radius: UIScale.radiusMd
        color: Colors.withAlpha(Colors.bg, 0.8)
        border.color: Colors.outline
        border.width: 1
        clip: true

        ColumnLayout {
            id: settingsColumn
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: UIScale.spacingMd
            spacing: UIScale.spacingSm

            // Collapsible
            RowLayout {
                id: collapseHeader
                Layout.fillWidth: true
                spacing: UIScale.spacingSm

                Text {
                    Layout.fillWidth: true
                    text: I18n.t("globe3d.title")
                    color: Colors.text
                    font.pixelSize: UIScale.fontBody
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    text: Globe3DService.settingsCollapsed ? "C" : "O"
                    font.family: "Material Icons"
                    font.pixelSize: Math.round(18 * UIScale.value)
                    color: collapseHover.hovered ? Colors.accent : Colors.textDim
                    scale: collapseHover.hovered ? 1.1 : 1.0

                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Anim.standard
                        }
                    }
                    Behavior on scale {
                        NumberAnimation {
                            duration: Anim.fast
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Anim.standard
                        }
                    }

                    HoverHandler {
                        id: collapseHover
                    }
                    TapHandler {
                        onTapped: Globe3DService.writeSettingsCollapsed(!Globe3DService.settingsCollapsed)
                    }
                }
            }

            Item {
                id: collapseWrapper
                Layout.fillWidth: true
                implicitHeight: Globe3DService.settingsCollapsed ? 0 : contentColumn.implicitHeight
                clip: true

                visible: implicitHeight > 0.5

                Behavior on implicitHeight {
                    NumberAnimation {
                        duration: Anim.morph
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Anim.spatial
                    }
                }

                ColumnLayout {
                    id: contentColumn
                    width: collapseWrapper.width
                    opacity: Globe3DService.settingsCollapsed ? 0 : 1
                    spacing: UIScale.spacingSm

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Anim.fast
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Globe3DService.settingsCollapsed ? Anim.emphasizedAccel : Anim.emphasizedDecel
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: I18n.t("globe3d.instancedRods", [engine.rodCount])
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontCaption
                    }

                    Flow {
                        Layout.fillWidth: true
                        Layout.topMargin: UIScale.spacingXs
                        spacing: UIScale.spacingSm

                        ActionButton {
                            label: I18n.t("globe3d.scatter")
                            onActivated: engine.triggerScatter()
                        }
                        ActionButton {
                            label: I18n.t("globe3d.assemble")
                            onActivated: engine.triggerAssemble()
                        }
                        ActionButton {
                            label: I18n.t("globe3d.rescatter")
                            onActivated: engine.triggerReScatter()
                        }
                        ActionButton {
                            label: I18n.t("globe3d.blowUp")
                            onActivated: engine.triggerBlowUp()
                        }
                        ActionButton {
                            label: engine.flattenT > 0.5 ? I18n.t("globe3d.globeify") : I18n.t("globe3d.flatten")
                            onActivated: engine.triggerFlattenToggle()
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: UIScale.spacingXs
                        Layout.bottomMargin: UIScale.spacingXs
                        implicitHeight: 1
                        color: Colors.withAlpha(Colors.accent, 0.10)
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: I18n.t("globe3d.rodCount")
                            color: Colors.text
                            font.pixelSize: UIScale.fontBody
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        Text {
                            text: "≈ " + root._formatCount(20 * root._pendingFrequency * root._pendingFrequency)
                            color: Colors.accent
                            font.pixelSize: UIScale.fontBody
                            font.weight: Font.Bold
                            font.family: "monospace"
                        }
                    }
                    SettingSlider {
                        id: detailSlider
                        Layout.fillWidth: true
                        from: 16
                        to: 96
                        step: 4
                        value: root._pendingFrequency
                        onMoved: v => root._pendingFrequency = v
                        onReleased: root._commitRodFrequency()
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: I18n.t("globe3d.height")
                            color: Colors.text
                            font.pixelSize: UIScale.fontBody
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        Text {
                            text: "x" + engine.heightExaggeration.toFixed(2)
                            color: Colors.accent
                            font.pixelSize: UIScale.fontBody
                            font.weight: Font.Bold
                            font.family: "monospace"
                        }
                    }
                    SettingSlider {
                        Layout.fillWidth: true
                        from: 0.0
                        to: 3.0
                        value: engine.heightExaggeration
                        onMoved: v => engine.heightExaggeration = v
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: I18n.t("globe3d.drift")
                            color: Colors.text
                            font.pixelSize: UIScale.fontBody
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        Text {
                            text: engine.driftAmplitude.toFixed(0)
                            color: Colors.accent
                            font.pixelSize: UIScale.fontBody
                            font.weight: Font.Bold
                            font.family: "monospace"
                        }
                    }
                    SettingSlider {
                        Layout.fillWidth: true
                        from: 0.0
                        to: 60.0
                        value: engine.driftAmplitude
                        onMoved: v => engine.driftAmplitude = v
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.topMargin: UIScale.spacingXs
                        text: I18n.t("globe3d.effect")
                        color: Colors.text
                        font.pixelSize: UIScale.fontBody
                        font.bold: true
                    }
                    OptionRow {
                        Layout.fillWidth: true
                        model: [I18n.t("globe3d.effectNone"), I18n.t("globe3d.effectScanner"), I18n.t("globe3d.effectRipple")]
                        currentIndex: engine.effectMode
                        onActivated: index => engine.effectMode = index
                    }

                    RowLayout {
                        id: glowRow
                        Layout.fillWidth: true
                        Layout.topMargin: UIScale.spacingXs

                        HoverHandler {
                            id: glowHover
                            onHoveredChanged: {
                                if (glowHover.hovered)
                                    hintTooltip.showFor(glowRow, I18n.t("globe3d.dotGlowHint"));
                                else
                                    hintTooltip.hideFor(glowRow);
                            }
                        }

                        Text {
                            text: I18n.t("globe3d.dotGlow")
                            color: Colors.text
                            font.pixelSize: UIScale.fontBody
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        ToggleSwitch {
                            checked: Globe3DService.glowEnabled
                            onToggled: Globe3DService.writeGlowEnabled(!Globe3DService.glowEnabled)
                        }
                    }

                    RowLayout {
                        id: dotsFollowRodRow
                        Layout.fillWidth: true

                        HoverHandler {
                            id: dotsFollowRodHover
                            onHoveredChanged: {
                                if (dotsFollowRodHover.hovered)
                                    hintTooltip.showFor(dotsFollowRodRow, I18n.t("globe3d.dotsTrackRodHeightHint"));
                                else
                                    hintTooltip.hideFor(dotsFollowRodRow);
                            }
                        }

                        Text {
                            text: I18n.t("globe3d.dotsTrackRodHeight")
                            color: Colors.text
                            font.pixelSize: UIScale.fontBody
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        ToggleSwitch {
                            checked: Globe3DService.dotsFollowRodHeight
                            onToggled: Globe3DService.writeDotsFollowRodHeight(!Globe3DService.dotsFollowRodHeight)
                        }
                    }

                    RowLayout {
                        id: closeGapsRow
                        Layout.fillWidth: true

                        HoverHandler {
                            id: closeGapsHover
                            onHoveredChanged: {
                                if (closeGapsHover.hovered)
                                    hintTooltip.showFor(closeGapsRow, I18n.t("globe3d.closeHeightGapsHint"));
                                else
                                    hintTooltip.hideFor(closeGapsRow);
                            }
                        }

                        Text {
                            text: I18n.t("globe3d.closeHeightGaps")
                            color: Colors.text
                            font.pixelSize: UIScale.fontBody
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        ToggleSwitch {
                            checked: Globe3DService.closeHeightGaps
                            onToggled: Globe3DService.writeCloseHeightGaps(!Globe3DService.closeHeightGaps)
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: UIScale.spacingXs
                        Layout.bottomMargin: UIScale.spacingXs
                        implicitHeight: 1
                        color: Colors.withAlpha(Colors.accent, 0.10)
                    }

                    RowLayout {
                        id: audioRow
                        Layout.fillWidth: true

                        HoverHandler {
                            id: audioReactiveHover
                            onHoveredChanged: {
                                if (audioReactiveHover.hovered)
                                    hintTooltip.showFor(audioRow, I18n.t("globe3d.audioReactiveHint"));
                                else
                                    hintTooltip.hideFor(audioRow);
                            }
                        }

                        Text {
                            text: I18n.t("globe3d.audioReactive")
                            color: Colors.text
                            font.pixelSize: UIScale.fontBody
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        ToggleSwitch {
                            checked: engine.audioReactiveEnabled
                            onToggled: engine.audioReactiveEnabled = !engine.audioReactiveEnabled
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        visible: engine.audioReactiveEnabled

                        Text {
                            text: I18n.t("globe3d.audioIntensity")
                            color: Colors.text
                            font.pixelSize: UIScale.fontBody
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        Text {
                            text: engine.audioIntensity.toFixed(2)
                            color: Colors.accent
                            font.pixelSize: UIScale.fontBody
                            font.weight: Font.Bold
                            font.family: "monospace"
                        }
                    }
                    SettingSlider {
                        Layout.fillWidth: true
                        visible: engine.audioReactiveEnabled
                        from: 0.0
                        to: 2
                        step: 0.01
                        value: engine.audioIntensity
                        onMoved: v => engine.audioIntensity = v
                    }
                } // contentColumn
            } // collapseWrapper
        } // settingsColumn
    } // settingsCard

    // Floating hint for the settings rows above
    Rectangle {
        id: hintTooltip

        property Item anchorRow: null
        property string hintText: ""

        function showFor(row, text) {
            hintTooltip.hintText = text;
            hintTooltip.anchorRow = row;
        }
        function hideFor(row) {
            if (hintTooltip.anchorRow === row)
                hintTooltip.anchorRow = null;
        }

        visible: anchorRow !== null
        z: 60
        radius: UIScale.radiusSm
        color: Colors.withAlpha(Colors.bg, 0.94)
        border.color: Colors.outline
        border.width: 1
        width: hintTextItem.implicitWidth + UIScale.spacingMd * 2
        height: hintTextItem.implicitHeight + UIScale.spacingSm * 2

        // ABOVE the card, not beside it. We need some PROPER UI!!!!!
        // Squirrel please for the sake of your own sanity, re-write me.
        // - 00:29 Squirrel comment
        x: settingsCard.x
        y: settingsCard.y - hintTooltip.height - UIScale.spacingSm

        Text {
            id: hintTextItem
            anchors.centerIn: parent
            width: Math.round(220 * UIScale.value)
            text: hintTooltip.hintText
            color: Colors.text
            font.pixelSize: UIScale.fontSmall
            wrapMode: Text.WordWrap
        }
    }
}
