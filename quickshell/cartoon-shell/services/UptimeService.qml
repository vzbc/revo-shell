pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  // Properties
  property string uptimePretty: "Loading..."
  property string uptimeSeconds: "0"
  property string bootTime: "Loading..."
  property int uptimeHours: 0
  property int uptimeMinutes: 0
  property int uptimeDays: 0
  property bool isLoading: false
  property string errorMessage: ""

  // Process for uptime -p (pretty format)
  Process {
    id: uptimePrettyProcess
    command: ["uptime", "-p"]
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        if (text && text.length > 0) {
          root.uptimePretty = text.trim()
          root.parseUptimePretty(text.trim())
        } else {
          root.uptimePretty = "Unknown"
          root.errorMessage = "Cannot get uptime info"
        }
      }
    }
  }

  // Process for uptime -s (boot time)
  Process {
    id: bootTimeProcess
    command: ["uptime", "-s"]
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        if (text && text.length > 0) {
          root.bootTime = text.trim()
        } else {
          root.bootTime = "Unknown"
        }
      }
    }
  }

  // Process for /proc/uptime (seconds)
  Process {
    id: uptimeSecondsProcess
    command: ["cat", "/proc/uptime"]
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        if (text && text.length > 0) {
          const seconds = text.trim().split(' ')[0]
          root.uptimeSeconds = seconds
          root.calculateUptimeComponents(parseFloat(seconds))
        }
      }
    }
  }

  function parseUptimePretty(text) {
    // Parse "up 2 hours, 37 minutes" format
    const hoursMatch = text.match(/(\d+)\s*hours?/)
    const minutesMatch = text.match(/(\d+)\s*minutes?/)
    const daysMatch = text.match(/(\d+)\s*days?/)

    root.uptimeHours = hoursMatch ? parseInt(hoursMatch[1]) : 0
    root.uptimeMinutes = minutesMatch ? parseInt(minutesMatch[1]) : 0
    root.uptimeDays = daysMatch ? parseInt(daysMatch[1]) : 0

    // If days exist, add to hours
    if (root.uptimeDays > 0) {
      root.uptimeHours += root.uptimeDays * 24
    }
  }

  function calculateUptimeComponents(totalSeconds) {
    const days = Math.floor(totalSeconds / 86400)
    const hours = Math.floor((totalSeconds % 86400) / 3600)
    const minutes = Math.floor((totalSeconds % 3600) / 60)

    root.uptimeDays = days
    root.uptimeHours = hours
    root.uptimeMinutes = minutes

    // Update pretty format if not already set
    if (root.uptimePretty === "Loading..." || root.uptimePretty === "Unknown") {
      if (days > 0) {
        root.uptimePretty = `up ${days} day${days > 1 ? 's' : ''}, ${hours} hour${hours !== 1 ? 's' : ''}, ${minutes} minute${minutes !== 1 ? 's' : ''}`
      } else if (hours > 0) {
        root.uptimePretty = `up ${hours} hour${hours !== 1 ? 's' : ''}, ${minutes} minute${minutes !== 1 ? 's' : ''}`
      } else {
        root.uptimePretty = `up ${minutes} minute${minutes !== 1 ? 's' : ''}`
      }
    }
  }

  function getFormattedUptime() {
    if (root.uptimeDays > 0) {
      return `${root.uptimeDays}d ${root.uptimeHours}h ${root.uptimeMinutes}m`
    } else if (root.uptimeHours > 0) {
      return `${root.uptimeHours}h ${root.uptimeMinutes}m`
    } else {
      return `${root.uptimeMinutes}m`
    }
  }

  function getShortUptime() {
    if (root.uptimeDays > 0) {
      return `${root.uptimeDays}d`
    } else if (root.uptimeHours > 0) {
      return `${root.uptimeHours}h`
    } else {
      return `${root.uptimeMinutes}m`
    }
  }

  function getBootTimeFormatted() {
    if (root.bootTime === "Loading..." || root.bootTime === "Unknown") {
      return "Unknown"
    }

    const date = new Date(root.bootTime)
    const now = new Date()
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
    const bootDate = new Date(date.getFullYear(), date.getMonth(), date.getDate())

    if (bootDate.getTime() === today.getTime()) {
      // Today: show time only
      return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    } else {
      // Different day: show date and time
      return date.toLocaleString([], {
          month: 'numeric',
          day: 'numeric',
          hour: '2-digit',
          minute: '2-digit'
      })
    }
  }

  function updateAll() {
    root.isLoading = true
    root.errorMessage = ""

    // Run all processes
    uptimePrettyProcess.running = true
    bootTimeProcess.running = true
    uptimeSecondsProcess.running = true

    // Set timeout to clear loading state
    updateTimer.start()
  }

  function updateUptime() {
    uptimePrettyProcess.running = true
    uptimeSecondsProcess.running = true
  }

  // Timer to reset loading state
  Timer {
    id: updateTimer
    interval: 1000
    repeat: false
    onTriggered: {
      root.isLoading = false
    }
  }

  // Auto-update timer (every minute)
  Timer {
    interval: 60000
    running: true
    repeat: true
    onTriggered: {
      updateUptime()
    }
  }

  // Initial load
  Timer {
    id: initialLoadTimer
    interval: 100
    running: true
    repeat: false
    onTriggered: {
      updateAll()
    }
  }

  Component.onCompleted: {
    // Initialize
    root.uptimePretty = "Loading..."
    root.bootTime = "Loading..."
    root.uptimeSeconds = "0"
    root.uptimeHours = 0
    root.uptimeMinutes = 0
    root.uptimeDays = 0
  }
}
