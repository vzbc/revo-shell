import QtQuick
import Quickshell.Io

// One-shot HTTP request against diaspora's API
// Note: Captcha solve (POST /captcha/solve) uses this normally. Only the
// challenge fetch (POST /captcha) bypasses it, since that response is a
// binary PNG that needs to be saved straight to disk via curl's `-o`,
// which this JSON/text-only wrapper has no way to do.
//
// `command` is passed directly to Process as an argv array.

Process {
    id: root

    property string apiBase: ""
    property string path: ""
    property string httpMethod: "GET"   // GET, POST, DELETE, ...
    property string token: ""           // Authorization: Bearer <token>, omitted if empty
    property string body: ""            // sent as JSON (Content-Type: application/json) if non-empty

    // Fired exactly once per run(), whether curl itself succeeded or not
    // status is "" if curl failed to run at all (network error, timeout, ...)
    signal finished(int exitCode, string status, string body)

    property var _lines: []

    function run() {
        root._lines = [];
        var args = ["curl", "-s", "-w", "\n%{http_code}", "--max-time", "8", "-X", root.httpMethod];
        if (root.token !== "")
            args.push("-H", "Authorization: Bearer " + root.token);
        if (root.body !== "") {
            args.push("-H", "Content-Type: application/json");
            args.push("-d", root.body);
        }
        args.push(root.apiBase + root.path);
        root.command = args;
        root.running = false;
        root.running = true;
    }

    stdout: SplitParser {
        onRead: data => root._lines.push(data)
    }
    onExited: code => {
        var status = root._lines.length > 0 ? root._lines[root._lines.length - 1] : "";
        var respBody = root._lines.slice(0, -1).join("\n");
        root.finished(code, status, respBody);
    }
}
