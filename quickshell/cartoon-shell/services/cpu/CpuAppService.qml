import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var listAppCpu: []

    Process {
        id: cpuProcess

        command: [
            "bash",
            "-c",
            `
            LC_ALL=C ps -eo pid,comm,pcpu,rss --no-headers --sort=-pcpu |
            head -n 10 |
            awk '
            {
                gsub(/"/, "\\\\\\"", $2)

                cpu = $3 + 0
                rss_mb = $4 / 1024

                printf "{\\"pid\\":%d,\\"name\\":\\"%s\\",\\"cpu\\":%.1f,\\"mem\\":%.1f}\\n",
                    $1, $2, cpu, rss_mb
            }' |
            jq -s .
            `
        ]

        running: false

        stdout: StdioCollector {
            onTextChanged: {
                try {
                    const data = JSON.parse(text.trim());

                    if (Array.isArray(data))
                        root.listAppCpu = data;
                } catch (e) {
                    console.log("Parse CPU process error:", e);
                }
            }
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.visible
        triggeredOnStart: true

        onTriggered: {
            if (!cpuProcess.running)
                cpuProcess.running = true;
        }
    }
}