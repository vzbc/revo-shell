import QtQuick
import QtQuick.Controls
import ".."

// Apple Intelligence & Siri (macOS 27, SiriPreferenceExtension.appex).
// Labels/footers are the pane's own en strings (Localizable.loctable);
// settings live in ~/.config/siri27/config.json (read by the Siri shell
// module and siri27d.py); helper actions go through siri27ctl.py.
Column {
    id: page

    property string pageId: "siri"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    width: parent ? parent.width : 640
    spacing: 12

    readonly property string base: HOME_DIR + "/.local/share/siri27"
    readonly property string cfgPath: HOME_DIR + "/.config/siri27/config.json"
    readonly property string ctl: "python3 -I " + base + "/siri27ctl.py"

    readonly property var defaults: ({
        provider: "ollama", language: "auto", apple_intelligence: true, enabled: true,
        listen_for: "off", allow_when_locked: false, shortcut: "SUPER + ALT + S",
        spoken_responses: "automatic", captions: true, show_speech: true, history: true,
        ollama: { url: "http://127.0.0.1:11434", model: "llama3.2" },
        openai: { api_key: "", model: "gpt-4o-mini", url: "https://api.openai.com/v1/chat/completions" },
        anthropic: { api_key: "", model: "claude-sonnet-5-5", url: "https://api.anthropic.com/v1/messages" },
        voices: { ar: "ar_JO-kareem-medium", en: "en_US-hfc_female-medium" }
    })

    property var cfg: ({})
    property int rev: 0
    property var voiceList: []
    property var modelList: []
    property bool ollamaUp: false
    property string ollamaVersion: ""
    property string shortcutError: ""
    property string historyMsg: ""
    property bool customizing: false
    property string captured: ""
    property string pulling: ""
    property string pullStatus: ""
    property string voiceGetting: ""
    property string voiceStatus: ""
    property string importMsg: ""

    // ------------------------------------------------------------ config io
    function load() {
        var c = {}
        try { c = JSON.parse(Shell.readFile(cfgPath) || "{}") } catch (e) { c = {} }
        var m = JSON.parse(JSON.stringify(defaults))
        for (var k in c) {
            if (c[k] !== null && typeof c[k] === "object" && !Array.isArray(c[k]) && m[k] !== null && typeof m[k] === "object") {
                for (var j in c[k]) m[k][j] = c[k][j]
            } else m[k] = c[k]
        }
        cfg = m
        rev++
    }
    function g(k, d) {
        rev
        var o = cfg, p = k.split(".")
        for (var i = 0; i < p.length; i++) {
            if (o === undefined || o === null) return d
            o = o[p[i]]
        }
        return o === undefined ? d : o
    }
    function s(k, v) {
        var o = cfg, p = k.split(".")
        for (var i = 0; i < p.length - 1; i++) {
            if (typeof o[p[i]] !== "object" || o[p[i]] === null) o[p[i]] = {}
            o = o[p[i]]
        }
        o[p[p.length - 1]] = v
        Shell.writeFile(cfgPath, JSON.stringify(cfg, null, 2) + "\n")
        rev++
    }
    function json(cmd, ms) {
        try { return JSON.parse(Shell.execOut(cmd, ms || 5000) || "{}") } catch (e) { return {} }
    }
    function refreshVoices() { voiceList = json(ctl + " voices").voices || [] }
    function refreshModels() {
        var st = json(ctl + " status")
        ollamaUp = st.running === true
        ollamaVersion = st.version || ""
        modelList = ollamaUp ? (json(ctl + " models").models || []) : []
    }

    Component.onCompleted: { load(); refreshVoices(); refreshModels() }
    onPageIdChanged: { load(); if (pageId === "siri.ext.local") refreshModels(); if (pageId === "siri.voice" || pageId === "siri") refreshVoices() }

    // -------------------------------------------------------------- helpers
    readonly property var languages: [
        ["Automatic", "auto"], ["Arabic", "ar"], ["English", "en"], ["French", "fr"], ["German", "de"],
        ["Spanish", "es"], ["Italian", "it"], ["Portuguese", "pt"], ["Turkish", "tr"], ["Persian", "fa"],
        ["Urdu", "ur"], ["Hindi", "hi"], ["Russian", "ru"], ["Chinese", "zh"], ["Japanese", "ja"], ["Korean", "ko"]
    ]
    function langName(code) {
        for (var i = 0; i < languages.length; i++) if (languages[i][1] === code) return languages[i][0]
        return code
    }
    function langCode(name) {
        for (var i = 0; i < languages.length; i++) if (languages[i][0] === name) return languages[i][1]
        return "auto"
    }

    function comboLabel(c) {
        if (!c || String(c).toLowerCase() === "off") return "Off"
        if (c === "SUPER + Space") return "Hold Command Space"
        if (c === "ALT + Space") return "Hold Option Space"
        var sym = { SUPER: "⌘", ALT: "⌥", CTRL: "⌃", CONTROL: "⌃", SHIFT: "⇧" }
        var parts = String(c).split("+").map(function (x) { return x.trim() })
        var key = parts.pop()
        return "Press " + parts.map(function (p) { return sym[p.toUpperCase()] || p }).join("") + (key.length === 1 ? key.toUpperCase() : key)
    }
    function shortcutOptions() {
        var cur = comboLabel(g("shortcut", "off"))
        var o = ["Hold Command Space", "Hold Option Space"]
        if (o.indexOf(cur) < 0 && cur !== "Off") o.push(cur)
        o.push("Customize…")
        o.push("Off")
        return o
    }
    function applyShortcut(combo) {
        var prev = g("shortcut", "off")
        s("shortcut", combo)
        var r = json(ctl + " hotkey apply", 8000)
        if (r.error) {
            s("shortcut", prev)
            shortcutError = r.error
        } else shortcutError = ""
    }

    function voiceName(id, short) {
        for (var i = 0; i < voiceList.length; i++)
            if (voiceList[i].id === id) return voiceList[i].name + (!short && voiceList[i].region ? " (" + voiceList[i].region + ")" : "")
        return id
    }
    function bareModel(n) { return String(n).replace(/:latest$/, "") }
    function gb(b) { return (b / 1e9).toFixed(1) + " GB" }
    function hasModel(n) {
        for (var i = 0; i < modelList.length; i++) if (bareModel(modelList[i].name) === bareModel(n)) return true
        return false
    }
    function startPull(name) {
        name = name.trim()
        if (!name || pulling) return
        pulling = name
        pullStatus = "Starting…"
        Shell.run(ctl + " pull " + JSON.stringify(name))
        pullPoll.start()
    }

    Timer {
        id: pullPoll
        interval: 600
        repeat: true
        onTriggered: {
            var lines = (Shell.readFile(HOME_DIR + "/.cache/siri27/pull.log") || "").trim().split("\n")
            var last = lines[lines.length - 1] || ""
            if (last === "DONE") {
                stop()
                page.refreshModels()
                page.s("ollama.model", page.bareModel(page.pulling))
                page.pullStatus = "Downloaded " + page.pulling + "."
                page.pulling = ""
            } else if (last.indexOf("ERROR") === 0) {
                stop()
                page.pullStatus = last.substring(6)
                page.pulling = ""
            } else page.pullStatus = last.charAt(0).toUpperCase() + last.substring(1)
        }
    }
    Timer {
        id: voicePoll
        interval: 600
        repeat: true
        onTriggered: {
            var last = (Shell.readFile(HOME_DIR + "/.cache/siri27/voice.log") || "").trim()
            if (last === "DONE") {
                stop(); page.refreshVoices()
                page.voiceStatus = ""; page.voiceGetting = ""
            } else if (last.indexOf("ERROR") === 0) {
                stop(); page.voiceStatus = last.substring(6); page.voiceGetting = ""
            } else page.voiceStatus = last
        }
    }

    // ----------------------------------------------------------- components
    component Note: Text {
        x: Theme.cardMargin + 4
        width: page.width - 2 * (Theme.cardMargin + 4)
        visible: text.length > 0
        wrapMode: Text.WordWrap
        textFormat: Text.PlainText
        font.family: Theme.fontText
        font.pixelSize: 12
        color: Theme.textSecondary
    }
    component Gap: Item { width: 1; height: 2 }
    component FieldRow: Item {
        id: fr
        property string title: ""
        property string text: ""
        property string placeholder: ""
        property bool secret: false
        property bool separator: false
        property real fieldWidth: Math.min(300, fr.width * 0.58)
        signal committed(string v)
        width: parent ? parent.width : 100
        height: Theme.detailRowHeight
        Rectangle {
            visible: fr.separator
            anchors.top: parent.top
            x: 16; width: parent.width - 28; height: 1
            color: Theme.separator
        }
        Text {
            x: 16
            anchors.verticalCenter: parent.verticalCenter
            text: fr.title
            font.family: Theme.fontText
            font.pixelSize: 13
            color: Theme.textPrimary
        }
        TextField {
            id: tf
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: fr.fieldWidth
            height: 26
            text: fr.text
            placeholderText: fr.placeholder
            placeholderTextColor: Theme.textSecondary
            echoMode: fr.secret && !activeFocus ? TextInput.Password : TextInput.Normal
            font.family: Theme.fontText
            font.pixelSize: 13
            color: Theme.textPrimary
            leftPadding: 8; rightPadding: 8; topPadding: 0; bottomPadding: 0
            verticalAlignment: TextInput.AlignVCenter
            selectByMouse: true
            onEditingFinished: if (text !== fr.text) fr.committed(text)
            background: Rectangle {
                radius: 6
                color: Theme.checkBg
                border.width: tf.activeFocus ? 2 : 1
                border.color: tf.activeFocus ? Theme.accent : Theme.checkBorder
            }
        }
    }

    // ===================================================================
    // Apple Intelligence & Siri
    // ===================================================================
    Column {
        visible: page.pageId === "siri"
        width: page.width
        spacing: 12

        Placard {
            iconFile: "sb_apple-intelligence"
            title: "Apple Intelligence & Siri"
            subtitle: "Siri is an intelligent assistant that helps you find information and get things done."
        }

        GroupCard {
            DetailRow {
                title: "Apple Intelligence"
                showSwitch: true
                switchOn: page.g("apple_intelligence", true) === true
                onToggled: (c) => page.s("apple_intelligence", c)
            }
        }
        Note {
            text: page.g("apple_intelligence", true)
                  ? "Apple Intelligence answers with " + (page.g("provider") === "openai" ? "ChatGPT" : page.g("provider") === "anthropic" ? "Claude" : "a local model on this Mac (" + page.g("ollama.model") + ")") + "."
                  : "Apple Intelligence features will not be available. Siri will also stop using the additional capabilities provided by Apple Intelligence."
        }

        SectionHeader { text: "Siri" }
        GroupCard {
            DetailRow {
                title: "Siri"
                subtitle: "Siri helps you get things done, just by asking. Dictate a note, check the weather, and more."
                showSwitch: true
                switchOn: page.g("enabled", true) === true
                onToggled: (c) => page.s("enabled", c)
            }
            DetailRow {
                separator: true
                title: "Listen for"
                dimmed: true
                pickerOptions: ["Off"]
                value: "Off"
            }
            DetailRow {
                separator: true
                title: "Allow Siri when locked"
                showSwitch: true
                switchOn: page.g("allow_when_locked", false) === true
                onToggled: (c) => { page.s("allow_when_locked", c); page.applyShortcut(page.g("shortcut", "off")) }
            }
            DetailRow {
                separator: true
                title: "Keyboard shortcut"
                subtitle: page.g("shortcut", "off") === "off" ? "" : "Press to type to Siri, hold to speak to Siri"
                pickerOptions: page.shortcutOptions()
                value: page.comboLabel(page.g("shortcut", "off"))
                onPicked: (v) => {
                    if (v === "Customize…") { page.captured = ""; page.customizing = true; return }
                    page.customizing = false
                    if (v === "Off") page.applyShortcut("off")
                    else if (v === "Hold Command Space") page.applyShortcut("SUPER + Space")
                    else if (v === "Hold Option Space") page.applyShortcut("ALT + Space")
                }
            }
            // "Customize…": record a key combination
            Item {
                visible: page.customizing
                width: parent ? parent.width : 100
                height: Theme.detailRowHeight
                Rectangle { anchors.top: parent.top; x: 16; width: parent.width - 28; height: 1; color: Theme.separator }
                Rectangle {
                    id: capBox
                    x: 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 32 - capBtns.width - 12
                    height: 26
                    radius: 6
                    color: Theme.checkBg
                    border.width: capArea.activeFocus ? 2 : 1
                    border.color: capArea.activeFocus ? Theme.accent : Theme.checkBorder
                    Text {
                        anchors.centerIn: parent
                        text: page.captured ? page.comboLabel(page.captured).replace(/^Press /, "") : "Press keys now"
                        font.family: Theme.fontText
                        font.pixelSize: 13
                        color: page.captured ? Theme.textPrimary : Theme.textSecondary
                    }
                    FocusScope {
                        id: capArea
                        anchors.fill: parent
                        focus: page.customizing
                        onVisibleChanged: if (visible) forceActiveFocus()
                        MouseArea { anchors.fill: parent; onClicked: capArea.forceActiveFocus() }
                        Keys.onPressed: (event) => {
                            var k = event.key
                            if ([Qt.Key_Meta, Qt.Key_Super_L, Qt.Key_Super_R, Qt.Key_Alt, Qt.Key_Control, Qt.Key_Shift, Qt.Key_AltGr].indexOf(k) >= 0) return
                            var mods = []
                            if (event.modifiers & Qt.MetaModifier) mods.push("SUPER")
                            if (event.modifiers & Qt.ControlModifier) mods.push("CTRL")
                            if (event.modifiers & Qt.AltModifier) mods.push("ALT")
                            if (event.modifiers & Qt.ShiftModifier) mods.push("SHIFT")
                            if (k === Qt.Key_Escape && mods.length === 0) { page.customizing = false; event.accepted = true; return }
                            var name = k === Qt.Key_Space ? "Space"
                                     : (k >= Qt.Key_A && k <= Qt.Key_Z) || (k >= Qt.Key_0 && k <= Qt.Key_9) ? String.fromCharCode(k)
                                     : (k >= Qt.Key_F1 && k <= Qt.Key_F35) ? "F" + (k - Qt.Key_F1 + 1)
                                     : (event.text || "").toUpperCase()
                            if (!name) return
                            page.captured = mods.concat([name]).join(" + ")
                            event.accepted = true
                        }
                    }
                }
                Row {
                    id: capBtns
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    MacButton { text: "Cancel"; onClicked: page.customizing = false }
                    MacButton {
                        text: "Done"; primary: true
                        btnEnabled: page.captured.indexOf("+") > 0
                        onClicked: { page.customizing = false; page.applyShortcut(page.captured) }
                    }
                }
            }
            DetailRow {
                separator: true
                title: "Language"
                pickerOptions: page.languages.map(function (l) { return l[0] })
                value: page.langName(page.g("language", "auto"))
                onPicked: (v) => page.s("language", page.langCode(v))
            }
            DetailRow {
                separator: true
                title: "Voice"
                subtitle: page.voiceName(page.g("voices.ar"), true) + " (Arabic) · " + page.voiceName(page.g("voices.en"), true) + " (English)"
                buttonLabel: "Select…"
                onClicked: page.navigate("siri.voice")
            }
            DetailRow {
                separator: true
                title: "Siri history"
                buttonLabel: "Delete Siri & Dictation History…"
                onClicked: {
                    var r = page.json(page.ctl + " delete-history")
                    page.historyMsg = r.ok ? "Your Siri and Dictation history will be deleted."
                                           : "Your Siri and Dictation history was unable to be deleted."
                }
            }
        }
        Note { text: page.shortcutError; color: Theme.red }
        Note { text: page.historyMsg }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: Theme.cardMargin
            spacing: 8
            MacButton { text: "About Ask Siri, Dictation & Privacy…"; onClicked: page.navigate("siri.privacy") }
            MacButton { text: "Siri Responses…"; onClicked: page.navigate("siri.responses") }
        }

        SectionHeader { text: "Extensions" }
        GroupCard {
            DetailRow {
                title: "ChatGPT"
                value: page.g("provider") === "openai" ? "On" : "Off"
                chevron: true
                onClicked: page.navigate("siri.ext.chatgpt")
            }
            DetailRow {
                separator: true
                title: "Claude"
                value: page.g("provider") === "anthropic" ? "On" : "Off"
                chevron: true
                onClicked: page.navigate("siri.ext.claude")
            }
            DetailRow {
                separator: true
                title: "Local Model"
                value: page.g("provider") === "ollama" ? page.bareModel(page.g("ollama.model")) : "Off"
                chevron: true
                onClicked: page.navigate("siri.ext.local")
            }
        }
        Note { text: "Siri and other features can use ChatGPT to help answer your requests. Claude and local models running on this Mac’s graphics card can be used the same way." }
        Gap {}
    }

    // ===================================================================
    // Siri Responses…
    // ===================================================================
    Column {
        visible: page.pageId === "siri.responses"
        width: page.width
        spacing: 12

        GroupCard {
            DetailRow {
                title: "Spoken Responses"
                pickerOptions: ["Automatic", "Prefer Silent Responses", "Prefer Spoken Responses"]
                value: ({ automatic: "Automatic", silent: "Prefer Silent Responses", spoken: "Prefer Spoken Responses" })[page.g("spoken_responses", "automatic")] || "Automatic"
                onPicked: (v) => page.s("spoken_responses", v === "Prefer Silent Responses" ? "silent" : v === "Prefer Spoken Responses" ? "spoken" : "automatic")
            }
        }
        Note {
            text: page.g("spoken_responses", "automatic") === "automatic"
                  ? "Siri will take different factors into account to determine whether to speak." : ""
        }
        GroupCard {
            DetailRow {
                title: "Always show Siri captions"
                subtitle: "Show what Siri says on screen."
                showSwitch: true
                switchOn: page.g("captions", true) === true
                onToggled: (c) => page.s("captions", c)
            }
            DetailRow {
                separator: true
                title: "Always show speech"
                subtitle: "Show a transcription of your speech on screen."
                showSwitch: true
                switchOn: page.g("show_speech", true) === true
                onToggled: (c) => page.s("show_speech", c)
            }
        }
        Gap {}
    }

    // ===================================================================
    // Voice
    // ===================================================================
    Column {
        visible: page.pageId === "siri.voice"
        width: page.width
        spacing: 12

        Repeater {
            model: [["ar", "Arabic"], ["en", "English"]]
            delegate: Column {
                required property var modelData
                width: page.width
                spacing: 12
                readonly property string lang: modelData[0]
                SectionHeader { text: modelData[1] }
                GroupCard {
                    Repeater {
                        model: page.voiceList.filter(function (v) { return v.lang === lang })
                        delegate: DetailRow {
                            required property var modelData
                            required property int index
                            separator: index > 0
                            title: modelData.name + (modelData.region ? " (" + modelData.region + ")" : "")
                            subtitle: (page.g("voices." + lang) === modelData.id ? "✓ Selected · " : "") + "Quality: " + modelData.quality
                            buttonLabel: "Play"
                            onClicked: {
                                page.s("voices." + lang, modelData.id)
                                Shell.run(page.ctl + " say " + modelData.id + " " + JSON.stringify(lang === "ar" ? "مرحبا، أنا سيري. كيف أقدر أساعدك؟" : "Hi, I'm Siri. How can I help you?"))
                            }
                        }
                    }
                }
            }
        }
        Note { text: "Click a voice to select it and hear a sample. Siri answers in Arabic or English depending on the language of its answer." }

        SectionHeader { text: "More Voices" }
        GroupCard {
            Repeater {
                model: [
                    ["en_US-amy-medium", "Amy (US)", "English"],
                    ["en_US-ryan-high", "Ryan (US)", "English · high quality"],
                    ["en_GB-alba-medium", "Alba (GB)", "English"],
                    ["en_GB-northern_english_male-medium", "Northern English Male (GB)", "English"],
                    ["ar_JO-kareem-low", "Kareem, Low (JO)", "Arabic · lighter"]
                ]
                delegate: DetailRow {
                    required property var modelData
                    required property int index
                    readonly property bool have: page.voiceList.some(function (v) { return v.id === modelData[0] })
                    separator: index > 0
                    title: modelData[1]
                    subtitle: page.voiceGetting === modelData[0] ? page.voiceStatus : modelData[2]
                    value: have ? "Installed" : ""
                    buttonLabel: have ? "" : (page.voiceGetting === modelData[0] ? "Downloading…" : "Get")
                    onClicked: {
                        if (have || page.voiceGetting) return
                        page.voiceGetting = modelData[0]
                        page.voiceStatus = "Starting…"
                        Shell.run(page.ctl + " voice-get " + modelData[0])
                        voicePoll.start()
                    }
                }
            }
        }
        Gap {}
    }

    // ===================================================================
    // About Ask Siri, Dictation & Privacy
    // ===================================================================
    Column {
        visible: page.pageId === "siri.privacy"
        width: page.width
        spacing: 12
        Placard {
            iconFile: "sb_apple-intelligence"
            title: "Ask Siri, Dictation & Privacy"
        }
        GroupCard {
            DetailRow { title: "Voice input"; subtitle: "Processed on this Mac by Whisper on the graphics card. Recordings are deleted right after."; }
            DetailRow {
                separator: true
                title: "Requests"
                subtitle: page.g("provider") === "openai" ? "Transcripts of your requests are sent to OpenAI (ChatGPT)."
                        : page.g("provider") === "anthropic" ? "Transcripts of your requests are sent to Anthropic (Claude)."
                        : "Answered on this Mac by " + page.bareModel(page.g("ollama.model")) + ". Nothing leaves your Mac."
            }
            DetailRow { separator: true; title: "Spoken answers"; subtitle: "Generated on this Mac with Piper." }
            DetailRow {
                separator: true
                title: "Siri history"
                subtitle: "Kept on this Mac in ~/.local/share/siri27/history.jsonl."
                showSwitch: true
                switchOn: page.g("history", true) === true
                onToggled: (c) => page.s("history", c)
            }
        }
        Gap {}
    }

    // ===================================================================
    // Extensions: ChatGPT / Claude
    // ===================================================================
    Repeater {
        model: [
            { id: "siri.ext.chatgpt", key: "openai", name: "ChatGPT", by: "OpenAI",
              models: ["gpt-4o-mini", "gpt-4o", "gpt-4.1", "gpt-4.1-mini", "o4-mini"] },
            { id: "siri.ext.claude", key: "anthropic", name: "Claude", by: "Anthropic",
              models: ["claude-sonnet-5-5", "claude-opus-5-5", "claude-haiku-5-5"] }
        ]
        delegate: Column {
            required property var modelData
            visible: page.pageId === modelData.id
            width: page.width
            spacing: 12
            readonly property string k: modelData.key

            GroupCard {
                DetailRow {
                    title: "Use " + modelData.name
                    subtitle: "Siri can use " + modelData.name + " to help answer your requests."
                    showSwitch: true
                    switchOn: page.g("provider") === k
                    onToggled: (c) => page.s("provider", c ? k : "ollama")
                }
            }
            SectionHeader { text: "Account" }
            GroupCard {
                FieldRow {
                    title: "API Key"
                    secret: true
                    placeholder: modelData.key === "openai" ? "sk-…" : "sk-ant-…"
                    text: page.g(k + ".api_key", "")
                    onCommitted: (v) => page.s(k + ".api_key", v.trim())
                }
                DetailRow {
                    separator: true
                    title: "Model"
                    pickerOptions: {
                        var o = modelData.models.slice()
                        var cur = page.g(k + ".model", o[0])
                        if (o.indexOf(cur) < 0) o.unshift(cur)
                        return o
                    }
                    value: page.g(k + ".model", modelData.models[0])
                    onPicked: (v) => page.s(k + ".model", v)
                }
                FieldRow {
                    separator: true
                    title: "Custom model"
                    placeholder: "model id"
                    text: ""
                    onCommitted: (v) => { if (v.trim()) page.s(k + ".model", v.trim()) }
                }
            }
            Note {
                text: (page.g(k + ".api_key", "") === "" ? "Add an API key from " + modelData.by + " to use " + modelData.name + ". " : "")
                      + "When " + modelData.name + " is on, transcripts of your requests are sent to " + modelData.by + "."
            }
            Gap {}
        }
    }

    // ===================================================================
    // Extensions: Local Model (Ollama on this Mac's GPU)
    // ===================================================================
    Column {
        visible: page.pageId === "siri.ext.local"
        width: page.width
        spacing: 12

        GroupCard {
            DetailRow {
                title: "Use Local Model"
                subtitle: "Answer Siri requests on this Mac’s graphics card. Nothing leaves your Mac."
                value: page.g("provider") === "ollama" ? "In Use" : ""
                buttonLabel: page.g("provider") === "ollama" ? "" : "Use"
                onClicked: page.s("provider", "ollama")
            }
            DetailRow {
                separator: true
                title: "Ollama"
                subtitle: page.ollamaUp ? "Running · version " + page.ollamaVersion : "Not running"
                buttonLabel: "Refresh"
                onClicked: page.refreshModels()
            }
            FieldRow {
                separator: true
                title: "Server"
                text: page.g("ollama.url", "http://127.0.0.1:11434")
                onCommitted: (v) => { page.s("ollama.url", v.trim()); page.refreshModels() }
            }
        }

        SectionHeader { text: "Models on This Mac" }
        GroupCard {
            Repeater {
                model: page.modelList
                delegate: DetailRow {
                    required property var modelData
                    required property int index
                    readonly property bool sel: page.bareModel(page.g("ollama.model")) === page.bareModel(modelData.name)
                    separator: index > 0
                    title: page.bareModel(modelData.name)
                    subtitle: [modelData.params, modelData.quant, page.gb(modelData.size)].filter(function (x) { return x }).join(" · ")
                    value: sel ? "✓" : ""
                    buttonLabel: sel ? "" : "Select"
                    onClicked: page.s("ollama.model", page.bareModel(modelData.name))
                }
            }
            DetailRow {
                visible: page.modelList.length === 0
                title: page.ollamaUp ? "No models yet" : "Start Ollama to see models"
                dimmed: true
            }
        }

        SectionHeader { text: "Add Model" }
        GroupCard {
            Repeater {
                model: [
                    ["qwen2.5:7b", "Qwen 2.5 7B", "Strong in Arabic and English · 4.7 GB"],
                    ["qwen2.5:3b", "Qwen 2.5 3B", "Fast, Arabic and English · 1.9 GB"],
                    ["llama3.1:8b", "Llama 3.1 8B", "English · 4.9 GB"],
                    ["gemma3:4b", "Gemma 3 4B", "Multilingual · 3.3 GB"]
                ]
                delegate: DetailRow {
                    required property var modelData
                    required property int index
                    readonly property bool have: page.hasModel(modelData[0])
                    separator: index > 0
                    title: modelData[1]
                    subtitle: page.pulling === modelData[0] ? page.pullStatus : modelData[2]
                    value: have ? "Installed" : ""
                    buttonLabel: have ? "" : (page.pulling === modelData[0] ? "Downloading…" : "Get")
                    onClicked: if (!have) page.startPull(modelData[0])
                }
            }
            FieldRow {
                id: pullField
                separator: true
                title: "Other model"
                placeholder: "e.g. mistral:7b"
                fieldWidth: Math.min(260, width * 0.5)
                onCommitted: (v) => page.startPull(v)
            }
            FieldRow {
                separator: true
                title: "GGUF file"
                placeholder: "/path/model.gguf"
                fieldWidth: Math.min(260, width * 0.5)
                onCommitted: (v) => {
                    var p = v.trim()
                    if (!p) return
                    var name = p.split("/").pop().replace(/\.gguf$/i, "").toLowerCase().replace(/[^a-z0-9._-]+/g, "-")
                    page.importMsg = "Adding " + name + "…"
                    var r = page.json(page.ctl + " import " + JSON.stringify(name) + " " + JSON.stringify(p), 600000)
                    page.importMsg = r.ok ? "Added " + name + "." : (r.error || "Could not add the file.")
                    if (r.ok) { page.refreshModels(); page.s("ollama.model", name) }
                }
            }
        }
        Note { text: page.pulling ? page.pulling + ": " + page.pullStatus : page.pullStatus }
        Note { text: page.importMsg }
        Note { text: "Type a model name and press Return to download it, or enter the path of a .gguf file to add it. The selected model answers Siri when Local Model is in use." }
        Gap {}
    }
}
