pragma ComponentBehavior: Bound
import QtQuick
import "../weather"
import "../globe2d"
import "../globe3d"

Item {
    id: root

    // 2D and 3D renderers frame VERY differently, they need entirely
    // different mechanisms to reposition the sphere within the frame:
    //
    // 2D: the shader analytically ray-marches a sphere centered in
    // whatever rect the ShaderEffect occupies, so oversizing that rect and
    // shifting it (zoom2D/centerXFrac2D/centerYFrac2D) pans a different
    // window across. In other words, it's just shrimple crop trick.
    //
    // 3D: a PerspectiveCamera always renders its subject centered in
    // ITS OWN viewport, moving/resizing the outer Item just crops a
    // different window into an otherwise-identical render. The correct
    // 3D equivalent is a camera-space translation
    // (cameraShiftXFrac3D/cameraShiftYFrac3D, see
    // AssemblyGlobeView.cameraShiftXFrac/YFrac) that keeps the camera
    // aimed the same absolute direction while sliding its position
    // sideways, aka true parallax.
    property real zoom2D: 1.5 // >1 = sphere bigger than the frame (cropped)
    property real centerXFrac2D: 0.35 // 0=left edge, 1=right edge, where the sphere's own center lands in the frame
    property real centerYFrac2D: 0.9 // 0=top edge, 1=bottom edge
    property real tiltDeg2D: 1

    property real camDist3D: 160 // AssemblyGlobeView's dolly distance (meshRadius 100, default 500), the actual zoom control for the 3D engine
    property real cameraShiftXFrac3D: 0.25
    property real cameraShiftYFrac3D: 0.2
    // Softened WAY down from AssemblyGlobeView's sharp-mirror default (0.0),
    // a continuously auto-rotating view flickers per-facet at low
    // roughness. It was very annoying to look at, at least for me.
    property real rodRoughness3D: 0.9

    property real autoRotateSpeedDegPerSec: 6

    // Whichever renderer the user picked in CommunityPanel, same shared
    // location data either way, only which globe draws it.
    readonly property bool _use3D: Globe3DService.use3DGlobe

    clip: true

    Loader {
        active: LocationSharingService.showBackgroundGlobe && !root._use3D
        width: root.width * root.zoom2D
        height: root.height * root.zoom2D
        x: root.width * root.centerXFrac2D - width / 2
        y: root.height * root.centerYFrac2D - height / 2

        sourceComponent: Globe2D {
            anchors.fill: parent
            interactive: false
            autoRotate: true
            autoRotateSpeedDegPerSec: root.autoRotateSpeedDegPerSec
            tiltDeg: root.tiltDeg2D
            points: LocationSharingService.locations
            initialLat: (LocationSharingService.optedIn && WeatherService.locationName !== "") ? WeatherService.latitude : 50.0
            initialLon: (LocationSharingService.optedIn && WeatherService.locationName !== "") ? WeatherService.longitude : 10.0
        }
    }

    Globe3DGate {
        anchors.fill: parent

        visible: LocationSharingService.showBackgroundGlobe && root._use3D
        panelActive: LocationSharingService.showBackgroundGlobe && root._use3D
        panelSource: "AssemblyGlobeView.qml"
        panelPoints: LocationSharingService.locations
        showErrorMessage: false
        panelInteractive: false
        panelAutoRotate: true
        panelAutoRotateSpeedDegPerSec: root.autoRotateSpeedDegPerSec
        panelCamDist: root.camDist3D
        panelCameraShiftXFrac: root.cameraShiftXFrac3D
        panelCameraShiftYFrac: root.cameraShiftYFrac3D
        panelRodRoughness: root.rodRoughness3D

        // I spent multiple days conceptualizing and coding the shatter->assemble.
        // SO WE SHOW IT OFF HERE, just keyed off Globe3DRuntimeState
        // (in-memory, THIS PROCESS only).
        onLoadedItemChanged: {
            if (!loadedItem)
                return;
            if (Globe3DRuntimeState.backgroundAssembledOnce) {
                loadedItem.assembleT = 1.0;
            } else {
                loadedItem.triggerAssemble();
                Globe3DRuntimeState.backgroundAssembledOnce = true;
            }
        }
    }
}
