import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.commons

PanelWindow {
  id: root

  property var lang: LanguageService.translations
  property var theme: ThemeService.theme

  property string pendingAction: ""
  property string pendingActionLabel: ""

  implicitWidth: ScalerService.s(380)
  implicitHeight: ScalerService.s(200)

  anchors {
    top: true
    left: true
  }
  margins {
    top: screen ? Math.round((screen.height - implicitHeight) / 2) : 0
    left: screen ? Math.round((screen.width - implicitWidth) / 2) : 0
  }

  exclusiveZone: 0
  visible: false
  color: "transparent"

  Process {
    id: sleepProcess
  }
  Process {
    id: lockProcess
  }
  Process {
    id: logoutProcess
  }
  Process {
    id: restartProcess
  }
  Process {
    id: shutdownProcess
  }

  function show(action, actionLabel) {
    pendingAction = action;
    pendingActionLabel = actionLabel;
    visible = true;
  }

  function hide() {
    visible = false;
    pendingAction = "";
    pendingActionLabel = "";
  }

  function executeAction() {
    switch (pendingAction) {
      case "sleep":
      sleepProcess.command = [
      "sh",
      "-c",
      "systemctl suspend && qs ipc --path ~/.config/quickshell/cartoon-shell/ call lock lock"
      ];
      sleepProcess.startDetached();
      break;
      case "lock":
      lockProcess.command = [
      "qs",
      "ipc",
      "--path",
      Directories.home + "/.config/quickshell/cartoon-shell/",
      "call",
      "lock",
      "lock"
      ]
      lockProcess.startDetached();
      break;
      case "logout":
      logoutProcess.command = ["hyprctl", "dispatch", "exit"];
      logoutProcess.startDetached();
      break;
      case "restart":
      restartProcess.command = ["systemctl", "reboot"];
      restartProcess.startDetached();
      break;
      case "shutdown":
      shutdownProcess.command = ["systemctl", "poweroff"];
      shutdownProcess.startDetached();
      break;
    }
    hide();
  }

  Rectangle {
    anchors.fill: parent
    radius: ScalerService.s(15)
    color: theme.primary.background
    border.color: theme.normal.black
    border.width: ScalerService.s(3)

    Column {
      anchors.fill: parent
      anchors.margins: ScalerService.s(25)
      spacing: ScalerService.s(20)

      Text {
        text: lang?.confirm?.title || "Xác nhận"
        color: theme.primary.foreground
        font.pixelSize: ScalerService.s(24)
        font.bold: true
        font.family: "ComicShannsMono Nerd Font"
        anchors.horizontalCenter: parent.horizontalCenter
      }

      Text {
        text: (lang?.confirm?.message || "Bạn có chắc chắn muốn {action}?").replace("{action}", pendingActionLabel)
        color: theme.primary.foreground
        font.pixelSize: ScalerService.s(16)
        font.family: "ComicShannsMono Nerd Font"
        wrapMode: Text.WordWrap
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
      }

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: ScalerService.s(30)

        Rectangle {
          width: ScalerService.s(110)
          height: ScalerService.s(45)
          radius: ScalerService.s(10)
          color: mouseAreaNo.containsMouse ? theme.button.background_select : theme.button.background
          border.color: theme.button.border
          border.width: ScalerService.s(2)

          Text {
            anchors.centerIn: parent
            text: lang?.confirm?.no || "Không"
            color: theme.primary.foreground
            font.pixelSize: ScalerService.s(18)
            font.family: "ComicShannsMono Nerd Font"
          }

          MouseArea {
            id: mouseAreaNo
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: hide()
          }
        }

        Rectangle {
          width: ScalerService.s(110)
          height: ScalerService.s(45)
          radius: ScalerService.s(10)
          color: mouseAreaYes.containsMouse ? theme.normal.red : theme.button.background
          border.color: theme.normal.red
          border.width: ScalerService.s(2)

          Text {
            anchors.centerIn: parent
            text: lang?.confirm?.yes || "Có"
            color: mouseAreaYes.containsMouse ? "white" : theme.primary.foreground
            font.pixelSize: ScalerService.s(18)
            font.family: "ComicShannsMono Nerd Font"
            font.bold: true
          }

          MouseArea {
            id: mouseAreaYes
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: executeAction()
          }
        }
      }
    }
  }

  Shortcut {
    sequence: "Escape"
    onActivated: hide()
  }
}
