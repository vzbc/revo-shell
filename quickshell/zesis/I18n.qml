pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io

// Translation lookup. Strings live in i18n/<lang>/<domain>.json, one small
// JSON file per domain (roughly one per widgets/<Folder>) so contributors
// touching a single feature area only ever conflict with themselves - see
// i18n/manifest.json for the domain list and docs/i18n.md for how to add a
// domain or a language.
//
// Usage: I18n.t("user.title"), or I18n.t("battery.percent", [level]) for a
// template containing %1/%2/... placeholders (Qt .arg()-style, positional so
// translators can reorder them per language grammar).
Singleton {
    id: root

    readonly property string fallbackLanguage: "en"

    readonly property string _i18nDir: Quickshell.shellDir + "/i18n"
    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"
    readonly property string _configPath: _configDir + "/locale.json"

    property var manifest: ({
            "languages": [
                {
                    "code": "en",
                    "englishName": "English",
                    "nativeName": "English"
                }
            ],
            "domains": []
        })
    readonly property var languages: manifest.languages || []

    // "system" (default) tracks the detected OS locale; anything else is a
    // user-pinned override made in Settings / Account / User.
    readonly property string selection: localeData.language
    readonly property string systemLanguage: _detectSystemLanguage()
    readonly property string language: selection === "system" ? systemLanguage : selection

    property var _currentStrings: ({})
    property var _fallbackStrings: ({})

    function t(key, args) {
        var s = root._currentStrings[key];
        if (s === undefined)
            s = root._fallbackStrings[key];
        if (s === undefined)
            return key;
        if (args !== undefined) {
            var list = Array.isArray(args) ? args : [args];
            for (var i = 0; i < list.length; i++) {
                s = s.replace("%" + (i + 1), list[i]);
            }
        }
        return s;
    }

    function setLanguage(code) {
        writeProc.command = ["bash", "-c", "mkdir -p \"$1\" && printf '%s' \"$2\" > \"$3\"", "--",
            root._configDir, JSON.stringify({language: code}), root._configPath];
        writeProc.running = true;
    }

    function _detectSystemLanguage() {
        var raw = Quickshell.env("LC_ALL") || Quickshell.env("LC_MESSAGES") || Quickshell.env("LANG") || "";
        var code = _normalize(raw);
        if (code === "")
            code = _normalize(Qt.locale().name);
        return _resolve(code);
    }

    // "pt_BR.UTF-8" -> "pt_BR"; "C"/"POSIX"/"" -> "" (no usable locale set)
    function _normalize(raw) {
        if (!raw || raw === "C" || raw === "POSIX")
            return "";
        return raw.split(".")[0].split("@")[0];
    }

    // Exact match first (pt_BR), then base-language match (pt_BR -> any
    // shipped pt_* variant), then the hard fallback.
    function _resolve(code) {
        if (code === "")
            return root.fallbackLanguage;
        for (var i = 0; i < root.languages.length; i++)
            if (root.languages[i].code === code)
                return code;
        var base = code.split(/[_-]/)[0];
        for (var j = 0; j < root.languages.length; j++)
            if (root.languages[j].code.split(/[_-]/)[0] === base)
                return root.languages[j].code;
        return root.fallbackLanguage;
    }

    function _mergeCurrent(domain, text) {
        var data = JSON.parse(text || "{}");
        var out = Object.assign({}, root._currentStrings);
        for (var k in data)
            out[domain + "." + k] = data[k];
        root._currentStrings = out;
    }

    function _mergeFallback(domain, text) {
        var data = JSON.parse(text || "{}");
        var out = Object.assign({}, root._fallbackStrings);
        for (var k in data)
            out[domain + "." + k] = data[k];
        root._fallbackStrings = out;
    }

    FileView {
        id: manifestView
        path: root._i18nDir + "/manifest.json"
        watchChanges: true
        onLoaded: root.manifest = JSON.parse(text())
        onFileChanged: reload()
    }

    JsonAdapter {
        id: localeData
        property string language: "system"
    }

    FileView {
        path: root._configPath
        watchChanges: true
        adapter: localeData
        onFileChanged: reload()
    }

    Process {
        id: writeProc
        running: false
    }

    // One small FileView per domain per language track (current + English
    // fallback). Re-parented under the effective language, so switching
    // languages just re-points these at a different directory.
    Instantiator {
        model: root.manifest.domains
        delegate: FileView {
            id: currentDomainView
            required property string modelData
            path: root._i18nDir + "/" + root.language + "/" + modelData + ".json"
            watchChanges: true
            onLoaded: root._mergeCurrent(modelData, text())
            onFileChanged: reload()
        }
    }

    Instantiator {
        model: root.manifest.domains
        delegate: FileView {
            id: fallbackDomainView
            required property string modelData
            path: root._i18nDir + "/" + root.fallbackLanguage + "/" + modelData + ".json"
            watchChanges: true
            onLoaded: root._mergeFallback(modelData, text())
            onFileChanged: reload()
        }
    }
}
