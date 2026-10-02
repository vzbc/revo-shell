import QtQuick
import ".."
import "../Pages.js" as Pages
import "../PagesContent.js" as Content

Column {
    id: page

    property string pageId: ""
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    readonly property var meta: Pages.info[pageId] || {}
    readonly property var blocks: Content.content[pageId] || []

    // reactive bumps so every row re-reads config after a write
    readonly property var bumpU: Shell.userCfg
    readonly property var bumpE: Shell.eqCfg
    property int rev: 0

    width: parent ? parent.width : 700
    spacing: 12

    Timer {
        id: commit
        property var pending
        interval: 220
        repeat: false
        onTriggered: if (pending) { pending(); pending = null }
    }

    Placard {
        visible: meta.root === true
        iconFile: meta.root === true ? meta.icon : ""
        title: meta.root === true ? meta.title : ""
        subtitle: meta.subtitle !== undefined ? meta.subtitle : ""
    }

    Repeater {
        model: page.blocks.length > 0 ? page.blocks : [{
            rows: [{
                t: "No additional settings.",
                dim: true
            }]
        }]

        delegate: Column {
            id: block
            required property var modelData
            width: page.width
            spacing: 0

            SectionHeader {
                visible: modelData.header !== undefined && modelData.header.length > 0
                text: modelData.header !== undefined ? modelData.header : ""
            }

            GroupCard {
                Repeater {
                    model: modelData.rows

                    delegate: Loader {
                        id: rowLoader
                        required property var modelData
                        width: block.width
                        height: item ? item.height : 0

                        sourceComponent: modelData.sl !== undefined ? sliderComp : detailComp

                        Component {
                            id: sliderComp

                            DetailRow {
                                width: rowLoader.width
                                title: page.resolve(rowLoader.modelData.t || "")
                                subtitle: page.resolve(rowLoader.modelData.s || "")
                                iconFile: rowLoader.modelData.i || ""
                                isSlider: true
                                separator: rowLoader.modelData.sep === true
                                sliderValue: page.norm(rowLoader.modelData)
                                value: page.fmt(rowLoader.modelData, page.readVal(rowLoader.modelData))
                                onMoved: (v) => page.sliderMoved(rowLoader.modelData, v)
                            }
                        }

                        Component {
                            id: detailComp

                            DetailRow {
                                width: rowLoader.width
                                title: page.resolve(rowLoader.modelData.t || "")
                                subtitle: page.resolve(rowLoader.modelData.s || "")
                                iconFile: rowLoader.modelData.i || ""
                                value: page.fmt(rowLoader.modelData, page.readVal(rowLoader.modelData))
                                pickerOptions: rowLoader.modelData.opts !== undefined ? rowLoader.modelData.opts : []
                                chevron: rowLoader.modelData.c === true || rowLoader.modelData.to !== undefined
                                showSwitch: rowLoader.modelData.sw === true
                                switchOn: page.readBool(rowLoader.modelData)
                                showInfo: rowLoader.modelData.info === true
                                dimmed: rowLoader.modelData.dim === true
                                titleColor: rowLoader.modelData.red === true ? Theme.red : Theme.textPrimary

                                onClicked: {
                                    if (rowLoader.modelData.to !== undefined)
                                        page.navigate(rowLoader.modelData.to)
                                    page.activate(rowLoader.modelData)
                                }
                                onToggled: (checked) => page.setFlag(rowLoader.modelData, checked)
                                onPicked: (v) => page.writeVal(rowLoader.modelData, v)
                            }
                        }
                    }
                }
            }

            Text {
                visible: modelData.note !== undefined && modelData.note.length > 0
                x: 28
                width: parent.width - 56
                wrapMode: Text.WordWrap
                text: modelData.note !== undefined ? modelData.note : ""
                font { family: Theme.fontText; pixelSize: 12 }
                color: Theme.textSecondary
            }
        }
    }

    Item {
        width: 1
        height: 2
    }

    // ---------- generic config binding ----------

    function readVal(row) {
        bumpU; bumpE
        if (row.cfg !== undefined) {
            var v = Shell.uget(row.cfg, row.def !== undefined ? row.def : "")
            return v
        }
        if (row.ecfg !== undefined) {
            var e = Shell.eget(row.ecfg, row.def !== undefined ? row.def : "")
            return e
        }
        if (row.v !== undefined)
            return page.resolve(row.v)
        if (row.opts !== undefined)
            return row.value !== undefined ? row.value : row.opts[0]
        return ""
    }

    function writeVal(row, val, skipSideEffect) {
        if (row.cfg !== undefined)
            Shell.uset(row.cfg, val)
        else if (row.ecfg !== undefined)
            Shell.eset(row.ecfg, val)
        else if (row.valKey !== undefined)
            Shell.uset(row.valKey, val)

        rev++

        if (skipSideEffect === true)
            return
        sideEffects(row, val)
    }

    function sideEffects(row, val) {
        if (row.cmd !== undefined && row.cmd.length > 0)
            Shell.run(typeof val === "string" && row.cmdFmt !== undefined
                      ? row.cmdFmt.split("{v}").join(val)
                      : row.cmd)
        if (row.ipct !== undefined)
            Shell.ipc(row.ipct, row.ipcf, row.ipca !== undefined ? row.ipca : [])
        if (row.run !== undefined && row.run.length > 0)
            Shell.run(row.run)
        if (row.done !== undefined) {
            var fns = row.done
            for (var i = 0; i < fns.length; i++)
                Shell.ipc(fns[i][0], fns[i][1], fns[i][2] !== undefined ? fns[i][2] : [])
        }
    }

    function readBool(row) {
        bumpU; bumpE
        if (row.cfg !== undefined)
            return Shell.uget(row.cfg, row.def !== undefined ? row.def : false) === true
        if (row.ecfg !== undefined)
            return Shell.eget(row.ecfg, row.def !== undefined ? row.def : false) === true
        if (row.act !== undefined)
            return actState(row.act)
        return row.on === true
    }

    function actState(name) {
        switch (name) {
        case "spotlight": return Shell.eget("spotlight.enable", true) === true
        case "dockAutohide": return Shell.uget("dockAutohide", false) === true
        case "dockMagnification": return Shell.uget("dockMagnification", true) === true
        case "menubar.autohide": return Shell.eget("bar.autohide", false) === true
        case "menubar.enable": return Shell.eget("bar.enable", true) === true
        case "notch.enable": return Shell.eget("notch.enable", true) === true
        case "osd.enable": return Shell.eget("osd.enable", true) === true
        case "launchpad.enable": return Shell.eget("launchpad.enable", true) === true
        case "lock.enable": return Shell.eget("lockScreen.enable", true) === true
        case "dock.enable": return Shell.eget("dock.enable", true) === true
        case "desktop.enable": return Shell.eget("desktopEnable", true) === true
        case "widgets.enable": return Shell.eget("widgets.enable", true) === true
        case "reduceMotion": return Shell.eget("general.reduceMotion", false) === true
        }
        return false
    }

    function setAct(name, on) {
        switch (name) {
        case "spotlight": Shell.eset("spotlight.enable", on); break
        case "dockAutohide": Shell.uset("dockAutohide", on); Shell.eset("dock.autohide", on); break
        case "dockMagnification": Shell.uset("dockMagnification", on); Shell.eset("dock.magnify", on); break
        case "menubar.autohide": Shell.eset("bar.autohide", on); break
        case "menubar.enable": Shell.eset("bar.enable", on); Shell.ipc("menubar", "set", [on ? "true" : "false"]); break
        case "notch.enable": Shell.eset("notch.enable", on); break
        case "osd.enable": Shell.eset("osd.enable", on); break
        case "launchpad.enable": Shell.eset("launchpad.enable", on); break
        case "lock.enable": Shell.eset("lockScreen.enable", on); break
        case "dock.enable": Shell.eset("dock.enable", on); break
        case "desktop.enable": Shell.eset("wallpaper.desktopEnable", on); break
        case "widgets.enable": Shell.eset("widgets.enable", on); break
        case "reduceMotion": Shell.eset("general.reduceMotion", on); Shell.uset("reduceMotion", on); break
        }
        rev++
    }

    function setFlag(row, val) {
        if (row.act !== undefined) {
            setAct(row.act, val)
            sideEffects(row, val)
            return
        }
        if (row.cfg !== undefined || row.ecfg !== undefined || row.valKey !== undefined) {
            writeVal(row, val)
            return
        }
        row.on = val
        rev++
        sideEffects(row, val)
    }

    function activate(row) {
        if (row.cfg !== undefined || row.ecfg !== undefined)
            return
        if (row.act !== undefined) {
            setAct(row.act, !readBool(row))
            sideEffects(row, !readBool(row))
            return
        }
        if (row.opts !== undefined && row.valKey !== undefined) {
            var cur = readVal(row)
            var i = row.opts.indexOf(cur)
            writeVal(row, row.opts[(i + 1) % row.opts.length])
        }
        if (row.cmd !== undefined && row.sw !== true && row.opts === undefined)
            Shell.run(row.cmd)
        if (row.ipct !== undefined && row.sw !== true)
            Shell.ipc(row.ipct, row.ipcf, row.ipca !== undefined ? row.ipca : [])
    }

    function norm(row) {
        var min = row.min !== undefined ? row.min : 0
        var max = row.max !== undefined ? row.max : 100
        var v = parseFloat(readVal(row))
        if (isNaN(v))
            v = min
        if (max === min)
            return 0
        return Math.max(0, Math.min(1, (v - min) / (max - min)))
    }

    function sliderMoved(row, ratio) {
        var min = row.min !== undefined ? row.min : 0
        var max = row.max !== undefined ? row.max : 100
        var step = row.step !== undefined ? row.step : 0
        var v = min + ratio * (max - min)
        if (step > 0)
            v = Math.round(v / step) * step
        else
            v = Math.round(v * 100) / 100
        rev++
        commit.pending = function () { writeVal(row, v) }
        commit.restart()
    }

    function fmt(row, v) {
        if (row.sl !== undefined) {
            if (row.fmt !== undefined)
                return row.fmt.split("{v}").join(String(v))
            if (row.suffix !== undefined)
                return String(v) + row.suffix
            return String(v)
        }
        if (v === undefined || v === null)
            return ""
        if (typeof v === "boolean")
            return v ? "On" : "Off"
        return String(v)
    }

    property var _live: null

    function liveInfo() {
        if (_live !== null)
            return _live
        _live = ({
        host: Shell.execOut("hostname", 1200),
        user: Shell.execOut("id -un", 1200),
        model: Shell.execOut("cat /sys/class/dmi/id/product_name 2>/dev/null", 1200),
        serial: Shell.execOut("cat /sys/class/dmi/id/product_serial 2>/dev/null", 1200),
        cpu: Shell.execOut("lscpu 2>/dev/null | sed -n \"s/^Model name:[[:space:]]*//p\" | head -1", 1500),
        ram: Shell.execOut("free -h 2>/dev/null | awk \"/^Mem:/{print $2}\"", 1200),
        os: Shell.execOut("sed -n \"s/^PRETTY_NAME=//p\" /etc/os-release | tr -d '\\\"'", 1200),
        kernel: Shell.execOut("uname -r", 1200),
        ip: Shell.execOut("ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -1", 1500),
        uptime: Shell.execOut("uptime -p 2>/dev/null | sed \"s/^up //\"", 1500),
        country: Shell.execOut("locale -k country_name 2>/dev/null | awk -F'\"' \'/country_name/{print $2; exit}\'", 1500),
        lang: Shell.execOut("locale -k language 2>/dev/null | awk -F'\"' \'/language/{print $2; exit}\'", 1500)
        })
        return _live
    }

    function resolve(s) {
        if (s.indexOf("{storage}") >= 0)
            s = s.split("{storage}").join(SysInfo.fmt(SysInfo.usedBytes) + " of " + SysInfo.fmt(SysInfo.totalBytes) + " used")
        if (s.indexOf("{name}") >= 0) {
            var n = accountName.length > 0 ? accountName : "My"
            s = s.split("{name}").join(n)
        }
        if (s.indexOf("{email}") >= 0)
            s = s.split("{email}").join(accountEmail.length > 0 ? accountEmail : "—")
        if (s.indexOf("{volume}") >= 0)
            s = s.split("{volume}").join(String(Math.round(parseFloat(Shell.execOut("wpctl get-volume @DEFAULT_AUDIO_SINK@ | cut -d' ' -f2")) * 100)) + "%")
        var L = liveInfo()
        var map = { "{host}": L.host, "{user}": L.user, "{model}": L.model,
                    "{serial}": L.serial, "{cpu}": L.cpu, "{ram}": L.ram,
                    "{os}": L.os, "{kernel}": L.kernel, "{ip}": L.ip,
                    "{uptime}": L.uptime, "{country}": L.country, "{lang}": L.lang }
        for (var k in map) {
            if (s.indexOf(k) >= 0)
                s = s.split(k).join(map[k] && map[k].length > 0 ? map[k] : "\u2014")
        }
        return s
    }
}
