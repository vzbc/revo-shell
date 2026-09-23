import QtQuick
import "../../"

// Everything under this directory that actually renders the geodesic rod
// globe eventually does `import Congeries`. A plain `AssemblyTest {}`
// / `Globe3DPanel {}` object declaration anywhere, forces the QML engine to
// resolve that type (and everything it imports) as part of compiling the
// INCLUDING document, so a missing plugin would take down whatever screen
// embeds it, not just this one.
//
// TLDR:
// Prevents QML from shitting the bed. We gate the loading here, and show
// the user a popup warning, if they have not installed the dependencies.

Item {
    id: root
    required property string panelSource

    // False = the panel is unloaded
    property bool panelActive: true

    // Null while unloaded/loading/errored, same as loader.item
    readonly property QtObject loadedItem: loader.item

    property var panelPoints: []

    property bool panelInteractive: true
    property bool panelAutoRotate: false
    property real panelAutoRotateSpeedDegPerSec: 6

    property real panelCamDist: 500

    property real panelCameraShiftXFrac: 0.0
    property real panelCameraShiftYFrac: 0.0

    property real panelRodRoughness: 0.0

    // A decorative/background embedding (see BackgroundGlobe.qml) wants a
    // missing Congeries plugin to just render nothing.
    property bool showErrorMessage: true

    // Gate loading AssemblyGlobeView.qml until Globe3DService confirms the
    // star catalog data file it statically imports exists on disk.
    Loader {
        id: loader
        anchors.fill: parent
        active: root.panelActive && Globe3DService.starfieldReady
        source: root.panelSource
    }

    Text {
        anchors.centerIn: parent
        visible: root.panelActive && !Globe3DService.starfieldReady
        text: I18n.t("globe3d.preparingStarCatalog")
        color: Colors.textDim
        font.pixelSize: UIScale.fontBody
    }

    Binding {
        target: loader.item
        property: "points"
        value: root.panelPoints
        when: loader.item !== null && loader.item !== undefined && "points" in loader.item
    }

    Binding {
        target: loader.item
        property: "interactive"
        value: root.panelInteractive
        when: loader.item !== null && loader.item !== undefined && "interactive" in loader.item
    }

    Binding {
        target: loader.item
        property: "autoRotate"
        value: root.panelAutoRotate
        when: loader.item !== null && loader.item !== undefined && "autoRotate" in loader.item
    }

    Binding {
        target: loader.item
        property: "autoRotateSpeedDegPerSec"
        value: root.panelAutoRotateSpeedDegPerSec
        when: loader.item !== null && loader.item !== undefined && "autoRotateSpeedDegPerSec" in loader.item
    }

    Binding {
        target: loader.item
        property: "camDist"
        value: root.panelCamDist
        when: loader.item !== null && loader.item !== undefined && "camDist" in loader.item
    }

    Binding {
        target: loader.item
        property: "cameraShiftXFrac"
        value: root.panelCameraShiftXFrac
        when: loader.item !== null && loader.item !== undefined && "cameraShiftXFrac" in loader.item
    }

    Binding {
        target: loader.item
        property: "cameraShiftYFrac"
        value: root.panelCameraShiftYFrac
        when: loader.item !== null && loader.item !== undefined && "cameraShiftYFrac" in loader.item
    }

    Binding {
        target: loader.item
        property: "rodRoughness"
        value: root.panelRodRoughness
        when: loader.item !== null && loader.item !== undefined && "rodRoughness" in loader.item
    }

    Column {
        anchors.centerIn: parent
        visible: root.showErrorMessage && loader.status === Loader.Error
        spacing: UIScale.spacingSm
        width: Math.min(root.width - UIScale.spacingLg * 2, Math.round(360 * UIScale.value))

        Text {
            width: parent.width
            text: "3D globe unavailable"
            color: Colors.text
            font.pixelSize: UIScale.fontSubhead
            font.weight: Font.Bold
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
        Text {
            width: parent.width
            text: I18n.t("globe3d.missingPlugin")
            color: Colors.textDim
            font.pixelSize: UIScale.fontBody
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
