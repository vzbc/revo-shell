pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../"
import "../home"
import "../settings"
import "../lockscreen"
import "../shared"
import "../workspaceindicator/disc"

// This is the entire bar layout.
// It consists of "zones" laid which are divided out into fractions.
// Zone 0, 1 and 2 are always allocated, no matter what.
// Zone 0 and N-1 are always flush to the edge of the monitor.
// Each zone has an island, and each island atoms.
Item {
    id: root

    // Screen name this bar instance renders on
    property string screenName: ""

    readonly property real _pad: Math.round(24 * UIScale.value)
    readonly property real _gap: 4
    readonly property real _pillGap: Math.round(10 * UIScale.value)
    // Gap between adjacent zones
    readonly property real _zoneGap: Math.round(72 * UIScale.value)
    readonly property real _chevronWidth: Math.round(30 * UIScale.value)
    readonly property int _spawnHoldMs: 500

    readonly property int _spawnZoneHoldMs: 400
    readonly property real _zoneTickRadius: Math.round(24 * UIScale.value)
    readonly property real _emptyZoneCatchmentHalfWidth: Math.round(40 * UIScale.value)

    readonly property var _catalogById: {
        var m = {};
        var arr = BarItemsService.orderedItems;
        for (var i = 0; i < arr.length; i++)
            m[arr[i].id] = arr[i];
        return m;
    }
    function _catalogItem(id) {
        return root._catalogById[id];
    }

    // Pushed by each TrayItemSlot by onItemAvailableChanged
    property var _availabilityMap: ({})

    function _isAvailable(id) {
        return root._availabilityMap[id] !== false;
    }

    // We need to measure width after mount, so for example Airpods or
    // battery etc. Otherwise they are stale values.
    property var _widthMap: ({})
    property var _heightMap: ({})

    function _availableIdsIn(ids) {
        var out = [];
        for (var i = 0; i < ids.length; i++)
            if (root._isAvailable(ids[i]))
                out.push(ids[i]);
        return out;
    }

    // All zones filtered to show islands with only actice ids
    readonly property var _allZoneIslandGroups: {
        var raw = BarItemsService.zones;
        var out = [];
        for (var zi = 0; zi < raw.length; zi++) {
            var groups = raw[zi];
            var filtered = [];
            for (var j = 0; j < groups.length; j++) {
                var isl = [];
                for (var k = 0; k < groups[j].length; k++)
                    if (BarItemsService.isEnabled(groups[j][k]))
                        isl.push(groups[j][k]);
                if (isl.length > 0)
                    filtered.push(isl);
            }
            out.push(filtered);
        }
        return out;
    }

    // Zones which hold at least 1 enabled island, index tagged.
    readonly property var _liveZones: {
        var out = [];
        for (var zi = 0; zi < root._allZoneIslandGroups.length; zi++)
            if (root._allZoneIslandGroups[zi].length > 0)
                out.push({
                    rawIndex: zi,
                    islandGroups: root._allZoneIslandGroups[zi]
                });
        return out;
    }

    // Whatever axis the flows on is the natural width
    function _islandNaturalWidth(ids) {
        var avail = root._availableIdsIn(ids);
        var used = 0;
        for (var i = 0; i < avail.length; i++)
            used += (i > 0 ? root._gap : 0) + (BarConfig.isVertical ? root._itemHeight(avail[i]) : root._itemWidth(avail[i]));
        return used;
    }

    function _fitCountFor(ids, budget) {
        if (budget < 0)
            return ids.length;
        var innerBudget = budget - root._pad;

        // Logic
        // Can everything fit with no chevron? If not, perform a reserve-based
        // greedy loop, it'll reserve room for a chevron. This makes items
        // shrink gradually.
        var totalNatural = 0;
        for (var t = 0; t < ids.length; t++)
            totalNatural += (t > 0 ? root._gap : 0) + (BarConfig.isVertical ? root._itemHeight(ids[t]) : root._itemWidth(ids[t]));
        if (totalNatural <= innerBudget)
            return ids.length;

        var used = 0;
        var count = 0;
        for (var i = ids.length - 1; i >= 0; i--) {
            var w = BarConfig.isVertical ? root._itemHeight(ids[i]) : root._itemWidth(ids[i]);
            var next = used + (count > 0 ? root._gap : 0) + w;
            var reserve = (i > 0) ? (root._gap + root._chevronWidth) : 0;
            if (next + reserve > innerBudget)
                break;
            used = next;
            count++;
        }
        return count;
    }

    // Is this idlands pill background and padding suppressed?
    function _islandPad(ids) {
        var isWorkspaceOnly = ids.length === 1 && ids[0] === "workspace";
        var suppressed = isWorkspaceOnly && (WorkspaceDiscService.tuckEnabled || !WorkspaceDiscService.showIslandBackground);
        return suppressed ? 0 : root._pad;
    }

    // Minimum width of a non-empty island when collapsed.
    function _islandMinWidth(ids) {
        var avail = root._availableIdsIn(ids);
        if (avail.length === 0)
            return 0;
        var pad = root._islandPad(ids);
        return Math.min(root._islandNaturalWidth(ids) + pad, pad + root._chevronWidth);
    }

    // Per-island width budget within a zone, given that zone's own
    // allocated width.
    function _islandBudgetsForZone(rawIndex, zoneWidth) {
        var groups = root._allZoneIslandGroups[rawIndex] || [];
        var n = groups.length;
        var budgets = new Array(n);
        if (zoneWidth < 0) {
            for (var i = 0; i < n; i++)
                budgets[i] = -1;
            return budgets;
        }
        var mins = new Array(n);
        var naturals = new Array(n);
        var totalMin = 0;

        var visibleCount = 0;
        for (var i = 0; i < n; i++) {
            var ids = groups[i];
            if (root._availableIdsIn(ids).length === 0) {
                mins[i] = 0;
                naturals[i] = 0;
                budgets[i] = 0;
                continue;
            }
            mins[i] = root._islandMinWidth(ids);
            naturals[i] = Math.max(mins[i], root._islandNaturalWidth(ids) + root._islandPad(ids));
            totalMin += mins[i];
            budgets[i] = mins[i];
            visibleCount++;
        }
        var available = zoneWidth - Math.max(0, visibleCount - 1) * root._pillGap;
        var bonus = Math.max(0, available - totalMin);
        for (var j = n - 1; j >= 0; j--) {
            var extra = naturals[j] - mins[j];
            if (extra <= 0)
                continue;
            var give = Math.min(extra, bonus);
            budgets[j] += give;
            bonus -= give;
            if (budgets[j] >= naturals[j])
                budgets[j] = -1;
        }
        return budgets;
    }

    function _islandRenderedWidth(ids, budget) {
        var avail = root._availableIdsIn(ids);
        if (avail.length === 0)
            return 0;
        var pad = root._islandPad(ids);
        if (budget < 0)
            return root._islandNaturalWidth(ids) + pad;
        var fitCount = root._fitCountFor(avail, budget);
        var hasOverflow = fitCount < avail.length;
        var used = 0;
        for (var i = avail.length - fitCount; i < avail.length; i++)
            used += (used > 0 ? root._gap : 0) + (BarConfig.isVertical ? root._itemHeight(avail[i]) : root._itemWidth(avail[i]));
        if (hasOverflow)
            used += (used > 0 ? root._gap : 0) + root._chevronWidth;
        return Math.max(used + pad, root._islandMinWidth(ids));
    }

    // Per-island x offset and width, in islandGroups order.
    // When there are no pinned atoms, we just use a singular row instead
    function _islandLayout(rawIndex, budgetWidth) {
        var groups = root._allZoneIslandGroups[rawIndex] || [];
        var n = groups.length;
        var widths = new Array(n).fill(0);
        var visible = new Array(n).fill(false);
        var anchorIdx = -1;
        var totalRaw = BarItemsService.zones.length;
        var canPin = rawIndex !== 0 && rawIndex !== totalRaw - 1;
        var budgets = (budgetWidth !== undefined && budgetWidth >= 0) ? root._islandBudgetsForZone(rawIndex, budgetWidth) : null;
        for (var i = 0; i < n; i++) {
            var avail = root._availableIdsIn(groups[i]);
            if (avail.length === 0)
                continue;
            visible[i] = true;
            widths[i] = budgets ? root._islandRenderedWidth(groups[i], budgets[i]) : Math.max(root._islandMinWidth(groups[i]), root._islandNaturalWidth(groups[i]) + root._islandPad(groups[i]));
            if (canPin && anchorIdx < 0)
                for (var j = 0; j < avail.length; j++)
                    if (BarItemsService.isPinned(avail[j])) {
                        anchorIdx = i;
                        break;
                    }
        }

        var xs = new Array(n).fill(0);
        var totalWidth = 0;

        if (anchorIdx < 0) {
            var flowW = 0;
            for (var k = 0; k < n; k++)
                if (visible[k])
                    flowW += (flowW > 0 ? root._pillGap : 0) + widths[k];
            var cursor = -flowW / 2;
            for (var m = 0; m < n; m++) {
                if (!visible[m])
                    continue;
                if (cursor > -flowW / 2)
                    cursor += root._pillGap;
                xs[m] = cursor;
                cursor += widths[m];
            }
            totalWidth = flowW;
        } else {
            var leftW = 0, rightW = 0;
            for (var l = 0; l < anchorIdx; l++)
                if (visible[l])
                    leftW += (leftW > 0 ? root._pillGap : 0) + widths[l];
            for (var r = anchorIdx + 1; r < n; r++)
                if (visible[r])
                    rightW += (rightW > 0 ? root._pillGap : 0) + widths[r];
            var side = Math.max(leftW, rightW);
            totalWidth = widths[anchorIdx] + 2 * (side + root._pillGap);

            var anchorX = -widths[anchorIdx] / 2;
            xs[anchorIdx] = anchorX;

            var leftEdge = anchorX - root._pillGap;
            for (var li = anchorIdx - 1; li >= 0; li--) {
                if (!visible[li])
                    continue;
                leftEdge -= widths[li];
                xs[li] = leftEdge;
                leftEdge -= root._pillGap;
            }

            var rightEdge = anchorX + widths[anchorIdx] + root._pillGap;
            for (var ri = anchorIdx + 1; ri < n; ri++) {
                if (!visible[ri])
                    continue;
                xs[ri] = rightEdge;
                rightEdge += widths[ri] + root._pillGap;
            }
        }

        return {
            xs: xs,
            widths: widths,
            visible: visible,
            anchorIdx: anchorIdx,
            totalWidth: totalWidth
        };
    }

    function _zoneNaturalWidth(rawIndex) {
        return root._islandLayout(rawIndex).totalWidth;
    }

    // Minimum rendered width of a non-empty zone. All of its islands collapsed
    // to its own floor (_islandMinWidth).
    function _zoneMinWidth(rawIndex) {
        var groups = root._allZoneIslandGroups[rawIndex] || [];
        var sum = 0, count = 0;
        for (var i = 0; i < groups.length; i++) {
            var avail = root._availableIdsIn(groups[i]);
            if (avail.length === 0)
                continue;
            sum += (count > 0 ? root._pillGap : 0) + root._islandMinWidth(groups[i]);
            count++;
        }
        return sum;
    }

    // Positions are absolute for all zones. They are at fixed fractions.
    // I.e. the raw index divided by  zone count total.
    readonly property var _zoneLayout: {
        var liveRaw = [];
        for (var i = 0; i < root._liveZones.length; i++) {
            var rawIdx = root._liveZones[i].rawIndex;
            if (root._zoneNaturalWidth(rawIdx) > 0)
                liveRaw.push(rawIdx);
        }
        var n = liveRaw.length;
        if (n === 0)
            return [];

        var totalRaw = BarItemsService.zones.length;
        var mainSize = BarConfig.isVertical ? root.height : root.width;
        var usable = Math.max(0, mainSize - 2 * BarConfig.endGap);

        var mins = new Array(n), naturals = new Array(n);
        for (var i = 0; i < n; i++) {
            mins[i] = root._zoneMinWidth(liveRaw[i]);
            naturals[i] = root._zoneNaturalWidth(liveRaw[i]);
        }

        var positions = new Array(n), widths = new Array(n);

        // Interior zones first. Fixed center, full width always!
        var centerIdxs = [];
        for (var k = 0; k < n; k++) {
            var rawIdx = liveRaw[k];
            if (rawIdx !== 0 && rawIdx !== totalRaw - 1)
                centerIdxs.push(k);
        }
        for (var c = 0; c < centerIdxs.length; c++) {
            var ci = centerIdxs[c];
            var frac = (totalRaw > 1) ? (liveRaw[ci] / (totalRaw - 1)) : 0.5;
            widths[ci] = naturals[ci];
            positions[ci] = frac * usable - widths[ci] / 2;
            if (c > 0) {
                var prev = centerIdxs[c - 1];
                var prevEdge = positions[prev] + widths[prev] + root._zoneGap;
                if (positions[ci] < prevEdge)
                    positions[ci] = prevEdge;
            }
        }

        var leftIdx = liveRaw.indexOf(0);
        var rightIdx = liveRaw.indexOf(totalRaw - 1);

        if (centerIdxs.length > 0) {
            var firstC = centerIdxs[0];
            var lastC = centerIdxs[centerIdxs.length - 1];
            if (leftIdx >= 0) {
                var leftRoom = Math.max(0, positions[firstC] - root._zoneGap);
                widths[leftIdx] = Math.max(mins[leftIdx], Math.min(naturals[leftIdx], leftRoom));
                positions[leftIdx] = 0;
            }
            if (rightIdx >= 0) {
                var farEdge = positions[lastC] + widths[lastC] + root._zoneGap;
                var rightRoom = Math.max(0, usable - farEdge);
                widths[rightIdx] = Math.max(mins[rightIdx], Math.min(naturals[rightIdx], rightRoom));
                positions[rightIdx] = usable - widths[rightIdx];
            }
        } else {
            // No interior zone live right now
            var edgeIdxs = [];
            if (leftIdx >= 0)
                edgeIdxs.push(leftIdx);
            if (rightIdx >= 0)
                edgeIdxs.push(rightIdx);
            var totalGap = Math.max(0, edgeIdxs.length - 1) * root._zoneGap;
            var availableForZones = Math.max(0, usable - totalGap);
            var totalMin = 0;
            for (var e = 0; e < edgeIdxs.length; e++) {
                widths[edgeIdxs[e]] = mins[edgeIdxs[e]];
                totalMin += mins[edgeIdxs[e]];
            }
            var bonus = Math.max(0, availableForZones - totalMin);
            for (var e2 = edgeIdxs.length - 1; e2 >= 0; e2--) {
                var idx = edgeIdxs[e2];
                var extra = naturals[idx] - mins[idx];
                if (extra > 0) {
                    var give = Math.min(extra, bonus);
                    widths[idx] += give;
                    bonus -= give;
                }
            }
            if (leftIdx >= 0)
                positions[leftIdx] = 0;
            if (rightIdx >= 0)
                positions[rightIdx] = usable - widths[rightIdx];
        }

        var out = [];
        for (var m = 0; m < n; m++)
            out.push({
                rawIndex: liveRaw[m],
                pos: positions[m],
                width: widths[m],
                budget: widths[m]
            });
        return out;
    }

    function _zoneWidthFor(rawIndex) {
        for (var i = 0; i < root._zoneLayout.length; i++)
            if (root._zoneLayout[i].rawIndex === rawIndex)
                return root._zoneLayout[i].budget;
        return -1;
    }

    // Effective bounds for every raw zone. Ordered in raw-index.
    // Live zones computes rendered pos/width from _zoneLayout.
    // Empty zones get a fixed-size placeholder centered on the same fixed
    // anchor fraction _zoneLayout would use if they had content, so they
    // stay a reachable drop target and a sensible gap reference point.
    readonly property var _allZoneBounds: {
        var totalRaw = BarItemsService.zones.length;
        if (totalRaw === 0)
            return [];
        var mainSize = BarConfig.isVertical ? root.height : root.width;
        var usable = Math.max(0, mainSize - 2 * BarConfig.endGap);
        var byRaw = {};
        for (var i = 0; i < root._zoneLayout.length; i++)
            byRaw[root._zoneLayout[i].rawIndex] = root._zoneLayout[i];
        var out = [];
        for (var idx = 0; idx < totalRaw; idx++) {
            var entry = byRaw[idx];
            if (entry) {
                out.push({
                    rawIndex: idx,
                    start: entry.pos,
                    end: entry.pos + entry.width
                });
            } else {
                var frac = (totalRaw > 1) ? (idx / (totalRaw - 1)) : 0.5;
                var anchor = frac * usable;
                out.push({
                    rawIndex: idx,
                    start: anchor - root._emptyZoneCatchmentHalfWidth,
                    end: anchor + root._emptyZoneCatchmentHalfWidth
                });
            }
        }
        return out;
    }

    // The N+1 candidate zone-insertion slots (before raw zone 0, between
    // each adjacent pair of raw zones, after the last), positioned at the
    // midpoint of the gap between each pair's bounds. rawAt is the index to
    // splice a new zone at in BarItemsService.zones.
    readonly property var _zoneGapCandidates: {
        var bounds = root._allZoneBounds;
        var n = bounds.length;
        var mainSize = BarConfig.isVertical ? root.height : root.width;
        var usable = Math.max(0, mainSize - 2 * BarConfig.endGap);
        var totalRaw = BarItemsService.zones.length;
        var out = [];
        if (n === 0) {
            out.push({
                pos: usable / 2,
                rawAt: totalRaw,
                wide: true
            });
            return out;
        }
        out.push({
            pos: bounds[0].start / 2,
            rawAt: bounds[0].rawIndex,
            wide: false
        });
        for (var i = 1; i < n; i++) {
            out.push({
                pos: (bounds[i - 1].end + bounds[i].start) / 2,
                rawAt: bounds[i].rawIndex,
                wide: false
            });
        }
        out.push({
            pos: (bounds[n - 1].end + usable) / 2,
            rawAt: totalRaw,
            wide: false
        });
        return out;
    }

    function _zoneItemForRaw(rawIndex) {
        for (var i = 0; i < zonesRepeater.count; i++) {
            var z = zonesRepeater.itemAt(i);
            if (z && z.rawIndex === rawIndex)
                return z;
        }
        return null;
    }

    // Cross-zone geometry lookups. Searching every zone's own island Repeater
    function _pillFor(id) {
        for (var i = 0; i < zonesRepeater.count; i++) {
            var zoneItem = zonesRepeater.itemAt(i);
            if (!zoneItem)
                continue;
            var p = zoneItem.pillFor(id);
            if (p)
                return p;
        }
        return null;
    }

    function _slotFor(id) {
        var pill = root._pillFor(id);
        return pill ? pill.slotFor(id) : null;
    }

    function _itemWidth(id) {
        return root._widthMap[id] || 0;
    }

    function _itemHeight(id) {
        return root._heightMap[id] || 0;
    }

    function _isVisibleInRow(id) {
        var pill = root._pillFor(id);
        return pill ? pill.isVisibleInRow(id) : false;
    }

    // Item.mapToItem only works between items in the same window.
    // mapToGlobal/mapFromGlobal round-trip through screen coordinates, which
    // works whether item is in the same window as root or a different one.
    function _mapToRoot(item, x, y) {
        var g = item.mapToGlobal(x, y);
        return root.mapFromGlobal(g.x, g.y);
    }

    // Point-in-bounds test across every rendered island pill in every
    // zone. Returns { pill } or null. Strict bounds test, no tolerance.
    function _islandHitAt(pos) {
        for (var zi = 0; zi < zonesRepeater.count; zi++) {
            var zoneItem = zonesRepeater.itemAt(zi);
            if (!zoneItem || !zoneItem.visible)
                continue;
            var rep = zoneItem.islandsRepeater;
            for (var ii = 0; ii < rep.count; ii++) {
                var pill = rep.itemAt(ii);
                if (!pill || !pill.visible)
                    continue;
                var tl = pill.mapToItem(root, 0, 0);
                if (pos.x >= tl.x && pos.x <= tl.x + pill.width && pos.y >= tl.y && pos.y <= tl.y + pill.height)
                    return {
                        pill: pill
                    };
            }
        }
        return null;
    }

    // Zone catchment for island-spawn hit-testing.
    function _zoneIndexAtPos(pos) {
        var coord = BarConfig.isVertical ? pos.y : pos.x;
        var origin = BarConfig.endGap;
        var bounds = root._allZoneBounds;
        var cands = root._zoneGapCandidates;
        for (var i = 0; i < bounds.length; i++) {
            var loCand = cands[i];
            var hiCand = cands[i + 1];
            var lo = Math.min(origin + bounds[i].start, origin + loCand.pos + root._zoneTickRadius);
            var hi = Math.max(origin + bounds[i].end, origin + hiCand.pos - root._zoneTickRadius);
            if (coord >= lo && coord <= hi)
                return bounds[i].rawIndex;
        }
        return -1;
    }

    function _zoneGapCandidateAt(pos) {
        var coord = BarConfig.isVertical ? pos.y : pos.x;
        var origin = BarConfig.endGap;
        var cands = root._zoneGapCandidates;
        for (var i = 0; i < cands.length; i++) {
            if (cands[i].wide)
                return cands[i];
            if (Math.abs(coord - (origin + cands[i].pos)) <= root._zoneTickRadius)
                return cands[i];
        }
        return null;
    }

    // Nearest island-boundary insertion index within one zone (by raw
    // index), for both the island-spawn anchor and whole-island moves.
    function _islandInsertionIndexInZone(rawIndex, pos) {
        var zoneItem = root._zoneItemForRaw(rawIndex);
        if (!zoneItem)
            return 0;
        var coord = BarConfig.isVertical ? pos.y : pos.x;
        var rep = zoneItem.islandsRepeater;
        for (var i = 0; i < rep.count; i++) {
            var pill = rep.itemAt(i);
            if (!pill)
                continue;
            var c = pill.mapToItem(root, pill.width / 2, pill.height / 2);
            var cc = BarConfig.isVertical ? c.y : c.x;
            if (coord < cc)
                return i;
        }
        return rep.count;
    }

    // Merge target when the pointer is directly over a specific island
    // pill. It's unambiguous, resolved straight from pointer position.
    function _computeMergeTarget(draggedId, pos, pill) {
        var coord = BarConfig.isVertical ? pos.y : pos.x;
        var beforeId = "";
        for (var i = 0; i < pill.ids.length; i++) {
            var id = pill.ids[i];
            if (id === draggedId || !root._isVisibleInRow(id))
                continue;
            var slot = root._slotFor(id);
            if (!slot)
                continue;
            var center = slot.mapToItem(root, slot.width / 2, slot.height / 2);
            var centerCoord = BarConfig.isVertical ? center.y : center.x;
            if (coord < centerCoord) {
                beforeId = id;
                break;
            }
        }
        return {
            zoneRawIdx: pill.zoneRawIndex,
            islandIds: pill.ids.filter(function (x) {
                return x !== draggedId;
            }),
            beforeId: beforeId
        };
    }

    // Drag-to-reorder / merge / spawn-island / spawn-zone state.

    property var _dragItemData: null
    property real _dragItemW: 0
    property real _dragItemH: 0
    property point _dragPos: Qt.point(0, 0)
    property var _dragGrab: null

    property string _dropBeforeId: ""
    property int _dropTargetZoneRawIdx: -1
    // Non-null while hovering directly over a specific pill. That pill's
    // member ids (dragged id excluded). Null here means not over a pill. The
    // three-way gap disambiguation below (zone catchment / zone-insertion
    // tick / dead space) only runs when this is null.
    property var _dropTargetIslandIds: null

    property bool _spawnArmed: false
    property int _spawnTargetZoneRawIdx: -1
    property int _spawnBeforeIslandIdx: -1

    property bool _spawnZoneArmed: false
    property int _spawnZoneAtIndex: -1
    property real _spawnZonePos: 0

    // Identifies whichever hold-target the pointer is currently over, or ""
    // for pill-hover/dead-space.
    property string _holdTargetKey: ""

    function _setHoldTarget(key, timer) {
        if (key === root._holdTargetKey)
            return;
        spawnHoldTimer.stop();
        spawnZoneHoldTimer.stop();
        root._spawnArmed = false;
        root._spawnZoneArmed = false;
        root._holdTargetKey = key;
        if (timer)
            timer.restart();
    }

    // Whole-island drag state.
    property var _dragIslandIds: null
    property real _dragIslandW: 0
    property real _dragIslandH: 0
    property point _islandDragPos: Qt.point(0, 0)
    property var _islandDragGrab: null
    property int _islandDropZoneRawIdx: -1
    property int _islandDropIdx: -1

    readonly property string _dropEndTargetId: {
        if (!root._dragItemData || !root._dropTargetIslandIds || root._dropTargetIslandIds.length === 0)
            return "";
        return root._dropTargetIslandIds[root._dropTargetIslandIds.length - 1];
    }

    function _beginDrag(slot) {
        root._dragItemData = slot.itemData;
        root._dragItemW = slot.width;
        root._dragItemH = slot.height;
        root._dragGrab = null;
        root._setHoldTarget("");
        root._dropTargetIslandIds = null;
        root._dropTargetZoneRawIdx = -1;
        root._dropBeforeId = "";
        root._dragPos = root._mapToRoot(slot, slot.width / 2, slot.height / 2);
        if (slot.itemRef && slot.itemRef.grabToImage)
            slot.itemRef.grabToImage(function (result) {
                root._dragGrab = result;
            });
    }

    function _updateDragPos(p) {
        root._dragPos = p;

        var islandHit = root._islandHitAt(p);
        if (islandHit) {
            root._setHoldTarget("");
            var target = root._computeMergeTarget(root._dragItemData.id, p, islandHit.pill);
            root._dropTargetZoneRawIdx = target.zoneRawIdx;
            root._dropTargetIslandIds = target.islandIds;
            root._dropBeforeId = target.beforeId;
            return;
        }
        root._dropTargetZoneRawIdx = -1;
        root._dropTargetIslandIds = null;
        root._dropBeforeId = "";

        var rawIdx = root._zoneIndexAtPos(p);
        if (rawIdx >= 0) {
            root._spawnTargetZoneRawIdx = rawIdx;
            root._spawnBeforeIslandIdx = root._islandInsertionIndexInZone(rawIdx, p);
            root._setHoldTarget("zone:" + rawIdx, spawnHoldTimer);
            return;
        }

        var gapCand = root._zoneGapCandidateAt(p);
        if (gapCand) {
            root._spawnZoneAtIndex = gapCand.rawAt;
            root._spawnZonePos = gapCand.pos;
            root._setHoldTarget("gap:" + gapCand.rawAt, spawnZoneHoldTimer);
            return;
        }

        root._setHoldTarget("");
    }

    function _endDrag() {
        spawnHoldTimer.stop();
        spawnZoneHoldTimer.stop();
        if (root._dragItemData) {
            if (root._spawnZoneArmed) {
                BarItemsService.spawnZone(root._dragItemData.id, root._spawnZoneAtIndex);
            } else if (root._spawnArmed) {
                var zi = root._spawnTargetZoneRawIdx;
                var groups = root._allZoneIslandGroups[zi] || [];
                var idx = root._spawnBeforeIslandIdx;
                var anchorId = (idx >= 0 && idx < groups.length) ? groups[idx][0] : "";
                BarItemsService.spawnIsland(root._dragItemData.id, zi, anchorId);
            } else if (root._dropTargetIslandIds !== null) {
                BarItemsService.moveIconToIsland(root._dragItemData.id, root._dropTargetZoneRawIdx, root._dropTargetIslandIds, root._dropBeforeId);
            }
            // else released over dead space with nothing armed, no-op.
        }
        root._dragItemData = null;
        root._dragGrab = null;
        root._holdTargetKey = "";
        root._spawnArmed = false;
        root._spawnZoneArmed = false;
        root._dropTargetIslandIds = null;
        root._dropTargetZoneRawIdx = -1;
        root._dropBeforeId = "";
        root._spawnBeforeIslandIdx = -1;
        root._spawnTargetZoneRawIdx = -1;
        root._spawnZoneAtIndex = -1;
    }

    function _beginIslandDrag(pill) {
        root._dragIslandIds = pill.ids.slice();
        root._dragIslandW = pill.width;
        root._dragIslandH = pill.height;
        root._islandDragGrab = null;
        root._islandDropZoneRawIdx = pill.zoneRawIndex;
        root._islandDropIdx = pill.islandIndex;
        root._setHoldTarget("");
        if (pill.grabToImage)
            pill.grabToImage(function (result) {
                root._islandDragGrab = result;
            });
    }

    function _updateIslandDragPos(p) {
        root._islandDragPos = p;

        var rawIdx = root._zoneIndexAtPos(p);
        if (rawIdx >= 0) {
            root._setHoldTarget("");
            root._islandDropZoneRawIdx = rawIdx;
            root._islandDropIdx = root._islandInsertionIndexInZone(rawIdx, p);
            return;
        }

        var gapCand = root._zoneGapCandidateAt(p);
        if (gapCand) {
            root._spawnZoneAtIndex = gapCand.rawAt;
            root._spawnZonePos = gapCand.pos;
            root._setHoldTarget("gap:" + gapCand.rawAt, spawnZoneHoldTimer);
            return;
        }

        root._setHoldTarget("");
        // dead spacem, keep the last valid drop target (zone/idx)
    }

    function _endIslandDrag() {
        spawnZoneHoldTimer.stop();
        if (root._dragIslandIds) {
            if (root._spawnZoneArmed) {
                BarItemsService.spawnZoneWithIsland(root._dragIslandIds, root._spawnZoneAtIndex);
            } else {
                var rawIdx = root._islandDropZoneRawIdx;
                var groups = root._allZoneIslandGroups[rawIdx] || [];
                var idx = root._islandDropIdx;
                var anchorId = (idx >= 0 && idx < groups.length) ? groups[idx][0] : "";
                BarItemsService.moveIsland(root._dragIslandIds, rawIdx, anchorId);
            }
        }
        root._dragIslandIds = null;
        root._islandDragGrab = null;
        root._islandDropZoneRawIdx = -1;
        root._islandDropIdx = -1;
        root._setHoldTarget("");
        root._spawnZoneArmed = false;
        root._spawnZoneAtIndex = -1;
    }

    // The workspace renders beyond the bar for its popup effect.
    // This means its atom has no pixels of its own. PanelWindow is just
    // embedded into it.
    function _publishWorkspaceRect() {
        var slot = root._slotFor("workspace");
        if (!slot || !slot.itemRef)
            return;
        if (!slot.visible) {
            slot.itemRef.clearAtomRect();
            return;
        }
        var tl = slot.mapToItem(root, 0, 0);
        var size = BarConfig.isVertical ? slot.height : slot.width;
        var corner = root._workspaceCorner();
        slot.itemRef.setAtomRect({
            pos: (BarConfig.isVertical ? tl.y : tl.x) + size / 2,
            size: size,
            atCorner: corner.at,
            cornerFlip: corner.flip
        });
    }

    function _workspaceCorner() {
        var raw = BarItemsService.zones;
        if (raw.length === 0)
            return {
                at: false,
                flip: false
            };
        var firstZone = raw[0];
        if (firstZone.length > 0 && firstZone[0].length > 0 && firstZone[0][0] === "workspace")
            return {
                at: true,
                flip: false
            };
        var lastZone = raw[raw.length - 1];
        var lastIsland = lastZone.length > 0 ? lastZone[lastZone.length - 1] : null;
        if (!!lastIsland && lastIsland.length > 0 && lastIsland[lastIsland.length - 1] === "workspace")
            return {
                at: true,
                flip: true
            };
        return {
            at: false,
            flip: false
        };
    }

    on_ZoneLayoutChanged: Qt.callLater(root._publishWorkspaceRect)
    on_WidthMapChanged: Qt.callLater(root._publishWorkspaceRect)
    on_AvailabilityMapChanged: Qt.callLater(root._publishWorkspaceRect)

    Connections {
        target: BarItemsService
        function onZonesChanged() {
            Qt.callLater(root._publishWorkspaceRect);
        }
    }

    function beginWorkspaceDrag(w, h, barLocalX, barLocalY) {
        root._dragItemData = root._catalogItem("workspace");
        root._dragItemW = w;
        root._dragItemH = h;
        root._dragGrab = null;
        root._setHoldTarget("");
        root._dropTargetIslandIds = null;
        root._dropTargetZoneRawIdx = -1;
        root._dropBeforeId = "";
        root._dragPos = Qt.point(barLocalX, barLocalY);
    }
    function updateWorkspaceDragPos(barLocalX, barLocalY) {
        root._updateDragPos(Qt.point(barLocalX, barLocalY));
    }
    function setWorkspaceDragGrab(result) {
        root._dragGrab = result;
    }
    function endWorkspaceDrag() {
        root._endDrag();
    }

    onScreenNameChanged: Qt.callLater(root._publishWorkspaceRect)
    Component.onCompleted: Qt.callLater(root._publishWorkspaceRect)

    Timer {
        id: spawnHoldTimer
        interval: root._spawnHoldMs
        onTriggered: root._spawnArmed = true
    }

    Timer {
        id: spawnZoneHoldTimer
        interval: root._spawnZoneHoldMs
        onTriggered: root._spawnZoneArmed = true
    }

    Component {
        id: simpleButton
        BarButton {}
    }

    // The inner Loader stays active/visible, the wrapper's own visible is the
    // place overflow/disabled/unavailable state is expressed..
    component TrayItemSlot: Item {
        id: slot
        required property var itemData
        property bool forceVisible: false
        property bool reorderable: false

        readonly property real itemWidth: content.item ? content.implicitWidth : 0
        readonly property real itemHeight: content.item ? content.implicitHeight : 0
        readonly property var itemRef: content.item
        readonly property bool itemAvailable: content.item ? content.item.available !== false : true

        readonly property bool _isDragging: root._dragItemData !== null && root._dragItemData.id === slot.itemData.id
        readonly property bool _showDropBefore: root._dragItemData !== null && !slot._isDragging && root._dropBeforeId === slot.itemData.id
        readonly property bool _showDropAfter: root._dragItemData !== null && root._dropBeforeId === "" && root._dropEndTargetId === slot.itemData.id
        onItemAvailableChanged: {
            var m = Object.assign({}, root._availabilityMap);
            m[slot.itemData.id] = slot.itemAvailable;
            root._availabilityMap = m;
        }
        onItemWidthChanged: {
            var m = Object.assign({}, root._widthMap);
            m[slot.itemData.id] = slot.itemWidth;
            root._widthMap = m;
        }
        onItemHeightChanged: {
            var m = Object.assign({}, root._heightMap);
            m[slot.itemData.id] = slot.itemHeight;
            root._heightMap = m;
        }

        Layout.alignment: Qt.AlignCenter
        visible: slot.forceVisible || root._isVisibleInRow(slot.itemData.id)
        Layout.preferredWidth: slot.itemWidth
        Layout.preferredHeight: slot.itemHeight
        implicitWidth: Layout.preferredWidth
        implicitHeight: Layout.preferredHeight

        DragHandler {
            id: dragHandler
            enabled: slot.reorderable
            target: null
            grabPermissions: PointerHandler.CanTakeOverFromItems | PointerHandler.CanTakeOverFromHandlersOfDifferentType

            onActiveChanged: {
                if (active)
                    root._beginDrag(slot);
                else
                    root._endDrag();
            }
            onCentroidChanged: {
                if (!active)
                    return;
                var p = root._mapToRoot(slot, centroid.position.x, centroid.position.y);
                root._updateDragPos(p);
            }
        }

        Rectangle {
            visible: slot._showDropBefore
            color: Colors.accent
            radius: 1
            z: 10
            width: BarConfig.isVertical ? parent.width : 2
            height: BarConfig.isVertical ? 2 : parent.height
            x: BarConfig.isVertical ? 0 : -root._gap / 2 - width / 2
            y: BarConfig.isVertical ? -root._gap / 2 - height / 2 : 0
        }
        Rectangle {
            visible: slot._showDropAfter
            color: Colors.accent
            radius: 1
            z: 10
            width: BarConfig.isVertical ? parent.width : 2
            height: BarConfig.isVertical ? 2 : parent.height
            x: BarConfig.isVertical ? 0 : parent.width + root._gap / 2 - width / 2
            y: BarConfig.isVertical ? parent.height + root._gap / 2 - height / 2 : 0
        }

        Loader {
            id: content
            active: BarItemsService.isEnabled(slot.itemData.id)
            visible: active && (item == null || item.available !== false)
            opacity: slot._isDragging ? 0.3 : 1

            Component.onCompleted: {
                if (slot.itemData.src)
                    content.source = slot.itemData.src;
                else
                    content.sourceComponent = simpleButton;
            }

            onLoaded: {
                if (!slot.itemData.src) {
                    content.item.icon = slot.itemData.icon ?? "";
                    if (slot.itemData.id === "home") {
                        content.item.active = Qt.binding(() => HomePanelService.open);
                        content.item.clicked.connect(() => {
                            HomePanelService.open = !HomePanelService.open;
                        });
                    } else if (slot.itemData.id === "settings") {
                        content.item.active = Qt.binding(() => SettingsPanelService.open);
                        content.item.clicked.connect(() => {
                            SettingsPanelService.open = !SettingsPanelService.open;
                        });
                    } else if (slot.itemData.id === "lock") {
                        content.item.clicked.connect(() => {
                            LockService.triggerLock();
                        });
                    }
                } else if (slot.itemData.id === "workspace") {
                    content.item.screenName = Qt.binding(() => root.screenName);
                    content.item.barZoneRow = root;
                }
            }
        }
    }

    // One pill per island. Background, GridLayout of items, overflow chevron,
    // popup, scoped to ids.
    component IslandPill: Rectangle {
        id: pill
        required property int zoneRawIndex
        required property int islandIndex
        required property var ids

        readonly property bool _suppressBackground: root._islandPad(pill.ids) === 0

        radius: 100
        color: pill._suppressBackground ? "transparent" : Colors.barBg
        visible: pill._availableIds.length > 0
        implicitWidth: BarConfig.isVertical ? Math.round(50 * UIScale.value) : (pillLayout.implicitWidth + (pill._suppressBackground ? 0 : root._pad))
        implicitHeight: BarConfig.isVertical ? (pillLayout.implicitHeight + (pill._suppressBackground ? 0 : root._pad)) : Math.round(50 * UIScale.value)

        readonly property var _availableIds: root._availableIdsIn(pill.ids)
        readonly property real _budget: root._islandBudgetsForZone(pill.zoneRawIndex, root._zoneWidthFor(pill.zoneRawIndex))[pill.islandIndex] ?? -1
        readonly property int _fitCount: root._fitCountFor(pill._availableIds, pill._budget)
        readonly property bool _hasOverflow: pill._fitCount < pill._availableIds.length

        function isOverflowed(id) {
            var idx = pill._availableIds.indexOf(id);
            return idx >= 0 && idx < (pill._availableIds.length - pill._fitCount);
        }
        function isVisibleInRow(id) {
            var idx = pill._availableIds.indexOf(id);
            return idx >= 0 && idx >= (pill._availableIds.length - pill._fitCount);
        }
        function slotFor(id) {
            var idx = pill.ids.indexOf(id);
            return idx >= 0 ? innerRepeater.itemAt(idx) : null;
        }

        readonly property real _maxOverflowedItemWidth: {
            var max = 0;
            for (var i = 0; i < pill._availableIds.length - pill._fitCount; i++) {
                var s = pill.slotFor(pill._availableIds[i]);
                if (s && s.itemWidth > max)
                    max = s.itemWidth;
            }
            return max;
        }
        readonly property real _maxOverflowedItemHeight: {
            var max = 0;
            for (var i = 0; i < pill._availableIds.length - pill._fitCount; i++) {
                var s = pill.slotFor(pill._availableIds[i]);
                if (s && s.itemHeight > max)
                    max = s.itemHeight;
            }
            return max;
        }

        // Moves the whole island as a block. Maybe even into another zone.
        // Only receives presses no child claims first.
        DragHandler {
            id: islandDragHandler
            target: null
            onActiveChanged: {
                if (active)
                    root._beginIslandDrag(pill);
                else
                    root._endIslandDrag();
            }
            onCentroidChanged: {
                if (!active)
                    return;
                var p = pill.mapToItem(root, centroid.position.x, centroid.position.y);
                root._updateIslandDragPos(p);
            }
        }

        GridLayout {
            id: pillLayout
            anchors.centerIn: parent
            rowSpacing: root._gap
            columnSpacing: root._gap
            rows: BarConfig.isVertical ? -1 : 1
            columns: BarConfig.isVertical ? 1 : -1

            Loader {
                id: chevronLoader
                Layout.alignment: Qt.AlignCenter
                active: pill._hasOverflow
                visible: active
                sourceComponent: BarButton {
                    icon: "»"
                    onClicked: islandPopup.visible ? islandPopup.close() : islandPopup.open()
                }
            }

            Repeater {
                id: innerRepeater
                model: pill.ids
                delegate: TrayItemSlot {
                    id: traySlot
                    required property string modelData
                    itemData: root._catalogItem(traySlot.modelData)
                    reorderable: true
                }
            }
        }

        AnimatedPopup {
            id: islandPopup
            anchorItem: chevronLoader
            implicitWidth: Math.max(Math.round(180 * UIScale.value), pill._maxOverflowedItemWidth + Math.round(90 * UIScale.value) + UIScale.spacingSm * 4)
            readonly property real _rowHeight: Math.max(Math.round(30 * UIScale.value), pill._maxOverflowedItemHeight)
            implicitHeight: Math.min(Math.round(320 * UIScale.value), Math.max(1, pill.ids.length - pill._fitCount) * (_rowHeight + 2) + Math.round(16 * UIScale.value))
            content: Component {
                Flickable {
                    contentWidth: width
                    contentHeight: overflowCol.implicitHeight
                    clip: true

                    ColumnLayout {
                        id: overflowCol
                        width: parent.width
                        spacing: 2

                        Repeater {
                            model: pill.ids
                            delegate: RowLayout {
                                id: ovRow
                                required property string modelData
                                readonly property bool overflowed: pill.isOverflowed(ovRow.modelData)
                                Layout.fillWidth: true
                                Layout.leftMargin: UIScale.spacingSm
                                Layout.rightMargin: UIScale.spacingSm
                                visible: ovRow.overflowed
                                spacing: UIScale.spacingSm

                                TrayItemSlot {
                                    itemData: root._catalogItem(ovRow.modelData)
                                    forceVisible: true
                                    reorderable: true
                                }
                                Text {
                                    text: root._catalogItem(ovRow.modelData).label
                                    Layout.fillWidth: true
                                    color: Colors.text
                                    font.pixelSize: UIScale.fontSmall
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component ZoneGroup: Item {
        id: zoneGroup
        required property int rawIndex
        required property var islandGroups

        readonly property alias islandsRepeater: islandsRepeaterInner

        readonly property var _availableIslandGroups: {
            var out = [];
            for (var i = 0; i < islandGroups.length; i++)
                if (root._availableIdsIn(islandGroups[i]).length > 0)
                    out.push(islandGroups[i]);
            return out;
        }

        visible: _availableIslandGroups.length > 0

        // Islands position and width calculate here. A pinned atom has a zone
        // which needs one atom fixed at the exact center with two independent
        // flanking runs around it.
        readonly property var _layout: root._islandLayout(zoneGroup.rawIndex, root._zoneWidthFor(zoneGroup.rawIndex))

        implicitWidth: BarConfig.isVertical ? Math.round(50 * UIScale.value) : _layout.totalWidth
        implicitHeight: BarConfig.isVertical ? _layout.totalWidth : Math.round(50 * UIScale.value)

        function pillFor(id) {
            for (var i = 0; i < islandsRepeaterInner.count; i++) {
                var p = islandsRepeaterInner.itemAt(i);
                if (p && p.ids.indexOf(id) >= 0)
                    return p;
            }
            return null;
        }

        Repeater {
            id: islandsRepeaterInner
            model: zoneGroup.islandGroups
            delegate: IslandPill {
                id: pill
                required property var modelData
                required property int index
                zoneRawIndex: zoneGroup.rawIndex
                islandIndex: index
                ids: modelData

                readonly property var _zoneLayout: zoneGroup._layout
                visible: pill._zoneLayout.visible[pill.index] ?? false

                x: BarConfig.isVertical ? (zoneGroup.width - pill.width) / 2 : zoneGroup.width / 2 + (pill._zoneLayout.xs[pill.index] ?? 0)
                y: BarConfig.isVertical ? zoneGroup.height / 2 + (pill._zoneLayout.xs[pill.index] ?? 0) : (zoneGroup.height - pill.height) / 2
            }
        }
    }

    Repeater {
        id: zonesRepeater
        model: root._liveZones
        delegate: ZoneGroup {
            id: zoneDelegate
            required property var modelData
            rawIndex: modelData.rawIndex
            islandGroups: modelData.islandGroups

            readonly property var _layoutEntry: {
                for (var i = 0; i < root._zoneLayout.length; i++)
                    if (root._zoneLayout[i].rawIndex === zoneDelegate.rawIndex)
                        return root._zoneLayout[i];
                return null;
            }

            // Trailing raw zone (e.g. the systray) is anchored to the edge
            // using its own renderedd width/height. _zoneLayout's width for
            // this zone is a budget. _fitCountFor fits a whole number of items
            // into that budget.
            readonly property bool _isTrailing: zoneDelegate.rawIndex === BarItemsService.zones.length - 1

            x: {
                if (BarConfig.isVertical)
                    return (root.width - width) / 2;
                if (zoneDelegate._isTrailing)
                    return root.width - BarConfig.endGap - width;
                return BarConfig.endGap + (_layoutEntry ? _layoutEntry.pos : 0);
            }
            y: {
                if (!BarConfig.isVertical)
                    return (root.height - height) / 2;
                if (zoneDelegate._isTrailing)
                    return root.height - BarConfig.endGap - height;
                return BarConfig.endGap + (_layoutEntry ? _layoutEntry.pos : 0);
            }
        }
    }

    // Zone insertion markers, visible during atom or islandd drag
    Repeater {
        model: (root._dragItemData !== null || root._dragIslandIds !== null) ? root._zoneGapCandidates : []
        delegate: Rectangle {
            id: tick
            required property var modelData
            required property int index
            visible: !modelData.wide
            readonly property bool _lit: root._holdTargetKey === ("gap:" + modelData.rawAt)
            readonly property real _size: _lit ? Math.round(10 * UIScale.value) : Math.round(5 * UIScale.value)
            width: _size
            height: _size
            radius: _size / 2
            color: _lit ? Colors.accent : Colors.muted
            opacity: _lit ? 0.9 : 0.35
            x: BarConfig.isVertical ? (root.width - width) / 2 : BarConfig.endGap + modelData.pos - width / 2
            y: BarConfig.isVertical ? BarConfig.endGap + modelData.pos - height / 2 : (root.height - height) / 2
            z: 998

            Behavior on width {
                NumberAnimation {
                    duration: Anim.fast
                }
            }
            Behavior on height {
                NumberAnimation {
                    duration: Anim.fast
                }
            }
        }
    }

    // Floating snapshot of the dragged item, following the pointer.
    Item {
        id: dragGhost
        visible: root._dragItemData !== null
        z: 1000
        width: root._dragItemW
        height: root._dragItemH
        x: root._dragPos.x - width / 2
        y: root._dragPos.y - height / 2
        opacity: 0.85

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: Colors.barBg
            border.color: Colors.accent
            border.width: 1
            visible: ghostImage.status !== Image.Ready
        }
        Image {
            id: ghostImage
            anchors.fill: parent
            source: root._dragGrab ? root._dragGrab.url : ""
            visible: status === Image.Ready
            smooth: true
        }
    }

    // Preview shown once a drag-out-and-hold has armed a new-island spawn
    // in an existing zone.
    Rectangle {
        id: spawnPreview
        visible: root._spawnArmed
        z: 999
        radius: 100
        color: Colors.barBg
        opacity: 0.5
        border.color: Colors.accent
        border.width: 2
        width: root._dragItemW + root._pad
        height: root._dragItemH
        x: root._dragPos.x - width / 2
        y: root._dragPos.y - height / 2
    }

    // Preview shown once a drag-out-and-hold has armed a brand new zone
    Item {
        id: spawnZonePreview
        visible: root._spawnZoneArmed
        z: 999
        width: (root._dragIslandIds !== null ? root._dragIslandW : root._dragItemW + root._pad)
        height: (root._dragIslandIds !== null ? root._dragIslandH : root._dragItemH)
        x: (BarConfig.isVertical ? (root.width - width) / 2 : BarConfig.endGap + root._spawnZonePos - width / 2)
        y: (BarConfig.isVertical ? BarConfig.endGap + root._spawnZonePos - height / 2 : (root.height - height) / 2)

        Rectangle {
            anchors.fill: parent
            radius: 100
            color: "transparent"
            border.color: Colors.accent
            border.width: 2
        }
        Text {
            anchors.centerIn: parent
            text: "+"
            color: Colors.accent
            font.pixelSize: UIScale.fontLead
            font.bold: true
        }
    }

    // Floating snapshot of a whole island being dragged
    Item {
        id: islandDragGhost
        visible: root._dragIslandIds !== null
        z: 1000
        readonly property real _ghostScale: 0.55
        width: root._dragIslandW * _ghostScale
        height: root._dragIslandH * _ghostScale
        x: root._islandDragPos.x - width / 2
        y: root._islandDragPos.y - height / 2
        opacity: 0.6

        Rectangle {
            anchors.fill: parent
            radius: 100
            color: Colors.barBg
            border.color: Colors.accent
            border.width: 1
            visible: islandGhostImage.status !== Image.Ready
        }
        Image {
            id: islandGhostImage
            anchors.fill: parent
            source: root._islandDragGrab ? root._islandDragGrab.url : ""
            visible: status === Image.Ready
            smooth: true
        }
    }
}
