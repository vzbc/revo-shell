import QtQuick
import qs.components
import QtQuick.Layouts
import Quickshell
import qs.services

PanelWindow {
  id: root
  implicitWidth: ScalerService.s(1000)
  implicitHeight: ScalerService.s(750)
  color: "transparent"

  PackageService{
    id: packageService
    simplePackage: false
  }

  property var diskList: null
  property var infoPackage: null
  property bool loaded: false
  property var indexPackages : 7
  property string currentView: "groups"
  property bool isGroups: currentView === "groups"
  property bool isPackages: currentView === "packages"
  property bool isPackageInfo: currentView === "packageInfo"

  // Proper color list for disks
  property var listColor: [
  theme.normal.red,
  theme.normal.green,
  theme.normal.blue,
  theme.normal.yellow,
  theme.normal.magenta,
  theme.normal.cyan,
  ]

  // Function to get color for a specific disk
  function getDiskColor(index) {
    return listColor[index % listColor.length]
  }
  function onBubbleClicked(index) {
    root.loaded = false
    if (isPackages) {
      packageService.getPackageInfo(
        root.diskList[index].name,

        function(data) {
          root.infoPackage = data
        }
      )
      currentView = "packageInfo"

      root.loaded = true
      return
    }

    const data = packageService.dataModel[index]

    if (!data || !data.packages)
    return

    currentView = "packages"

    root.diskList = data.packages

    Qt.callLater(function() {
        packCircles()
    })
  }

  property var circlePositions: []
  property real padding: ScalerService.s(6)
  property real packScale: 1.0

  Connections {
    target: packageService

    function onDataModelChanged() {
      if (packageService.dataModel && packageService.dataModel.length > 0) {
        diskList = [
        {"name":"Desktop","size":1},
        {"name":"Dev","size":1},
        {"name":"Libs","size":1},
        {"name":"Media","size":1},
        {"name":"Misc","size":1},
        {"name":"Network","size":1},
        {"name":"Misc","size":1},
        ]
        packCircles()
      }
    }
  }
  onWidthChanged: packCircles()
  onHeightChanged: packCircles()

  function packCircles() {
    root.loaded = false
    if (root.diskList === null) {
      return
    }
    const items = []

    for (let i = 0; i < diskList.length; i++) {
      const d = diskList[i]
      items.push({
          index: i,
          name: d.name,
          size: d.size,
          radius: 0,
          x: 0,
          y: 0
      })
    }

    const cx = root.width / 2
    const cy = root.height / 2

    const boundaryRadius =
    Math.min(root.width, root.height) / 2 - ScalerService.s(18)

    let totalSize = 0
    for (const item of items)
    totalSize += item.size

    // Scale to make total bubble area occupy most of the container
    const fillRatio = 0.72
    packScale = Math.sqrt((fillRatio * boundaryRadius * boundaryRadius) / totalSize)

    for (const item of items)
    item.radius = Math.sqrt(item.size) * packScale

    // Sort large -> small for better packing
    items.sort((a, b) => b.radius - a.radius)

    // Initial positions: slight spiral to avoid overlap from the start
    const goldenAngle = 137.507764 * Math.PI / 180
    for (let i = 0; i < items.length; i++) {
      const angle = i * goldenAngle
      const r = Math.sqrt(i + 1) * ScalerService.s(18)
      items[i].x = cx + Math.cos(angle) * r
      items[i].y = cy + Math.sin(angle) * r
    }

    // Multiple relaxation iterations
    for (let iter = 0; iter < 350; iter++) {
      // Push apart
      for (let i = 0; i < items.length; i++) {
        for (let j = i + 1; j < items.length; j++) {
          const a = items[i]
          const b = items[j]

          let dx = b.x - a.x
          let dy = b.y - a.y
          let dist = Math.sqrt(dx * dx + dy * dy)
          if (dist < 0.001) dist = 0.001

          const minDist = a.radius + b.radius + padding
          if (dist < minDist) {
            const overlap = minDist - dist
            const nx = dx / dist
            const ny = dy / dist

            a.x -= nx * overlap * 0.5
            a.y -= ny * overlap * 0.5
            b.x += nx * overlap * 0.5
            b.y += ny * overlap * 0.5
          }
        }
      }

      // Pull slightly toward center + keep within circular boundary
      for (const c of items) {
        c.x += (cx - c.x) * 0.002
        c.y += (cy - c.y) * 0.002

        let dx = c.x - cx
        let dy = c.y - cy
        let dist = Math.sqrt(dx * dx + dy * dy)
        if (dist < 0.001) dist = 0.001

        const maxDist = boundaryRadius - c.radius
        if (dist > maxDist) {
          c.x = cx + (dx / dist) * maxDist
          c.y = cy + (dy / dist) * maxDist
        }
      }
    }

    const positions = []
    for (const c of items) {
      positions[c.index] = {
        x: c.x - c.radius,
        y: c.y - c.radius,
        size: c.radius * 2
      }
    }

    circlePositions = positions
    root.loaded = true
  }

  Rectangle {
    anchors.fill: parent
    radius: ScalerService.s(Settings.appearance.radius1)
    border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0
    border.color: theme.primary.foreground
    color: theme.primary.background

    CustomText {
      anchors.centerIn: parent
      visible: !loaded
      name: "LOADING..."
      size: "2xl"
    }
    ColumnLayout {
      anchors.fill: parent
      Item {
        visible: !isGroups
        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(50)
        ButtonText{
          visible: loaded
          name: "Back"
          onClicked: {
            if (isPackages) {
              root.diskList = [
              {"name":"Desktop","size":1},
              {"name":"Dev","size":1},
              {"name":"Libs","size":1},
              {"name":"Media","size":1},
              {"name":"Misc","size":1},
              {"name":"Network","size":1},
              {"name":"Misc","size":1},
              ]
              packCircles()
              root.currentView = "groups"

            } else if (isPackageInfo) {
              root.currentView = "packages"

            }

          }
        }

      }
      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: loaded && !isPackageInfo
        Repeater {
          model: root.diskList

          Rectangle {
            id: bubble

            property var pos: root.circlePositions[index]
            property var diskColor:  getDiskColor(index)

            width: pos ? pos.size : ScalerService.s(10)
            height: pos ? pos.size : ScalerService.s(10)
            radius: width / 2
            border.width: ScalerService.s(2)
            border.color: theme.primary.foreground
            clip: true

            // Apply the color from listColor
            color: diskColor

            scale: mouseArea.containsMouse ? 1.1 : 1
            z: mouseArea.containsMouse ? 999 : index

            Behavior on scale {
              NumberAnimation {
                duration: 450
                easing.type: Easing.OutCubic
              }
            }

            visible: !modelData.name.startsWith("zram")

            x: (pos ? pos.x : parent.width / 2 - width / 2)
            y: (pos ? pos.y : parent.height / 2 - height / 2)

            SequentialAnimation on y {
              loops: Animation.Infinite
              running: true

              NumberAnimation {
                from: (pos ? pos.y : parent.height / 2 - height / 2) - ScalerService.s(8)
                to: (pos ? pos.y : parent.height / 2 - height / 2) + ScalerService.s(8)
                duration: 1800 + (index * 250)
                easing.type: Easing.InOutSine
              }
              NumberAnimation {
                from: (pos ? pos.y : parent.height / 2 - height / 2) + ScalerService.s(8)
                to: (pos ? pos.y : parent.height / 2 - height / 2) - ScalerService.s(8)
                duration: 1800 + (index * 250)
                easing.type: Easing.InOutSine
              }
            }

            Behavior on x {
              NumberAnimation {
                duration: 350
                easing.type: Easing.OutCubic
              }
            }

            Behavior on y {
              NumberAnimation {
                duration: 350
                easing.type: Easing.OutCubic
              }
            }

            ColumnLayout {
              anchors.centerIn: parent
              spacing: ScalerService.s(2)

              CustomText {
                width: pos ? pos.size * 0.8 : ScalerService.s(50)

                name: modelData.name
                textColor: theme.primary.background

                property var sizeText: Math.max(ScalerService.s(10), bubble.width * 0.1)

                font.pixelSize: mouseArea.containsMouse
                ? sizeText * 1.1
                : sizeText

                isBold: mouseArea.containsMouse

                horizontalAlignment: Text.AlignHCenter

                wrapMode: Text.WrapAnywhere
                maximumLineCount: 2
              }

              CustomText {
                visible: root.isPackages
                width: pos ? pos.size * 0.8 : ScalerService.s(50)

                property var sizeText: Math.max(ScalerService.s(8), bubble.width * 0.1)

                font.pixelSize: mouseArea.containsMouse
                ? sizeText * 1.1
                : sizeText

                textColor: theme.primary.background
                name: modelData.size + " MB"

                horizontalAlignment: Text.AlignHCenter

              }
            }

            MouseArea {
              id: mouseArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.onBubbleClicked(index)
            }
          }
        }

      }

      Item {
        visible: isPackageInfo
        Layout.fillWidth: true
        Layout.fillHeight: true

        Flickable {
          anchors.fill: parent

          contentWidth: width
          contentHeight: infoColumn.implicitHeight + ScalerService.s(40)

          clip: true

          ColumnLayout {
            id: infoColumn

            width: parent.width - ScalerService.s(40)

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: ScalerService.s(20)

            spacing: ScalerService.s(14)

            // =========================
            // Header
            // =========================
            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: contentHeader.implicitHeight + ScalerService.s(20)

              radius: ScalerService.s(16)

              color: theme.button.background
              border.width: ScalerService.s(2)
              border.color: theme.button.border

              RowLayout {
                anchors.fill: parent
                anchors.margins: ScalerService.s(18)

                ColumnLayout {
                  id: contentHeader
                  spacing: ScalerService.s(6)

                  CustomText {
                    name: root.infoPackage["Name"] || "Unknown"
                    size: "2xl"
                    isBold: true
                    textColor: theme.button.text
                  }

                  CustomText {
                    name: root.infoPackage["Description"] || ""
                    size: "normal"
                    textColor: theme.button.text
                  }
                }
              }
            }

            // =========================
            // Info Cards
            // =========================
            Repeater {
              model: [
              ["Version", root.infoPackage["Version"]],
              ["Architecture", root.infoPackage["Architecture"]],
              ["Installed Size", root.infoPackage["Installed Size"]],
              ["Build Date", root.infoPackage["Build Date"]],
              ["Install Date", root.infoPackage["Install Date"]],
              ["Packager", root.infoPackage["Packager"]],
              ["Install Reason", root.infoPackage["Install Reason"]],
              ["Validated By", root.infoPackage["Validated By"]],
              ["Licenses", root.infoPackage["Licenses"]],
              ["URL", root.infoPackage["URL"]]
              ]

              delegate: Rectangle {

                Layout.fillWidth: true

                implicitHeight: contentColumn.implicitHeight + ScalerService.s(20)

                radius: ScalerService.s(14)

                color: theme.button.background
                border.width: ScalerService.s(1)
                border.color: theme.button.border

                ColumnLayout {
                  id: contentColumn

                  anchors.fill: parent
                  anchors.margins: ScalerService.s(14)

                  spacing: ScalerService.s(6)

                  CustomText {
                    name: modelData[0]
                    size: "lg"
                    isBold: true
                    textColor: theme.button.text
                  }

                  CustomText {
                    Layout.fillWidth: true

                    name: modelData[1] || "None"

                    wrapMode: Text.WrapAnywhere

                    textColor: theme.button.text
                  }
                }
              }
            }

            // =========================
            // Dependencies
            // =========================
            Rectangle {

              Layout.fillWidth: true

              implicitHeight: depColumn.implicitHeight + ScalerService.s(20)

              radius: ScalerService.s(14)

              color: theme.button.background

              border.width: ScalerService.s(1)
              border.color: theme.button.border
              ColumnLayout {
                id: depColumn

                anchors.fill: parent
                anchors.margins: ScalerService.s(14)

                spacing: ScalerService.s(10)

                CustomText {
                  name: "Dependencies"
                  size: "xl"
                  isBold: true
                  textColor: theme.button.text
                }

                CustomText {
                  Layout.fillWidth: true

                  name: root.infoPackage["Depends On"] || "None"

                  wrapMode: Text.WrapAnywhere

                  textColor: theme.button.text
                }
              }
            }

            // =========================
            // Optional Dependencies
            // =========================
            Rectangle {

              Layout.fillWidth: true

              implicitHeight: optDepColumn.implicitHeight + ScalerService.s(20)

              radius: ScalerService.s(14)

              color: theme.button.background

              border.width: ScalerService.s(1)
              border.color: theme.button.border

              ColumnLayout {
                id: optDepColumn

                anchors.fill: parent
                anchors.margins: ScalerService.s(14)

                spacing: ScalerService.s(10)

                CustomText {
                  name: "Optional Dependencies"
                  size: "xl"
                  isBold: true
                  textColor: theme.button.text
                }

                CustomText {
                  Layout.fillWidth: true

                  name: root.infoPackage["Optional Deps"] || "None"

                  wrapMode: Text.WrapAnywhere

                  textColor: theme.button.text
                }
              }
            }
          }
        }
      }

    }
  }
}
