import QtQuick
import QtQuick.Controls
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.win

/**
 * Windows 11 style tooltip.
 */
ToolTip {
    id: root
    property bool extraVisibleCondition: true
    property bool alternativeVisibleCondition: false

    readonly property bool internalVisibleCondition: (extraVisibleCondition && (parent.hovered === undefined || parent?.hovered)) || alternativeVisibleCondition
    verticalPadding: 6
    horizontalPadding: 10
    delay: 0
    visible: internalVisibleCondition

    font {
        family: Appearance.font.family.main
        variableAxes: Appearance.font.variableAxes.main
        pixelSize: Appearance?.font.pixelSize.smaller ?? 14
        hintingPreference: Font.PreferNoHinting // Prevent shaky text
    }

    background: Rectangle {
        radius: 4
        color: "#2d2d2d"
        border.width: 1
        border.color: WinTheme.border
    }

    contentItem: StyledText {
        text: root.text
        color: WinTheme.text
        wrapMode: Text.Wrap
    }
}
