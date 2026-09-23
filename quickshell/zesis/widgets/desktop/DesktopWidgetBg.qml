pragma ComponentBehavior: Bound

// Shared background renderer for desktop widgets.
// Consumed by both DesktopWidget (live layer) and the config overlay proxy.
import QtQuick
import QtQuick.Effects
import "../../"

Item {
    id: root

    // Full bg config object: { enabled, type, color, overlayOpacity, imagePath, cachedImagePath, maskPath }
    property var bgConfig: ({
            enabled: false,
            type: "color",
            color: "",
            overlayOpacity: 0.4,
            imagePath: "",
            cachedImagePath: "",
            maskPath: ""
        })

    // Color background
    Rectangle {
        anchors.fill: parent
        visible: root.bgConfig.enabled && root.bgConfig.type === "color"
        color: (root.bgConfig.color ?? "") !== "" ? root.bgConfig.color : Colors.withAlpha(Colors.bg, 0.62)
        radius: UIScale.radiusMd
    }

    // Image background
    Loader {
        anchors.fill: parent
        active: root.bgConfig.enabled && root.bgConfig.type === "image"
        onLoaded: item.bgConfig = Qt.binding(() => root.bgConfig)

        sourceComponent: Item {
            id: imageBg
            property var bgConfig
            anchors.fill: parent

            // Mask sources, invisible, rendered to texture for MultiEffect.
            Rectangle {
                id: clipMask
                anchors.fill: parent
                radius: UIScale.radiusMd
                visible: false
                layer.enabled: true
            }

            Image {
                id: shapeMask
                anchors.fill: parent
                source: (imageBg.bgConfig.maskPath ?? "") !== "" ? ("file://" + imageBg.bgConfig.maskPath) : ""
                fillMode: Image.PreserveAspectCrop
                visible: false
                layer.enabled: true
            }

            // Outer item: optional shape mask
            Item {
                anchors.fill: parent
                layer.enabled: (imageBg.bgConfig.maskPath ?? "") !== ""
                layer.effect: MultiEffect {
                    maskEnabled: (imageBg.bgConfig.maskPath ?? "") !== ""
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                    maskSource: shapeMask
                }

                // Inner item: rounded-corner clip
                Item {
                    anchors.fill: parent
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskThresholdMin: 0.5
                        maskSpreadAtMin: 1.0
                        maskSource: clipMask
                    }

                    Image {
                        anchors.fill: parent
                        cache: false
                        source: {
                            var p = (imageBg.bgConfig.cachedImagePath ?? "") || (imageBg.bgConfig.imagePath ?? "");
                            return p ? ("file://" + p) : "";
                        }
                        fillMode: Image.PreserveAspectCrop
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "black"
                        opacity: imageBg.bgConfig.overlayOpacity ?? 0.4
                    }
                }
            }
        }
    }
}
