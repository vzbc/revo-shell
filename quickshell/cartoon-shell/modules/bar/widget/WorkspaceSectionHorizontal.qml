import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.commons
import qs.components

RowLayout {
    id: root
    spacing: ScalerService.s(4)

    property real animationProgress: 1.0
    property bool isVertical: Settings.bar.position === "left" || Settings.bar.position === "right"
    readonly property var sizeIcon: ({
            "style1": "normal",
            "style2": "small",
            "style3": "small"
        })
    readonly property var sizeIconEmpty: ({
            "style1": "small",
            "style2": "xs",
            "style3": "xs"
        })
    readonly property var sizeImage: ({
            "style1": "normal",
            "style2": "small",
            "style3": "small"
        })
    readonly property var sizeRe: ({
            "style1": 32,
            "style2": 22,
            "style3": 22
        })
    readonly property var sizeNumber: ({
            "style1": "small",
            "style2": "xs",
            "style3": "xs"
        })
    readonly property var nameIcon: ({
            "pac_man": {
                "active": "󰮯",
                "exists": "󰊠",
                "empty": ""
            },
            "pokemon": {
                "active": "󰐝",
                "exists": "󰊠",
                "empty": ""
            }
        })
    readonly property var textNumber: ({
            "ja": {
                1: "一",
                2: "二",
                3: "三",
                4: "四",
                5: "五",
                6: "六",
                7: "七",
                8: "八",
                9: "九",
                10: "十"
            },
            "en": {
                1: "1",
                2: "2",
                3: "3",
                4: "4",
                5: "5",
                6: "6",
                7: "7",
                8: "8",
                9: "9",
                10: "10"
            },
            "ar": {
                1: "١",
                2: "٢",
                3: "٣",
                4: "٤",
                5: "٥",
                6: "٦",
                7: "٧",
                8: "٨",
                9: "٩",
                10: "١٠"
            },
            "hi": {
                1: "१",
                2: "२",
                3: "३",
                4: "४",
                5: "५",
                6: "६",
                7: "७",
                8: "८",
                9: "९",
                10: "१०"
            },
            "bn": {
                1: "১",
                2: "২",
                3: "৩",
                4: "৪",
                5: "৫",
                6: "৬",
                7: "৭",
                8: "৮",
                9: "৯",
                10: "১০"
            },
            "pa": {
                1: "੧",
                2: "੨",
                3: "੩",
                4: "੪",
                5: "੫",
                6: "੬",
                7: "੭",
                8: "੮",
                9: "੯",
                10: "੧੦"
            },
            "gu": {
                1: "૧",
                2: "૨",
                3: "૩",
                4: "૪",
                5: "૫",
                6: "૬",
                7: "૭",
                8: "૮",
                9: "૯",
                10: "૧૦"
            },
            "ta": {
                1: "௧",
                2: "௨",
                3: "௩",
                4: "௪",
                5: "௫",
                6: "௬",
                7: "௭",
                8: "௮",
                9: "௯",
                10: "௰"
            },
            "te": {
                1: "౧",
                2: "౨",
                3: "౩",
                4: "౪",
                5: "౫",
                6: "౬",
                7: "౭",
                8: "౮",
                9: "౯",
                10: "౧౦"
            },
            "kn": {
                1: "೧",
                2: "೨",
                3: "೩",
                4: "೪",
                5: "೫",
                6: "೬",
                7: "೭",
                8: "೮",
                9: "೯",
                10: "೧೦"
            },
            "ml": {
                1: "൧",
                2: "൨",
                3: "൩",
                4: "൪",
                5: "൫",
                6: "൬",
                7: "൭",
                8: "൮",
                9: "൯",
                10: "൰"
            },
            "th": {
                1: "๑",
                2: "๒",
                3: "๓",
                4: "๔",
                5: "๕",
                6: "๖",
                7: "๗",
                8: "๘",
                9: "๙",
                10: "๑๐"
            },
            "km": {
                1: "១",
                2: "២",
                3: "៣",
                4: "៤",
                5: "៥",
                6: "៦",
                7: "៧",
                8: "៨",
                9: "៩",
                10: "១០"
            },
            "lo": {
                1: "໑",
                2: "໒",
                3: "໓",
                4: "໔",
                5: "໕",
                6: "໖",
                7: "໗",
                8: "໘",
                9: "໙",
                10: "໑໐"
            },
            "my": {
                1: "၁",
                2: "၂",
                3: "၃",
                4: "၄",
                5: "၅",
                6: "၆",
                7: "၇",
                8: "၈",
                9: "၉",
                10: "၁၀"
            }
        })

    Repeater {
        model: CompositorService.uiWorkspaces
        Loader {
            required property var modelData
            Layout.alignment: Qt.AlignVCenter

            sourceComponent: Settings.bar.styleWorkspace === "icon" ? textIcon : Settings.bar.styleWorkspace === "image" ? imageIcon : numberText
        }
    }
    Component {
        id: imageIcon

        ButtonIconImage {
            size: sizeImage[Settings.bar.style ?? "normal"]
            opacity: root.animationProgress > 0.2 ? 1 : 0
            path: modelData.isActive || modelData.exists ? `workspace/${Settings.bar.iconWorkspace}/${modelData.isActive ? "active" : "exists"}.png` : "workspace/empty.png"

            onClicked: CompositorService.switchToWorkspaceById(modelData.id)

            onWheel: event => {
                CompositorService.handleScroll(event.angleDelta.y, event.angleDelta.x, root.isVertical);
            }
        }
    }
    Component {
        id: textIcon

        ButtonIconText {
            size: modelData.isActive || modelData.exists ? sizeIcon[Settings.bar.style ?? "normal"] : sizeIconEmpty[Settings.bar.style ?? "normal"]
            textColor: modelData.isActive ? theme.normal.yellow : (modelData.exists ? theme.normal.blue : theme.primary.dim_foreground)
            name: modelData.isActive ? nameIcon[Settings.bar.iconWorkspace]["active"] : (modelData.exists ? nameIcon[Settings.bar.iconWorkspace]["exists"] : nameIcon[Settings.bar.iconWorkspace]["empty"])
            fontFamily: "Symbols Nerd Font"
            implicitWidth: sizeRe[Settings.bar.style ?? "normal"]
            implicitHeight: sizeRe[Settings.bar.style ?? "normal"]
            onClicked: CompositorService.switchToWorkspaceById(modelData.id)

            onWheel: event => {
                CompositorService.handleScroll(event.angleDelta.y, event.angleDelta.x, root.isVertical);
            }
        }
    }
    Component {
        id: numberText
        ButtonText {
            size: sizeNumber[Settings.bar.style ?? "normal"]
            textColor: modelData.isActive ? theme.button.text : (modelData.exists ? theme.primary.foreground : theme.primary.dim_foreground)
            isBold: modelData.isActive || modelData.exists ? true : false
            implicitWidth: sizeRe[Settings.bar.style ?? "normal"]
            implicitHeight: sizeRe[Settings.bar.style ?? "normal"]
            color: "transparent"
            name: textNumber[Settings.bar.iconWorkspace]?.[modelData.id] ?? modelData.id.toString()
            border.width: 0
            onClicked: CompositorService.switchToWorkspaceById(modelData.id)

            onWheel: event => {
                CompositorService.handleScroll(event.angleDelta.y, event.angleDelta.x, root.isVertical);
            }
        }
    }
}
