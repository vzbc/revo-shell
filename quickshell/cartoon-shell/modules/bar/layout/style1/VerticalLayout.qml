import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.bar
import qs.commons
import qs.services
import "." as Com

ColumnLayout {
    id: vertical
    property real animationProgress: 0
    SequentialAnimation on animationProgress {
        running: true
        NumberAnimation {
            from: 0
            to: 1
            duration: 500
            easing.type: Easing.Linear
        }
    }
    anchors.fill: parent

    // Top spacer
    Item {
        Layout.fillHeight: true
    }

    // LauncherSection (top section)
    Item {
        Layout.preferredHeight: ScalerService.s(40)
        Layout.fillWidth: true
        Com.LauncherSection {
            animationProgress: vertical.animationProgress
        }
    }

    // Spacer
    Item {
        Layout.fillHeight: true
    }

    // WorkspaceSection
    Item {
        Layout.preferredHeight: Settings.bar.workspaceCount * ScalerService.s(34)
        Layout.fillWidth: true
        Com.WorkspaceSection {
            animationProgress: vertical.animationProgress
        }
    }

    // Spacer
    Item {
        Layout.fillHeight: true
    }

    // MediaSection
    Item {
        Layout.preferredHeight: ScalerService.s(160)
        Layout.fillWidth: true
        Com.MediaSection {
            animationProgress: vertical.animationProgress
        }
    }

    // Spacer
    Item {
        Layout.fillHeight: true
    }

    // InfoSection
    Item {
        Layout.preferredHeight: ScalerService.s(150)
        Layout.fillWidth: true
        Com.InfoSection {
            animationProgress: vertical.animationProgress
        }
    }

    // Spacer
    Item {
        Layout.fillHeight: true
    }

    // SystemStatsSection
    Item {
        Layout.preferredHeight: ScalerService.s(100)
        Layout.fillWidth: true
        Com.SystemStatsSection {
            animationProgress: vertical.animationProgress
        }
    }

    // Spacer
    Item {
        Layout.fillHeight: true
    }

    // StatusTraySection (bottom section)
    Item {
        Layout.preferredHeight: ScalerService.s(220)
        Layout.fillWidth: true
        Com.StatusTraySection {
            animationProgress: vertical.animationProgress
        }
    }

    // Bottom spacer
    Item {
        Layout.fillHeight: true
    }
}
