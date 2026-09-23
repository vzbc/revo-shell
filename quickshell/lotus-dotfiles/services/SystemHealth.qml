import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool active: false
    property bool diskLoading: true
    property bool diskError: false
    property int diskUsage: 0
    property string diskFreeText: "..."
    property bool temperaturesLoading: true
    property bool temperaturesError: false
    property real cpuTemperature: 0
    property real gpuTemperature: 0
    property real driveTemperature: 0
    property bool updatesLoading: true
    property bool updatesError: false
    property int updatesCount: 0
    property bool networkLoading: true
    property bool networkError: false
    property double downloadBytesPerSecond: 0
    property double uploadBytesPerSecond: 0
    property double previousReceiveBytes: -1
    property double previousTransmitBytes: -1
    property double previousNetworkTimestamp: 0
    property Process diskProcess
    property Process sensorsProcess
    property Process updatesProcess
    property Process networkProcess
    property Timer slowTimer
    property Timer sensorTimer
    property Timer networkTimer
    property Timer updatesTimer
    readonly property string cpuTemperatureText: temperaturesLoading ? "..." : (temperaturesError || cpuTemperature <= 0 ? "N/A" : Math.round(cpuTemperature) + "°C")
    readonly property string gpuTemperatureText: temperaturesLoading ? "..." : (temperaturesError || gpuTemperature <= 0 ? "N/A" : Math.round(gpuTemperature) + "°C")
    readonly property string driveTemperatureText: temperaturesLoading ? "..." : (temperaturesError || driveTemperature <= 0 ? "N/A" : Math.round(driveTemperature) + "°C")
    readonly property string updatesText: updatesLoading ? "..." : (updatesError ? "N/A" : String(updatesCount))
    readonly property string downloadText: networkLoading ? "..." : (networkError ? "N/A" : formatRate(downloadBytesPerSecond))
    readonly property string uploadText: networkLoading ? "..." : (networkError ? "N/A" : formatRate(uploadBytesPerSecond))

    function formatBytes(bytes) {
        const value = Math.max(0, Number(bytes) || 0);
        if (value >= 1.07374e+09)
            return (value / 1.07374e+09).toFixed(value >= 1.07374e+10 ? 0 : 1) + " GiB";

        if (value >= 1.04858e+06)
            return (value / 1.04858e+06).toFixed(value >= 1.04858e+07 ? 0 : 1) + " MiB";

        return Math.round(value / 1024) + " KiB";
    }

    function formatRate(bytesPerSecond) {
        return formatBytes(bytesPerSecond) + "/s";
    }

    function refreshAll() {
        refreshDisk();
        refreshTemperatures();
        refreshNetwork();
        refreshUpdates();
    }

    function refreshDisk() {
        if (active && !diskProcess.running)
            diskProcess.running = true;

    }

    function refreshTemperatures() {
        if (active && !sensorsProcess.running)
            sensorsProcess.running = true;

    }

    function refreshNetwork() {
        if (active && !networkProcess.running)
            networkProcess.running = true;

    }

    function refreshUpdates() {
        if (active && !updatesProcess.running)
            updatesProcess.running = true;

    }

    function parseDisk(output) {
        const lines = String(output).trim().split("\n");
        if (lines.length < 2) {
            diskError = true;
            return ;
        }
        const fields = lines[lines.length - 1].trim().split(/\s+/);
        if (fields.length < 6) {
            diskError = true;
            return ;
        }
        diskUsage = Math.max(0, Math.min(100, Number(String(fields[4]).replace("%", "")) || 0));
        diskFreeText = formatBytes((Number(fields[3]) || 0) * 1024);
        diskError = false;
    }

    function parseTemperatures(output) {
        const text = String(output);
        const cpuMatch = text.match(/^Tctl:\s+\+?([0-9.]+)°C/m);
        const gpuMatch = text.match(/^edge:\s+\+?([0-9.]+)°C/m);
        const driveMatch = text.match(/^Composite:\s+\+?([0-9.]+)°C/m);
        cpuTemperature = cpuMatch === null ? 0 : Number(cpuMatch[1]);
        gpuTemperature = gpuMatch === null ? 0 : Number(gpuMatch[1]);
        driveTemperature = driveMatch === null ? 0 : Number(driveMatch[1]);
        temperaturesError = cpuMatch === null && gpuMatch === null && driveMatch === null;
    }

    function parseNetwork(output) {
        const lines = String(output).split("\n");
        let receiveBytes = 0;
        let transmitBytes = 0;
        let found = false;
        for (let index = 0; index < lines.length; index++) {
            const separator = lines[index].indexOf(":");
            if (separator < 0)
                continue;

            const interfaceName = lines[index].slice(0, separator).trim();
            if (interfaceName === "lo")
                continue;

            const fields = lines[index].slice(separator + 1).trim().split(/\s+/);
            if (fields.length < 9)
                continue;

            receiveBytes += Number(fields[0]) || 0;
            transmitBytes += Number(fields[8]) || 0;
            found = true;
        }
        const now = Date.now();
        if (found && previousReceiveBytes >= 0 && previousNetworkTimestamp > 0) {
            const elapsedSeconds = Math.max(0.1, (now - previousNetworkTimestamp) / 1000);
            downloadBytesPerSecond = Math.max(0, (receiveBytes - previousReceiveBytes) / elapsedSeconds);
            uploadBytesPerSecond = Math.max(0, (transmitBytes - previousTransmitBytes) / elapsedSeconds);
        }
        previousReceiveBytes = receiveBytes;
        previousTransmitBytes = transmitBytes;
        previousNetworkTimestamp = now;
        networkLoading = false;
        networkError = !found;
    }

    onActiveChanged: {
        if (active) {
            previousReceiveBytes = -1;
            previousTransmitBytes = -1;
            previousNetworkTimestamp = 0;
            refreshAll();
        }
    }

    diskProcess: Process {
        command: ["df", "-Pk", "/"]
        onExited: (exitCode, exitStatus) => {
            root.diskLoading = false;
            root.diskError = exitCode !== 0;
            if (exitCode === 0)
                root.parseDisk(diskOutput.text);

        }

        stdout: StdioCollector {
            id: diskOutput
        }

    }

    sensorsProcess: Process {
        command: ["sensors"]
        onExited: (exitCode, exitStatus) => {
            root.temperaturesLoading = false;
            root.temperaturesError = exitCode !== 0;
            if (exitCode === 0)
                root.parseTemperatures(sensorsOutput.text);

        }

        stdout: StdioCollector {
            id: sensorsOutput
        }

    }

    updatesProcess: Process {
        command: ["checkupdates"]
        onExited: (exitCode, exitStatus) => {
            root.updatesLoading = false;
            if (exitCode !== 0 && exitCode !== 2) {
                root.updatesError = true;
                return ;
            }
            const output = String(updatesOutput.text).trim();
            root.updatesCount = output.length === 0 ? 0 : output.split("\n").length;
            root.updatesError = false;
        }

        stdout: StdioCollector {
            id: updatesOutput
        }

    }

    networkProcess: Process {
        command: ["cat", "/proc/net/dev"]
        onExited: (exitCode, exitStatus) => {
            root.networkLoading = false;
            root.networkError = exitCode !== 0;
            if (exitCode === 0)
                root.parseNetwork(networkOutput.text);

        }

        stdout: StdioCollector {
            id: networkOutput
        }

    }

    slowTimer: Timer {
        interval: 30000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: root.refreshDisk()
    }

    sensorTimer: Timer {
        interval: 5000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: root.refreshTemperatures()
    }

    networkTimer: Timer {
        interval: 2500
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: root.refreshNetwork()
    }

    updatesTimer: Timer {
        interval: 1.8e+06
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: root.refreshUpdates()
    }

}
