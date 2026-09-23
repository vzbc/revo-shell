// components/Settings/SystemSettings.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import qs.services
import qs.components
import "./system/" as Com

Item {
  id: root
  
  property var systemInfo: ({})
  property bool dataLoaded: false
  
  // Fetch system info using fastfetch
  Process {
    id: fastfetchProcess
    running: false
    stdout: StdioCollector {
      id: outputCollector
    }
    command: ["fastfetch", "--format", "json"]
    
    onExited: {
      try {
        var txt = outputCollector.text ? outputCollector.text.trim() : "";
        if (txt !== "") {
          var data = JSON.parse(txt);
          root.systemInfo = parseSystemInfo(data);
          root.dataLoaded = true;
        }
      } catch (e) {
        console.error("Error parsing fastfetch output:", e);
      }
    }
  }
  
  function parseSystemInfo(data) {
    var info = {};
    
    data.forEach(function(item) {
      // OS
      if (item.type === "OS" && item.result) {
        info.os = item.result.prettyName || item.result.name || "Unknown";
        info.osVersion = item.result.version || "Unknown";
      }
      
      // Kernel
      if (item.type === "Kernel" && item.result) {
        info.kernel = item.result.release || "Unknown";
        info.architecture = item.result.architecture || "Unknown";
      }
      
      // Uptime
      if (item.type === "Uptime" && item.result) {
        info.uptime = formatUptime(item.result.uptime);
      }
      
      // Host
      if (item.type === "Host" && item.result) {
        info.hostVendor = item.result.vendor || "Unknown";
        info.hostFamily = item.result.family || "Unknown";
      }
      
      // CPU
      if (item.type === "CPU" && item.result) {
        info.cpu = item.result.cpu || "Unknown";
        info.cpuCores = item.result.cores ? 
          item.result.cores.physical + " Cores • " + item.result.cores.logical + " Threads" : "Unknown";
        info.cpuFreq = item.result.frequency ? 
          "Base: " + item.result.frequency.base + " MHz" : "Unknown";
      }
      
      // GPU
      if (item.type === "GPU" && item.result) {
        var gpuNames = [];
        item.result.forEach(function(gpu) {
          if (gpu.name) {
            gpuNames.push(gpu.name);
          }
        });
        info.gpu = gpuNames;
      }
      
      // Memory
      if (item.type === "Memory" && item.result) {
        var total = item.result.total;
        var used = item.result.used;
        info.memory = {
          total: total,
          used: used,
          totalFormatted: formatBytes(total),
          usedFormatted: formatBytes(used),
          percent: Math.round((used / total) * 100)
        };
      }
      
      // Disk
      if (item.type === "Disk" && item.result) {
        var disk = item.result[0];
        if (disk && disk.bytes) {
          var total = disk.bytes.total;
          var used = disk.bytes.used;
          var available = disk.bytes.available;
          info.disk = {
            total: total,
            used: used,
            available: available,
            totalFormatted: formatBytes(total),
            usedFormatted: formatBytes(used),
            availableFormatted: formatBytes(available),
            filesystem: disk.filesystem || "Unknown",
            mountpoint: disk.mountpoint || "/",
            percent: Math.round((used / total) * 100)
          };
        }
      }
      
      // Battery
      if (item.type === "Battery" && item.result) {
        var battery = item.result[0];
        if (battery) {
          info.battery = {
            capacity: Math.round(battery.capacity || 0),
            cycleCount: battery.cycleCount || 0,
            status: battery.status ? battery.status.join(", ") : "Unknown",
            technology: battery.technology || "Unknown"
          };
        }
      }
      
      // Display
      if (item.type === "Display" && item.result) {
        var display = item.result[0];
        if (display && display.output) {
          info.display = {
            resolution: display.output.width + "×" + display.output.height,
            refreshRate: display.output.refreshRate ? display.output.refreshRate.toFixed(0) + " Hz" : "Unknown",
            type: display.type || "Unknown"
          };
        }
      }
      
      // Network
      if (item.type === "LocalIp" && item.result) {
        var network = item.result[0];
        if (network) {
          info.network = {
            ip: network.ipv4 || "Unknown",
            interface: network.name || "Unknown"
          };
        }
      }
      
      // WM
      if (item.type === "WM" && item.result) {
        info.wm = item.result.prettyName || "Unknown";
      }
      
      // Shell
      if (item.type === "Shell" && item.result) {
        info.shell = item.result.prettyName || "Unknown";
      }
      
      // Terminal
      if (item.type === "Terminal" && item.result) {
        info.terminal = item.result.prettyName || "Unknown";
      }
      
      // Packages
      if (item.type === "Packages" && item.result) {
        info.packages = item.result.all || 0;
      }
      
      // Cursor
      if (item.type === "Cursor" && item.result) {
        info.cursor = item.result.theme || "Unknown";
      }
      
      // Terminal Font
      if (item.type === "TerminalFont" && item.result) {
        info.font = item.result.font?.pretty || "Unknown";
      }
    });
    
    return info;
  }
  
  function formatBytes(bytes) {
    if (bytes === 0) return "0 B";
    var k = 1024;
    var sizes = ["B", "KB", "MB", "GB", "TB"];
    var i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + " " + sizes[i];
  }
  
  function formatUptime(seconds) {
    var days = Math.floor(seconds / 86400);
    var hours = Math.floor((seconds % 86400) / 3600);
    var minutes = Math.floor((seconds % 3600) / 60);
    
    var parts = [];
    if (days > 0) parts.push(days + "d");
    if (hours > 0) parts.push(hours + "h");
    if (minutes > 0) parts.push(minutes + "m");
    
    return parts.join(" ") || "0m";
  }
  
  ScrollView {
    anchors.fill: parent
    anchors.margins: ScalerService.s(20)
    clip: true
    contentWidth: availableWidth
    
    ColumnLayout {
      width: parent.width
      spacing: ScalerService.s(20)
      
      // Header
      CustomText {
        name: "System Information"
        textColor: theme.primary.foreground
        size: "large"
        isBold: true
        Layout.topMargin: ScalerService.s(5)
      }
      
      // Loading state
      Rectangle {
        Layout.fillWidth: true
        height: ScalerService.s(200)
        color: "transparent"
        visible: !root.dataLoaded
        
        Column {
          anchors.centerIn: parent
          spacing: ScalerService.s(10)
          
          Text {
            text: "⏳"
            font.pixelSize: ScalerService.s(32)
            anchors.horizontalCenter: parent.horizontalCenter
          }
          
          Text {
            text: "Loading system information..."
            color: theme.primary.dim_foreground
            font.pixelSize: ScalerService.s(14)
            anchors.horizontalCenter: parent.horizontalCenter
          }
        }
      }
      
      // Info Sections
      ColumnLayout {
        Layout.fillWidth: true
        visible: root.dataLoaded
        spacing: ScalerService.s(15)
        
        // Section: System
        Com.InfoSection {
          title: "System"
          
          Com.InfoRow {
            label: "Operating System"
            value: root.systemInfo.os || "Unknown"
          }
          
          Com.InfoRow {
            label: "Kernel"
            value: root.systemInfo.kernel || "Unknown"
          }
          
          Com.InfoRow {
            label: "Architecture"
            value: root.systemInfo.architecture || "Unknown"
          }
          
          Com.InfoRow {
            label: "Uptime"
            value: root.systemInfo.uptime || "0m"
          }
        }
        
        // Section: Hardware
        Com.InfoSection {
          title: "Hardware"
          
          Com.InfoRow {
            label: "CPU"
            value: root.systemInfo.cpu || "Unknown"
          }
          
          Com.InfoRow {
            label: "Cores"
            value: root.systemInfo.cpuCores || "Unknown"
            valueColor: theme.primary.dim_foreground
          }
          
          Com.InfoRow {
            label: "Base Frequency"
            value: root.systemInfo.cpuFreq || "Unknown"
            valueColor: theme.primary.dim_foreground
          }
        }
        
        // Section: Graphics
        Com.InfoSection {
          title: "Graphics"
          
          Repeater {
            model: root.systemInfo.gpu || []
            
            Com.InfoRow {
              label: index === 0 ? "GPU" : ""
              value: modelData || "Unknown"
              labelVisible: index === 0
            }
          }
        }
        
        // Section: Memory
        Com.InfoSection {
          title: "Memory"
          
          Com.InfoRow {
            label: "RAM"
            value: root.systemInfo.memory ? 
              root.systemInfo.memory.usedFormatted + " / " + root.systemInfo.memory.totalFormatted : "Unknown"
            valueColor: {
              var p = root.systemInfo.memory?.percent || 0;
              if (p > 80) return theme.normal.red;
              if (p > 60) return theme.normal.yellow;
              return theme.normal.green;
            }
          }
          
          Rectangle {
            Layout.fillWidth: true
            height: ScalerService.s(8)
            radius: ScalerService.s(4)
            color: theme.normal.black
            Layout.topMargin: ScalerService.s(2)
            
            Rectangle {
              width: parent.width * ((root.systemInfo.memory?.percent || 0) / 100)
              height: parent.height
              radius: ScalerService.s(4)
              color: {
                var p = root.systemInfo.memory?.percent || 0;
                if (p > 80) return theme.normal.red;
                if (p > 60) return theme.normal.yellow;
                return theme.normal.green;
              }
            }
          }
          
          Com.InfoRow {
            label: "Used"
            value: root.systemInfo.memory ? root.systemInfo.memory.usedFormatted : "Unknown"
            valueColor: theme.primary.dim_foreground
          }
        }
        
        // Section: Storage
        Com.InfoSection {
          title: "Storage"
          
          Com.InfoRow {
            label: "Filesystem"
            value: root.systemInfo.disk?.filesystem || "Unknown"
          }
          
          Com.InfoRow {
            label: "Mount Point"
            value: root.systemInfo.disk?.mountpoint || "/"
          }
          
          Com.InfoRow {
            label: "Usage"
            value: root.systemInfo.disk ? 
              root.systemInfo.disk.usedFormatted + " / " + root.systemInfo.disk.totalFormatted : "Unknown"
            valueColor: {
              var p = root.systemInfo.disk?.percent || 0;
              if (p > 80) return theme.normal.red;
              if (p > 60) return theme.normal.yellow;
              return theme.normal.green;
            }
          }
          
          Rectangle {
            Layout.fillWidth: true
            height: ScalerService.s(8)
            radius: ScalerService.s(4)
            color: theme.normal.black
            Layout.topMargin: ScalerService.s(2)
            
            Rectangle {
              width: parent.width * ((root.systemInfo.disk?.percent || 0) / 100)
              height: parent.height
              radius: ScalerService.s(4)
              color: {
                var p = root.systemInfo.disk?.percent || 0;
                if (p > 80) return theme.normal.red;
                if (p > 60) return theme.normal.yellow;
                return theme.normal.green;
              }
            }
          }
          
          Com.InfoRow {
            label: "Available"
            value: root.systemInfo.disk?.availableFormatted || "Unknown"
            valueColor: theme.primary.dim_foreground
          }
        }
        
        // Section: Battery
        Com.InfoSection {
          title: "Battery"
          
          Com.InfoRow {
            label: "Health"
            value: (root.systemInfo.battery?.capacity || 0) + "%"
            valueColor: {
              var p = root.systemInfo.battery?.capacity || 0;
              if (p > 60) return theme.normal.green;
              if (p > 20) return theme.normal.yellow;
              return theme.normal.red;
            }
          }
          
          Com.InfoRow {
            label: "Cycles"
            value: (root.systemInfo.battery?.cycleCount || 0) + " cycles"
            valueColor: theme.primary.dim_foreground
          }
          
          Com.InfoRow {
            label: "Status"
            value: root.systemInfo.battery?.status || "Unknown"
            valueColor: root.systemInfo.battery?.status === "AC Connected" ? 
              theme.normal.green : theme.normal.yellow
          }
        }
        
        // Section: Display
        Com.InfoSection {
          title: "Display"
          
          Com.InfoRow {
            label: "Type"
            value: root.systemInfo.display?.type || "Unknown"
          }
          
          Com.InfoRow {
            label: "Resolution"
            value: root.systemInfo.display?.resolution || "Unknown"
          }
          
          Com.InfoRow {
            label: "Refresh Rate"
            value: root.systemInfo.display?.refreshRate || "Unknown"
            valueColor: theme.primary.dim_foreground
          }
        }
        
        // Section: Network
        Com.InfoSection {
          title: "Network"
          
          Com.InfoRow {
            label: "Interface"
            value: root.systemInfo.network?.interface || "Unknown"
          }
          
          Com.InfoRow {
            label: "IPv4"
            value: root.systemInfo.network?.ip || "Unknown"
            valueColor: theme.primary.dim_foreground
          }
        }
        
        // Section: Software
        Com.InfoSection {
          title: "Software"
          
          Com.InfoRow {
            label: "WM"
            value: root.systemInfo.wm || "Unknown"
          }
          
          Com.InfoRow {
            label: "Shell"
            value: root.systemInfo.shell || "Unknown"
          }
          
          Com.InfoRow {
            label: "Terminal"
            value: root.systemInfo.terminal || "Unknown"
          }
          
          Com.InfoRow {
            label: "Terminal Font"
            value: root.systemInfo.font || "Unknown"
            valueColor: theme.primary.dim_foreground
          }
          
          Com.InfoRow {
            label: "Packages"
            value: (root.systemInfo.packages || 0) + " packages"
          }
          
          Com.InfoRow {
            label: "Cursor Theme"
            value: root.systemInfo.cursor || "Unknown"
            valueColor: theme.primary.dim_foreground
          }
        }
      }
    }
  }
  
  Component.onCompleted: {
    fastfetchProcess.running = true;
  }
}
