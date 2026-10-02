import QtQuick
import ".."

Column {
    id: page

    property string pageId: "general"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    width: parent ? parent.width : 700
    spacing: 12

    Placard {
        iconFile: "hdr_gear"
        title: "General"
        subtitle: "Manage your overall setup and preferences for Mac, such as software updates, device language, AirDrop, and more."
    }

    GroupCard {
        DetailRow {
            title: "About"
            iconFile: "dt_about"
            chevron: true
            onClicked: page.navigate("gen.about")
        }
        DetailRow {
            separator: true
            title: "Software Update"
            iconFile: "dt_software-update"
            chevron: true
            onClicked: page.navigate("gen.softwareUpdate")
        }
        DetailRow {
            separator: true
            title: "Storage"
            iconFile: "dt_storage"
            chevron: true
            onClicked: page.navigate("gen.storage")
        }
    }

    GroupCard {
        DetailRow {
            title: "AppleCare & Warranty"
            iconFile: "dt_applecare"
            chevron: true
            onClicked: page.navigate("gen.appleCare")
        }
    }

    GroupCard {
        DetailRow {
            title: "AirDrop & Handoff"
            iconFile: "dt_airdrop"
            chevron: true
            onClicked: page.navigate("gen.airDrop")
        }
    }

    GroupCard {
        DetailRow {
            title: "AutoFill & Passwords"
            iconFile: "dt_autofill"
            chevron: true
            onClicked: page.navigate("gen.autoFill")
        }
        DetailRow {
            separator: true
            title: "Date & Time"
            iconFile: "dt_date-and-time"
            chevron: true
            onClicked: page.navigate("gen.dateAndTime")
        }
        DetailRow {
            separator: true
            title: "Language & Region"
            iconFile: "dt_language"
            chevron: true
            onClicked: page.navigate("gen.language")
        }
        DetailRow {
            separator: true
            title: "Login Items & Extensions"
            iconFile: "dt_login-items"
            chevron: true
            onClicked: page.navigate("gen.loginItems")
        }
        DetailRow {
            separator: true
            title: "Sharing"
            iconFile: "dt_sharing"
            chevron: true
            onClicked: page.navigate("gen.sharing")
        }
        DetailRow {
            separator: true
            title: "Startup Disk"
            iconFile: "dt_startup-disk"
            chevron: true
            onClicked: page.navigate("gen.startupDisk")
        }
        DetailRow {
            separator: true
            title: "Time Machine"
            iconFile: "dt_time-machine"
            chevron: true
            onClicked: page.navigate("gen.timeMachine")
        }
    }

    GroupCard {
        DetailRow {
            title: "Device Management"
            iconFile: "dt_device-management"
            chevron: true
            onClicked: page.navigate("gen.deviceManagement")
        }
    }

    GroupCard {
        DetailRow {
            title: "Transfer or Reset"
            iconFile: "dt_transfer"
            chevron: true
            onClicked: page.navigate("gen.transfer")
        }
    }

    Item {
        width: 1
        height: 2
    }
}
