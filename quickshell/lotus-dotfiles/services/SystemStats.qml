import QtQuick
import Quickshell.Io
import Quickshell.Services.UPower

QtObject {
    id: root

    property bool active: false
    property bool cpuLoading: true
    property bool memoryLoading: true
    property bool cpuError: false
    property bool memoryError: false
    property int cpuUsage: 0
    property int memoryUsage: 0
    property double previousCpuIdle: 0
    property double previousCpuTotal: 0
    readonly property bool loading: cpuLoading || memoryLoading
    readonly property bool error: cpuError || memoryError
    readonly property var battery: UPower.displayDevice
    readonly property bool batteryAvailable: battery !== null && battery.ready && battery.isPresent && battery.isLaptopBattery
    readonly property int batteryPercent: batteryAvailable ? Math.round(battery.percentage) : 0
    property Process cpuProcess
    property Process memoryProcess
    property Timer pollTimer

    function refresh() {
        if (!cpuProcess.running)
            cpuProcess.running = true;

        if (!memoryProcess.running)
            memoryProcess.running = true;

    }

    function parseCpu(output) {
        const firstLine = String(output).split("\n")[0].trim();
        const parts = firstLine.split(/\s+/);
        if (parts.length < 6 || parts[0] !== "cpu") {
            cpuError = true;
            return ;
        }
        let total = 0;
        for (let index = 1; index < parts.length; index++) total += Number(parts[index]) || 0
        const idle = (Number(parts[4]) || 0) + (Number(parts[5]) || 0);
        const totalDelta = total - previousCpuTotal;
        const idleDelta = idle - previousCpuIdle;
        if (totalDelta > 0)
            cpuUsage = Math.max(0, Math.min(100, Math.round((1 - idleDelta / totalDelta) * 100)));

        previousCpuTotal = total;
        previousCpuIdle = idle;
        cpuError = false;
    }

    function parseMemory(output) {
        const text = String(output);
        const totalMatch = text.match(/^MemTotal:\s+(\d+)/m);
        const availableMatch = text.match(/^MemAvailable:\s+(\d+)/m);
        if (totalMatch === null || availableMatch === null) {
            memoryError = true;
            return ;
        }
        const total = Number(totalMatch[1]);
        const available = Number(availableMatch[1]);
        memoryUsage = total > 0 ? Math.max(0, Math.min(100, Math.round((1 - available / total) * 100))) : 0;
        memoryError = false;
    }

    cpuProcess: Process {
        id: cpuProcess

        command: ["cat", "/proc/stat"]
        onExited: (exitCode, exitStatus) => {
            root.cpuLoading = false;
            root.cpuError = exitCode !== 0;
            if (exitCode === 0)
                root.parseCpu(cpuOutput.text);

        }

        stdout: StdioCollector {
            id: cpuOutput
        }

    }

    memoryProcess: Process {
        id: memoryProcess

        command: ["cat", "/proc/meminfo"]
        onExited: (exitCode, exitStatus) => {
            root.memoryLoading = false;
            root.memoryError = exitCode !== 0;
            if (exitCode === 0)
                root.parseMemory(memoryOutput.text);

        }

        stdout: StdioCollector {
            id: memoryOutput
        }

    }

    pollTimer: Timer {
        interval: 2500
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

}
