import QtQuick
import ".."

Column {
    id: page

    property string pageId: "acct.deviceDetails"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    width: parent ? parent.width : 620
    spacing: 12

    property var info: ({})

    Component.onCompleted: {
        info = {
            host: Shell.execOut("hostname", 1200),
            user: Shell.execOut("id -un", 1200),
            model: Shell.execOut("cat /sys/class/dmi/id/product_name 2>/dev/null", 1200),
            serial: Shell.execOut("cat /sys/class/dmi/id/product_serial 2>/dev/null", 1200),
            uuid: Shell.execOut("cat /sys/class/dmi/id/product_uuid 2>/dev/null", 1500),
            bios: Shell.execOut("cat /sys/class/dmi/id/bios_version 2>/dev/null", 1200),
            cpu: Shell.execOut("lscpu 2>/dev/null | sed -n \"s/^Model name:[[:space:]]*//p\" | head -1", 1500),
            cores: Shell.execOut("nproc", 1200),
            ram: Shell.execOut("free -h 2>/dev/null | awk '/^Mem:/{print $2 \" / \" $3 \" used\"}'", 1500),
            os: Shell.execOut("sed -n \"s/^PRETTY_NAME=//p\" /etc/os-release | tr -d '\\\"'", 1200),
            kernel: Shell.execOut("uname -r", 1200),
            ip: Shell.execOut("ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -1", 1500),
            mac: Shell.execOut("ip -o link show scope link 2>/dev/null | awk '/ether/{print $2; exit}'", 1500),
            uptime: Shell.execOut("uptime -p 2>/dev/null | sed \"s/^up //\"", 1500),
            display: Shell.execOut("hyprctl monitors -j 2>/dev/null | jq -r '.[0] | (.width|tostring) + \"x\" + (.height|tostring) + \" @ \" + (.refreshRate|round|tostring) + \"Hz\"' 2>/dev/null", 2500)
        }
    }

    function val(k) {
        var v = info[k]
        return (v !== undefined && String(v).length > 0) ? String(v) : "\u2014"
    }

    Placard {
        iconFile: "sb_group"
        title: "Device Details"
        subtitle: accountEmail
    }

    // ---- device hero ----
    Rectangle {
        width: parent.width - 24
        x: 12
        height: heroCol.implicitHeight + 36
        radius: 10
        color: Theme.cardBg

        Column {
            id: heroCol
            width: parent.width
            y: 18
            spacing: 0

            Image {
                source: Theme.icon("macpro", 120)
                width: 120
                height: 120
                anchors.horizontalCenter: parent.horizontalCenter
                asynchronous: true
                mipmap: true
            }

            Item { width: 1; height: 10 }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: page.val("host")
                font { family: Theme.fontText; pixelSize: 18; weight: Font.DemiBold }
                color: Theme.textPrimary
            }

            Item { width: 1; height: 2 }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: "This Mac Pro"
                font { family: Theme.fontText; pixelSize: 12 }
                color: Theme.textSecondary
            }

            Item { width: 1; height: 6 }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: page.accountEmail.length > 0 ? page.accountEmail : ""
                visible: text.length > 0
                font { family: Theme.fontText; pixelSize: 12 }
                color: Theme.textSecondary
            }

            Item { width: 1; height: 16 }
        }
    }

    GroupCard {
        DetailRow {
            title: "Device Name"
            value: page.val("host")
            chevron: false
            onClicked: Shell.run("kitty --title 'Rename Device' -e sh -c 'printf \"Current: %s\\n\" \"$(hostname)\"; sudo hostnamectl set-hostname; read -r -p \"New name: \" n; [ -n \"$n\" ] && sudo hostnamectl set-hostname \"$n\"; hostnamectl hostname'")
        }
        DetailRow {
            separator: true
            title: "Model"
            value: page.val("model")
        }
        DetailRow {
            separator: true
            title: "Version"
            value: page.val("os")
        }
        DetailRow {
            separator: true
            title: "Chip"
            value: page.val("cpu")
        }
        DetailRow {
            separator: true
            title: "Cores"
            value: page.val("cores")
        }
        DetailRow {
            separator: true
            title: "Memory"
            value: page.val("ram")
        }
        DetailRow {
            separator: true
            title: "Storage"
            value: SysInfo.fmt(SysInfo.usedBytes) + " of " + SysInfo.fmt(SysInfo.totalBytes) + " used"
        }
        DetailRow {
            separator: true
            title: "Serial Number"
            value: page.val("serial")
        }
        DetailRow {
            separator: true
            title: "IP Address"
            value: page.val("ip")
        }
        DetailRow {
            separator: true
            title: "Wi-Fi Address"
            value: page.val("mac")
        }
        DetailRow {
            separator: true
            title: "Display"
            value: page.val("display")
        }
        DetailRow {
            separator: true
            title: "Kernel"
            value: page.val("kernel")
        }
        DetailRow {
            separator: true
            title: "Uptime"
            value: page.val("uptime")
        }
    }

    Item { width: 1; height: 4 }

    SectionHeader { text: "Find My" }

    GroupCard {
        DetailRow {
            title: "Find My Mac"
            showSwitch: true
            switchOn: Shell.eget("findmy.mac", true) === true
            onToggled: (c) => Shell.eset("findmy.mac", c)
        }
        DetailRow {
            separator: true
            title: "Locate This Mac"
            subtitle: page.val("ip")
            chevron: true
            onClicked: Shell.run("notify-send 'Find My Mac' 'Last known location: IP " + page.val("ip") + "'")
        }
        DetailRow {
            separator: true
            title: "Copy Serial Number"
            chevron: true
            onClicked: Shell.run("printf '%s' '" + page.val("serial") + "' | xclip -selection clipboard && notify-send 'Serial Number' 'Copied to clipboard.'")
        }
        DetailRow {
            separator: true
            title: "Erase This Mac\u2026"
            titleColor: Theme.red
            chevron: true
            onClicked: Shell.run("sh -c 'notify-send \"Erase This Mac\" \"Confirmation required. Nothing was erased.\"'")
        }
    }

    Item { width: 1; height: 8 }
}
