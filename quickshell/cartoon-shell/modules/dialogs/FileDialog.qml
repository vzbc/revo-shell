import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import qs.components
import qs.services
import "./open_file" as Com

PanelWindow {
  id: root

  width: ScalerService.s(730)
  height: ScalerService.s(700)

  color: "transparent"

  property var theme: ThemeService.theme
  property url selectedFile: ""
  property int gridSize: ScalerService.s(100)  // Kích thước mỗi item
  property string currentPath: "file:///home/long/"
  signal fileOpened(url fileUrl)

  focusable: true

  FolderListModel {
    id: folderModel
    folder: currentPath
    showDirs: true
    showFiles: true
    showHidden: false
  }
  function show(action) {
    visible = true;
  }

  function hide() {
    visible = false;
  }

  // Function để lấy icon dựa trên loại file
  function getFileIcon(fileName, fileIsDir) {
    if (fileIsDir) return "filebrowser/folder.png"

    // Lấy extension
    const ext = fileName.split('.').pop().toLowerCase()

    const iconMap = {
      // Images
      'jpg': '🖼️', 'jpeg': '🖼️', 'png': '🖼️', 'gif': '🖼️', 'svg': '🖼️', 'webp': '🖼️',
      // Videos
      'mp4': 'video.png', 'mkv': 'video.png', 'avi': 'video.png', 'mov': 'video.png', 'webm': 'video.png',
      // Audio
      'mp3': 'audio.png', 'wav': 'audio.png', 'flac': 'audio.png', 'ogg': 'audio.png', 'm4a': 'audio.png',
      // Documents
      'pdf': 'file.png', 'doc': 'file.png', 'docx': 'file.png', 'txt': 'file.png', 'md': 'file.png',
      'xls': 'file.png', 'xlsx': 'file.png', 'ppt': 'file.png', 'pptx': 'file.png',
      // Code
      'js': 'file.png', 'py': 'file.png', 'html': 'file.png', 'css': 'file.png', 'cpp': 'file.png',
      'c': 'file.png', 'h': 'file.png', 'qml': 'file.png', 'json': 'file.png', 'xml': 'file.png',
      // Archives
      'zip': 'zip.png', 'rar': 'rar.png', 'tar': 'zip.png', 'gz': 'zip.png', '7z': 'zip.png',
      // Executables
      'exe': '⚡', 'msi': 'file.png', 'deb': 'file.png', 'rpm': 'file.png', 'AppImage': 'file.png',
      // Others
      'iso': 'file.png', 'torrent': 'file.png'
    }

    return "filebrowser/" + (iconMap[ext] ||"file.png")
  }

  Rectangle {
    anchors.fill: parent

    color: theme.primary.background
    radius: ScalerService.s(16)
    border.width: ScalerService.s(3)
    border.color: theme.primary.foreground
    // Navigation buttons
    ColumnLayout {
      anchors.fill: parent
      anchors.margins: ScalerService.s(20)
      spacing: ScalerService.s(16)

      Com.HeaderFileDialog{}
      RowLayout {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Com.SidebarLayout{}
        ColumnLayout {
          Layout.fillHeight: true
          Layout.fillWidth: true
          spacing: ScalerService.s(10)
          RowLayout {
            id: navBar
            Layout.fillWidth: true
            Layout.preferredHeight: ScalerService.s(30)
            spacing: ScalerService.s(10)

            Rectangle {
              Layout.fillHeight: true
              Layout.preferredWidth: ScalerService.s(70)
              color: theme.button.background
              border.width: ScalerService.s(2)
              border.color: theme.button.border
              radius: ScalerService.s(8)
              RowLayout {
                anchors.margins: ScalerService.s(20)
                IconText{
                  name: "arrow_back"
                  size: "small"
                }
                CustomText {
                  name: "back"
                  size: "small"
                }
              }
              MouseArea {
                id: mouseAreaBack
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                  if (folderModel.parentFolder !== "") {
                    currentPath = folderModel.parentFolder
                    folderModel.folder = currentPath
                  }
                }
              }
            }

            Com.SearchFile{
              currentPath: root.currentPath

            }
          }

          // Grid View for files/folders
          Item {
            Layout.fillWidth: true
            Layout.preferredHeight: ScalerService.s(420)

            Com.GridView {
              id: gridViewComponent
              anchors.fill: parent
              folderModel: folderModel
              gridSize: root.gridSize
              currentPath: root.currentPath
              theme: root.theme

              onFileSelected: function(fileUrl) {
                root.selectedFile = fileUrl
              }

              onFolderChanged: function(newPath) {
                root.currentPath = newPath
                folderModel.folder = currentPath
              }

              onPathFieldChanged: function(path) {
                // Update path field if needed
              }
            }

          }

          // Status bar
        }
      }
      Com.StatusBar{
        id: statusBar

        selectedFile: root.selectedFile

        onFileOpened: function(fileUrl) {
          root.fileOpened(fileUrl)
          root.hide()
        }
      }
    }
  }
  // Helper functions
  function formatFileSize(bytes) {
    if (bytes === 0) return "0 B"
    const k = 1024
    const sizes = ["B", "KB", "MB", "GB", "TB"]
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return (bytes / Math.pow(k, i)).toFixed(1) + " " + sizes[i]
  }

  function environmentVariable(name) {
    // Simple function to get env var - you might need to implement this properly
    switch(name) {
      case "USER": return "long"
      default: return ""
    }
  }

  // Keyboard navigation
  Shortcut {
    sequence: "Backspace"
    onActivated: {
      if (folderModel.parentFolder !== "") {
        currentPath = folderModel.parentFolder
        folderModel.folder = currentPath
      }
    }
  }

  Shortcut {
    sequence: "Escape"
    onActivated: root.close()
  }

  // Zoom controls (Ctrl +/Ctrl -)

  Component.onCompleted: {
    folderModel.folder = currentPath
  }
}
