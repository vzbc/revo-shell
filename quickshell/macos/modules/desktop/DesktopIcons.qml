import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Wayland
import "../common"

Scope {
    id: root

    PanelWindow {
        id: desktopWindow
        
        // ربط الشاشة باسمها الفعلي مباشرة بطريقة Quickshell الصحيحة
        screen: Quickshell.screens.find(function(s) { return s.name === "eDP-1"; }) || Quickshell.screens[0]
        
        anchors { top: true; bottom: true; left: true; right: true }
        
        // إعدادات الطبقة لضمان البقاء في الخلفية بشكل مستقر تماماً
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Bottom   // above the wallpaper daemon, below windows
        WlrLayershell.namespace: "desktop_icons"
        
        color: "transparent" // شفافة لكي تظهر خلفية جهازك الأساسية

        // Desktop & Dock › "Click wallpaper to reveal desktop": a click on the bare
        // wallpaper (this layer only gets clicks where no window is) toggles
        // show-desktop; "Only in Stage Manager" = off (there is no Stage Manager)
        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: {
                const mode = String(((Appearance.userCfg || {}).desktop || {}).clickWallpaper || "Always")
                if (mode === "Always")
                    Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/show_desktop.sh"])
            }
        }

        GridView {
            id: grid
            // Desktop & Dock › Show Items › On Desktop
            visible: ((Appearance.userCfg || {}).desktop || {}).showOnDesktop === true
            anchors.fill: parent
            anchors.topMargin: 80     // مسافة كافية لكي لا تتداخل الأيقونات مع الـ TopBar في الأعلى
            anchors.bottomMargin: 120  // مسافة كافية لكي لا تتداخل مع الـ Dock في الأسفل
            anchors.leftMargin: 50
            anchors.rightMargin: 50
            cellWidth: 120
            cellHeight: 120
            flow: GridView.FlowTopToBottom // ترتيب المجلدات عمودياً كالمعتاد

            model: FolderListModel {
                id: folderModel
                // مسار صريح ومباشر لمجلد سطح المكتب الخاص بك لتجنب مشاكل القراءة
                folder: "file://" + Quickshell.env("HOME") + "/Desktop"
                showDotAndDotDot: false
            }

            delegate: Item {
                width: grid.cellWidth
                height: grid.cellHeight

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    // تصميم مربع الأيقونة (مجلد أو ملف)
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 55
                        height: 55
                        color: fileIsDir ? "#4c566a" : "#81a1c1" // ألوان مؤقتة متناسقة مع مظهر النظام
                        radius: 10
                        opacity: 0.85
                    }

                    // اسم المجلد أو الملف
                    Text {
                        Layout.fillWidth: true
                        text: fileName
                        color: "white"
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.Wrap
                        // إضافة ظل خفيف للاسم ليكون مقروءاً فوق أي خلفية
                        style: Text.Outline
                        styleColor: "black"
                    }
                }

                // فتح العناصر عند الضغط المزدوج
                MouseArea {
                    anchors.fill: parent
                    onDoubleClicked: {
                        Quickshell.exec(["xdg-open", filePath])
                    }
                }
            }
        }
    }
}
