pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../"

Item {
    id: root

    function focusSearch() {
        searchField.forceActiveFocus();
    }

    property var _filtered: {
        var q = searchField.text.trim().toLowerCase();
        if (!q)
            return KeybindService.sections;
        return KeybindService.sections.map(sec => ({
                    name: sec.name,
                    icon: sec.icon,
                    binds: sec.binds.filter(b => b.label.toLowerCase().includes(q) || b.keys.join(" ").toLowerCase().includes(q))
                })).filter(sec => sec.binds.length > 0);
    }

    // Card background
    Rectangle {
        anchors.fill: parent
        radius: UIScale.radiusLg
        color: Colors.bg
        border.color: Colors.outline
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: UIScale.spacingLg
            spacing: UIScale.spacingMd

            // Search bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.round(40 * UIScale.value)
                radius: UIScale.radiusMd
                color: Colors.surface
                border.color: searchField.activeFocus ? Colors.accent : Colors.outline
                border.width: 1
                Behavior on border.color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Math.round(12 * UIScale.value)
                    anchors.rightMargin: Math.round(12 * UIScale.value)
                    spacing: UIScale.spacingSm

                    Text {
                        text: "󰍉"
                        color: Colors.textDim
                        font.pixelSize: Math.round(16 * UIScale.value)
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.round(24 * UIScale.value)

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: Math.round(2 * UIScale.value)
                            text: I18n.t("keybinds.searchPlaceholder")
                            color: Colors.textDim
                            font.pixelSize: UIScale.fontBody
                            verticalAlignment: Text.AlignVCenter
                            visible: searchField.text.length === 0
                        }

                        TextInput {
                            id: searchField
                            anchors.fill: parent
                            color: Colors.text
                            font.pixelSize: UIScale.fontBody
                            verticalAlignment: TextInput.AlignVCenter
                            Keys.onEscapePressed: {
                                if (text.length > 0)
                                    clear();
                                else
                                    KeybindService.popupOpen = false;
                            }
                        }
                    }
                }
            }

            // Section cards
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: cardsFlow.implicitHeight
                clip: true

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                Flow {
                    id: cardsFlow
                    width: parent.width
                    spacing: Math.round(10 * UIScale.value)

                    Repeater {
                        model: root._filtered

                        delegate: Rectangle {
                            id: sectionCard
                            required property var modelData

                            width: Math.round(270 * UIScale.value)
                            height: cardCol.height + Math.round(24 * UIScale.value)
                            radius: Math.round(12 * UIScale.value)
                            color: Colors.surface

                            Column {
                                id: cardCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: Math.round(12 * UIScale.value)
                                spacing: Math.round(6 * UIScale.value)

                                // Header
                                Row {
                                    spacing: Math.round(7 * UIScale.value)

                                    Text {
                                        text: sectionCard.modelData.icon
                                        color: Colors.accent
                                        font.pixelSize: Math.round(15 * UIScale.value)
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: sectionCard.modelData.name
                                        color: Colors.text
                                        font.pixelSize: UIScale.fontSmall
                                        font.weight: Font.DemiBold
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                // Divider
                                Rectangle {
                                    width: parent.width
                                    height: 1
                                    color: Colors.outline
                                }

                                // Bind rows
                                Repeater {
                                    model: sectionCard.modelData.binds

                                    delegate: Item {
                                        id: brow
                                        required property var modelData

                                        width: cardCol.width
                                        height: Math.round(22 * UIScale.value)

                                        Row {
                                            id: chips
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: Math.round(2 * UIScale.value)

                                            Repeater {
                                                model: {
                                                    var flat = [];
                                                    var ks = brow.modelData.keys;
                                                    for (var ki = 0; ki < ks.length; ki++) {
                                                        if (ki > 0)
                                                            flat.push("+");
                                                        flat.push(ks[ki]);
                                                    }
                                                    return flat;
                                                }

                                                delegate: Rectangle {
                                                    required property string modelData
                                                    required property int index

                                                    property bool isSep: modelData === "+"

                                                    radius: Math.round(3 * UIScale.value)
                                                    color: isSep ? "transparent" : Colors.withAlpha(Colors.text, 0.07)
                                                    border.color: isSep ? "transparent" : Colors.outline
                                                    border.width: 1
                                                    implicitWidth: chipTxt.implicitWidth + (isSep ? Math.round(2 * UIScale.value) : Math.round(10 * UIScale.value))
                                                    height: Math.round(18 * UIScale.value)

                                                    Text {
                                                        id: chipTxt
                                                        anchors.centerIn: parent
                                                        text: parent.modelData
                                                        color: parent.isSep ? Colors.textDim : Colors.text
                                                        font.pixelSize: UIScale.fontCaption
                                                        font.weight: Font.Medium
                                                        font.family: "monospace"
                                                    }
                                                }
                                            }
                                        }

                                        Text {
                                            anchors.left: chips.right
                                            anchors.leftMargin: UIScale.spacingSm
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: brow.modelData.label
                                            color: Colors.textDim
                                            font.pixelSize: UIScale.fontCaption
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Empty state
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root._filtered.length === 0 && KeybindService.sections.length > 0

                Text {
                    anchors.centerIn: parent
                    text: I18n.t("keybinds.noMatch")
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontBody
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: KeybindService.sections.length === 0

                Text {
                    anchors.centerIn: parent
                    text: I18n.t("keybinds.noCompositorConfig")
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontBody
                }
            }
        }
    }
}
