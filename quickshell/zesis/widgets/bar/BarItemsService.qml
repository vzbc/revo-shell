pragma Singleton
import QtQuick
import Quickshell
import "../../"

Singleton {
    id: root

    readonly property var items: [
        {
            id: "workspace",
            label: I18n.t("bar.itemWorkspace"),
            src: "../workspaceindicator/WorkspaceIndicator.qml"
        },
        {
            id: "systray",
            label: I18n.t("bar.itemSystray"),
            src: "SystrayItems.qml"
        },
        {
            id: "taskbar",
            label: I18n.t("bar.itemTaskbar"),
            src: "../taskbar/Taskbar.qml"
        },
        {
            id: "music",
            label: I18n.t("bar.itemMusic"),
            src: "../music/MusicChip.qml"
        },
        // The repaint of this widget causes 0.6% hits on the CPU in regular intervals
        {
            id: "sysmon",
            label: I18n.t("bar.itemSysmon"),
            src: "../sysmon/SysMonItem.qml"
        },
        {
            id: "theme",
            label: I18n.t("bar.itemTheme"),
            src: "../themeswitcher/ThemeSwitcherItem.qml"
        },
        {
            id: "keybinds",
            label: I18n.t("bar.itemKeybinds"),
            src: "../keybinds/KeybindsItem.qml"
        },
        {
            id: "bluetooth",
            label: I18n.t("bar.itemBluetooth"),
            src: "../bluetooth/BluetoothItem.qml"
        },
        {
            id: "airpods",
            label: I18n.t("bar.itemAirpods"),
            src: "../airpods/AirPods.qml"
        },
        {
            id: "wifi",
            label: I18n.t("bar.itemWifi"),
            src: "../wifi/WifiItem.qml"
        },
        {
            id: "weather",
            label: I18n.t("bar.itemWeather"),
            src: "../weather/WeatherItem.qml"
        },
        {
            id: "brightness",
            label: I18n.t("bar.itemBrightness"),
            src: "../brightness/BrightnessItem.qml"
        },
        {
            id: "sound",
            label: I18n.t("bar.itemSound"),
            src: "../sound/SoundItem.qml"
        },
        {
            id: "mic",
            label: I18n.t("bar.itemMic"),
            src: "../mic/MicItem.qml"
        },
        {
            id: "notifications",
            label: I18n.t("bar.itemNotifications"),
            src: "../notifications/NotificationsItem.qml"
        },
        {
            id: "config",
            label: I18n.t("bar.itemConfig"),
            src: "../config/ConfigItem.qml"
        },
        {
            id: "battery",
            label: I18n.t("bar.itemBattery"),
            src: "../battery/BatteryItem.qml"
        },
        {
            id: "record",
            label: I18n.t("bar.itemRecord"),
            src: "../record/RecordItem.qml"
        },
        {
            id: "gitupdate",
            label: I18n.t("bar.itemGitupdate"),
            src: "../gitupdate/GitUpdateItem.qml"
        },
        {
            id: "home",
            label: I18n.t("bar.itemHome"),
            icon: ""
        },
        {
            id: "settings",
            label: I18n.t("bar.itemSettings"),
            icon: "󰘮"
        },
        {
            id: "lock",
            label: I18n.t("bar.itemLock"),
            icon: "󰌾"
        },
        {
            id: "clock",
            label: I18n.t("bar.itemClock"),
            src: "../clock/ClockItem.qml"
        },
    ]

    property var _state: {
        const s = {};
        for (const item of items)
            s[item.id] = true;
        return s;
    }

    // Ordered list going from Zones -> Islands -> Atom ids Atoms are catalog
    // items, tray icons, taskbar and so on.
    property var zones: []

    // Flattened, catalog-object view of zones, for consumers that only care
    // about a flat list.
    readonly property var orderedItems: {
        const byId = {};
        for (const item of items)
            byId[item.id] = item;
        const result = [];
        for (const zone of root.zones)
            for (const group of zone)
                for (const id of group)
                    if (byId[id])
                        result.push(byId[id]);
        return result;
    }

    readonly property bool anyEnabled: {
        const s = _state;
        return items.some(item => s[item.id] !== false);
    }

    function isEnabled(id) {
        return _state[id] !== false;
    }

    function toggle(id) {
        const s = Object.assign({}, _state);
        s[id] = !isEnabled(id);
        _state = s;
        BarConfig.writeItemStates(s);
    }

    property var pinnedIds: BarConfig.pinnedIds

    function isPinned(id) {
        return root.pinnedIds.indexOf(id) >= 0;
    }

    function togglePin(id) {
        const next = root.pinnedIds.slice();
        const idx = next.indexOf(id);
        if (idx >= 0)
            next.splice(idx, 1);
        else
            next.push(id);
        root.pinnedIds = next;
        BarConfig.writePinnedIds(next);
    }

    // Clones the current zones structure into mutable arrays, for mutation
    // functions to work on before committing via _commitZones.
    function _cloneZones() {
        return root.zones.map(zone => zone.map(arr => arr.slice()));
    }

    // Removes id from wherever it currently lives (any zone, any island),
    // pruning the island it leaves behind if that empties it. Returns the
    // raw zone index id was removed from (-1 if not found), so the caller
    // can targeted-prune that specific zone via _maybePruneEmptyZone below
    // if it's now empty.
    function _removeAtom(zonesList, id) {
        for (let zi = 0; zi < zonesList.length; zi++) {
            const zone = zonesList[zi];
            for (let ii = 0; ii < zone.length; ii++) {
                const idx = zone[ii].indexOf(id);
                if (idx >= 0) {
                    zone[ii].splice(idx, 1);
                    if (zone[ii].length === 0)
                        zone.splice(ii, 1);
                    return zi;
                }
            }
        }
        return -1;
    }

    // Removes zonesList[rawIdx] if it's now empty and doing so wouldn't
    // bring the total zone count below the floor of 3.
    function _maybePruneEmptyZone(zonesList, rawIdx) {
        if (rawIdx >= 0 && rawIdx < zonesList.length && zonesList[rawIdx].length === 0 && zonesList.length > 3)
            zonesList.splice(rawIdx, 1);
    }

    // Floor guarantee
    function _commitZones(zonesList) {
        while (zonesList.length < 3)
            zonesList.push([]);
        root.zones = zonesList;
        BarConfig.writeZones(zonesList);
    }

    // Moves id to an explicit position within a specific island in
    // targetZoneIdx. targetIslandIds is a snapshot of that island's other
    // member ids (id itself excluded, whether or not it was already a
    // member there). beforeId is one of targetIslandIds to insert
    // before, or "" to append at that island's own end.
    function moveIconToIsland(id, targetZoneIdx, targetIslandIds, beforeId) {
        if (targetIslandIds.length === 0)
            return; // id dropped back into its own solo island, so no-op
        const zonesList = root._cloneZones();
        const sourceZoneIdx = root._removeAtom(zonesList, id);
        const targetZone = zonesList[targetZoneIdx];
        if (!targetZone)
            return;
        const target = targetZone.find(arr => arr.indexOf(targetIslandIds[0]) >= 0);
        if (!target)
            return;
        const at = beforeId ? target.indexOf(beforeId) : -1;
        target.splice(at < 0 ? target.length : at, 0, id);

        root._maybePruneEmptyZone(zonesList, sourceZoneIdx);
        root._commitZones(zonesList);
    }

    // Removes id from wherever it is and inserts it as a brand-new
    // single-item island in targetZoneIdx, immediately before the island
    // containing beforeIslandAnchorId, or at the end of that zone when "".
    function spawnIsland(id, targetZoneIdx, beforeIslandAnchorId) {
        const zonesList = root._cloneZones();
        const targetZone = zonesList[targetZoneIdx];
        if (!targetZone)
            return;
        let at = beforeIslandAnchorId ? targetZone.findIndex(arr => arr.indexOf(beforeIslandAnchorId) >= 0) : -1;
        let fromIdx = -1;
        for (let i = 0; i < targetZone.length; i++) {
            const idx = targetZone[i].indexOf(id);
            if (idx >= 0) {
                targetZone[i].splice(idx, 1);
                fromIdx = i;
                break;
            }
        }
        if (fromIdx >= 0) {
            if (targetZone[fromIdx].length === 0) {
                targetZone.splice(fromIdx, 1);
                if (at > fromIdx)
                    at--;
            }
        } else {
            const sourceZoneIdx = root._removeAtom(zonesList, id);
            root._maybePruneEmptyZone(zonesList, sourceZoneIdx);
        }
        targetZone.splice(at < 0 ? targetZone.length : at, 0, [id]);
        root._commitZones(zonesList);
    }

    // Moves a whole island (identified by any current member id in
    // islandIds. Its first is used as the anchor) into targetZoneIdx, to
    // sit immediately before the island containing beforeIslandAnchorId, or
    // at the end of that zone when "".
    function moveIsland(islandIds, targetZoneIdx, beforeIslandAnchorId) {
        if (islandIds.length === 0)
            return;
        const zonesList = root._cloneZones();
        let fromZoneIdx = -1, fromIslandIdx = -1;
        for (let zi = 0; zi < zonesList.length; zi++) {
            const idx = zonesList[zi].findIndex(arr => arr.indexOf(islandIds[0]) >= 0);
            if (idx >= 0) {
                fromZoneIdx = zi;
                fromIslandIdx = idx;
                break;
            }
        }
        if (fromZoneIdx < 0)
            return;
        const moving = zonesList[fromZoneIdx].splice(fromIslandIdx, 1)[0];
        const targetZone = zonesList[targetZoneIdx];
        if (!targetZone)
            return;
        const at = beforeIslandAnchorId ? targetZone.findIndex(arr => arr.indexOf(beforeIslandAnchorId) >= 0) : -1;
        targetZone.splice(at < 0 ? targetZone.length : at, 0, moving);
        root._maybePruneEmptyZone(zonesList, fromZoneIdx);
        root._commitZones(zonesList);
    }

    // Removes id from wherever it is and inserts it as a brand-new zone
    // (a single island containing just id) at atIndex in the zones list.
    // One of the N+1 candidate insertion slots (before zone 0, between each
    // adjacent pair, or after the last zone), resolved by the caller from
    // live rendered gap geometry.
    function spawnZone(id, atIndex) {
        const zonesList = root._cloneZones();
        const sourceZoneIdx = root._removeAtom(zonesList, id);
        let at = atIndex;
        if (sourceZoneIdx >= 0 && zonesList[sourceZoneIdx] && zonesList[sourceZoneIdx].length === 0 && zonesList.length > 3) {
            zonesList.splice(sourceZoneIdx, 1);
            if (at > sourceZoneIdx)
                at--;
        }
        at = Math.max(0, Math.min(at, zonesList.length));
        zonesList.splice(at, 0, [[id]]);
        root._commitZones(zonesList);
    }

    // Whole-island equivalent of spawnZone: removes the whole island
    // (islandIds, identified by its first member) from wherever it is and
    // inserts it as a brand-new zone containing exactly that island (all
    // its members, intact as one block) at atIndex.
    function spawnZoneWithIsland(islandIds, atIndex) {
        if (islandIds.length === 0)
            return;
        const zonesList = root._cloneZones();
        let fromZoneIdx = -1, fromIslandIdx = -1;
        for (let zi = 0; zi < zonesList.length; zi++) {
            const idx = zonesList[zi].findIndex(arr => arr.indexOf(islandIds[0]) >= 0);
            if (idx >= 0) {
                fromZoneIdx = zi;
                fromIslandIdx = idx;
                break;
            }
        }
        if (fromZoneIdx < 0)
            return;
        const moving = zonesList[fromZoneIdx].splice(fromIslandIdx, 1)[0];
        let at = atIndex;
        if (zonesList[fromZoneIdx].length === 0 && zonesList.length > 3) {
            zonesList.splice(fromZoneIdx, 1);
            if (at > fromZoneIdx)
                at--;
        }
        at = Math.max(0, Math.min(at, zonesList.length));
        zonesList.splice(at, 0, [moving]);
        root._commitZones(zonesList);
    }

    function _merge() {
        const raw = BarConfig.itemStates;
        const s = Object.assign({}, raw);
        let dirty = false;
        for (const item of items) {
            if (!(item.id in s)) {
                s[item.id] = true;
                dirty = true;
            }
        }
        const known = new Set(items.map(x => x.id));
        for (const id of Object.keys(s)) {
            if (!known.has(id)) {
                delete s[id];
                dirty = true;
            }
        }
        _state = s;
        if (dirty)
            BarConfig.writeItemStates(s);
    }

    // Drops ids/islands that no longer exist, appends brand-new catalog ids
    // into the last zone's last island, enforces the zones.length >= 3 floor.
    //
    // Also handles one-time migration.
    function _mergeZones() {
        const known = new Set(items.map(x => x.id));
        let raw = BarConfig.zones;
        let dirty = false;

        if (!raw || raw.length === 0) {
            dirty = true;
            const legacy = BarConfig._legacyItemIslands;
            raw = [[["workspace"]], [["music"], ["taskbar"]], (legacy && legacy.length > 0) ? legacy : []];
        }

        const seen = new Set();
        const result = [];
        for (const zone of raw) {
            const resultZone = [];
            for (const group of (zone || [])) {
                const filtered = group.filter(id => known.has(id) && !seen.has(id));
                if (filtered.length !== group.length)
                    dirty = true;
                filtered.forEach(id => seen.add(id));
                if (filtered.length > 0)
                    resultZone.push(filtered);
            }
            result.push(resultZone);
        }

        while (result.length < 3) {
            result.push([]);
            dirty = true;
        }

        if (!seen.has("workspace") && known.has("workspace")) {
            dirty = true;
            result[0].unshift(["workspace"]);
            seen.add("workspace");
        }

        const newIds = items.map(i => i.id).filter(id => id !== "workspace" && !seen.has(id));
        if (newIds.length > 0) {
            dirty = true;
            const lastZone = result[result.length - 1];
            if (lastZone.length > 0)
                lastZone[lastZone.length - 1] = lastZone[lastZone.length - 1].concat(newIds);
            else
                lastZone.push(newIds);
        }

        root.zones = result;
        if (dirty)
            BarConfig.writeZones(result);
    }

    Connections {
        target: BarConfig
        function onItemStatesChanged() {
            root._merge();
        }
        function onZonesChanged() {
            root._mergeZones();
        }
        function onReadyChanged() {
            if (BarConfig.ready) {
                root._merge();
                root._mergeZones();
            }
        }
    }
}
