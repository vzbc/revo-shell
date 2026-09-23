pragma Singleton
import QtQuick
import Quickshell

// Aggregate network stats for the globe panel's sidebar, all of this is
// `GET /stats`, public and unauthenticated (see diaspora's README "Stats")
Singleton {
    id: root

    readonly property string _apiBase: "https://diaspora.talosvault.net"

    property bool loading: false
    property bool lastFetchFailed: false

    property int totalEntries: 0
    property int verifiedEntries: 0
    property int activeEntries: 0

    // [{ value: string, total: int, verified: int }, ...] shell whitelist
    // only (see README "Consent tiers"), sorted by total, largest first.
    property var shellStats: []

    // [{ dayStartUnix: int, total: int, verified: int, active: int }, ...],
    // oldest first
    property var dailyHistory: []

    function _fetchStats() {
        root.loading = true;
        fetchReq.run();
    }

    DiasporaRequest {
        id: fetchReq
        apiBase: root._apiBase
        path: "/stats"
        onFinished: (code, status, body) => {
            root.loading = false;
            if (code !== 0 || status !== "200") {
                console.warn("DiasporaStatsService: stats fetch failed (curl exit " + code + ", HTTP " + status + ")");
                root.lastFetchFailed = true;
                return;
            }
            try {
                var parsed = JSON.parse(body);
                root.totalEntries = parsed.total_entries || 0;
                root.verifiedEntries = parsed.verified_entries || 0;
                root.activeEntries = parsed.active_entries || 0;
                root.shellStats = (parsed.shell || []).slice().sort((a, b) => b.total - a.total);
                root.dailyHistory = (parsed.daily_history || []).map(d => ({
                            dayStartUnix: d.day_start_unix,
                            total: d.total,
                            verified: d.verified,
                            active: d.active
                        }));
                root.lastFetchFailed = false;
            } catch (e) {
                console.warn("DiasporaStatsService: stats parse failed:", e);
                root.lastFetchFailed = true;
            }
        }
    }

    Component.onCompleted: root._fetchStats()

    Timer {
        interval: 5 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root._fetchStats()
    }
}
