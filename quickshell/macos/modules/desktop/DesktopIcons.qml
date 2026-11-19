import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell

Scope {
    id: root

    PanelWindow {
        id: desktopWindow
        
        // ربط الشاشة باسمها الفعلي مباشرة بطريقة Quickshell الصحيحة
        screen: Quickshell.screens.find(function(s) { return s.name === "eDP-1"; })
        
        anchors.fill: parent
        
        // إعدادات الطبقة لضمان البقاء في الخلفية بشكل مستقر تماماً
        WlrLayershell.exclusionMode: WlrLayershell.ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayershell.Layer.Background
        WlrLayershell.namespace: "desktop_icons"
        
        color: "transparent" // شفافة لكي تظهر خلفية جهازك الأساسية

        GridView {
            id: grid
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
                folder: "file:///home/revo/Desktop"
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
