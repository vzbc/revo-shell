import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.services
import qs.components

Rectangle {
  id: passwordBox
  property var wifiManager
  property var networkData

  property bool showPassword: false
  property bool hasError: false
  property string errorMessage: ""
  property bool hasSavedPassword: networkData.saved_password && networkData.saved_password !== "--" && networkData.saved_password !== ""
  property bool isConnected: networkData.ssid === wifiManager.connectedWifi

  color: theme.primary.dim_background
  radius: ScalerService.s(12)
  border.width: ScalerService.s(2)
  border.color: theme.button.border_select

  Behavior on height {
    NumberAnimation {
      duration: 200
    }
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: ScalerService.s(12)
    spacing: ScalerService.s(8)

    Rectangle {
      Layout.fillWidth: true
      height: ScalerService.s(30)
      visible: passwordBox.hasError
      color: theme.normal.red
      radius: ScalerService.s(6)
      Text {
        anchors.centerIn: parent
        text: "❌ " + passwordBox.errorMessage
        color: theme.primary.foreground
        font.pixelSize: ScalerService.s(12)
        font.family: "ComicShannsMono Nerd Font"
      }
    }

    // Phần hiển thị mật khẩu đã lưu (luôn hiển thị nếu có saved password)
    RowLayout {
      Layout.fillWidth: true
      spacing: ScalerService.s(8)
      visible: passwordBox.hasSavedPassword || networkData.security === "--"

      Rectangle {
        Layout.fillWidth: true
        height: ScalerService.s(40)
        color: theme.primary.background
        radius: ScalerService.s(8)
        border.color: theme.button.border_select
        visible: networkData.security !== "--"
        border.width: ScalerService.s(1)

        Text {
          anchors.centerIn: parent
          text: passwordBox.showPassword ? networkData.saved_password : "••••••••"
          font.family: "ComicShannsMono Nerd Font"
          color: theme.primary.foreground
          font.pixelSize: ScalerService.s(14)
        }
      }

      ButtonText {
        name: passwordBox.showPassword ? "visibility" : "visibility_off"
        size: "xs"
        implicitHeight: ScalerService.s(30)
        fontFamily: "Material Symbols Rounded"
        visible: networkData.security !== "--"
        onClicked: {
          passwordBox.showPassword = !passwordBox.showPassword;
        }
      }

      ButtonText {
        name: lang?.wifi?.connect || "Kết nối"
        size: "xs"
        implicitHeight: ScalerService.s(30)
        visible: !networkData.isConnected

        onClicked: {
          // Kết nối với mật khẩu đã lưu
          wifiManager.connectToWifi(networkData.ssid, networkData.saved_password);

          Qt.callLater(function () {
              if (wifiManager.connectionError) {
                passwordBox.hasError = true;
                passwordBox.errorMessage = lang?.wifi?.wrong_password || "Mật khẩu không đúng";
                // Nếu sai mật khẩu, xóa saved password để người dùng nhập lại
                networkData.saved_password = "";
                passwordBox.hasSavedPassword = false;
              }
          });
        }
      }

      ButtonText {
        name: lang?.wifi?.forget || "Quên"
        size: "xs"
        implicitHeight: ScalerService.s(30)
        visible: networkData.isConnected
        onClicked: {
          wifiManager.forgetPassword(networkData.ssid);
          passwordBox.hasSavedPassword = false;
          networkData.saved_password = "";
          wifiManager.openSsid = "";
          wifiManager.scanWifiNetworks();
        }
      }
    }

    // Phần nhập mật khẩu mới (khi chưa có saved password)
    RowLayout {
      Layout.fillWidth: true
      spacing: ScalerService.s(8)
      visible: !passwordBox.hasSavedPassword && networkData.security !== "--"

      TextField {
        id: wifiPassword
        Layout.fillWidth: true
        placeholderText: networkData.security === "Open" ? (lang?.wifi?.no_password || "Không cần mật khẩu") : (lang?.wifi?.enter_password || "Nhập mật khẩu")
        echoMode: passwordBox.showPassword ? TextInput.Normal : TextInput.Password
        enabled: networkData.security !== "Open"
        font.family: "ComicShannsMono Nerd Font"
        font.pixelSize: ScalerService.s(14)
        horizontalAlignment: TextInput.AlignHCenter
        color: theme.primary.foreground
        background: Rectangle {
          color: theme.primary.background
          radius: ScalerService.s(8)
          border.color: theme.button.border_select
          border.width: ScalerService.s(1)
        }

        onActiveFocusChanged: {
          wifiManager.userTyping = activeFocus;
        }
      }

      ButtonText {
        name: passwordBox.showPassword ? "visibility" : "visibility_off"
        size: "xs"
        implicitHeight: ScalerService.s(30)
        fontFamily: "Material Symbols Rounded"
        onClicked: {
          passwordBox.showPassword = !passwordBox.showPassword;
        }
      }

      ButtonText {
        name: lang?.wifi?.connect || "Kết nối"
        size: "xs"
        implicitHeight: ScalerService.s(30)
        onClicked: {
          var password = wifiPassword.text.trim();

          if (password.length === 0 && networkData.security !== "Open" && networkData.security !== "--")
          {
            passwordBox.hasError = true;
            passwordBox.errorMessage = lang?.wifi?.password_required || "Vui lòng nhập mật khẩu";
            return;
          }

          passwordBox.hasError = false;
          passwordBox.errorMessage = "";

          wifiManager.connectToWifi(networkData.ssid, password);

          Qt.callLater(function () {
              if (wifiManager.connectionError) {
                passwordBox.hasError = true;
                passwordBox.errorMessage = lang?.wifi?.wrong_password || "Mật khẩu không đúng";
              } else {
                // Lưu mật khẩu sau khi kết nối thành công
                if (password) {
                  networkData.saved_password = password;
                  passwordBox.hasSavedPassword = true;
                }
                wifiManager.openSsid = "";
              }
          });

          wifiPassword.text = "";
        }
      }
    }
  }
}
