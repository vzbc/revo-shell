import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.bar
import qs.commons
import qs.services
import "." as Com

RowLayout {
    id: root
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
    Item {
        Layout.fillWidth: true
    }
    Item {
        Layout.preferredWidth: ScalerService.s(60)
        Layout.fillHeight: true
        Com.LauncherSection {
            animationProgress: root.animationProgress
        }
    }

    Item {
        Layout.fillWidth: true
    }
    Item {
        Layout.preferredWidth: Settings.bar.workspaceCount * ScalerService.s(38)
        Layout.fillHeight: true
        Com.WorkspaceSection {
            animationProgress: root.animationProgress
        }
    }

    Item {
        Layout.fillWidth: true
    }
    Item {
        Layout.preferredWidth: ScalerService.s(340)
        Layout.fillHeight: true
        Com.MediaSection {
            animationProgress: root.animationProgress
        }
    }

    Item {
        Layout.fillWidth: true
    }

    Item {
        Layout.preferredWidth: ScalerService.s(400)
        Layout.fillHeight: true
        Com.InfoSection {
            animationProgress: root.animationProgress
        }
    }
    Item {
        Layout.fillWidth: true
    }
    Item {
        Layout.preferredWidth: ScalerService.s(200)
        Layout.fillHeight: true
        Com.SystemStatsSection {
            animationProgress: root.animationProgress
        }
    }

    Item {
        Layout.fillWidth: true
    }
    Item {
        Layout.preferredWidth: ScalerService.s(430)
        Layout.fillHeight: true
        Com.StatusTraySection {
            animationProgress: root.animationProgress
        }
    }
    Item {
        Layout.fillWidth: true
    }
}
