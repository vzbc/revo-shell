pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Detailed hardware / system information for the Windows-11 style Home page.
 */
Singleton {
    id: root

    property string hostname: ""
    property string cpuModel: ""
    property string gpuModel: ""
    property string ramTotal: ""        // e.g. "16.0 GB"
    property string diskUsed: ""        // e.g. "422 GB"
    property string diskTotal: ""       // e.g. "485 GB"
    property real diskPercent: 0
    property string lastUpdate: ""      // human readable date of last pacman upgrade

    Timer {
        triggeredOnStart: true
        interval: 1
        running: true
        repeat: false
        onTriggered: {
            fileCpuInfo.reload()
            fileMeminfo.reload()
            fileHostname.reload()
            gpuProc.running = true
            diskProc.running = true
            updateLogProc.running = true
        }
    }

    FileView {
        id: fileHostname
        path: "/etc/hostname"
        onLoaded: {
            root.hostname = fileHostname.text().trim()
        }
    }

    FileView {
        id: fileCpuInfo
        path: "/proc/cpuinfo"
        onLoaded: {
            const m = fileCpuInfo.text().match(/^model name\s*:\s*(.+)$/m)
            root.cpuModel = m ? m[1].trim() : ""
        }
    }

    FileView {
        id: fileMeminfo
        path: "/proc/meminfo"
        onLoaded: {
            const m = fileMeminfo.text().match(/^MemTotal:\s*(\d+)/m)
            if (m) {
                root.ramTotal = (Number(m[1]) / (1024 * 1024)).toFixed(1) + " GB"
            }
        }
    }

    Process {
        id: gpuProc
        command: ["bash", "-c", "lspci | grep -iE 'vga|3d|display' | head -1 | sed 's/.*: //'"]
        stdout: StdioCollector {
            id: gpuCollector
            onStreamFinished: {
                root.gpuModel = gpuCollector.text.trim()
            }
        }
    }

    Process {
        id: diskProc
        command: ["bash", "-c", "df -h / | tail -1"]
        stdout: StdioCollector {
            id: diskCollector
            onStreamFinished: {
                const parts = diskCollector.text.trim().split(/\s+/)
                if (parts.length >= 5) {
                    root.diskUsed = parts[2]
                    root.diskTotal = parts[1]
                    const pct = parts[4].replace("%", "")
                    root.diskPercent = parseInt(pct) || 0
                }
            }
        }
    }

    Process {
        id: updateLogProc
        command: ["bash", "-c", "grep '\\[PACMAN\\] upgraded' /var/log/pacman.log | tail -1"]
        stdout: StdioCollector {
            id: updateLogCollector
            onStreamFinished: {
                const line = updateLogCollector.text.trim()
                const m = line.match(/\[(\d{4}-\d{2}-\d{2})T(\d{2}:\d{2})/)
                if (m) {
                    const d = new Date(m[1] + "T" + m[2] + ":00")
                    root.lastUpdate = Qt.formatDate(d, "MMMM d, yyyy")
                }
            }
        }
    }
}
