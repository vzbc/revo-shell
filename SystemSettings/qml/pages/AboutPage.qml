import QtQuick
import QtQuick.Controls
import ".."

// General › About (macOS 27, AboutExtension.appex). Identity comes from the
// mac shell's own About This Mac (scripts/mac-tahoe-about-info) so both agree;
// display and storage are read live from Hyprland and df.
Column {
    id: page

    property string pageId: "gen.about"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    width: parent ? parent.width : 640
    spacing: 12

    property var info: ({})
    property var mon: ({})
    property var disk: ({ size: 0, avail: 0 })
    property string prettyName: ""

    function load() {
        try { info = JSON.parse(Shell.execOut(HOME_DIR + "/.config/quickshell/macos/scripts/mac-tahoe-about-info", 4000) || "{}") } catch (e) { info = {} }
        try { mon = (JSON.parse(Shell.execOut("hyprctl monitors -j", 3000) || "[]")[0]) || {} } catch (e) { mon = {} }
        const d = (Shell.execOut("df -B1 --output=size,avail / | tail -1", 3000) || "").trim().split(/\s+/)
        disk = { size: Number(d[0] || 0), avail: Number(d[1] || 0) }
        prettyName = (Shell.execOut("hostnamectl --pretty 2>/dev/null", 2000) || "").trim()
    }
    Component.onCompleted: load()

    readonly property string vendor: info.vendor || "Mac"
    readonly property string macName: prettyName || ((accountName || "My") + "’s " + vendor)
    readonly property bool intel: /intel|amd|ryzen|core\(tm\)/i.test(info.chip || "")
    function gb(b) { return (b / 1e9).toFixed(b >= 1e11 ? 0 : 2) + " GB" }
    readonly property string displayName: {
        const n = String(mon.name || "")
        if (/^eDP|^LVDS|^DSI/.test(n)) return "Built-in Retina Display"
        return (mon.make && mon.make !== "Unknown" ? mon.make + " " : "") + (mon.model || "Display")
    }
    readonly property string displaySize: {
        const w = Number(mon.physicalWidth || 0), h = Number(mon.physicalHeight || 0)
        const res = (mon.width || 0) + " × " + (mon.height || 0)
        if (!w || !h) return "(" + res + ")"
        const inch = Math.round(Math.sqrt(w * w + h * h) / 25.4 * 10) / 10
        return (inch % 1 === 0 ? inch.toFixed(0) : inch.toFixed(1)) + "-inch (" + res + ")"
    }

    component InfoRow: Item {
        property string label: ""
        property string val: ""
        property bool separator: true
        width: parent ? parent.width : 100
        height: Theme.detailRowHeight
        Rectangle { visible: parent.separator; anchors.top: parent.top; x: 16; width: parent.width - 32; height: 1; color: Theme.separator }
        Text {
            x: 16; anchors.verticalCenter: parent.verticalCenter
            text: parent.label; font.family: Theme.fontText; font.pixelSize: 13; color: Theme.textPrimary
        }
        Text {
            anchors.right: parent.right; anchors.rightMargin: 16; anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, parent.width * 0.62); elide: Text.ElideRight; horizontalAlignment: Text.AlignRight
            text: parent.val; font.family: Theme.fontText; font.pixelSize: 13; color: Theme.textSecondary
        }
    }
    component IconRow: Item {
        property string iconSrc: ""
        property string line1: ""
        property string line2: ""
        width: parent ? parent.width : 100
        height: 64
        Image {
            id: ic
            x: 14; anchors.verticalCenter: parent.verticalCenter
            width: 40; height: 40; source: parent.iconSrc; mipmap: true; smooth: true
            fillMode: Image.PreserveAspectFit
        }
        Column {
            anchors.left: ic.right; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            Text { text: line1; font.family: Theme.fontText; font.pixelSize: 13; color: Theme.textPrimary }
            Text { text: line2; font.family: Theme.fontText; font.pixelSize: 12; color: Theme.textSecondary }
        }
    }
    component RightButton: Item {
        property alias text: btn.text
        signal clicked
        width: page.width; height: btn.height
        MacButton { id: btn; anchors.right: parent.right; anchors.rightMargin: Theme.cardMargin; onClicked: parent.clicked() }
    }

    // ------------------------------------------------------------- header
    Item { width: 1; height: 10 }
    Image {
        anchors.horizontalCenter: parent.horizontalCenter
        source: "qrc:/icons/about_mac.png"
        width: 220; height: 220 * sourceSize.height / Math.max(1, sourceSize.width)
        mipmap: true; smooth: true
    }
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 2
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: page.vendor
            font.family: Theme.fontDisplay; font.pixelSize: 26; font.weight: Font.Bold; color: Theme.textDetail
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: page.info.model || ""
            font.family: Theme.fontText; font.pixelSize: 13; color: Theme.textSecondary
        }
    }
    Item { width: 1; height: 6 }

    GroupCard {
        Item {
            width: parent ? parent.width : 100
            height: Theme.detailRowHeight
            Text { x: 16; anchors.verticalCenter: parent.verticalCenter; text: "Name"; font.family: Theme.fontText; font.pixelSize: 13; color: Theme.textPrimary }
            TextField {
                id: nameField
                anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                width: Math.min(260, parent.width * 0.55); height: 26
                text: page.macName
                horizontalAlignment: TextInput.AlignRight
                font.family: Theme.fontText; font.pixelSize: 13
                color: activeFocus ? Theme.textPrimary : Theme.textSecondary
                leftPadding: 8; rightPadding: 8; topPadding: 0; bottomPadding: 0
                verticalAlignment: TextInput.AlignVCenter
                selectByMouse: true
                background: Rectangle {
                    radius: 6
                    color: nameField.activeFocus ? Theme.checkBg : "transparent"
                    border.width: nameField.activeFocus ? 2 : 0
                    border.color: Theme.accent
                }
                onEditingFinished: if (text.trim() && text.trim() !== page.macName) {
                    Shell.run("hostnamectl set-hostname --pretty " + JSON.stringify(text.trim()))
                    page.prettyName = text.trim()
                }
            }
        }
        InfoRow { label: page.intel ? "Processor" : "Chip"; val: page.info.chip || "Unknown" }
        InfoRow { visible: !!page.info.graphics; label: "Graphics"; val: page.info.graphics || "" }
        InfoRow { label: "Memory"; val: page.info.memory || "Unknown" }
        InfoRow { label: "Startup disk"; val: page.info.disk || "macOS" }
        InfoRow { label: "Serial number"; val: page.info.serial || "" }
    }

    SectionHeader { text: "macOS" }
    GroupCard {
        IconRow {
            iconSrc: Theme.dark ? "qrc:/icons/about_macos_dark.png" : "qrc:/icons/about_macos_light.png"
            line1: "macOS " + String(page.info.os || "Tahoe 26").split(" ")[0]
            line2: "Version " + (String(page.info.os || "").split(" ")[1] || "26")
        }
    }

    SectionHeader { text: "Displays" }
    GroupCard {
        IconRow {
            iconSrc: /^eDP|^LVDS|^DSI/.test(String(page.mon.name || "")) ? "qrc:/icons/about_mac.png" : "qrc:/icons/dt_display2.png"
            line1: page.displayName
            line2: page.displaySize
        }
    }
    RightButton { text: "Display Settings…"; onClicked: page.navigate("displays") }

    SectionHeader { text: "Storage" }
    GroupCard {
        IconRow {
            iconSrc: "qrc:/icons/dt_startup-disk.png"
            line1: page.info.disk || "macOS"
            line2: page.disk.size ? page.gb(page.disk.avail) + " available of " + page.gb(page.disk.size) : "Calculating…"
        }
    }
    RightButton { text: "Storage Settings…"; onClicked: page.navigate("gen.storage") }

    Item { width: 1; height: 4 }
    RightButton { text: "System Report…"; onClicked: Shell.run("kitty --title 'System Report' -e sh -c 'fastfetch; printf \"\\nPress Enter to close\"; read _' >/dev/null 2>&1 &") }

    Item { width: 1; height: 6 }
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 3
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "<a style='text-decoration:none' href='lic'>Software License Agreement</a> – <a style='text-decoration:none' href='reg'>Regulatory Certification</a>"
            textFormat: Text.RichText; linkColor: Theme.link
            font.family: Theme.fontText; font.pixelSize: 11; color: Theme.textSecondary
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "<a style='text-decoration:none' href='es'>ENERGY STAR® Compliance</a> – <a style='text-decoration:none' href='la'>License Agreement</a>"
            textFormat: Text.RichText; linkColor: Theme.link
            font.family: Theme.fontText; font.pixelSize: 11; color: Theme.textSecondary
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "™ and © 1983–2026 Apple Inc. All Rights Reserved."
            font.family: Theme.fontText; font.pixelSize: 11; color: Theme.textSecondary
        }
    }
    Item { width: 1; height: 10 }
}
