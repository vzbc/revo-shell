pragma Singleton
import QtQuick
import Quickshell

// I honestly don't know how else to do right right now... and I don't care at this point. I just want it working.
// This was the quickest "ship it" solution I could come up with.

Singleton {
    id: root
    property bool backgroundAssembledOnce: false
}
