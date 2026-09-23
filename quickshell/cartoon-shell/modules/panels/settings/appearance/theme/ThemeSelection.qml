import QtQuick
import QtQuick.Layouts
import "." as Com
import qs.services
import qs.commons
import qs.components

RowLayout {
    id: themeSelection
    spacing: ScalerService.s(12)

    CustomText {
        name: lang.appearance?.theme_label || "Chủ đề:"
        size: "small"
        isBold: true
        Layout.preferredWidth: ScalerService.s(150)
    }

    Row {
        spacing: ScalerService.s(12)
        Layout.fillWidth: true

        // Light Theme Card
        Com.ThemeCard {
            type: "light"
            isSelected: theme.type === "light"
            label: lang.appearance?.theme_light || "Sáng"
            onClicked: {
                // Set theme to matugen and mode to light
                Settings.appearance.theme = "matugen";
                Settings.appearance.dynamic = true;
                Settings.appearance.mode = "light";
            }
        }

        // Dark Theme Card
        Com.ThemeCard {
            type: "dark"
            isSelected: theme.type === "dark"
            label: lang.appearance?.theme_dark || "Tối"
            onClicked: {
                Settings.appearance.theme = "matugen";
                Settings.appearance.dynamic = true;
                Settings.appearance.mode = "dark";
            }
        }
    }
}
