pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.commons

Singleton {
  id: root

  // ===============================
  // Paths
  // ===============================
  readonly property string languagesDir: Quickshell.shellDir + "/assets/i18n"
  readonly property string fallbackLang: "en"

  // ===============================
  // State
  // ===============================
  property string currentLanguage: Settings.general.lang || fallbackLang
  property var translations: ({})
  property bool loading: false

  signal languageChanged(string lang)

  // ===============================
  // Init
  // ===============================
  function init() {
    loadLanguage(currentLanguage);
  }

  // ===============================
  // Load language
  // ===============================
  function loadLanguage(lang) {
    if (!lang || lang === "")
    lang = fallbackLang;

    root.loading = true;
    root.currentLanguage = lang;

    const path = languagesDir + "/" + lang + ".json";
    languageReader.path = "";
    languageReader.path = path;
  }

  // ===============================
  // Change language (public API)
  // ===============================
  function changeLanguage(newLang) {
    if (newLang === currentLanguage)
    return translations;

    Settings.general.lang = newLang;
    loadLanguage(newLang);
    return translations;
  }

  // ===============================
  // Translation helper
  // ===============================
  function t(section, key) {
    if (translations?.[section]?.[key])
    return translations[section][key];
    return key;
  }

  // ===============================
  // Fallback language
  // ===============================
  function getFallbackLanguage() {
    return {
      "settings": {
        "title": "Settings",
        "general": "General",
        "appearance": "Appearance",
        "network": "Network",
        "audio": "Audio",
        "performance": "Performance",
        "shortcuts": "Shortcuts",
        "system": "System"
      }
    };
  }

  // ===============================
  // File loader
  // ===============================
  FileView {
    id: languageReader
    watchChanges: true

    onLoaded: {
      try {
        const jsonText = text();
        if (!jsonText || jsonText === "") {
          throw "Empty language file";
        }

        root.translations = JSON.parse(jsonText);
      } catch (e) {
        console.error("Language parse error:", e);
        root.translations = getFallbackLanguage();
      }

      root.loading = false;
      languageChanged(root.currentLanguage);
    }

    onLoadFailed: error => {
      root.translations = getFallbackLanguage();
      root.loading = false;
      languageChanged(root.currentLanguage);
    }
  }

  // ===============================
  // React to Settings change
  // ===============================
  Connections {
    target: Settings.general

    function onLangChanged() {
      Qt.callLater(function () {
          loadLanguage(Settings.general.lang);
      });
    }
  }
}
