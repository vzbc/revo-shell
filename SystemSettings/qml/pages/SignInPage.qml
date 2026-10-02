import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import ".."

Column {
    id: page

    property string pageId: "appleId"
    property string accountName: ""
    property string accountEmail: ""

    signal navigate(string pageId)
    signal signedIn(string email, string name)
    signal signedOut

    // email | password (signed-out), account view when signed in
    readonly property string view: accountEmail.length > 0 ? "account" : authState

    property string authState: "email"
    property string emailInput: ""
    property string passInput: ""

    property int rev: 0
    readonly property string avatarPath: { rev; return String(Shell.uget("avatarPath", "")) }
    readonly property string avatarDir: "/home/revo/.local/share/systemsettings/"

    function pathFromFileUrl(u) {
        var s = String(u)
        if (s.indexOf("file://") === 0)
            s = s.slice(7)
        try { s = decodeURIComponent(s) } catch (e) {}
        return s
    }

    function deriveName(email) {
        var local = email.split("@")[0]
        var part = local.split(/[._\-0-9]/)[0]
        if (part.length === 0)
            return local
        return part.charAt(0).toUpperCase() + part.slice(1)
    }

    function doContinue() {
        if (authState === "email") {
            authState = "password"
            passInput = ""
            input.text = ""
            input.forceActiveFocus()
        } else {
            var em = emailInput
            signedIn(em, deriveName(em))
            authState = "email"
            emailInput = ""
            passInput = ""
            input.text = ""
        }
    }

    width: parent ? parent.width : 500
    spacing: 0

    Popup {
        id: confirmSignOut
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        width: 340
        height: signCol.implicitHeight + 40
        anchors.centerIn: Overlay.overlay

        background: Rectangle {
            radius: 12
            color: Theme.menuBg
            border.width: 1
            border.color: Theme.menuBorder
        }

        Column {
            id: signCol
            width: parent.width - 40
            x: 20
            y: 20
            spacing: 6

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "Sign Out of your Apple Account?"
                wrapMode: Text.WordWrap
                font { family: Theme.fontText; pixelSize: 14; weight: Font.DemiBold }
                color: Theme.textPrimary
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: "This removes your account from System Settings. Files and data on this Mac are kept."
                font { family: Theme.fontText; pixelSize: 12 }
                color: Theme.textSecondary
            }

            Item { width: 1; height: 8 }

            Row {
                width: parent.width
                spacing: 8

                MacButton {
                    width: (parent.width - 8) / 2
                    text: "Cancel"
                    onClicked: confirmSignOut.close()
                }
                MacButton {
                    width: (parent.width - 8) / 2
                    text: "Sign Out"
                    primary: true
                    onClicked: {
                        confirmSignOut.close()
                        page.signedOut()
                        authState = "email"
                        emailInput = ""
                        passInput = ""
                        input.text = ""
                    }
                }
            }
        }
    }

    // ===== Signed-out flow =====
    Column {
        visible: page.view !== "account"
        width: parent.width
        spacing: 0

        Item { width: 1; height: 14 }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "\uF8FF"
            font { family: "SF Pro"; pixelSize: 46 }
            color: Theme.btnText
        }

        Item { width: 1; height: 10 }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "Sign in with Your Apple Account"
            font { family: "SF Pro Display"; pixelSize: 20; weight: Font.Bold }
            color: Theme.btnText
        }

        Item { width: 1; height: 8 }

        Text {
            width: Math.min(400, parent.width - 40)
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: page.authState === "password"
                  ? "Enter your password for " + page.emailInput + "."
                  : "Enter your Apple Account to use iCloud, the App Store, and more."
            font { family: "SF Pro Text"; pixelSize: 13 }
            color: Theme.textSecondary
        }

        Item { width: 1; height: 18 }

        // Field box: label left, input right
        Rectangle {
            width: 430
            height: 25
            anchors.horizontalCenter: parent.horizontalCenter
            radius: 6
            color: Theme.checkBg
            border.width: 1
            border.color: Theme.checkBorder

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: page.authState === "password" ? "Password" : "Email or Phone"
                font { family: "SF Pro Text"; pixelSize: 13 }
                color: Theme.textSecondary
            }

            TextInput {
                id: input
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 250
                horizontalAlignment: TextInput.AlignRight
                clip: true
                font { family: "SF Pro Text"; pixelSize: 13 }
                color: Theme.btnText
                echoMode: page.authState === "password" ? TextInput.Password : TextInput.Normal
                selectByMouse: true

                onTextChanged: {
                    if (page.authState === "email")
                        emailInput = text
                    else
                        passInput = text
                }

                onAccepted: page.doContinue()

                Text {
                    visible: !input.text && !input.activeFocus
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: page.authState === "password" ? "Required" : ""
                    font { family: "SF Pro Text"; pixelSize: 13 }
                    color: Theme.btnTextDisabled
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.IBeamCursor
                onClicked: input.forceActiveFocus()
            }
        }

        Item { width: 1; height: 10 }

        // Continue button (right)
        Row {
            width: 430
            anchors.horizontalCenter: parent.horizontalCenter
            layoutDirection: Qt.RightToLeft

            MacButton {
                id: continueBtn
                text: "Continue"
                primary: true
                btnEnabled: page.authState === "password" ? passInput.length > 0 : emailInput.length > 0
                onClicked: page.doContinue()
            }
        }

        Item { width: 1; height: 14 }

        BlueLink {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
            label: "See how your data is managed…"
            font.pixelSize: 13
            onClicked: {}
        }

        Item { width: 1; height: 18 }

        // Bottom row: Forgot password? — Create Apple Account ?
        Row {
            width: 430
            anchors.horizontalCenter: parent.horizontalCenter
            layoutDirection: Qt.RightToLeft
            spacing: 14

            HelpCircle { anchors.verticalCenter: parent.verticalCenter; onClicked: {} }

            BlueLink {
                anchors.verticalCenter: parent.verticalCenter
                label: "Create Apple Account"
                onClicked: {}
            }

            Item { width: 1; height: 1 }

            BlueLink {
                anchors.verticalCenter: parent.verticalCenter
                label: "Forgot password?"
                onClicked: {}
            }
        }

        Item { width: 1; height: 8 }
    }

    // ===== Signed-in account =====
    Column {
        visible: page.view === "account"
        width: parent.width
        spacing: 12

        // Header card
        Rectangle {
            x: 12
            width: parent.width - 24
            radius: 10
            color: Theme.cardBg
            height: headerCol.implicitHeight + 48

            Column {
                id: headerCol
                width: parent.width
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Item { width: 1; height: 24 }

                Avatar {
                    size: 84
                    avatarPath: page.avatarPath
                    editable: true
                    anchors.horizontalCenter: parent.horizontalCenter
                    onEditClicked: avatarDlg.open()
                }

                Item { width: 1; height: 10 }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: page.accountName
                    font { family: "SF Pro Display"; pixelSize: 19; weight: Font.DemiBold }
                    color: Theme.btnText
                }

                Item { width: 1; height: 3 }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: page.accountEmail
                    font { family: "SF Pro Text"; pixelSize: 13 }
                    color: Theme.textSecondary
                }

                Item { width: 1; height: 24 }
            }
        }

        GroupCard {
            DetailRow {
                title: "Account Photo"
                subtitle: "Use your own picture for this Apple Account."
                value: page.avatarPath.length > 0 ? "Custom" : "Default"
                pickerOptions: ["Default", "Choose Image\u2026"]
                onPicked: (v) => {
                    if (v.indexOf("Choose") === 0) {
                        avatarDlg.open()
                        return
                    }
                    if (page.avatarPath.length > 0)
                        Shell.run("rm -f '" + page.avatarPath + "'")
                    Shell.uset("avatarPath", "")
                    console.log("AVATAR_RESET")
                    page.rev++
                }
            }
            DetailRow {
                separator: true
                title: "Personal Information"
                iconFile: "dt_personal-info"
                chevron: true
                onClicked: page.navigate("acct.personalInfo")
            }
            DetailRow {
                separator: true
                title: "Sign-In & Security"
                iconFile: "dt_security"
                chevron: true
                onClicked: page.navigate("acct.security")
            }
            DetailRow {
                separator: true
                title: "Payment & Shipping"
                iconFile: "dt_payment"
                chevron: true
                onClicked: page.navigate("acct.payment")
            }
        }

        GroupCard {
            DetailRow {
                title: "iCloud"
                iconFile: "dt_icloud"
                chevron: true
                onClicked: page.navigate("icloud")
            }
            DetailRow {
                separator: true
                title: "Family"
                iconFile: "dt_family"
                chevron: true
                onClicked: page.navigate("acct.family")
            }
            DetailRow {
                separator: true
                title: "Media & Purchases"
                iconFile: "dt_media"
                chevron: true
                onClicked: page.navigate("acct.media")
            }
            DetailRow {
                separator: true
                title: "Find My"
                iconFile: "dt_findmy"
                chevron: true
                onClicked: page.navigate("acct.findMy")
            }
        }

        GroupCard {
            DetailRow {
                title: "Sign in with Apple"
                iconFile: "dt_signin-apple"
                chevron: true
                onClicked: page.navigate("acct.signinWithApple")
            }
        }

        SectionHeader {
            text: "Devices"
        }

        GroupCard {
            DetailRow {
                title: (page.accountName.length > 0 ? page.accountName : "My") + "'s Mac"
                subtitle: "This Mac Pro"
                iconFile: "macpro"
                chevron: true
                onClicked: page.navigate("acct.deviceDetails")
            }
        }

        GroupCard {
            DetailRow {
                title: "Sign Out\u2026"
                titleColor: Theme.red
                onClicked: confirmSignOut.open()
            }
        }

        Item { width: 1; height: 2 }
    }

    FileDialog {
        id: avatarDlg
        title: "Choose an account photo"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.bmp *.gif *.tif *.tiff)", "All files (*)"]
        onAccepted: {
            var src = page.pathFromFileUrl(selectedFile)
            // unique name every time: QML caches images by URL, so reusing the
            // same path would keep showing the previous picture.
            var dst = page.avatarDir + "avatar-" + Date.now() + ".png"
            var ok = Shell.saveAvatar(src, dst, 512)
            console.log("AVATAR_COPY", ok ? "ok" : "fail", src, "->", dst)
            if (!ok) {
                page.rev++
                return
            }
            var old = page.avatarPath
            Shell.uset("avatarPath", dst)
            if (old.length > 0 && old !== dst)
                Shell.run("rm -f '" + old + "'")
            page.rev++
            console.log("AVATAR_PATH", dst)
        }
    }
}
