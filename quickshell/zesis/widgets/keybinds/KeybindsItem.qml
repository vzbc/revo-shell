import "../bar"

BarButton {
    icon: "󰌌"
    active: KeybindService.popupOpen
    onClicked: KeybindService.popupOpen = !KeybindService.popupOpen
}
