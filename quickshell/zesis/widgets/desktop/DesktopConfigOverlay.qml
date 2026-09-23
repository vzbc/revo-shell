pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Dialogs
import Quickshell
import Quickshell.Wayland
import "./"
import "../../"
import "../globe2d"

PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "zesis:desktop:config"
    WlrLayershell.keyboardFocus: root._fileDialogOpen ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    exclusiveZone: -1
    color: "transparent"
    visible: DesktopWidgetStore.configMode
    onVisibleChanged: {
        if (!visible) {
            root.selectedKey = "";
            root._fileDialogOpen = false;
        }
    }

    property bool snapEnabled: true
    readonly property real snapThreshold: 20

    property string selectedKey: ""

    // Goes click-through while a portal file-picker is open so the native window
    // can receive pointer events (WlrLayer.Top would otherwise intercept them).
    property bool _fileDialogOpen: false
    Region {
        id: overlayInputRegion
        width: root._fileDialogOpen ? 0 : root.width
        height: root._fileDialogOpen ? 0 : root.height
    }
    mask: overlayInputRegion

    // Active alignment guides, set during drag, cleared on release.
    // undefined = hidden, a number = draw guide at that coordinate.
    property var _snapGuideX // vertical line (x snap)
    property var _snapGuideY // horizontal line (y snap)

    // Returns { x, y, guideX, guideY } where guide* may be undefined.
    function _computeSnap(activeProxy, rawX, rawY) {
        var pW = activeProxy.width;
        var pH = activeProxy.height;
        var thr = root.snapThreshold;

        var xC = [
            {
                snapX: (root.width - pW) / 2,
                guideX: root.width / 2
            },
            {
                snapX: 0,
                guideX: 0
            },
            {
                snapX: root.width - pW,
                guideX: root.width
            },
        ];
        var yC = [
            {
                snapY: (root.height - pH) / 2,
                guideY: root.height / 2
            },
            {
                snapY: 0,
                guideY: 0
            },
            {
                snapY: root.height - pH,
                guideY: root.height
            },
        ];

        for (var i = 0; i < widgetRepeater.count; i++) {
            var o = widgetRepeater.itemAt(i);
            if (o === null || o === activeProxy)
                continue;
            var oX = o.x, oY = o.y, oW = o.width, oH = o.height;

            xC.push({
                snapX: oX,
                guideX: oX
            });
            xC.push({
                snapX: oX + oW - pW,
                guideX: oX + oW
            });
            xC.push({
                snapX: oX + oW / 2 - pW / 2,
                guideX: oX + oW / 2
            });
            xC.push({
                snapX: oX - pW,
                guideX: oX
            });
            xC.push({
                snapX: oX + oW,
                guideX: oX + oW
            });

            yC.push({
                snapY: oY,
                guideY: oY
            });
            yC.push({
                snapY: oY + oH - pH,
                guideY: oY + oH
            });
            yC.push({
                snapY: oY + oH / 2 - pH / 2,
                guideY: oY + oH / 2
            });
            yC.push({
                snapY: oY - pH,
                guideY: oY
            });
            yC.push({
                snapY: oY + oH,
                guideY: oY + oH
            });
        }

        var bX = rawX, bgX = undefined, bdX = thr;
        for (var j = 0; j < xC.length; j++) {
            var dx = Math.abs(rawX - xC[j].snapX);
            if (dx < bdX) {
                bdX = dx;
                bX = xC[j].snapX;
                bgX = xC[j].guideX;
            }
        }

        var bY = rawY, bgY = undefined, bdY = thr;
        for (var k = 0; k < yC.length; k++) {
            var dy = Math.abs(rawY - yC[k].snapY);
            if (dy < bdY) {
                bdY = dy;
                bY = yC[k].snapY;
                bgY = yC[k].guideY;
            }
        }

        return {
            x: bX,
            y: bY,
            guideX: bgX,
            guideY: bgY
        };
    }

    Shortcut {
        sequence: "Escape"
        enabled: !root._fileDialogOpen
        onActivated: DesktopWidgetStore.configMode = false
    }

    // Background dim
    Rectangle {
        anchors.fill: parent
        color: Colors.withAlpha(Colors.bg, 0.45)
    }

    // Widget proxies
    Repeater {
        id: widgetRepeater
        model: DesktopWidgetStore._widgets

        delegate: Item {
            id: proxy
            required property var modelData
            required property int index

            readonly property string wKey: modelData.key
            readonly property bool _selected: root.selectedKey === proxy.wKey
            property real _nx: DesktopWidgetStore.getPos(wKey).nx
            property real _ny: DesktopWidgetStore.getPos(wKey).ny

            readonly property var _bgConfig: {
                var _ = DesktopWidgetStore._positions;
                return DesktopWidgetStore.getBgConfig(proxy.wKey);
            }
            readonly property bool _hasBg: _bgConfig.enabled
            readonly property real _bgPad: _hasBg ? Math.round(10 * UIScale.value) : 0
            readonly property real _dpr: Screen.devicePixelRatio

            // Mirrors DesktopWidget.qml's override logic so the proxy you drag around
            // here matches what actually renders once you hit Done.
            readonly property var _size: {
                var _ = DesktopWidgetStore._positions;
                return DesktopWidgetStore.getSize(proxy.wKey);
            }
            readonly property bool _overrideW: _size.w > 0
            readonly property bool _overrideH: _size.h > 0

            width: (proxy._overrideW ? proxy._size.w : proxyContent.implicitWidth) + _bgPad * 2
            height: (proxy._overrideH ? proxy._size.h : proxyContent.implicitHeight) + _bgPad * 2

            x: _nx * Math.max(1, root.width - width)
            y: _ny * Math.max(1, root.height - height)

            z: proxy._selected ? 10 : 0

            // Loaders create a fresh FileDialog each time to avoid a Qt 6.11 "bug" where
            // QQuickFileDialogImpl::setInitialCurrentFolderAndSelectedFile crashes on
            // the second open() call due to a stale internal QUrl pointer.
            // If this is *not* a bug, and I've just been using FileDialog incorrectly this whole time...
            // Please don't tell me I've been using it incorrectly.
            function openImageDialog() {
                imgDialogLoader.active = false;
                imgDialogLoader.active = true;
            }
            function openMaskDialog() {
                maskDialogLoader.active = false;
                maskDialogLoader.active = true;
            }
            Loader {
                id: imgDialogLoader
                active: false
                onActiveChanged: if (!active)
                    root._fileDialogOpen = false
                onLoaded: {
                    root._fileDialogOpen = true;
                    item.open();
                }
                sourceComponent: FileDialog {
                    title: I18n.t("desktop.chooseBackgroundImageDialogTitle")
                    nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.svg *.gif *.bmp)", "All files (*)"]
                    onAccepted: {
                        var path = selectedFile.toString();
                        if (path.startsWith("file://"))
                            path = path.slice(7);
                        var c = DesktopWidgetStore.getBgConfig(proxy.wKey);
                        c.imagePath = path;
                        DesktopWidgetStore.setBgConfig(proxy.wKey, c, Math.round(proxy.width * proxy._dpr), Math.round(proxy.height * proxy._dpr));
                        imgDialogLoader.active = false;
                    }
                    onRejected: {
                        imgDialogLoader.active = false;
                    }
                }
            }

            Loader {
                id: maskDialogLoader
                active: false
                onActiveChanged: if (!active)
                    root._fileDialogOpen = false
                onLoaded: {
                    root._fileDialogOpen = true;
                    item.open();
                }
                sourceComponent: FileDialog {
                    title: I18n.t("desktop.chooseMaskImageDialogTitle")
                    nameFilters: ["Images (*.png *.svg)", "All files (*)"]
                    onAccepted: {
                        var path = selectedFile.toString();
                        if (path.startsWith("file://"))
                            path = path.slice(7);
                        var c = DesktopWidgetStore.getBgConfig(proxy.wKey);
                        c.maskPath = path;
                        DesktopWidgetStore.setBgConfig(proxy.wKey, c);
                        maskDialogLoader.active = false;
                    }
                    onRejected: {
                        maskDialogLoader.active = false;
                    }
                }
            }

            DesktopWidgetBg {
                anchors.fill: parent
                bgConfig: proxy._bgConfig
            }

            // width/height stay bound always, see docs/qml-patterns.md #2 for why
            Loader {
                id: proxyContent
                anchors.centerIn: parent
                sourceComponent: proxy.modelData.component
                width: proxy._overrideW ? proxy._size.w : (item?.implicitWidth ?? 0)
                height: proxy._overrideH ? proxy._size.h : (item?.implicitHeight ?? 0)
            }

            DragHandler {
                id: dragger
                target: null
                grabPermissions: PointerHandler.CanTakeOverFromAnything

                property point _startScene: Qt.point(0, 0)
                property point _startPos: Qt.point(0, 0)

                onActiveChanged: {
                    if (active) {
                        dragger._startScene = dragger.centroid.scenePosition;
                        dragger._startPos = Qt.point(proxy.x, proxy.y);
                    } else {
                        root._snapGuideX = undefined;
                        root._snapGuideY = undefined;
                        var rW = Math.max(1, root.width - proxy.width);
                        var rH = Math.max(1, root.height - proxy.height);
                        proxy._nx = Math.max(0.0, Math.min(1.0, proxy.x / rW));
                        proxy._ny = Math.max(0.0, Math.min(1.0, proxy.y / rH));
                        DesktopWidgetStore.setPos(proxy.wKey, proxy._nx, proxy._ny);
                        proxy.x = Qt.binding(() => proxy._nx * Math.max(1, root.width - proxy.width));
                        proxy.y = Qt.binding(() => proxy._ny * Math.max(1, root.height - proxy.height));
                    }
                }

                onCentroidChanged: {
                    if (!dragger.active)
                        return;
                    var rawX = dragger._startPos.x + (dragger.centroid.scenePosition.x - dragger._startScene.x);
                    var rawY = dragger._startPos.y + (dragger.centroid.scenePosition.y - dragger._startScene.y);
                    if (root.snapEnabled) {
                        var s = root._computeSnap(proxy, rawX, rawY);
                        proxy.x = s.x;
                        proxy.y = s.y;
                        root._snapGuideX = s.guideX;
                        root._snapGuideY = s.guideY;
                    } else {
                        proxy.x = rawX;
                        proxy.y = rawY;
                        root._snapGuideX = undefined;
                        root._snapGuideY = undefined;
                    }
                }
            }

            TapHandler {
                onTapped: root.selectedKey = proxy._selected ? "" : proxy.wKey
            }

            HoverHandler {
                cursorShape: dragger.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            }

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: Colors.withAlpha(Colors.accent, proxy._selected ? 1.0 : (dragger.active ? 1.0 : 0.75))
                border.width: Math.round((proxy._selected ? 2 : 1.5) * UIScale.value)
                radius: UIScale.radiusSm

                Behavior on border.width {
                    NumberAnimation {
                        duration: 100
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: UIScale.spacingXs
                text: proxy.wKey
                color: proxy._selected ? Colors.accent : Colors.textDim
                font.pixelSize: UIScale.fontTiny
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1

                Behavior on color {
                    ColorAnimation {
                        duration: 100
                    }
                }
            }

            // Resize handles: 4 corner grabs (width + height) + 4 edge grabs
            // (single axis).
            Repeater {
                model: proxy._selected ? ["nw", "n", "ne", "w", "e", "sw", "s", "se"] : []

                delegate: Rectangle {
                    id: handle
                    required property string modelData

                    readonly property bool _left: modelData.indexOf("w") >= 0
                    readonly property bool _right: modelData.indexOf("e") >= 0
                    readonly property bool _top: modelData.indexOf("n") >= 0
                    readonly property bool _bottom: modelData.indexOf("s") >= 0

                    width: Math.round(9 * UIScale.value)
                    height: width
                    radius: width / 2
                    color: Colors.bg
                    border.color: Colors.accent
                    border.width: Math.max(1, Math.round(1.5 * UIScale.value))
                    z: 20

                    x: (handle._left ? 0 : handle._right ? proxy.width : proxy.width / 2) - handle.width / 2
                    y: (handle._top ? 0 : handle._bottom ? proxy.height : proxy.height / 2) - handle.height / 2

                    property real _startX
                    property real _startY
                    property real _startW
                    property real _startH
                    property point _startScene

                    HoverHandler {
                        cursorShape: {
                            switch (handle.modelData) {
                            case "n":
                            case "s":
                                return Qt.SizeVerCursor;
                            case "e":
                            case "w":
                                return Qt.SizeHorCursor;
                            case "nw":
                            case "se":
                                return Qt.SizeFDiagCursor;
                            default:
                                // ne, sw
                                return Qt.SizeBDiagCursor;
                            }
                        }
                    }

                    DragHandler {
                        id: resizeDrag
                        target: null
                        grabPermissions: PointerHandler.CanTakeOverFromAnything

                        onActiveChanged: {
                            if (resizeDrag.active) {
                                handle._startScene = resizeDrag.centroid.scenePosition;
                                handle._startX = proxy.x;
                                handle._startY = proxy.y;
                                handle._startW = proxy.width;
                                handle._startH = proxy.height;
                            } else {
                                var w = Math.max(1, Math.round(proxy.width - proxy._bgPad * 2));
                                var h = Math.max(1, Math.round(proxy.height - proxy._bgPad * 2));
                                DesktopWidgetStore.setSize(proxy.wKey, w, h);

                                var rW = Math.max(1, root.width - proxy.width);
                                var rH = Math.max(1, root.height - proxy.height);
                                proxy._nx = Math.max(0.0, Math.min(1.0, proxy.x / rW));
                                proxy._ny = Math.max(0.0, Math.min(1.0, proxy.y / rH));
                                DesktopWidgetStore.setPos(proxy.wKey, proxy._nx, proxy._ny);

                                proxy.x = Qt.binding(() => proxy._nx * Math.max(1, root.width - proxy.width));
                                proxy.y = Qt.binding(() => proxy._ny * Math.max(1, root.height - proxy.height));
                                proxy.width = Qt.binding(() => (proxy._overrideW ? proxy._size.w : proxyContent.implicitWidth) + proxy._bgPad * 2);
                                proxy.height = Qt.binding(() => (proxy._overrideH ? proxy._size.h : proxyContent.implicitHeight) + proxy._bgPad * 2);
                            }
                        }

                        onCentroidChanged: {
                            if (!resizeDrag.active)
                                return;

                            var dx = resizeDrag.centroid.scenePosition.x - handle._startScene.x;
                            var dy = resizeDrag.centroid.scenePosition.y - handle._startScene.y;
                            var minW = Math.round(40 * UIScale.value) + proxy._bgPad * 2;
                            var minH = Math.round(24 * UIScale.value) + proxy._bgPad * 2;

                            var newW = handle._startW;
                            var newH = handle._startH;
                            var newX = handle._startX;
                            var newY = handle._startY;

                            if (handle._right) {
                                newW = Math.max(minW, handle._startW + dx);
                            } else if (handle._left) {
                                newW = Math.max(minW, handle._startW - dx);
                                newX = handle._startX + (handle._startW - newW);
                            }

                            if (handle._bottom) {
                                newH = Math.max(minH, handle._startH + dy);
                            } else if (handle._top) {
                                newH = Math.max(minH, handle._startH - dy);
                                newY = handle._startY + (handle._startH - newH);
                            }

                            proxy.width = newW;
                            proxy.height = newH;
                            proxy.x = newX;
                            proxy.y = newY;
                        }
                    }
                }
            }

            // Per-widget settings card, appears below the proxy when selected.
            Loader {
                active: proxy._selected
                anchors.horizontalCenter: parent.horizontalCenter
                y: proxy.height + Math.round(UIScale.spacingSm) + UIScale.fontTiny + UIScale.spacingXs

                sourceComponent: Rectangle {
                    radius: UIScale.radiusSm
                    color: Colors.surface
                    implicitWidth: cardContent.implicitWidth + Math.round(UIScale.spacingMd * 2)
                    implicitHeight: cardContent.implicitHeight + Math.round(UIScale.spacingSm * 2)

                    Column {
                        id: cardContent
                        anchors.centerIn: parent
                        spacing: Math.round(UIScale.spacingSm)

                        // Row 0: Fixed size, independent per axis. Empty/0 means "auto",
                        // falls back to the content's own natural size.
                        Row {
                            spacing: Math.round(UIScale.spacingSm)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: I18n.t("desktop.size")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontSmall
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                implicitWidth: Math.round(52 * UIScale.value)
                                implicitHeight: widthInput.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                color: Colors.withAlpha(Colors.outline, 0.2)
                                radius: UIScale.radiusSm
                                clip: true

                                TextInput {
                                    id: widthInput
                                    anchors {
                                        fill: parent
                                        margins: Math.round(UIScale.spacingXs)
                                    }
                                    text: {
                                        var w = DesktopWidgetStore.getSize(proxy.wKey).w;
                                        return w > 0 ? String(w) : "";
                                    }
                                    color: Colors.text
                                    font.pixelSize: UIScale.fontSmall
                                    selectByMouse: true
                                    validator: IntValidator {
                                        bottom: 0
                                    }
                                    onEditingFinished: {
                                        var s = DesktopWidgetStore.getSize(proxy.wKey);
                                        DesktopWidgetStore.setSize(proxy.wKey, parseInt(widthInput.text) || 0, s.h);
                                    }
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                // I am also conflicted on the usage of × because VSCodium
                                // keeps warning me about it, which is annoying.
                                // I could use X or x, but those don't look as good.
                                // Am I rambling? Yes. Is this the place to do it? No.
                                text: "×"
                                color: Colors.muted
                                font.pixelSize: UIScale.fontSmall
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                implicitWidth: Math.round(52 * UIScale.value)
                                implicitHeight: heightInput.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                color: Colors.withAlpha(Colors.outline, 0.2)
                                radius: UIScale.radiusSm
                                clip: true

                                TextInput {
                                    id: heightInput
                                    anchors {
                                        fill: parent
                                        margins: Math.round(UIScale.spacingXs)
                                    }
                                    text: {
                                        var h = DesktopWidgetStore.getSize(proxy.wKey).h;
                                        return h > 0 ? String(h) : "";
                                    }
                                    color: Colors.text
                                    font.pixelSize: UIScale.fontSmall
                                    selectByMouse: true
                                    validator: IntValidator {
                                        bottom: 0
                                    }
                                    onEditingFinished: {
                                        var s = DesktopWidgetStore.getSize(proxy.wKey);
                                        DesktopWidgetStore.setSize(proxy.wKey, s.w, parseInt(heightInput.text) || 0);
                                    }
                                }
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: proxy._overrideW || proxy._overrideH
                                implicitWidth: sizeAutoLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                                implicitHeight: sizeAutoLabel.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                radius: UIScale.radiusSm
                                color: sizeAutoHover.hovered ? Colors.withAlpha(Colors.outline, 0.4) : Colors.withAlpha(Colors.outline, 0.2)

                                Text {
                                    id: sizeAutoLabel
                                    anchors.centerIn: parent
                                    text: I18n.t("common.auto")
                                    color: Colors.muted
                                    font.pixelSize: UIScale.fontSmall
                                }

                                HoverHandler {
                                    id: sizeAutoHover
                                }
                                TapHandler {
                                    onTapped: {
                                        DesktopWidgetStore.setSize(proxy.wKey, 0, 0);
                                        widthInput.text = "";
                                        heightInput.text = "";
                                    }
                                }
                            }
                        }

                        // Row 1: Background enable toggle
                        Row {
                            spacing: Math.round(UIScale.spacingMd)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: I18n.t("desktop.background")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontSmall
                            }

                            Rectangle {
                                id: bgToggle
                                anchors.verticalCenter: parent.verticalCenter

                                property bool _on: (DesktopWidgetStore._positions[proxy.wKey]?.bg?.enabled) ?? false

                                implicitWidth: bgToggleLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                                implicitHeight: bgToggleLabel.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                radius: height / 2
                                color: _on ? Colors.withAlpha(Colors.accent, 0.2) : Colors.withAlpha(Colors.outline, 0.3)

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 100
                                    }
                                }

                                Text {
                                    id: bgToggleLabel
                                    anchors.centerIn: parent
                                    text: bgToggle._on ? I18n.t("common.on") : I18n.t("common.off")
                                    color: bgToggle._on ? Colors.accent : Colors.muted
                                    font.pixelSize: UIScale.fontSmall
                                    font.weight: Font.Medium

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 100
                                        }
                                    }
                                }

                                HoverHandler {}
                                TapHandler {
                                    onTapped: {
                                        var c = DesktopWidgetStore.getBgConfig(proxy.wKey);
                                        c.enabled = !c.enabled;
                                        DesktopWidgetStore.setBgConfig(proxy.wKey, c);
                                    }
                                }
                            }
                        }

                        // Row 2: Type selector, Color / Image
                        Row {
                            visible: (DesktopWidgetStore._positions[proxy.wKey]?.bg?.enabled) ?? false
                            spacing: Math.round(UIScale.spacingSm)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: I18n.t("desktop.type")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontSmall
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                property bool _active: ((DesktopWidgetStore._positions[proxy.wKey]?.bg?.type) ?? "color") === "color"
                                implicitWidth: colorTypeLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                                implicitHeight: colorTypeLabel.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                radius: height / 2
                                color: _active ? Colors.withAlpha(Colors.accent, 0.2) : Colors.withAlpha(Colors.outline, 0.15)
                                border.color: _active ? Colors.accent : "transparent"
                                border.width: 1

                                Text {
                                    id: colorTypeLabel
                                    anchors.centerIn: parent
                                    text: I18n.t("desktop.color")
                                    color: parent._active ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontSmall
                                }

                                HoverHandler {}
                                TapHandler {
                                    onTapped: {
                                        var c = DesktopWidgetStore.getBgConfig(proxy.wKey);
                                        c.type = "color";
                                        DesktopWidgetStore.setBgConfig(proxy.wKey, c);
                                    }
                                }
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                property bool _active: ((DesktopWidgetStore._positions[proxy.wKey]?.bg?.type) ?? "color") === "image"
                                implicitWidth: imageTypeLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                                implicitHeight: imageTypeLabel.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                radius: height / 2
                                color: _active ? Colors.withAlpha(Colors.accent, 0.2) : Colors.withAlpha(Colors.outline, 0.15)
                                border.color: _active ? Colors.accent : "transparent"
                                border.width: 1

                                Text {
                                    id: imageTypeLabel
                                    anchors.centerIn: parent
                                    text: I18n.t("desktop.image")
                                    color: parent._active ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontSmall
                                }

                                HoverHandler {}
                                TapHandler {
                                    onTapped: {
                                        var c = DesktopWidgetStore.getBgConfig(proxy.wKey);
                                        c.type = "image";
                                        DesktopWidgetStore.setBgConfig(proxy.wKey, c);
                                    }
                                }
                            }
                        }

                        // Row 3: Inline color picker
                        Loader {
                            active: ((DesktopWidgetStore._positions[proxy.wKey]?.bg?.enabled) ?? false) && ((DesktopWidgetStore._positions[proxy.wKey]?.bg?.type) ?? "color") === "color"
                            sourceComponent: ColorPicker {
                                property bool _ready: false
                                Component.onCompleted: {
                                    var col = DesktopWidgetStore._positions[proxy.wKey]?.bg?.color ?? "";
                                    if (col !== "")
                                        setFromColor(Qt.color(col));
                                    _ready = true;
                                }
                                onSelectedColorChanged: {
                                    if (!_ready)
                                        return;
                                    var c = DesktopWidgetStore.getBgConfig(proxy.wKey);
                                    c.color = selectedColor.toString();
                                    DesktopWidgetStore.setBgConfig(proxy.wKey, c);
                                }
                            }
                        }

                        // Row 4: Image path
                        Row {
                            visible: ((DesktopWidgetStore._positions[proxy.wKey]?.bg?.enabled) ?? false) && ((DesktopWidgetStore._positions[proxy.wKey]?.bg?.type) ?? "color") === "image"
                            spacing: Math.round(UIScale.spacingSm)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: I18n.t("desktop.image")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontSmall
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                implicitWidth: Math.round(180 * UIScale.value)
                                implicitHeight: imgPathInput.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                color: Colors.withAlpha(Colors.outline, 0.2)
                                radius: UIScale.radiusSm
                                clip: true

                                TextInput {
                                    id: imgPathInput
                                    anchors {
                                        fill: parent
                                        margins: Math.round(UIScale.spacingXs)
                                    }
                                    text: (DesktopWidgetStore._positions[proxy.wKey]?.bg?.imagePath) ?? ""
                                    color: Colors.text
                                    font.pixelSize: UIScale.fontSmall
                                    selectByMouse: true
                                    onEditingFinished: {
                                        var c = DesktopWidgetStore.getBgConfig(proxy.wKey);
                                        c.imagePath = imgPathInput.text;
                                        DesktopWidgetStore.setBgConfig(proxy.wKey, c, Math.round(proxy.width * proxy._dpr), Math.round(proxy.height * proxy._dpr));
                                    }
                                }
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                implicitWidth: imgBrowseLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                                implicitHeight: imgBrowseLabel.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                radius: UIScale.radiusSm
                                color: imgBrowseHover.hovered ? Colors.withAlpha(Colors.outline, 0.4) : Colors.withAlpha(Colors.outline, 0.2)

                                Text {
                                    id: imgBrowseLabel
                                    anchors.centerIn: parent
                                    text: I18n.t("desktop.browse")
                                    color: Colors.textDim
                                    font.pixelSize: UIScale.fontSmall
                                }

                                HoverHandler {
                                    id: imgBrowseHover
                                }
                                TapHandler {
                                    onTapped: proxy.openImageDialog()
                                }
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: ((DesktopWidgetStore._positions[proxy.wKey]?.bg?.imagePath) ?? "") !== ""
                                implicitWidth: imgClearLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                                implicitHeight: imgClearLabel.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                radius: UIScale.radiusSm
                                color: imgClearHover.hovered ? Colors.withAlpha(Colors.outline, 0.4) : Colors.withAlpha(Colors.outline, 0.2)

                                Text {
                                    id: imgClearLabel
                                    anchors.centerIn: parent
                                    text: I18n.t("desktop.clear")
                                    color: Colors.muted
                                    font.pixelSize: UIScale.fontSmall
                                }

                                HoverHandler {
                                    id: imgClearHover
                                }
                                TapHandler {
                                    onTapped: {
                                        var c = DesktopWidgetStore.getBgConfig(proxy.wKey);
                                        c.imagePath = "";
                                        DesktopWidgetStore.setBgConfig(proxy.wKey, c, Math.round(proxy.width * proxy._dpr), Math.round(proxy.height * proxy._dpr));
                                    }
                                }
                            }
                        }

                        // Row 5: Overlay opacity
                        Row {
                            visible: ((DesktopWidgetStore._positions[proxy.wKey]?.bg?.enabled) ?? false) && ((DesktopWidgetStore._positions[proxy.wKey]?.bg?.type) ?? "color") === "image"
                            spacing: Math.round(UIScale.spacingSm)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: I18n.t("desktop.overlay")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontSmall
                            }

                            Item {
                                id: overlaySlider
                                anchors.verticalCenter: parent.verticalCenter
                                implicitWidth: Math.round(120 * UIScale.value)
                                implicitHeight: Math.round(16 * UIScale.value)

                                readonly property real _val: (DesktopWidgetStore._positions[proxy.wKey]?.bg?.overlayOpacity) ?? 0.4

                                Rectangle {
                                    id: sliderTrack
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width
                                    height: Math.max(2, Math.round(3 * UIScale.value))
                                    radius: height / 2
                                    color: Colors.withAlpha(Colors.outline, 0.4)

                                    Rectangle {
                                        width: sliderTrack.width * overlaySlider._val
                                        height: parent.height
                                        radius: height / 2
                                        color: Colors.accent
                                    }
                                }

                                Rectangle {
                                    width: Math.round(12 * UIScale.value)
                                    height: width
                                    radius: width / 2
                                    color: Colors.accent
                                    x: (overlaySlider.implicitWidth - width) * overlaySlider._val
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    function _update(mx) {
                                        var ratio = Math.max(0.0, Math.min(1.0, mx / overlaySlider.implicitWidth));
                                        var c = DesktopWidgetStore.getBgConfig(proxy.wKey);
                                        c.overlayOpacity = Math.round(ratio * 100) / 100;
                                        DesktopWidgetStore.setBgConfig(proxy.wKey, c);
                                    }
                                    onPressed: _update(mouseX)
                                    onPositionChanged: if (pressed)
                                        _update(mouseX)
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Math.round(((DesktopWidgetStore._positions[proxy.wKey]?.bg?.overlayOpacity) ?? 0.4) * 100) + "%"
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontSmall
                            }
                        }

                        // Row 6: Mask path
                        Row {
                            visible: ((DesktopWidgetStore._positions[proxy.wKey]?.bg?.enabled) ?? false) && ((DesktopWidgetStore._positions[proxy.wKey]?.bg?.type) ?? "color") === "image"
                            spacing: Math.round(UIScale.spacingSm)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: I18n.t("desktop.mask")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontSmall
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                implicitWidth: Math.round(180 * UIScale.value)
                                implicitHeight: maskPathInput.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                color: Colors.withAlpha(Colors.outline, 0.2)
                                radius: UIScale.radiusSm
                                clip: true

                                TextInput {
                                    id: maskPathInput
                                    anchors {
                                        fill: parent
                                        margins: Math.round(UIScale.spacingXs)
                                    }
                                    text: (DesktopWidgetStore._positions[proxy.wKey]?.bg?.maskPath) ?? ""
                                    color: Colors.text
                                    font.pixelSize: UIScale.fontSmall
                                    selectByMouse: true
                                    onEditingFinished: {
                                        var c = DesktopWidgetStore.getBgConfig(proxy.wKey);
                                        c.maskPath = maskPathInput.text;
                                        DesktopWidgetStore.setBgConfig(proxy.wKey, c);
                                    }
                                }
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                implicitWidth: maskBrowseLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                                implicitHeight: maskBrowseLabel.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                radius: UIScale.radiusSm
                                color: maskBrowseHover.hovered ? Colors.withAlpha(Colors.outline, 0.4) : Colors.withAlpha(Colors.outline, 0.2)

                                Text {
                                    id: maskBrowseLabel
                                    anchors.centerIn: parent
                                    text: I18n.t("desktop.browse")
                                    color: Colors.textDim
                                    font.pixelSize: UIScale.fontSmall
                                }

                                HoverHandler {
                                    id: maskBrowseHover
                                }
                                TapHandler {
                                    onTapped: proxy.openMaskDialog()
                                }
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: ((DesktopWidgetStore._positions[proxy.wKey]?.bg?.maskPath) ?? "") !== ""
                                implicitWidth: maskClearLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                                implicitHeight: maskClearLabel.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                radius: UIScale.radiusSm
                                color: maskClearHover.hovered ? Colors.withAlpha(Colors.outline, 0.4) : Colors.withAlpha(Colors.outline, 0.2)

                                Text {
                                    id: maskClearLabel
                                    anchors.centerIn: parent
                                    text: I18n.t("desktop.clear")
                                    color: Colors.muted
                                    font.pixelSize: UIScale.fontSmall
                                }

                                HoverHandler {
                                    id: maskClearHover
                                }
                                TapHandler {
                                    onTapped: {
                                        var c = DesktopWidgetStore.getBgConfig(proxy.wKey);
                                        c.maskPath = "";
                                        DesktopWidgetStore.setBgConfig(proxy.wKey, c);
                                    }
                                }
                            }
                        }

                        // Row 7: Globe-only rotation mode (auto-spin vs a
                        // single static frame)
                        Row {
                            visible: proxy.wKey === "globe2d"
                            spacing: Math.round(UIScale.spacingSm)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: I18n.t("desktop.rotation")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontSmall
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                property bool _active: Globe2DSettings.rotateMode === "auto"
                                implicitWidth: autoModeLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                                implicitHeight: autoModeLabel.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                radius: height / 2
                                color: _active ? Colors.withAlpha(Colors.accent, 0.2) : Colors.withAlpha(Colors.outline, 0.15)
                                border.color: _active ? Colors.accent : "transparent"
                                border.width: 1

                                Text {
                                    id: autoModeLabel
                                    anchors.centerIn: parent
                                    text: I18n.t("common.auto")
                                    color: parent._active ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontSmall
                                }

                                HoverHandler {}
                                TapHandler {
                                    onTapped: Globe2DSettings.setRotateMode("auto")
                                }
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                property bool _active: Globe2DSettings.rotateMode === "manual"
                                implicitWidth: manualModeLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
                                implicitHeight: manualModeLabel.implicitHeight + Math.round(UIScale.spacingXs * 2)
                                radius: height / 2
                                color: _active ? Colors.withAlpha(Colors.accent, 0.2) : Colors.withAlpha(Colors.outline, 0.15)
                                border.color: _active ? Colors.accent : "transparent"
                                border.width: 1

                                Text {
                                    id: manualModeLabel
                                    anchors.centerIn: parent
                                    text: I18n.t("desktop.manual")
                                    color: parent._active ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontSmall
                                }

                                HoverHandler {}
                                TapHandler {
                                    onTapped: Globe2DSettings.setRotateMode("manual")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Alignment guides (drawn above proxies)
    Rectangle {
        visible: root._snapGuideX !== undefined
        x: root._snapGuideX !== undefined ? Math.round(root._snapGuideX) : 0
        y: 0
        width: Math.max(1, Math.round(UIScale.value))
        height: root.height
        color: Colors.accent
        opacity: 0.55
    }

    Rectangle {
        visible: root._snapGuideY !== undefined
        x: 0
        y: root._snapGuideY !== undefined ? Math.round(root._snapGuideY) : 0
        width: root.width
        height: Math.max(1, Math.round(UIScale.value))
        color: Colors.accent
        opacity: 0.55
    }

    // Widget catalog panel, left side
    Column {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: Math.round(UIScale.spacingLg)
        spacing: Math.round(UIScale.spacingXs)

        Repeater {
            model: DesktopWidgetCatalog.entries

            delegate: Rectangle {
                id: catalogRow
                required property var modelData
                required property int index

                property bool _on: DesktopWidgetStore.isEnabled(catalogRow.modelData.key)

                implicitWidth: catalogRowContent.implicitWidth + Math.round(UIScale.spacingMd * 2)
                implicitHeight: catalogRowContent.implicitHeight + Math.round(UIScale.spacingSm * 2)
                radius: height / 2
                color: catalogRow._on ? Colors.withAlpha(Colors.accent, 0.15) : Colors.surface

                Behavior on color {
                    ColorAnimation {
                        duration: 100
                    }
                }

                Row {
                    id: catalogRowContent
                    anchors.centerIn: parent
                    spacing: Math.round(UIScale.spacingSm)

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: catalogRow.modelData.label
                        color: catalogRow._on ? Colors.accent : Colors.textDim
                        font.pixelSize: UIScale.fontSmall

                        Behavior on color {
                            ColorAnimation {
                                duration: 100
                            }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: catalogRow._on ? "x" : "+"
                        color: catalogRow._on ? Colors.accent : Colors.textDim
                        font.pixelSize: UIScale.fontSmall
                        font.bold: true

                        Behavior on color {
                            ColorAnimation {
                                duration: 100
                            }
                        }
                    }
                }

                HoverHandler {}
                TapHandler {
                    onTapped: {
                        if (catalogRow._on)
                            DesktopWidgetStore.disableWidget(catalogRow.modelData.key);
                        else
                            DesktopWidgetStore.enableWidget(catalogRow.modelData.key);
                    }
                }
            }
        }
    }

    // HUD mode label, top centre
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.round(UIScale.spacingLg)
        implicitWidth: modeLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
        implicitHeight: modeLabel.implicitHeight + Math.round(UIScale.spacingSm * 2)
        radius: height / 2
        color: Colors.surface

        Text {
            id: modeLabel
            anchors.centerIn: parent
            text: I18n.t("desktop.widgetConfigMode")
            color: Colors.textDim
            font.pixelSize: UIScale.fontSmall
        }
    }

    // Controls, top right
    Row {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Math.round(UIScale.spacingLg)
        spacing: Math.round(UIScale.spacingSm)

        Rectangle {
            implicitWidth: snapLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
            implicitHeight: snapLabel.implicitHeight + Math.round(UIScale.spacingSm * 2)
            radius: height / 2
            color: root.snapEnabled ? Colors.withAlpha(Colors.accent, 0.18) : Colors.surface
            border.color: root.snapEnabled ? Colors.accent : "transparent"
            border.width: 1

            Behavior on color {
                ColorAnimation {
                    duration: 100
                }
            }

            Text {
                id: snapLabel
                anchors.centerIn: parent
                text: I18n.t("desktop.snap")
                color: root.snapEnabled ? Colors.accent : Colors.textDim
                font.pixelSize: UIScale.fontSmall

                Behavior on color {
                    ColorAnimation {
                        duration: 100
                    }
                }
            }

            HoverHandler {}
            TapHandler {
                onTapped: root.snapEnabled = !root.snapEnabled
            }
        }

        Rectangle {
            implicitWidth: doneLabel.implicitWidth + Math.round(UIScale.spacingMd * 2)
            implicitHeight: doneLabel.implicitHeight + Math.round(UIScale.spacingSm * 2)
            radius: height / 2
            color: doneHover.hovered ? Colors.accent : Colors.surface

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }

            Text {
                id: doneLabel
                anchors.centerIn: parent
                text: I18n.t("desktop.done")
                color: doneHover.hovered ? Colors.bg : Colors.text
                font.pixelSize: UIScale.fontSmall
                font.weight: Font.Medium

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }
            }

            HoverHandler {
                id: doneHover
            }
            TapHandler {
                onTapped: DesktopWidgetStore.configMode = false
            }
        }
    }
}
