import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.components
import qs.commons

Rectangle {
    id: container
    radius: ScalerService.s(Settings.appearance.radius2)
    color: Qt.alpha(theme.primary.dim_background, 0.6)
    border.color: theme.button.border
    border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0

    property real animationProgress: 0
    property var apps: []
    property var allApps: []
    property string lastQuery: ""
    property string selectedCategory: "All"
    property int currentIndex: 0

    // Danh sách tất cả các Category hiển thị trên giao diện
    readonly property var categoryList: ["All", "Accessories", "Programming", "Graphics", "Internet", "Office", "Sound & Video", "System", "Preferences", "Other"]

    function getAppCategory(desktopEntry) {
        if (!desktopEntry || !desktopEntry.categories)
            return "Other";

        const cats = desktopEntry.categories;

        if (cats.includes("Utility"))
            return "Accessories";
        if (cats.includes("Development"))
            return "Programming";
        if (cats.includes("Graphics"))
            return "Graphics";
        if (cats.includes("Network"))
            return "Internet";
        if (cats.includes("Office"))
            return "Office";
        if (cats.includes("AudioVideo") || cats.includes("Audio") || cats.includes("Video"))
            return "Sound & Video";
        if (cats.includes("System"))
            return "System";
        if (cats.includes("Settings"))
            return "Preferences";

        return "Other";
    }

    signal appLaunched

    Repeater {
        id: appRepeater
        model: DesktopEntries.applications

        Item {
            Component.onCompleted: {
                container.allApps.push({
                    name: modelData.name || "",
                    comment: modelData.comment || "",
                    icon: modelData.icon || "",
                    exec: modelData.execString || "",
                    category: container.getAppCategory(modelData),
                    entry: modelData
                });
            }
        }
    }

    Component.onCompleted: {
        Qt.callLater(function () {
            container.allApps.sort(function (a, b) {
                return a.name.toLowerCase().localeCompare(b.name.toLowerCase());
            });
            container.filterApps();
        });
    }

    // Hàm lọc ứng dụng kết hợp cả Tìm kiếm và Danh mục
    function filterApps() {
        var q = container.lastQuery.toLowerCase();
        var cat = container.selectedCategory;

        var filtered = container.allApps.filter(function (app) {
            // Lọc theo Category
            var matchCategory = (cat === "All") || (app.category === cat);
            if (!matchCategory)
                return false;

            // Nếu không gõ từ khóa tìm kiếm -> Giữ lại tất cả app thuộc category đó
            if (q.length === 0)
                return true;

            // Lọc theo Search Query
            var name = (app.name || "").toLowerCase();
            var comment = (app.comment || "").toLowerCase();
            var exec = (app.exec || "").toLowerCase();

            var match = name.indexOf(q) >= 0 || comment.indexOf(q) >= 0 || exec.indexOf(q) >= 0;

            if (!match && exec) {
                var execParts = exec.split(' ');
                if (execParts.length > 0) {
                    var executableName = execParts[0];
                    var lastSlash = executableName.lastIndexOf('/');
                    if (lastSlash >= 0) {
                        executableName = executableName.substring(lastSlash + 1);
                    }
                    match = executableName.toLowerCase().indexOf(q) >= 0;
                }
            }

            return match;
        });

        container.apps = filtered;
        container.currentIndex = 0;
    }

    function runSearch(query) {
        if (query === undefined || query === null)
            query = "";
        container.lastQuery = query;
        container.filterApps();
    }

    ColumnLayout {
        id: rootLayout
        anchors.fill: parent
        anchors.margins: ScalerService.s(8)
        spacing: ScalerService.s(6)

        // --- Bổ sung: Thanh chọn Category dạng Tab nằm ngang ---
        ListView {
            id: categoryView
            Layout.fillWidth: true
            Layout.preferredHeight: ScalerService.s(36)
            clip: true
            orientation: ListView.Horizontal  // Đổi sang cuộn ngang
            spacing: ScalerService.s(6)
            model: container.categoryList

            // Bật tính năng vuốt chạm và cuộn bằng chuột
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                required property string modelData
                required property int index

                implicitWidth: catText.implicitWidth + ScalerService.s(16)
                height: ScalerService.s(30)
                radius: ScalerService.s(Settings.appearance.radius3)

                color: container.selectedCategory === modelData ? theme.button.background_select : theme.button.background
                border.color: container.selectedCategory === modelData ? theme.button.border_select : "transparent"
                border.width: Settings.appearance.enableBorder ? ScalerService.s(1) : 0

                CustomText {
                    id: catText
                    anchors.centerIn: parent
                    name: modelData
                    size: "xs"
                    isBold: true
                    textColor: container.selectedCategory === modelData ? theme.button.text : theme.primary.dim_foreground
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        SoundService.playSound("pick");
                        container.selectedCategory = modelData;
                        container.filterApps();
                        categoryView.currentIndex = index;
                    }
                    onEntered: {
                        SoundService.playSound("hover");
                    }
                }
            }
        }

        // --- Danh sách Apps ---
        ListView {
            id: appList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: ScalerService.s(4)
            model: container.apps
            currentIndex: container.currentIndex
            focus: true
            keyNavigationWraps: true

            delegate: Rectangle {
                width: ListView.view.width
                height: ScalerService.s(56)
                radius: ScalerService.s(Settings.appearance.radius3)
                color: (ListView.isCurrentItem || mouseArea.containsMouse) ? theme.button.background_select : "transparent"
                border.color: (ListView.isCurrentItem || mouseArea.containsMouse) ? theme.button.border_select : "transparent"
                border.width: Settings.appearance.enableBorder ? ScalerService.s(1) : 0

                opacity: 0

                SequentialAnimation on opacity {
                    running: animationProgress > 0.5

                    PauseAnimation {
                        duration: index * 15
                    }

                    NumberAnimation {
                        to: 1
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: ScalerService.s(8)
                    spacing: ScalerService.s(10)

                    Image {
                        Layout.preferredWidth: ScalerService.s(36)
                        Layout.preferredHeight: ScalerService.s(36)
                        fillMode: Image.PreserveAspectFit
                        source: modelData.icon ? "image://icon/" + modelData.icon : ""
                        asynchronous: true
                        opacity: 0

                        SequentialAnimation on opacity {
                            running: animationProgress > 0.6

                            PauseAnimation {
                                duration: index * 15
                            }

                            NumberAnimation {
                                to: 1
                                duration: 200
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    ColumnLayout {
                        spacing: ScalerService.s(2)

                        CustomText {
                            name: modelData.name || "Unknown"
                            size: "small"
                            elide: Text.ElideRight
                            opacity: 0

                            SequentialAnimation on opacity {
                                running: animationProgress > 0.7

                                PauseAnimation {
                                    duration: index * 15
                                }

                                NumberAnimation {
                                    to: 1
                                    duration: 200
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                        CustomText {
                            name: modelData.comment || modelData.category || ""
                            size: "xs"
                            elide: Text.ElideRight
                            textColor: theme.button.text
                            opacity: 0

                            SequentialAnimation on opacity {
                                running: animationProgress > 0.8

                                PauseAnimation {
                                    duration: index * 15
                                }

                                NumberAnimation {
                                    to: 1
                                    duration: 200
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData && modelData.entry) {
                            modelData.entry.execute();
                            VisibleService.closeAllPanels();
                        }
                    }
                    onEntered: {
                        SoundService.playSound("hover");
                        if (ListView.view) {
                            ListView.view.currentIndex = index;
                        }
                    }
                }
            }
        }

        CustomText {
            visible: container.apps.length === 0
            name: "Không có kết quả"
            anchors.centerIn: parent
        }
    }

    Shortcut {
        sequence: "Tab"
        onActivated: {
            if (container.apps.length > 0) {
                container.currentIndex = (container.currentIndex + 1) % container.apps.length;
                appList.currentIndex = container.currentIndex;
            }
        }
    }

    Shortcut {
        sequence: "Up"
        onActivated: {
            if (container.apps.length > 0) {
                container.currentIndex = Math.max(container.currentIndex - 1, 0);
                appList.currentIndex = container.currentIndex;
            }
        }
    }

    Shortcut {
        sequence: "Down"
        onActivated: {
            if (container.apps.length > 0) {
                container.currentIndex = (container.currentIndex + 1) % container.apps.length;
                appList.currentIndex = container.currentIndex;
            }
        }
    }

    Shortcut {
        sequence: "Return"
        onActivated: {
            if (container.apps.length > 0 && container.currentIndex < container.apps.length) {
                var item = container.apps[container.currentIndex];
                if (item && item.entry) {
                    item.entry.execute();
                    VisibleService.closeAllPanels();
                }
            }
        }
    }
}
