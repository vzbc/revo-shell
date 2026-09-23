import QtQuick
import QtQuick.Controls
import qs.modules.common
import qs.modules.win

/**
 * Windows 11 style settings text area.
 */
TextArea {
    id: root
    renderType: Text.QtRendering

    color: WinTheme.text
    selectionColor: WinTheme.accentDark
    selectedTextColor: WinTheme.text
    placeholderTextColor: WinTheme.textTertiary
    padding: 8

    background: Rectangle {
        implicitHeight: 60
        radius: 4
        color: WinTheme.bgAlt
        border.width: 1
        border.color: root.activeFocus ? WinTheme.accent : WinTheme.border

        Behavior on border.color {
            ColorAnimation { duration: 120 }
        }
    }

    font {
        family: Appearance.font.family.main
        pixelSize: Appearance?.font.pixelSize.small ?? 15
        hintingPreference: Font.PreferFullHinting
        variableAxes: Appearance.font.variableAxes.main
    }
    wrapMode: TextEdit.Wrap
}
