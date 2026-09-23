pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.commons

Singleton {
  id: root

  property var settings: Settings
  property var theme: settings ? settings.appearance : null
  property Process matugenProcess: Process {
    command: ["bash", "-c", ""]
    stdout: StdioCollector {
      onTextChanged: {
        if (text && text.trim() !== "") {
          try {
            var jsonData = JSON.parse(text);
            processMatugenOutput(jsonData);
          } catch (e) {
            console.error("Failed to parse matugen output:", e);
          }
        }
      }
    }
  }

  property Timer reloadTimer: Timer {
    interval: 200
    repeat: false
    onTriggered: {
      ThemeService.loadTheme();
    }
  }

  // Function to process matugen JSON output and create theme
  function processMatugenOutput(jsonData) {

    if (!jsonData || !jsonData.colors) {
      console.error("Invalid matugen output");
      return;
    }

    var mode = jsonData.mode || "dark";
    var colors = jsonData.colors;
    var palettes = jsonData.palettes || {};

    // Create theme structure based on template
    var theme = {
      "type": mode,
      "primary": {
        "background": colors.surface ? colors.surface.default : "#101410",
        "dim_background": colors.surface_dim ? colors.surface_dim.default : "#101410",
        "foreground": colors.on_surface_variant ? colors.on_surface_variant.default : "#c0c9bc",
        "dim_foreground": colors.secondary_fixed_dim ? colors.secondary_fixed_dim.default : "#b1cead",
        "bright_foreground": colors.primary ? colors.primary.default : "#92d792"
      },
      "button": {
        "background": colors.outline_variant ? colors.outline_variant.default : "#41493f",
        "text": colors.primary ? colors.primary.default : "#92d792",
        "background_select": colors.outline ? colors.outline.default : "#8a9387",
        "border": colors.on_surface_variant ? colors.on_surface_variant.default : "#c0c9bc",
        "border_select": colors.on_surface_variant ? colors.on_surface_variant.default : "#c0c9bc"
      },
      "cursor": {
        "cursor": "#cad3f5",
        "text": "#24273a"
      },
      "normal": {
        "black": palettes.neutral ? palettes.neutral[40] || "#494d64" : "#494d64",
        "red": colors.error ? colors.error.default : "#ed8796",
        "green": colors.primary ? colors.primary.default : "#a6da95",
        "yellow": colors.tertiary ? colors.tertiary.default : "#eed49f",
        "blue": "#8aadf4",
        "magenta": "#f5bde6",
        "cyan": colors.tertiary ? colors.tertiary.default : "#8bd5ca",
        "white": colors.on_surface ? colors.on_surface.default : "#b8c0e0"
      },
      "bright": {
        "black": palettes.neutral ? palettes.neutral[60] || "#5b6078" : "#5b6078",
        "red": colors.error ? colors.error.default : "#ed8796",
        "green": colors.primary ? colors.primary.default : "#a6da95",
        "yellow": colors.tertiary ? colors.tertiary.default : "#eed49f",
        "blue": "#8aadf4",
        "magenta": "#f5bde6",
        "cyan": colors.tertiary ? colors.tertiary.default : "#8bd5ca",
        "white": colors.on_surface ? colors.on_surface.default : "#a5adcb"
      }
    };

    // Save theme to file
    saveThemeToFile(theme);
  }

  // Function to save theme to JSON file
  function saveThemeToFile(theme) {
    var themeJson = JSON.stringify(theme, null, 2);
    var filePath = Directories.assetsPath + "/themes/matugen.json";

    var file = Qt.createQmlObject('import QtQuick; import Quickshell.Io; File { }', root);
    file.path = filePath;
    file.text = themeJson;

    if (file.write()) {

      // Update current theme to matugen if not already set
      if (settings && settings.appearance.theme !== "matugen") {
        settings.appearance.theme = "matugen";
      }

      // Trigger theme reload
      reloadTimer.restart();
    } else {
      console.error("Failed to save theme file");
    }

    file.destroy();
  }

  // Function run matugen with JSON output
  function runMatugen(currentWallpaper, themeMode) {
    if (!currentWallpaper || currentWallpaper === "") {
      return;
    }

    // Run matugen with JSON output format
    var command = "matugen image '"
    + currentWallpaper +
    "' -j hex --mode " + themeMode +
    " --prefer dark";
    matugenProcess.command = ["bash", "-c", command];
    matugenProcess.running = true;
    reloadTimer.restart();
  }

  function triggerMatugenOnThemeChange(themeMode) {

    // Update Settings mode first
    if (settings && settings.appearance) {
      settings.appearance.mode = themeMode;
    }

    // Only run matugen if theme is set to "matugen"
    if (!settings || settings.appearance.theme !== "matugen") {
      return;
    }

    // Lấy wallpaper từ màn hình chính hoặc màn hình đầu tiên
    var currentWallpaper = "";

    if (Quickshell.screens.length > 0) {
      var primaryScreenName = "";

      // Tìm màn hình chính
      for (let i = 0; i < Quickshell.screens.length; i++) {
        if (Quickshell.screens[i].primary) {
          primaryScreenName = Quickshell.screens[i].name;
          break;
        }
      }

      // Nếu không tìm thấy màn hình chính, lấy màn hình đầu tiên
      if (primaryScreenName === "" && Quickshell.screens.length > 0) {
        primaryScreenName = Quickshell.screens[0].name;
      }

      // Lấy wallpaper từ WallpaperService
      if (primaryScreenName !== "" && typeof WallpaperService !== 'undefined') {
        currentWallpaper = WallpaperService.getWallpaper(primaryScreenName);
      }
    }

    if (currentWallpaper && currentWallpaper !== "") {
      runMatugen(currentWallpaper, themeMode);
      ThemeService.loadTheme();
    } else {
    }
  }

  function triggerMatugenOnWallpaperChange(currentWallpaper) {
    if (!currentWallpaper || currentWallpaper === "") {
      return;
    }

    // Only run matugen if theme is set to "matugen"
    if (!settings || settings.appearance.theme !== "matugen") {
      return;
    }

    var themeMode = settings.appearance.mode || "dark";
    runMatugen(currentWallpaper, themeMode);
  }

  // Hàm khởi tạo
  function init() {

    // Chạy matugen lần đầu khi khởi động nếu theme là matugen
    if (settings && settings.appearance.theme === "matugen") {
      Qt.callLater(function () {
          triggerMatugenOnThemeChange(settings.appearance.mode);
      });
    }
  }

  Component.onCompleted: {
    // Đợi Settings được load
    if (settings && settings.ready) {
      init();
    } else {
      // Kết nối signal nếu Settings có sẵn
      if (settings) {
        settings.settingsLoaded.connect(init);
      }
    }
  }
}
