pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../shared"

Singleton {
    id: root

    // Availability flags
    property bool smbAvailable: false
    property bool smbnetfsAvailable: false
    property bool fusermountAvailable: false
    readonly property bool keychainAvailable: KeychainService.available
    property bool keychainUnavailable: false
    readonly property string _secretTool: KeychainService.tool  // "secret-tool" or "oo7-cli"

    // Session info
    property bool scanning: false
    property string systemUser: ""
    property int uid: 1000
    property string mountCifsPath: ""
    property string umountPath: ""

    // Backend config
    property string mountBackend: netConfig.mountBackend  // "mountcifs" | "smbnetfs"
    property bool persistCredentials: netConfig.persistCredentials
    property bool useKeyring: netConfig.useKeyring
    property bool showWarnings: netConfig.showWarnings

    readonly property bool _useKeyringBackend: keychainAvailable && useKeyring

    readonly property string _netConfigDir: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/zesis"
    readonly property string _netConfigPath: _netConfigDir + "/network.json"

    // Discovery / share state
    // [{name, hostname, address}]
    property var servers: []

    // {hostname: {status, shares: [{name, comment, state}], error, user}}
    property var serverState: ({})

    // CIFS mounts (mount.cifs mode only)
    property var mounts: []

    // smbnetfs state
    property var _smbnetfsCredentials: ({})    // {host: {user, pass}}, never exposed to UI
    property var _smbnetfsSavedCreds: ({})     // remembered across disconnect when creds persist
    property var smbnetfsConnected: []         // just hostnames, for UI
    property var smbnetfsSavedHosts: []        // hosts with saved creds (for reconnect button)
    property bool _smbnetfsRunning: false

    readonly property string _smbnetfsRoot: "/run/user/" + root.uid + "/smb"
    readonly property string _smbHome: Quickshell.env("HOME") + "/.smb"

    // Startup
    Component.onCompleted: {
        checkSmbProc.running = true;
        checkSmbnetfsProc.running = true;
        checkFusermountProc.running = true;
        whoamiProc.running = true;
        uidProc.running = true;
        findMountCifsProc.running = true;
        findUmountProc.running = true;
        readAuthFileProc.running = true;
        ensureSmbClientConfProc.running = true;
        scan();
        refreshMounts();
        if (root.keychainAvailable && root.useKeyring) {
            secretSearchProc.running = true;
        }
    }

    // KeychainService may finish tool detection after this singleton starts up
    onKeychainAvailableChanged: {
        if (root.keychainAvailable && root.useKeyring) {
            secretSearchProc.running = false;
            secretSearchProc.running = true;
        }
    }

    Connections {
        target: KeychainService
        function onLockedChanged() {
            if (!KeychainService.locked && root.keychainAvailable && root.useKeyring) {
                secretSearchProc.running = false;
                secretSearchProc.running = true;
            }
        }
    }

    // Public API

    function scan() {
        root.scanning = true;
        root.servers = [];
        avahiProc.running = false;
        avahiProc.running = true;
    }

    function listShares(host, user, pass) {
        var st = Object.assign({}, root.serverState);
        st[host] = {
            status: "listing",
            shares: st[host]?.shares ?? [],
            error: "",
            user: user
        };
        root.serverState = st;
        smbListProc._host = host;
        smbListProc._pending = [];
        smbListProc._stderr = "";
        smbListProc.command = ["smbclient", "-L", "//" + host, "-U", user + "%" + pass, "-g", "-s", root._smbHome + "/smb.conf"];
        smbListProc.running = false;
        smbListProc.running = true;
    }

    // mount.cifs backend
    function mount(host, share, user, pass) {
        var mp = root._smbnetfsRoot + "/" + host + "/" + share;
        _setShareState(host, share, "mounting");
        mkdirProc._host = host;
        mkdirProc._share = share;
        mkdirProc._mountPoint = mp;
        mkdirProc._user = user;
        mkdirProc._pass = pass;
        mkdirProc.command = ["mkdir", "-p", mp];
        mkdirProc.running = false;
        mkdirProc.running = true;
    }

    function unmount(target) {
        unmountProc._target = target;
        unmountProc._elevated = false;
        unmountProc.command = ["umount", target];
        unmountProc.running = false;
        unmountProc.running = true;
    }

    function disconnectMountcifs(host) {
        for (var m of root.mounts) {
            var match = m.source.match(/^\/\/([^\/]+)\//);
            if (match && match[1] === host)
                unmount(m.uri);
        }
        var st = Object.assign({}, root.serverState);
        delete st[host];
        root.serverState = st;
    }

    // smbnetfs backend
    function connectSmbnetfs(host, user, pass) {
        _setSmbnetfsCredentials(Object.assign({}, root._smbnetfsCredentials, {
            [host]: {
                user,
                pass
            }
        }));
        listShares(host, user, pass);
        ensureSmbConfProc.running = false;
        ensureSmbConfProc.running = true;
    }

    function disconnectSmbnetfs(host) {
        var creds = Object.assign({}, root._smbnetfsCredentials);
        var hadCreds = creds[host];
        delete creds[host];
        _setSmbnetfsCredentials(creds);

        // Remember credentials if they'll still be available (file or keyring)
        if (hadCreds && (root.persistCredentials || root._useKeyringBackend)) {
            root._smbnetfsSavedCreds = Object.assign({}, root._smbnetfsSavedCreds, {
                [host]: hadCreds
            });
            root.smbnetfsSavedHosts = Object.keys(root._smbnetfsSavedCreds);
        }

        // Reset server so reconnect UI appears
        var st = Object.assign({}, root.serverState);
        if (st[host]) {
            st[host] = Object.assign({}, st[host], {
                status: "idle",
                shares: []
            });
            root.serverState = st;
        }

        if (Object.keys(creds).length === 0) {
            if (root._smbnetfsRunning) {
                smbnetfsProc._pendingRestart = false;
                smbnetfsProc.running = false;
            }
        } else {
            _writeConfigAndRestart();
        }
    }

    function forgetSmbnetfs(host) {
        var saved = root._smbnetfsSavedCreds[host];
        var sh = Object.assign({}, root._smbnetfsSavedCreds);
        delete sh[host];
        root._smbnetfsSavedCreds = sh;
        root.smbnetfsSavedHosts = Object.keys(sh);

        var esc = s => s.replace(/'/g, "'\\''");
        var cmd;
        if (root._useKeyringBackend && saved) {
            cmd = root._secretTool === "oo7-cli" ? "oo7-cli delete protocol=smb server='" + esc(host) + "' user='" + esc(saved.user) + "'" : "secret-tool clear protocol smb server '" + esc(host) + "' user '" + esc(saved.user) + "'";
        } else {
            var remaining = Object.entries(sh).map(([h, c]) => "printf 'auth \"%s\" \"%s\" \"%s\"\\n' '" + esc(h) + "' '" + esc(c.user) + "' '" + esc(c.pass) + "'").join("; ");
            var af = esc(root._smbHome + "/smbnetfs.auth");
            cmd = remaining.length > 0 ? "{ " + remaining + "; } > '" + af + "'" : "printf '' > '" + af + "'";
        }
        forgetProc.command = ["sh", "-c", cmd];
        forgetProc.running = false;
        forgetProc.running = true;
    }

    function reconnectSmbnetfs(host) {
        var saved = root._smbnetfsSavedCreds[host];
        if (!saved)
            return;
        if (saved.pass) {
            var sh = Object.assign({}, root._smbnetfsSavedCreds);
            delete sh[host];
            root._smbnetfsSavedCreds = sh;
            root.smbnetfsSavedHosts = Object.keys(sh);
            connectSmbnetfs(host, saved.user, saved.pass);
        } else if (root._useKeyringBackend) {
            var esc = s => s.replace(/'/g, "'\\''");
            secretLookupProc._host = host;
            secretLookupProc._user = saved.user;
            secretLookupProc._pass = "";
            var lookupCmd = root._secretTool === "oo7-cli" ? "timeout 30 oo7-cli lookup --secret-only protocol=smb server='" + esc(host) + "' user='" + esc(saved.user) + "' 2>/dev/null" : "timeout 30 secret-tool lookup protocol smb server '" + esc(host) + "' user '" + esc(saved.user) + "' 2>/dev/null";
            secretLookupProc.command = ["sh", "-c", lookupCmd];
            secretLookupProc.running = false;
            secretLookupProc.running = true;
        } else {
            var sh2 = Object.assign({}, root._smbnetfsSavedCreds);
            delete sh2[host];
            root._smbnetfsSavedCreds = sh2;
            root.smbnetfsSavedHosts = Object.keys(sh2);
            connectSmbnetfs(host, saved.user, "");
        }
    }

    function retryKeychain() {
        root.keychainUnavailable = false;
        secretSearchProc.running = false;
        secretSearchProc.running = true;
    }

    function saveBackend(backend) {
        _saveNetConfig(backend, root.persistCredentials, root.useKeyring, root.showWarnings);
    }

    function savePersistCredentials(val) {
        _saveNetConfig(root.mountBackend, val, root.useKeyring, root.showWarnings);
    }

    function saveUseKeyring(val) {
        _saveNetConfig(root.mountBackend, root.persistCredentials, val, root.showWarnings);
    }

    function saveShowWarnings(val) {
        _saveNetConfig(root.mountBackend, root.persistCredentials, root.useKeyring, val);
    }

    function _saveNetConfig(backend, persist, keyring, warnings) {
        var json = '{"mountBackend":"' + backend + '","persistCredentials":' + (persist ? 'true' : 'false') + ',"useKeyring":' + (keyring ? 'true' : 'false') + ',"showWarnings":' + (warnings ? 'true' : 'false') + '}';
        netConfigWriteProc.command = ["sh", "-c", "mkdir -p '" + root._netConfigDir + "' && printf '%s' '" + json + "' > '" + root._netConfigPath + "'"];
        netConfigWriteProc.running = false;
        netConfigWriteProc.running = true;
    }

    function openPath(path) {
        openProc.command = ["xdg-open", path];
        openProc.running = false;
        openProc.running = true;
    }

    function refreshMounts() {
        if (root.mountBackend === "smbnetfs") {
            _updateSmbnetfsShareStates();
        } else {
            mountListProc._pending = [];
            mountListProc.running = false;
            mountListProc.running = true;
        }
    }

    function isMounted(host, share) {
        if (root.mountBackend === "smbnetfs")
            return host in root._smbnetfsCredentials;
        return mountUri(host, share) !== "";
    }

    function mountUri(host, share) {
        if (root.mountBackend === "smbnetfs")
            return root._smbnetfsRoot + "/" + host + "/" + share;
        var h = host.toLowerCase().replace(/\.local$/, "");
        for (var m of root.mounts) {
            var match = m.source.match(/^\/\/([^\/]+)\/(.+)$/);
            if (match && match[1].toLowerCase().replace(/\.local$/, "") === h && match[2] === share)
                return m.target;
        }
        return "";
    }

    function _setShareState(host, share, state) {
        var st = Object.assign({}, root.serverState);
        if (!st[host])
            return;
        var server = Object.assign({}, st[host]);
        server.shares = server.shares.map(s => s.name === share ? Object.assign({}, s, {
                state
            }) : s);
        st[host] = server;
        root.serverState = st;
    }

    // smbnetfs internals

    function _setSmbnetfsCredentials(creds) {
        root._smbnetfsCredentials = creds;
        root.smbnetfsConnected = Object.keys(creds);
    }

    function _updateSmbnetfsShareStates() {
        var st = Object.assign({}, root.serverState);
        var anyChanged = false;
        Object.keys(st).forEach(host => {
            var server = st[host];
            if (!server.shares)
                return;
            var connected = host in root._smbnetfsCredentials;
            var serverChanged = false;
            var newShares = server.shares.map(s => {
                var want = connected ? "mounted" : "idle";
                if (s.state !== want && s.state !== "mounting") {
                    serverChanged = true;
                    return Object.assign({}, s, {
                        state: want
                    });
                }
                return s;
            });
            if (serverChanged) {
                anyChanged = true;
                st[host] = Object.assign({}, server, {
                    shares: newShares
                });
            }
        });
        if (anyChanged)
            root.serverState = st;
    }

    function _writeConfigAndRestart() {
        if (root._smbnetfsRunning) {
            smbnetfsProc._pendingRestart = true;
            smbnetfsProc.running = false;
        } else {
            _doWriteConfig();
        }
    }

    function _doWriteConfig() {
        var esc = s => s.replace(/'/g, "'\\''");
        var hosts = Object.keys(root._smbnetfsCredentials);
        if (hosts.length === 0)
            return;
        var hf = esc(root._smbHome + "/smbnetfs.host");
        var hostLines = hosts.map(h => "printf 'host %s\\n' '" + esc(h) + "'").join("; ");
        var hostCmd = "{ " + hostLines + "; } > '" + hf + "' && chmod 600 '" + hf + "'";

        var cmd;
        if (root._useKeyringBackend) {
            // Store credentials asynchronously so secret-tool/oo7-cli timeout doesn't delay smbnetfs start
            var secretCmds = Object.entries(root._smbnetfsCredentials).map(([h, c]) => root._secretTool === "oo7-cli" ? "printf '%s' '" + esc(c.pass) + "' | timeout 30 oo7-cli store 'SMB " + esc(h) + "' protocol=smb server='" + esc(h) + "' user='" + esc(c.user) + "'" : "printf '%s' '" + esc(c.pass) + "' | timeout 30 secret-tool store --label='SMB " + esc(h) + "' protocol smb server '" + esc(h) + "' user '" + esc(c.user) + "'").join("; ");
            storeCredsProc.command = ["sh", "-c", secretCmds];
            storeCredsProc.running = false;
            storeCredsProc.running = true;
            cmd = hostCmd;
        } else {
            var af = esc(root._smbHome + "/smbnetfs.auth");
            var authLines = Object.entries(root._smbnetfsCredentials).map(([h, c]) => "printf 'auth \"%s\" \"%s\" \"%s\"\\n' '" + esc(h) + "' '" + esc(c.user) + "' '" + esc(c.pass) + "'").join("; ");
            cmd = hostCmd + " && { " + authLines + "; } > '" + af + "' && chmod 600 '" + af + "'";
        }
        writeConfigProc.command = ["sh", "-c", cmd];
        writeConfigProc.running = false;
        writeConfigProc.running = true;
    }

    function _doStartSmbnetfs() {
        smbnetfsMkdirProc.running = false;
        smbnetfsMkdirProc.running = true;
    }

    // Config persistence

    JsonAdapter {
        id: netConfig
        property string mountBackend: "mountcifs"
        property bool persistCredentials: false
        property bool useKeyring: true
        property bool showWarnings: true
    }

    FileView {
        path: root._netConfigPath
        watchChanges: true
        adapter: netConfig
        onFileChanged: reload()
    }

    Process {
        id: netConfigWriteProc
    }

    // Dependency checks

    Process {
        id: checkSmbProc
        command: ["sh", "-c", "command -v smbclient"]
        onExited: code => root.smbAvailable = (code === 0)
    }

    Process {
        id: checkSmbnetfsProc
        command: ["sh", "-c", "command -v smbnetfs"]
        onExited: code => root.smbnetfsAvailable = (code === 0)
    }

    Process {
        id: checkFusermountProc
        command: ["sh", "-c", "command -v fusermount"]
        onExited: code => root.fusermountAvailable = (code === 0)
    }

    Process {
        id: secretSearchProc
        property string _stdout: ""
        command: root._secretTool === "oo7-cli" ? ["sh", "-c", "timeout 5 oo7-cli search --all --json protocol=smb 2>/dev/null"] : ["sh", "-c", "timeout 5 secret-tool search protocol smb 2>&1 | awk '/attribute.server/{s=$3} /attribute.user/{u=$3} u && s {print s \":\" u; s=\"\"; u=\"\"}'"]
        stdout: SplitParser {
            onRead: line => {
                if (root._secretTool === "oo7-cli") {
                    secretSearchProc._stdout += line + "\n";
                    return;
                }
                var sep = line.indexOf(":");
                if (sep < 0)
                    return;
                var host = line.substring(0, sep).trim();
                var user = line.substring(sep + 1).trim();
                if (!host || !user)
                    return;
                root._smbnetfsSavedCreds = Object.assign({}, root._smbnetfsSavedCreds, {
                    [host]: {
                        user,
                        pass: ""
                    }
                });
                root.smbnetfsSavedHosts = Object.keys(root._smbnetfsSavedCreds);
            }
        }
        onExited: code => {
            if (root._secretTool === "oo7-cli" && secretSearchProc._stdout.trim().length > 0) {
                try {
                    var entries = JSON.parse(secretSearchProc._stdout);
                    var creds = Object.assign({}, root._smbnetfsSavedCreds);
                    for (var e of entries) {
                        var host = e.attributes?.server;
                        var user = e.attributes?.user;
                        if (host && user)
                            creds[host] = {
                                user,
                                pass: ""
                            };
                    }
                    root._smbnetfsSavedCreds = creds;
                    root.smbnetfsSavedHosts = Object.keys(creds);
                } catch (err) {
                    console.log("[NetworkService] failed to parse oo7-cli search output:", err);
                }
            }
            secretSearchProc._stdout = "";
            if (code === 124)
                root.keychainUnavailable = true;
            else if (code === 0)
                root.keychainUnavailable = false;
        }
    }

    // Async credential store, runs in parallel with smbnetfs start
    Process {
        id: storeCredsProc
        onExited: code => {
            if (code === 124)
                root.keychainUnavailable = true;
            else if (code === 0)
                root.keychainUnavailable = false;
        }
    }

    // Look up a single password from keyring then reconnect
    Process {
        id: secretLookupProc
        property string _host: ""
        property string _user: ""
        property string _pass: ""
        stdout: SplitParser {
            onRead: data => secretLookupProc._pass += data
        }
        onExited: code => {
            if (code === 124 || (code !== 0 && secretLookupProc._pass.length === 0)) {
                root.keychainUnavailable = true;
                return;
            }
            if (secretLookupProc._pass.length === 0)
                return;
            root.keychainUnavailable = false;
            var host = secretLookupProc._host;
            var sh = Object.assign({}, root._smbnetfsSavedCreds);
            delete sh[host];
            root._smbnetfsSavedCreds = sh;
            root.smbnetfsSavedHosts = Object.keys(sh);
            root.connectSmbnetfs(host, secretLookupProc._user, secretLookupProc._pass.trim());
        }
    }

    // smbclient refuses to run at all without a loadable config file, give it a
    // minimal client-only one instead of depending on /etc/samba/smb.conf existing.
    Process {
        id: ensureSmbClientConfProc
        command: ["sh", "-c", "mkdir -p \"" + root._smbHome + "\" && printf '%s\\n' '[global]' > \"" + root._smbHome + "/smb.conf\""]
    }

    Process {
        id: ensureSmbConfProc
        command: ["sh", "-c", "d=\"" + root._smbHome + "\"; mkdir -p \"$d\" &&" + " printf '%s\\n' 'smb_query_browsers \"false\"' 'config_update_period 0' 'include \"smbnetfs.auth\"' 'include \"smbnetfs.host\"' > \"$d/smbnetfs.conf\" &&" + " { touch \"$d/smbnetfs.auth\" && chmod 600 \"$d/smbnetfs.auth\"; } &&" + " { touch \"$d/smbnetfs.host\" && chmod 600 \"$d/smbnetfs.host\"; }"]
        onExited: code => {
            if (code === 0)
                root._writeConfigAndRestart();
        }
    }

    Process {
        id: whoamiProc
        command: ["whoami"]
        stdout: SplitParser {
            onRead: data => root.systemUser = data.trim()
        }
    }

    Process {
        id: uidProc
        command: ["id", "-u"]
        stdout: SplitParser {
            onRead: data => root.uid = parseInt(data.trim())
        }
    }

    Process {
        id: findMountCifsProc
        command: ["sh", "-c", "which mount.cifs 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                var p = data.trim();
                if (p.length > 0)
                    root.mountCifsPath = p;
            }
        }
    }

    Process {
        id: findUmountProc
        command: ["sh", "-c", "which umount"]
        stdout: SplitParser {
            onRead: data => root.umountPath = data.trim()
        }
    }

    // Discovery

    Process {
        id: avahiProc
        command: ["avahi-browse", "-t", "-r", "-p", "_smb._tcp"]
        stdout: SplitParser {
            onRead: line => {
                var p = line.split(";");
                if (p[0] !== "=" || p.length < 9)
                    return;
                var name = p[3];
                var hostname = p[6].replace(/\.$/, "");
                var address = p[7];
                for (var s of root.servers)
                    if (s.hostname === hostname)
                        return;
                root.servers = [...root.servers,
                    {
                        name,
                        hostname,
                        address
                    }
                ];
            }
        }
        onExited: root.scanning = false
    }

    // Share listing

    Process {
        id: smbListProc
        property string _host: ""
        property var _pending: []
        property string _stderr: ""
        stdout: SplitParser {
            onRead: line => {
                var parts = line.split("|");
                if (parts.length < 2 || parts[0] !== "Disk") {
                    // Apparently smbclient sends errors to stdout and not
                    // stderr when there is no controlling TTY. Why? IDK!
                    var t = line.trim();
                    if (t.length > 0)
                        smbListProc._stderr = t;
                    return;
                }
                var name = parts[1].trim();
                var comment = parts.length > 2 ? parts[2].trim() : "";
                if (name.endsWith("$"))
                    return;
                smbListProc._pending = [...smbListProc._pending,
                    {
                        name,
                        comment,
                        state: "idle"
                    }
                ];
            }
        }
        stderr: SplitParser {
            onRead: line => {
                var t = line.trim();
                if (t.length > 0)
                    smbListProc._stderr = t;
            }
        }
        onExited: code => {
            var st = Object.assign({}, root.serverState);
            var ok = code === 0 && smbListProc._pending.length > 0;
            var errMsg = "";
            if (code !== 0) {
                if (smbListProc._stderr.indexOf("NT_STATUS_LOGON_FAILURE") >= 0 || smbListProc._stderr.indexOf("NT_STATUS_ACCESS_DENIED") >= 0)
                    errMsg = "Authentication failed";
                else if (smbListProc._stderr.length > 0)
                    errMsg = smbListProc._stderr;
                else
                    errMsg = "Failed to list shares";
            } else if (smbListProc._pending.length === 0) {
                errMsg = "No shares found";
            }
            if (!ok)
                console.log("[NetworkService] smbclient failed (code " + code + "):", smbListProc._stderr);
            st[smbListProc._host] = {
                status: ok ? "listed" : "error",
                shares: smbListProc._pending.map(s => Object.assign({}, s, {
                        state: root.isMounted(smbListProc._host, s.name) ? "mounted" : "idle"
                    })),
                error: errMsg,
                user: st[smbListProc._host]?.user ?? ""
            };
            root.serverState = st;
        }
    }

    // mount.cifs processes

    Process {
        id: mkdirProc
        property string _host: ""
        property string _share: ""
        property string _mountPoint: ""
        property string _user: ""
        property string _pass: ""
        stderr: SplitParser {
            onRead: line => console.log("[NetworkService] mkdir stderr:", line)
        }
        onExited: code => {
            if (code === 0) {
                mountProc._host = mkdirProc._host;
                mountProc._share = mkdirProc._share;
                mountProc._mountPoint = mkdirProc._mountPoint;
                mountProc._user = mkdirProc._user;
                mountProc._pass = mkdirProc._pass;
                mountProc._elevated = false;
                mountProc.command = ["mount.cifs", "//" + mkdirProc._host + "/" + mkdirProc._share, mkdirProc._mountPoint, "-o", "username=" + mkdirProc._user + ",password=" + mkdirProc._pass + ",uid=" + root.uid + ",gid=" + root.uid];
                mountProc.running = false;
                mountProc.running = true;
            } else {
                root._setShareState(mkdirProc._host, mkdirProc._share, "error");
            }
        }
    }

    Process {
        id: mountProc
        property string _host: ""
        property string _share: ""
        property string _mountPoint: ""
        property string _user: ""
        property string _pass: ""
        property bool _elevated: false
        property bool _exited: false
        stderr: SplitParser {
            onRead: line => console.log("[NetworkService] mount.cifs stderr:", line)
        }
        function _retryOrFail() {
            if (!mountProc._elevated && root.mountCifsPath !== "") {
                mountProc._elevated = true;
                mountProc.command = ["pkexec", root.mountCifsPath, "//" + mountProc._host + "/" + mountProc._share, mountProc._mountPoint, "-o", "username=" + mountProc._user + ",password=" + mountProc._pass + ",uid=" + root.uid + ",gid=" + root.uid];
                mountProc.running = false;
                mountProc.running = true;
            } else {
                root._setShareState(mountProc._host, mountProc._share, "error");
            }
        }
        onExited: code => {
            mountProc._exited = true;
            if (code === 0)
                root.refreshMounts();
            else
                mountProc._retryOrFail();
        }
        // Prevents a forever hang of "mounting..."
        onRunningChanged: {
            if (running)
                mountProc._exited = false;
            else if (!mountProc._exited)
                mountProc._retryOrFail();
        }
    }

    Process {
        id: unmountProc
        property string _target: ""
        property bool _elevated: false
        property bool _exited: false
        stderr: SplitParser {
            onRead: line => console.log("[NetworkService] umount stderr:", line)
        }
        function _retryOrFail() {
            if (!unmountProc._elevated && root.umountPath !== "") {
                unmountProc._elevated = true;
                unmountProc.command = ["pkexec", root.umountPath, unmountProc._target];
                unmountProc.running = false;
                unmountProc.running = true;
            } else {
                root.refreshMounts();
            }
        }
        onExited: code => {
            unmountProc._exited = true;
            if (code === 0)
                root.refreshMounts();
            else
                unmountProc._retryOrFail();
        }
        onRunningChanged: {
            if (running)
                unmountProc._exited = false;
            else if (!unmountProc._exited)
                unmountProc._retryOrFail();
        }
    }

    Process {
        id: mountListProc
        command: ["cat", "/proc/mounts"]
        property var _pending: []
        stdout: SplitParser {
            onRead: line => {
                var parts = line.split(" ");
                if (parts.length < 3 || parts[2] !== "cifs")
                    return;
                var source = parts[0].replace(/\\040/g, " ");
                var target = parts[1].replace(/\\040/g, " ");
                var m = source.match(/^\/\/([^\/]+)\/(.+)$/);
                if (!m)
                    return;
                var displayName = m[1].replace(/\.local$/, "") + " / " + m[2];
                mountListProc._pending = [...mountListProc._pending,
                    {
                        source,
                        target,
                        displayName,
                        uri: target
                    }
                ];
            }
        }
        onExited: _ => {
            root.mounts = mountListProc._pending;
            var st = Object.assign({}, root.serverState);
            var anyChanged = false;
            Object.keys(st).forEach(host => {
                var server = st[host];
                if (!server.shares)
                    return;
                var hostChanged = false;
                var newShares = server.shares.map(s => {
                    var mounted = root.isMounted(host, s.name);
                    if (mounted && s.state !== "mounted") {
                        hostChanged = true;
                        return Object.assign({}, s, {
                            state: "mounted"
                        });
                    }
                    if (!mounted && s.state === "mounted") {
                        hostChanged = true;
                        return Object.assign({}, s, {
                            state: "idle"
                        });
                    }
                    return s;
                });
                if (hostChanged) {
                    anyChanged = true;
                    st[host] = Object.assign({}, server, {
                        shares: newShares
                    });
                }
            });
            if (anyChanged)
                root.serverState = st;
        }
    }

    Process {
        id: openProc
    }
    Process {
        id: forgetProc
    }

    // smbnetfs auth file reader

    Process {
        id: readAuthFileProc
        command: ["sh", "-c", "cat '" + root._smbHome + "/smbnetfs.auth' 2>/dev/null"]
        stdout: SplitParser {
            onRead: line => {
                var m = line.match(/^auth\s+"([^"]+)"\s+"([^"]+)"\s+"([^"]+)"/);
                if (!m)
                    return;
                root._smbnetfsSavedCreds = Object.assign({}, root._smbnetfsSavedCreds, {
                    [m[1]]: {
                        user: m[2],
                        pass: m[3]
                    }
                });
                root.smbnetfsSavedHosts = Object.keys(root._smbnetfsSavedCreds);
            }
        }
    }

    // smbnetfs processes

    Process {
        id: writeConfigProc
        stderr: SplitParser {
            onRead: line => console.log("[NetworkService] writeConfig stderr:", line)
        }
        onExited: code => {
            if (code === 0)
                root._doStartSmbnetfs();
            else
                console.log("[NetworkService] smbnetfs config write failed:", code);
        }
    }

    Process {
        id: smbnetfsMkdirProc
        command: ["sh", "-c", "rm -rf '" + root._smbnetfsRoot + "' && mkdir -p '" + root._smbnetfsRoot + "'"]
        onExited: _ => {
            smbnetfsProc.command = ["smbnetfs", "-f", root._smbnetfsRoot];
            smbnetfsProc.running = false;
            smbnetfsProc.running = true;
            root._smbnetfsRunning = true;
            if (!root._useKeyringBackend && !root.persistCredentials) {
                wipeAuthProc.running = false;
                wipeAuthProc.running = true;
            }
        }
    }

    Process {
        id: wipeAuthProc
        command: ["sh", "-c", "sleep 1 && printf '' > '" + root._smbHome + "/smbnetfs.auth' 2>/dev/null; true"]
    }

    Process {
        id: smbnetfsProc
        property bool _pendingRestart: false
        stderr: SplitParser {
            onRead: line => console.log("[NetworkService] smbnetfs:", line)
        }
        onExited: code => {
            root._smbnetfsRunning = false;
            console.log("[NetworkService] smbnetfs exited:", code);
            unmountSmbnetfsProc.running = false;
            unmountSmbnetfsProc.running = true;
        }
    }

    Process {
        id: unmountSmbnetfsProc
        command: ["sh", "-c", "fusermount -u '" + root._smbnetfsRoot + "' 2>/dev/null; true"]
        onExited: _ => {
            if (smbnetfsProc._pendingRestart) {
                smbnetfsProc._pendingRestart = false;
                root._doWriteConfig();
            }
        }
    }
}
