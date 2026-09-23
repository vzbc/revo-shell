pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../"

Singleton {
    id: root

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"
    readonly property string _configPath: _configDir + "/location-sharing.json"

    // True once the config FileView below has actually finished loading
    property bool ready: false

    // Always defaults to false until the user explicitly accepts the warning
    // dialog, we NEVER opt someone in silently, and NEVER assume consent from
    // a missing/unreadable cache file.
    property bool optedIn: config.optedIn

    // Opaque bearer identity for the diaspora server: generated exactly once,
    // on first opt-in, and never touched again after that,
    // If we did regenerate it, it woudl orphan the existing dot and register
    // a brand new one instead of updating it.
    // We source the UUID from /proc/sys/kernel/random/uuid
    property string token: config.token

    readonly property string _apiBase: "https://diaspora.talosvault.net"

    // Populated from GET /locations. Fetched regardless of optedIn
    property var locations: []
    property bool locationsLoading: false

    property bool _locationsFetchPending: false

    // Second, strictly-additional consent tier, meaningless without
    // optedIn, off by default. Display a second heavier warning for this.
    property bool activenessOptedIn: config.activenessOptedIn
    property int activenessCadenceSecs: config.activenessCadenceSecs

    readonly property var activenessCadenceOptions: [
        {
            label: I18n.t("diaspora.cadence5Min"),
            secs: 300
        },
        {
            label: I18n.t("diaspora.cadence15Min"),
            secs: 900
        },
        {
            label: I18n.t("diaspora.cadence30Min"),
            secs: 1800
        },
        {
            label: I18n.t("diaspora.cadence1Hour"),
            secs: 3600
        },
        {
            label: I18n.t("diaspora.cadence2Hours"),
            secs: 7200
        }
    ]

    // Verification: a one-time captcha (see diaspora's README "Consent
    // tiers"/"Captcha") that marks this token's entry as `verified` so other
    // clients can filter scripted noise out of what they render.
    // Note: This is not a privacy tradeoff, so no warnings here.
    // The only way to lose it server-side is deleting the entry entirely
    // (see setOptedIn's false branch below), so that's the only other place
    // this local cache is reset.
    property bool verified: config.verified

    // Result `verofied` is persisted. `captchaImagePath` is "" whenever no
    // challenge is currently being shown, a non-empty "file://..." path
    // drives CommunityPanel's captcha dialog directly off this property.
    property bool captchaBusy: false
    property string captchaImagePath: ""
    property int captchaNonce: 0
    property string captchaError: ""
    property int captchaAttemptsRemaining: -1

    // View-only stuff. It does pollute the sccope, but we want the values
    // to survice the panel being torn down and rebuilt. Temp fix?
    property bool showActiveOnly: config.showActiveOnly
    property bool showVerifiedOnly: config.showVerifiedOnly

    // Whether the dashboard's home pane renders everyone else's dots as a
    // faint spinning background globe.
    property bool showBackgroundGlobe: config.showBackgroundGlobe

    property bool settingsCollapsed: config.settingsCollapsed

    function setSettingsCollapsed(value) {
        root.settingsCollapsed = value;
        _writeConfig();
    }

    function setShowActiveOnly(value) {
        root.showActiveOnly = value;
        _writeConfig();
    }

    function setShowVerifiedOnly(value) {
        root.showVerifiedOnly = value;
        _writeConfig();
    }

    function setShowBackgroundGlobe(value) {
        root.showBackgroundGlobe = value;
        _writeConfig();
    }

    function setOptedIn(value) {
        if (value && root.token === "") {
            // _generateToken() itself flips optedIn true and checks in once
            // the token is ready, there's nothing further to do on this
            // branch until that completes.
            _generateToken();
            return;
        }
        root.optedIn = value;
        if (!value) {
            // Activeness can't outlive the base tier it depends on, force
            // it back off locally too, so re-enabling location sharing
            // later starts from a clean, re-warned state.
            root.activenessOptedIn = false;
            // SO, verification is only deleted at the END of the week, IF
            // the user has chosen to opt out of location sharing. We don't
            // know if they are verified or not. We assume they are not verified.
            // I guess we COULD do this automatically by querying the endpoint...
            root.verified = false;
            root.captchaImagePath = "";
            root.captchaError = "";
            root.captchaAttemptsRemaining = -1;
        }
        _writeConfig();
        if (value)
            _checkin();
        else
            _deleteCheckin();
    }

    // Disabling activeness is always immediate, no warning, reducing your
    // own exposure should NEVER be gated behind a confirmation dialog.
    // Enabling it, or changing the cadence while already on, is the panel's
    // job to gate behind the second warning dialog, by the time either of
    // these is called, that warning has already been accepted.
    function setActivenessOptedIn(value) {
        if (value && !root.optedIn)
            return;
        root.activenessOptedIn = value;
        _writeConfig();
        if (root.optedIn)
            _checkin();
    }

    function setActivenessCadence(secs) {
        root.activenessCadenceSecs = secs;
        _writeConfig();
        if (root.optedIn && root.activenessOptedIn)
            _checkin();
    }

    // Requests a fresh captcha challenge (`POST /captcha`)
    // `204`: token is already verified server-side
    // `200`: delivers a PNG image/png body, saved straight to disk
    // and pointed to by `captchaImagePath` for CommunityPanel's
    // dialog to display directly.
    function requestCaptcha() {
        if (root.token === "" || root.captchaBusy)
            return;
        root.captchaBusy = true;
        root.captchaError = "";
        root.captchaAttemptsRemaining = -1;
        var imgPath = root._configDir + "/captcha.png";
        captchaChallengeProc._imgPath = imgPath;
        captchaChallengeProc.command = ["sh", "-c", "mkdir -p " + _shellQuote(root._configDir) + " && curl -s -o " + _shellQuote(imgPath) + " -w '%{http_code}' --max-time 8 -X POST -H " + _shellQuote("Authorization: Bearer " + root.token) + " " + _shellQuote(root._apiBase + "/captcha")];
        captchaChallengeProc.running = false;
        captchaChallengeProc.running = true;
    }

    function _shellQuote(str) {
        return "'" + String(str).replace(/'/g, "'\\''") + "'";
    }

    // Submits an answer to whatever challenge is currently outstanding
    // (`POST /captcha/solve`). A wrong guess keeps the same challenge alive
    // (server-side attempt counter).
    function solveCaptcha(answer) {
        if (root.token === "")
            return;
        root.captchaBusy = true;
        captchaSolveReq.token = root.token;
        captchaSolveReq.body = JSON.stringify({
            answer: answer
        });
        captchaSolveReq.run();
    }

    function dismissCaptcha() {
        root.captchaImagePath = "";
        root.captchaError = "";
        root.captchaAttemptsRemaining = -1;
    }

    function _generateToken() {
        tokenGenProc.running = false;
        tokenGenProc.running = true;
    }

    Process {
        id: tokenGenProc
        command: ["cat", "/proc/sys/kernel/random/uuid"]

        stdout: StdioCollector {
            onStreamFinished: {
                var uuid = text.trim();
                // Malformed shapes should not get accepted.
                // An incorrect mount? Sandboxed? Either way, we deny it here.
                var looksValid = /^[0-9a-fA-F-]{36}$/.test(uuid);
                if (!looksValid) {
                    console.warn("LocationSharingService: failed to read a UUID from /proc/sys/kernel/random/uuid, got:", uuid);
                    return;
                }
                root.token = uuid;
                root.optedIn = true;
                root._writeConfig();
                root._checkin();
            }
        }
    }

    readonly property string _shellName: "Zesis"

    function _checkin() {
        if (root.token === "")
            return;
        var body = JSON.stringify({
            share_activeness: root.activenessOptedIn,
            activeness_cadence_secs: root.activenessOptedIn ? root.activenessCadenceSecs : null,
            shell: root._shellName
        });
        console.log("LocationSharingService: _checkin firing, body=" + body);
        checkinReq.token = root.token;
        checkinReq.body = body;
        checkinReq.run();
    }

    function _deleteCheckin() {
        if (root.token === "")
            return;
        deleteReq.token = root.token;
        deleteReq.run();
    }

    function _fetchLocations() {
        if (root.locationsLoading) {
            root._locationsFetchPending = true;
            return;
        }
        root.locationsLoading = true;
        fetchReq.run();
    }

    DiasporaRequest {
        id: checkinReq
        apiBase: root._apiBase
        path: "/checkin"
        httpMethod: "POST"
        onFinished: (code, status, body) => {
            console.log("LocationSharingService: checkin response - curl exit=" + code + " status=" + status + " body=" + body);
            if (code !== 0) {
                console.warn("LocationSharingService: checkin request failed to run (curl exit " + code + ")");
                return;
            }
            if (status !== "200" && status !== "201") {
                console.warn("LocationSharingService: checkin rejected, HTTP " + status + ":", body);
                return;
            }
            root._fetchLocations();
        }
    }

    DiasporaRequest {
        id: deleteReq
        apiBase: root._apiBase
        path: "/checkin"
        httpMethod: "DELETE"
        onFinished: (code, status, body) => {
            if (code !== 0) {
                console.warn("LocationSharingService: delete request failed to run (curl exit " + code + ")");
                return;
            }
            // 404 here just means the epoch-cleanup or a prior delete
            // already removed it server-side, not worth surfacing as a
            // failure to the user, the end state (not on the map) matches
            // what they asked for either way.
            if (status !== "204" && status !== "404") {
                console.warn("LocationSharingService: delete rejected, HTTP " + status);
            }
            root._fetchLocations();
        }
    }

    DiasporaRequest {
        id: fetchReq
        apiBase: root._apiBase
        path: "/locations"
        onFinished: (code, status, body) => {
            root.locationsLoading = false;
            if (code !== 0 || status !== "200") {
                console.warn("LocationSharingService: locations fetch failed (curl exit " + code + ", HTTP " + status + ")");
            } else {
                try {
                    root.locations = JSON.parse(body);
                } catch (e) {
                    console.warn("LocationSharingService: locations parse failed:", e);
                }
            }
            if (root._locationsFetchPending) {
                root._locationsFetchPending = false;
                root._fetchLocations();
            }
        }
    }

    // Unlike the three above, the challenge response body is binary
    // (image/png), SO it can't share the "-w '\n%{http_code}'" +
    // SplitParser split-on-lines I think???? I could not get it to work.
    // Something something 0x0A byte corruption nonsense. So instead we've gotta
    // use curl `-o` which redirects the body straight to disk, leaving
    // stdout carrying nothing but the bare status code. Simple enough to
    // read via StdioCollector + text.trim(), the same pattern tokenGenProc
    // above already uses for its own single-value (UUID) output.
    Process {
        id: captchaChallengeProc
        property string _imgPath: ""
        stdout: StdioCollector {
            onStreamFinished: {
                root.captchaBusy = false;
                var status = text.trim();
                if (status === "204") {
                    root.verified = true;
                    root._writeConfig();
                    return;
                }
                if (status === "200") {
                    root.captchaNonce++;
                    root.captchaImagePath = "file://" + captchaChallengeProc._imgPath + "?r=" + root.captchaNonce;
                    return;
                }
                if (status === "429") {
                    root.captchaError = "too_soon";
                } else if (status === "404") {
                    root.captchaError = "unknown_token";
                } else {
                    console.warn("LocationSharingService: captcha challenge request failed, HTTP " + status);
                    root.captchaError = "request_failed";
                }
            }
        }
    }

    DiasporaRequest {
        id: captchaSolveReq
        apiBase: root._apiBase
        path: "/captcha/solve"
        httpMethod: "POST"
        onFinished: (code, status, body) => {
            root.captchaBusy = false;
            if (code !== 0) {
                console.warn("LocationSharingService: captcha solve request failed to run (curl exit " + code + ")");
                root.captchaError = "request_failed";
                return;
            }
            if (status === "200") {
                root.verified = true;
                root.captchaImagePath = "";
                root.captchaError = "";
                root.captchaAttemptsRemaining = -1;
                root._writeConfig();
                return;
            }
            try {
                var parsed = JSON.parse(body);
                root.captchaError = parsed.error || "request_failed";
                root.captchaAttemptsRemaining = typeof parsed.attempts_remaining === "number" ? parsed.attempts_remaining : -1;
            } catch (e) {
                console.warn("LocationSharingService: captcha solve response parse failed:", e);
                root.captchaError = "request_failed";
            }
        }
    }

    Component.onCompleted: root._fetchLocations()

    // The startup checkin itself DOES need the persisted config
    // (optedIn/token/activenessOptedIn) to be loaded first.
    onReadyChanged: {
        if (!root.ready)
            return;
        console.log("LocationSharingService: config ready - optedIn=" + root.optedIn + " token=" + (root.token !== "" ? "(set)" : "(empty)") + " activenessOptedIn=" + root.activenessOptedIn);
        if (root.optedIn && root.token !== "")
            root._checkin();
        else
            console.log("LocationSharingService: startup checkin skipped (not opted in or no token)");
    }

    // We do not align to the server's Monday-00:00-UTC wipe boundary.
    // Now you might ask: Why?
    // It'll tell ya why:
    //
    // A plain 24h-from-launch interval already avoids a synchronized
    // thundering herd by construction. Different users launching at
    // different real times keeps this naturally desynchronized without
    // needing epoch math on the client! Otherwise we would DDOS Squirrel.
    // A self-inflicted DDOS. There is a kind of beauty in that...
    //
    // It kinda makes me want to synchronize it. For shits and giggles.
    //
    // When activeness is on, its cadence takes over entirely, every checkin
    // already refreshes both the base presence and (when enabled) the
    // activeness recency bucket.
    Timer {
        interval: (root.activenessOptedIn ? root.activenessCadenceSecs : 24 * 3600) * 1000
        running: root.optedIn
        repeat: true
        onTriggered: root._checkin()
    }

    Timer {
        interval: 60 * 1000
        running: true
        repeat: true
        onTriggered: root._fetchLocations()
    }

    function _writeConfig() {
        var json = JSON.stringify({
            optedIn: root.optedIn,
            token: root.token,
            activenessOptedIn: root.activenessOptedIn,
            activenessCadenceSecs: root.activenessCadenceSecs,
            verified: root.verified,
            showActiveOnly: root.showActiveOnly,
            showVerifiedOnly: root.showVerifiedOnly,
            showBackgroundGlobe: root.showBackgroundGlobe,
            settingsCollapsed: root.settingsCollapsed
        });
        // 600, this file holds a bearer secret once a token exists
        configWriteProc.command = ["sh", "-c", "mkdir -p " + _shellQuote(root._configDir) + " && printf '%s' " + _shellQuote(json) + " > " + _shellQuote(root._configPath) + " && chmod 600 " + _shellQuote(root._configPath)];
        configWriteProc.running = false;
        configWriteProc.running = true;
    }

    Process {
        id: configWriteProc
    }

    JsonAdapter {
        id: config
        property bool optedIn: false
        property string token: ""
        property bool activenessOptedIn: false
        property int activenessCadenceSecs: 3600
        property bool verified: false
        property bool showActiveOnly: false
        property bool showVerifiedOnly: false
        property bool showBackgroundGlobe: false
        property bool settingsCollapsed: false
    }

    FileView {
        path: root._configPath
        watchChanges: true
        adapter: config
        onFileChanged: reload()

        onLoaded: root.ready = true
    }
}
