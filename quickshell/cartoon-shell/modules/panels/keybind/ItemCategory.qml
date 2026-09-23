import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

Item {
  id: root

  property var categoryData: null

  implicitHeight: columnLayout.implicitHeight
  implicitWidth: ScalerService.s(400)

  function parseKey(keyText) {
    var parts = keyText.split("+").map(p => p.trim())
    var result = []
    for (var i = 0; i < parts.length; i++) {
      if (parts[i] === "SUPER") {
        result.push({ type: "icon", value: "window" })
      } else {
        result.push({ type: "text", value: parts[i] })
      }
      if (i < parts.length - 1) {
        result.push({ type: "separator", value: "+" })
      }
    }
    return result
  }

  ColumnLayout {
    id: columnLayout
    anchors {
      fill: parent
      margins: ScalerService.s(10)
    }
    spacing: ScalerService.s(10)

    // Category Header
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: ScalerService.s(45)
      color: Qt.alpha(theme.primary.dim_background,0.5)
      radius: ScalerService.s(8)

      RowLayout {
        anchors {
          left: parent.left
          leftMargin: ScalerService.s(10)
          verticalCenter: parent.verticalCenter
        }
        spacing: ScalerService.s(6)

        CustomText {
          text:  root.categoryData.title
          isBold: true
          textColor: theme.button.text
        }
      }
    }

    // Shortcut items
    ColumnLayout {
      Layout.fillWidth: true
      spacing: ScalerService.s(8)

      Repeater {
        id: shortcutsRepeater
        model: root.categoryData ? root.categoryData.shortcuts : []

        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: ScalerService.s(36)

          RowLayout {
            anchors.fill: parent
            spacing: ScalerService.s(6)

            RowLayout {
              spacing: ScalerService.s(3)

              Repeater {
                model: parseKey(modelData.key)

                Loader {
                  sourceComponent: {
                    if (modelData.type === "icon") {
                      return iconComp
                    } else if (modelData.type === "separator") {
                      return separatorComp
                    } else {
                      return textComp
                    }
                  }

                  Component {
                    id: iconComp
                    IconText {
                      name: modelData.value
                      size: "small"
                    }
                  }

                  Component {
                    id: separatorComp
                    CustomText {
                      text: modelData.value
                      size: "small"
                      textColor: theme.primary.dim_foreground
                    }
                  }

                  Component {
                    id: textComp
                    CustomText {
                      text: modelData.value
                      size: "small"
                      isBold: true
                    }
                  }
                }
              }
            }

            Item {
              Layout.fillWidth: true
            }

            CustomText {
              text: modelData.action
              size: "small"
              textColor: theme.primary.foreground
              wrapMode: Text.WordWrap
              Layout.alignment: Qt.AlignVCenter
            }
          }
        }
      }
    }
  }
}
