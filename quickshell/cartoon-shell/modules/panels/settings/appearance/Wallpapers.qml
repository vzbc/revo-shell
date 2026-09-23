import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Qt.labs.folderlistmodel
import Qt.labs.platform
import qs.services
import qs.components
import qs.commons

Item {
    id: root

    // Animation progress tương tự mẫu
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

    // System & Path Properties
    property string homePath: Directories.home
    property url currentPath: "file://" + Directories.home + "/Pictures/Wallpapers/"
    property string currentWallpaper: ""
    property int currentScreenIndex: 0
    property var currentScreen: Quickshell.screens[currentScreenIndex] || null

    // State cho Modal Xem Chi Tiết & Xác Nhận Xóa
    property var selectedItem: null
    property bool showDetailModal: false
    property bool showDeleteConfirmModal: false

    // Helper chuẩn hóa đường dẫn
    function normalizePath(path) {
        if (!path)
            return "";
        return path.toString().replace(/^file:\/\//, "");
    }

    // Model duyệt danh sách file/folder
    FolderListModel {
        id: folderModel
        folder: root.currentPath
        showDirs: true
        showFiles: true
        showHidden: false
        showDirsFirst: true
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.bmp", "*.webp", "*.gif", "*.mp4", "*.webm", "*.mkv", "*.avi", "*.mov"]
        sortField: FolderListModel.Name
        caseSensitive: false
    }

    // ListView cấu hình giống form mẫu
    ListView {
        id: scrollView
        anchors.fill: parent
        clip: true
        anchors.margins: ScalerService.s(20)

        // Vuốt cảm ứng & hiệu ứng mượt
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds
        focus: true

        // Tính chiều cao nội dung theo Layout
        contentHeight: mainLayout.implicitHeight

        model: 1
        delegate: ColumnLayout {
            id: mainLayout
            width: scrollView.width
            spacing: ScalerService.s(20)

            // Header Section
            HeaderSettings {
                name: root.lang?.wallpapers?.title || "Wallpapers"
            }

            // Separator
            Rectangle {
                Layout.fillWidth: true
                height: ScalerService.s(1)
                color: theme.primary.foreground
                opacity: 0.2
                Layout.bottomMargin: ScalerService.s(5)
            }

            // Path & Navigation Header
            RowLayout {
                Layout.fillWidth: true
                spacing: ScalerService.s(10)

                Rectangle {
                    Layout.preferredHeight: ScalerService.s(36)
                    Layout.fillWidth: true
                    radius: ScalerService.s(8)
                    color: theme.button.background
                    border.color: theme.button.border
                    border.width: ScalerService.s(1)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: ScalerService.s(12)
                        anchors.rightMargin: ScalerService.s(12)
                        spacing: ScalerService.s(8)

                        CustomText {
                            name: "Total Items:"
                            textColor: theme.primary.dim_foreground
                            size: "small"
                        }

                        CustomText {
                            name: folderModel.count
                            textColor: theme.normal.blue
                            size: "small"
                            isBold: true
                        }

                        CustomText {
                            name: "|"
                            textColor: theme.primary.dim_foreground
                            size: "small"
                        }

                        CustomText {
                            name: normalizePath(folderModel.folder)
                            textColor: theme.primary.foreground
                            size: "small"
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // Display Selector
            RowLayout {
                Layout.fillWidth: true
                spacing: ScalerService.s(8)

                Repeater {
                    model: Quickshell.screens

                    delegate: Rectangle {
                        Layout.preferredWidth: ScalerService.s(110)
                        Layout.preferredHeight: ScalerService.s(32)
                        radius: ScalerService.s(6)
                        color: root.currentScreenIndex === index ? theme.normal.blue : theme.button.background
                        border.color: theme.button.border
                        border.width: ScalerService.s(1)

                        CustomText {
                            anchors.centerIn: parent
                            name: modelData.name || `Display ${index + 1}`
                            textColor: root.currentScreenIndex === index ? theme.primary.background : theme.primary.foreground
                            size: "small"
                            isBold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentScreenIndex = index
                        }
                    }
                }
            }

            // Wallpapers Grid View
            Grid {
                id: wallpapersGrid
                Layout.fillWidth: true
                columns: 3
                columnSpacing: ScalerService.s(12)
                rowSpacing: ScalerService.s(12)

                Repeater {
                    model: folderModel

                    delegate: Rectangle {
                        width: (mainLayout.width - ScalerService.s(24)) / 3
                        height: width * 0.85
                        color: Qt.alpha(theme.button.background, 0.5)
                        border.color: theme.button.border
                        radius: ScalerService.s(Settings.appearance.radius3)
                        border.width: Settings.appearance.enableBorder ? (isSelected ? ScalerService.s(2) : ScalerService.s(1)) : 0
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: ScalerService.s(8)
                            spacing: ScalerService.s(6)

                            // Thumbnail Preview
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: ScalerService.s(Settings.appearance.radius3)
                                clip: true
                                color: folderModel.isFolder(index) ? Qt.alpha(theme.normal.blue, 0.15) : "transparent"

                                Text {
                                    visible: folderModel.isFolder(index)
                                    anchors.centerIn: parent
                                    text: "🖿"
                                    font.pixelSize: ScalerService.s(42)
                                }

                                Image {
                                    id: previewImg
                                    visible: !folderModel.isFolder(index)
                                    anchors.fill: parent
                                    source: fileUrl
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                    smooth: true
                                }

                                Rectangle {
                                    visible: isVideoFile(fileName) && !folderModel.isFolder(index)
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.margins: ScalerService.s(6)
                                    width: ScalerService.s(22)
                                    height: ScalerService.s(22)
                                    radius: ScalerService.s(11)
                                    color: theme.normal.magenta

                                    Text {
                                        text: "▶"
                                        color: theme.primary.background
                                        font.pixelSize: ScalerService.s(10)
                                        font.bold: true
                                        anchors.centerIn: parent
                                    }
                                }

                                Rectangle {
                                    visible: !folderModel.isFolder(index) && normalizePath(fileUrl) === root.currentWallpaper
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: ScalerService.s(6)
                                    width: ScalerService.s(22)
                                    height: ScalerService.s(22)
                                    radius: ScalerService.s(11)
                                    color: theme.normal.green

                                    Text {
                                        text: "✓"
                                        color: theme.primary.background
                                        font.pixelSize: ScalerService.s(10)
                                        font.bold: true
                                        anchors.centerIn: parent
                                    }
                                }
                            }

                            // Filename
                            Text {
                                text: fileName
                                color: theme.primary.foreground
                                font.pixelSize: ScalerService.s(11)
                                elide: Text.ElideMiddle
                                Layout.fillWidth: true
                            }

                            // Actions Bar
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: ScalerService.s(4)
                                visible: !folderModel.isFolder(index)

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: ScalerService.s(24)
                                    radius: ScalerService.s(4)
                                    color: normalizePath(fileUrl) === root.currentWallpaper ? theme.normal.green : theme.normal.blue

                                    CustomText {
                                        anchors.centerIn: parent
                                        name: normalizePath(fileUrl) === root.currentWallpaper ? "Applied" : "Apply"
                                        textColor: theme.primary.background
                                        size: "xs"
                                        isBold: true
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            SoundService.playSound("pick");
                                            setWallpaper(fileUrl);
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.preferredWidth: ScalerService.s(24)
                                    height: ScalerService.s(24)
                                    radius: ScalerService.s(4)
                                    color: theme.button.background
                                    border.color: theme.button.border

                                    Text {
                                        anchors.centerIn: parent
                                        text: "ℹ"
                                        color: theme.primary.foreground
                                        font.pixelSize: ScalerService.s(11)
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            SoundService.playSound("pick");
                                            root.selectedItem = {
                                                index: index,
                                                name: fileName,
                                                url: fileUrl,
                                                path: normalizePath(fileUrl),
                                                size: fileSize,
                                                modified: fileModified,
                                                width: previewImg.sourceSize.width,
                                                height: previewImg.sourceSize.height,
                                                isVideo: isVideoFile(fileName)
                                            };
                                            root.showDetailModal = true;
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.preferredWidth: ScalerService.s(24)
                                    height: ScalerService.s(24)
                                    radius: ScalerService.s(4)
                                    color: theme.normal.red

                                    Text {
                                        anchors.centerIn: parent
                                        text: "🗑"
                                        color: theme.primary.background
                                        font.pixelSize: ScalerService.s(11)
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            SoundService.playSound("pick");
                                            root.selectedItem = {
                                                index: index,
                                                name: fileName,
                                                url: fileUrl
                                            };
                                            root.showDeleteConfirmModal = true;
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: folderModel.isFolder(index)
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentPath = fileUrl
                        }
                    }
                }
            }

            // Empty State
            Text {
                visible: folderModel.count === 0 && folderModel.status === FolderListModel.Ready
                text: "No images or directories found in the current location."
                color: theme.primary.dim_foreground
                font.pixelSize: ScalerService.s(13)
                Layout.alignment: Qt.AlignCenter
            }

            // Spacer
            Item {
                Layout.fillHeight: true
                Layout.minimumHeight: ScalerService.s(20)
            }
        }
    }

    // Modal Details View
    Rectangle {
        id: detailModal
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.7)
        visible: root.showDetailModal
        z: 2000

        MouseArea {
            anchors.fill: parent
        }

        Rectangle {
            anchors.centerIn: parent
            width: ScalerService.s(440)
            height: ScalerService.s(380)
            radius: ScalerService.s(12)
            color: theme.primary.background
            border.color: theme.button.border
            border.width: ScalerService.s(1)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: ScalerService.s(20)
                spacing: ScalerService.s(10)

                Text {
                    text: "🛈 File Details"
                    color: theme.normal.blue
                    font.pixelSize: ScalerService.s(16)
                    font.bold: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: ScalerService.s(1)
                    color: theme.button.border
                }

                Image {
                    Layout.preferredHeight: ScalerService.s(110)
                    Layout.fillWidth: true
                    source: root.selectedItem ? root.selectedItem.url : ""
                    fillMode: Image.PreserveAspectFit
                    horizontalAlignment: Image.AlignHCenter
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: ScalerService.s(4)

                    Text {
                        text: "File Name: " + (root.selectedItem ? root.selectedItem.name : "")
                        color: theme.primary.foreground
                        font.pixelSize: ScalerService.s(12)
                        elide: Text.ElideMiddle
                        Layout.fillWidth: true
                    }
                    Text {
                        text: "Path: " + (root.selectedItem ? root.selectedItem.path : "")
                        color: theme.primary.dim_foreground
                        font.pixelSize: ScalerService.s(11)
                        elide: Text.ElideMiddle
                        Layout.fillWidth: true
                    }
                    Text {
                        text: "File Size: " + (root.selectedItem ? formatBytes(root.selectedItem.size) : "")
                        color: theme.primary.foreground
                        font.pixelSize: ScalerService.s(12)
                    }
                    Text {
                        text: "Resolution: " + (root.selectedItem && root.selectedItem.width ? root.selectedItem.width + " x " + root.selectedItem.height + " px" : "N/A")
                        color: theme.primary.foreground
                        font.pixelSize: ScalerService.s(12)
                    }
                    Text {
                        text: "Last Modified: " + (root.selectedItem && root.selectedItem.modified ? root.selectedItem.modified.toLocaleString() : "N/A")
                        color: theme.primary.foreground
                        font.pixelSize: ScalerService.s(12)
                    }
                }

                Item {
                    Layout.fillHeight: true
                }

                Rectangle {
                    Layout.preferredWidth: ScalerService.s(90)
                    Layout.preferredHeight: ScalerService.s(30)
                    Layout.alignment: Qt.AlignRight
                    radius: ScalerService.s(6)
                    color: theme.button.background
                    border.color: theme.button.border

                    Text {
                        anchors.centerIn: parent
                        text: "Close"
                        color: theme.primary.foreground
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.showDetailModal = false
                    }
                }
            }
        }
    }

    // Modal Confirm Delete
    Rectangle {
        id: deleteModal
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.7)
        visible: root.showDeleteConfirmModal
        z: 2000

        MouseArea {
            anchors.fill: parent
        }

        Rectangle {
            anchors.centerIn: parent
            width: ScalerService.s(360)
            height: ScalerService.s(160)
            radius: ScalerService.s(12)
            color: theme.primary.background
            border.color: theme.normal.red
            border.width: ScalerService.s(1)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: ScalerService.s(18)
                spacing: ScalerService.s(12)

                Text {
                    text: "⚠️ Confirm Deletion"
                    color: theme.normal.red
                    font.pixelSize: ScalerService.s(15)
                    font.bold: true
                }

                Text {
                    text: "Are you sure you want to delete: " + (root.selectedItem ? root.selectedItem.name : "") + "?"
                    color: theme.primary.foreground
                    font.pixelSize: ScalerService.s(12)
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: ScalerService.s(8)

                    Rectangle {
                        Layout.preferredWidth: ScalerService.s(75)
                        Layout.preferredHeight: ScalerService.s(30)
                        radius: ScalerService.s(6)
                        color: theme.button.background

                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            color: theme.primary.foreground
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.showDeleteConfirmModal = false
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: ScalerService.s(75)
                        Layout.preferredHeight: ScalerService.s(30)
                        radius: ScalerService.s(6)
                        color: theme.normal.red

                        Text {
                            anchors.centerIn: parent
                            text: "Delete"
                            color: theme.primary.background
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.selectedItem) {
                                    deleteFile(root.selectedItem.url);
                                }
                                root.showDeleteConfirmModal = false;
                            }
                        }
                    }
                }
            }
        }
    }

    // Toast Notification
    Rectangle {
        id: successNotification
        visible: false
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: ScalerService.s(20)
        width: ScalerService.s(260)
        height: ScalerService.s(40)
        radius: ScalerService.s(8)
        color: theme.normal.green
        z: 3000

        Row {
            anchors.centerIn: parent
            spacing: ScalerService.s(8)
            CustomText {
                name: "✓"
                color: theme.primary.background
                isBold: true
                size: "small"
            }
            CustomText {
                id: notificationText
                textColor: theme.primary.background
                name: ""
                isBold: true
                size: "small"
            }
        }

        Timer {
            id: notificationTimer
            interval: 3000
            onTriggered: successNotification.visible = false
        }
    }

    // Helper Functions
    function deleteFile(filePath) {
        if (!filePath)
            return;
        var cleanPath = normalizePath(filePath);
        var success = File.remove(cleanPath);

        if (success) {
            showNotification("File deleted successfully!");
        } else {
            showNotification("Failed to delete file!");
        }
    }

    function setWallpaper(filePath) {
        Settings.wallpaper.shaders = Math.floor(Math.random() * 4);
        var cleanPath = normalizePath(filePath);

        if (Settings.wallpaper.setWallpaperOnAllMonitors) {
            for (var i = 0; i < Quickshell.screens.length; i++) {
                WallpaperService.changeWallpaper(cleanPath, Quickshell.screens[i].name);
            }
        } else {
            var screen = root.currentScreen;
            if (screen) {
                WallpaperService.changeWallpaper(cleanPath, screen.name);
            } else if (Quickshell.screens.length > 0) {
                WallpaperService.changeWallpaper(cleanPath, Quickshell.screens[0].name);
            }
        }

        showNotification("Wallpaper applied!");
        root.currentWallpaper = cleanPath;
    }

    function formatBytes(bytes) {
        if (!bytes || bytes === 0)
            return '0 Bytes';
        var k = 1024;
        var sizes = ['Bytes', 'KB', 'MB', 'GB'];
        var i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    }

    function isVideoFile(fileName) {
        if (!fileName)
            return false;
        var ext = fileName.toLowerCase().split('.').pop();
        return ["mp4", "webm", "mkv", "avi", "mov", "flv", "wmv", "m4v", "mpg", "mpeg"].indexOf(ext) !== -1;
    }

    function showNotification(message) {
        notificationText.text = message;
        successNotification.visible = true;
        notificationTimer.start();
    }

    Component.onCompleted: {
        if (currentScreen) {
            var wallpaper = WallpaperService.getWallpaper(currentScreen.name);
            root.currentWallpaper = normalizePath(wallpaper);
        }
    }
}
