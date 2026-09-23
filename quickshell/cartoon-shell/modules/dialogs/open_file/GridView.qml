import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.folderlistmodel
import qs.components
import qs.commons
import qs.services

Item {
  id: root
  property var folderModel
  property int gridSize: ScalerService.s(100)
  property url currentPath
  property var theme: ThemeService.theme
  property var selectedFile: ""

  signal fileSelected(url fileUrl)
  signal folderChanged(url newPath)
  signal pathFieldChanged(string path)

  function checkImage(ext) {
    return ext === 'jpg' || ext === 'jpeg' || ext === 'png' || ext === 'gif'

  }
  // Function để lấy icon dựa trên loại file
  function getFileIcon(fileName, fileIsDir,fileDir) {
    if (fileIsDir) {
      const iconFolder = {
        'Downloads' : "downloads.png", 'Pictures' : 'pictures', 'Documents' : 'documents'
      }
      return Directories.assetsPath + "/filebrowser/" + (iconFolder[fileName] || "folder.png")
    }

    const ext = fileName.split('.').pop().toLowerCase()
    if (checkImage(ext)) {
      return fileDir;
    }

    const iconMap = {
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

    return Directories.assetsPath + "/filebrowser/" + (iconMap[ext] || "file.png")
  }

  function formatFileSize(bytes) {
    if (bytes === 0) return "0 B"
    const k = 1024
    const sizes = ["B", "KB", "MB", "GB", "TB"]
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return (bytes / Math.pow(k, i)).toFixed(1) + " " + sizes[i]
  }

  ScrollView {
    anchors.fill: parent
    clip: true

    GridView {
      id: gridView
      anchors.fill: parent
      model: folderModel
      cellWidth: gridSize
      cellHeight: gridSize + ScalerService.s(30)

      property var currentIndex: -1

      delegate: Item {
        width: gridSize
        height: gridSize + ScalerService.s(30)

        Rectangle {
          clip: true
          id: itemBg
          anchors.fill: parent
          anchors.margins: ScalerService.s(5)
          radius: ScalerService.s(8)
          color: theme.button.background
          border.width: root.selectedFile === fileUrl  ? ScalerService.s(3) : ScalerService.s(1)
          border.color: root.selectedFile === fileUrl ? theme.button.text : theme.button.border

          ColumnLayout {
            anchors.centerIn: parent
            spacing: ScalerService.s(5)

            Image {
              id: itemIcon
              Layout.alignment: Qt.AlignHCenter

              source: getFileIcon(fileName, fileIsDir,fileUrl)
              Layout.preferredWidth: ScalerService.s(52)
              Layout.preferredHeight: ScalerService.s(52)
              fillMode: Image.PreserveAspectFit
              asynchronous: true
              cache: false
              smooth: true
              mipmap: true

            }

            CustomText {
              name: fileName
              Layout.alignment: Qt.AlignHCenter
              elide: Text.ElideRight
              horizontalAlignment: Text.AlignHCenter
              wrapMode: Text.WordWrap
              maximumLineCount: 2
              Layout.maximumWidth: gridSize - ScalerService.s(10)
              size: "xs"
            }

            Text {
              visible: !fileIsDir && fileSize > 0
              Layout.alignment: Qt.AlignHCenter
              text: formatFileSize(fileSize)
              color: theme.button.text
              font.pixelSize: ScalerService.s(9)
            }
          }
        }

        MouseArea {
          id: itemMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor

          onEntered: gridView.currentIndex = index
          onExited: {
            if (gridView.currentIndex === index)
            gridView.currentIndex = -1
          }
          onClicked: {
            root.selectedFile = fileUrl
            fileSelected(fileUrl)
          }

          onDoubleClicked: {
            if (fileIsDir) {
              folderChanged(fileUrl)
              pathFieldChanged(fileUrl.toString().replace("file://", ""))
            } else {
              fileSelected(fileUrl)
            }
          }
        }
      }
    }
  }

  // Keyboard navigation
  Shortcut {
    sequence: "Return"
    enabled: gridView.currentIndex >= 0 && gridView.visible
    onActivated: {
      const item = folderModel.get(gridView.currentIndex)
      if (item && item.fileIsDir) {
        folderChanged(item.fileURL)
        pathFieldChanged(item.fileURL.toString().replace("file://", ""))
      } else if (item) {
        fileSelected(item.fileURL)
      }
    }
  }

  function getCurrentIndex() {
    return gridView.currentIndex
  }

  function setCurrentIndex(index) {
    gridView.currentIndex = index
  }

  function getCurrentItem() {
    if (gridView.currentIndex >= 0) {
      return folderModel.get(gridView.currentIndex)
    }
    return null
  }
  Shortcut {
    sequence: "Ctrl++"
    onActivated: {
      gridSize = Math.min(gridSize + ScalerService.s(20), ScalerService.s(200))
    }
  }

  Shortcut {
    sequence: "Ctrl+-"
    onActivated: {
      gridSize = Math.max(gridSize - ScalerService.s(20), ScalerService.s(60))
    }
  }

}
