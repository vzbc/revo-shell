import QtQuick
import Quickshell.Io
import qs.commons

Item {
  id: root

  property var dataModel: []

  // Package info hiện tại
  property var packageInfo: ({})
  property var packageInfoList: []

  // Callback async
  property var _currentCallback: null
  property int totalPackage: 0
  property bool simplePackage : true

  function getPackageInfo(pkgName, callback) {

    root._currentCallback = callback

    root.packageInfo = ({})
    root.packageInfoList = []

    infoPkgProc.command = [
    "bash",
    "-c",
    "pacman -Qi " + pkgName
    ]

    infoPkgProc.running = true
  }

  // =========================
  // Process package info
  // =========================
  Process {
    id: infoPkgProc

    running: false

    stdout: StdioCollector {
      id: infoCollector

      onTextChanged: {
        parsePacmanInfo(text)
      }
    }

    onExited: {
      if (root._currentCallback)
      root._currentCallback(root.packageInfo)
    }
  }

  // =========================
  // Parse pacman -Qi
  // =========================
  function parsePacmanInfo(rawText) {

    const lines = rawText.split("\n")

    let result = {}
    let currentKey = ""

    for (let line of lines) {

      // Dòng key mới
      if (/^\S/.test(line)) {

        const idx = line.indexOf(":")

        if (idx === -1)
        continue

        currentKey = line.slice(0, idx).trim()

        let value = line.slice(idx + 1).trim()

        result[currentKey] = value
      }

      // Dòng nối tiếp
      else if (currentKey && line.trim() !== "") {

        result[currentKey] += " " + line.trim()
      }
    }

    root.packageInfo = result

    // Object -> Array
    root.packageInfoList = Object.keys(result).map(function(key) {
        return {
          key: key,
          value: result[key]
        }
    })
  }

  // =========================
  // Load all packages
  // =========================
  Process {
    id: pkgProc

    command: ["bash", Directories.scriptsPath + "/package.sh"]

    running: !root.simplePackage

    stdout: StdioCollector {
      onTextChanged: {
        try {
          root.dataModel = JSON.parse(text)
          console.log("Loaded packages")
        } catch (e) {
          console.log("JSON parse error:", e)
        }
      }
    }
  }

  Process {
    id: simplePkgProc

    command: [
    "bash",
    "-c",
    "pacman -Qq | wc -l"
    ]

    running: root.simplePackage

    stdout: StdioCollector {
      onTextChanged: {
        try {
          root.totalPackage = parseInt(text.trim())
        } catch (e) {
          console.log("parse error:", e)
        }
      }
    }
  }
}
