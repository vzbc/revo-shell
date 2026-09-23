import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import qs.services
import qs.commons
import qs.components

Item {
  id: settingsRoot
  property bool showSettings: false
  property string apiKey: Settings.weather?.keyApi || ""
  property string location: Settings.weather?.location || ""
  property bool isSearchingLocation: false
  property var locationSearchResults: []
  property int currentLocationIndex: 0
  property bool isUserSearching: false
  property string errorMessage: ""

  // Timer auto-validate API key
  property Timer apiKeyValidateTimer: Timer {
    interval: 500
    repeat: false
    onTriggered: {
      if (settingsRoot.apiKey !== Settings.weather?.keyApi) {
        saveAndValidateApiKey(settingsRoot.apiKey);
      }
    }
  }

  // Timer debounce location search
  property Timer searchDebounceTimer: Timer {
    interval: 300
    repeat: false
    onTriggered: {
      if (settingsRoot.location.length >= 2 && settingsRoot.isUserSearching) {
        searchLocation(settingsRoot.location);
      }
    }
  }

  // Timer ẩn location results
  Timer {
    id: hideResultsTimer
    interval: 200
    repeat: false
    onTriggered: {
      settingsRoot.locationSearchResults = [];
      settingsRoot.isUserSearching = false;
    }
  }

  // Process tìm kiếm địa điểm
  Process {
    id: searchLocationProcess
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        settingsRoot.isSearchingLocation = false;
        settingsRoot.locationSearchResults = [];
        if (text && text.length > 0) {
          try {
            const data = JSON.parse(text);
            if (!data.error) {
              settingsRoot.locationSearchResults = data;
              if (data.length > 0) {
                settingsRoot.currentLocationIndex = 0;
              }
            }
          } catch (e) {}
        }
      }
    }
  }

  function saveAndValidateApiKey(key) {
    if (key === "") {
      errorMessage = "Vui lòng nhập API key";
      return;
    }
    if (!Settings.weather) Settings.weather = {}
    Settings.weather.keyApi = key;
    settingsRoot.apiKey = key;
  }

  function searchLocation(query) {
    if (query === "" || apiKey === "") {
      locationSearchResults = [];
      isSearchingLocation = false;
      return;
    }
    try {
      searchLocationProcess.running = false;
    } catch (e) {}
    isSearchingLocation = true;
    const url = `https://api.weatherapi.com/v1/search.json?key=${apiKey}&q=${encodeURIComponent(query)}`;
    searchLocationProcess.command = ["curl", "-s", url];
    searchLocationProcess.running = true;
  }

  function selectLocation(locationName) {
    if (!Settings.weather) Settings.weather = {}
    Settings.weather.location = locationName;
    location = locationName;
    locationSearchResults = [];
    currentLocationIndex = 0;
    isUserSearching = false;
  }

  function saveAllSettings() {
    saveAndValidateApiKey(apiKey)
    selectLocation(location)
    showSettings = false
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: ScalerService.s(20)
    anchors.margins: ScalerService.s(30)

    // Scrollable Settings Content
    ColumnLayout {
      width: parent.width
      spacing: ScalerService.s(25)

      // API Key Section
      ColumnLayout {
        Layout.fillWidth: true
        spacing: ScalerService.s(12)

        RowLayout {
          Layout.fillWidth: true
          spacing: ScalerService.s(10)

          IconText {
            name: "vpn_key"
            font.pixelSize: ScalerService.s(24)
            color: theme.normal.green
          }

          CustomText {
            name: lang?.weather?.apiKeyLabel || "API Key (weatherapi.com)"
            size: "medium"
            isBold: true
            textColor: theme.primary.foreground
            Layout.fillWidth: true
          }
        }

        Rectangle {
          Layout.fillWidth: true
          height: ScalerService.s(48)
          color: theme.primary.dim_background
          border.color: apiKeyInput.activeFocus ? theme.normal.blue : theme.primary.dim_foreground
          radius: ScalerService.s(Settings.appearance.radius3)
          border.width: Settings.appearance.enableBorder ? ScalerService.s(1) : 0

          TextField {
            id: apiKeyInput
            anchors.fill: parent
            anchors.margins: ScalerService.s(8)
            text: settingsRoot.apiKey
            palette.text: theme.primary.foreground
            font {
              pixelSize: ScalerService.s(14)
              family: "ComicShannsMono Nerd Font"
            }
            background: Rectangle {
              color: "transparent"
            }
            verticalAlignment: TextInput.AlignVCenter
            selectByMouse: true
            clip: true
            placeholderText: lang?.weather?.apiKeyPlaceholder || "Nhập API key của bạn..."
            palette.placeholderText: theme.primary.dim_foreground

            onTextChanged: {
              settingsRoot.apiKey = text;
              settingsRoot.apiKeyValidateTimer.restart();
            }
          }
        }

        CustomText {
          name: lang?.weather?.apiKeyHint || "Nhận API key miễn phí tại: weatherapi.com"
          size: "xsmall"
          font.italic: true
          wrapMode: Text.WordWrap
          Layout.fillWidth: true
          textColor: theme.primary.dim_foreground
        }
      }

      // Location Section
      ColumnLayout {
        Layout.fillWidth: true
        spacing: ScalerService.s(12)

        RowLayout {
          Layout.fillWidth: true
          spacing: ScalerService.s(10)

          IconText {
            name: "location_on"
            font.pixelSize: ScalerService.s(24)
            color: theme.normal.red
          }

          CustomText {
            name: lang?.weather?.locationLabel || "Địa điểm"
            size: "medium"
            isBold: true
            textColor: theme.primary.foreground
            Layout.fillWidth: true
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: ScalerService.s(8)

          RowLayout {
            Layout.fillWidth: true
            spacing: ScalerService.s(10)

            Rectangle {
              Layout.fillWidth: true
              height: ScalerService.s(48)
              color: theme.primary.dim_background
              border.color: locationInput.activeFocus ? theme.normal.blue : theme.primary.dim_foreground
              radius: ScalerService.s(Settings.appearance.radius3)
              border.width: Settings.appearance.enableBorder ? ScalerService.s(1) : 0

              TextField {
                id: locationInput
                anchors.fill: parent
                anchors.margins: ScalerService.s(8)
                text: settingsRoot.location
                color: theme.primary.foreground
                font {
                  pixelSize: ScalerService.s(14)
                  family: "ComicShannsMono Nerd Font"
                }
                palette.text: theme.primary.foreground
                background: Rectangle {
                  color: "transparent"
                }
                verticalAlignment: TextInput.AlignVCenter
                selectByMouse: true
                clip: true
                placeholderText: lang?.weather?.locationPlaceholder || "Tìm kiếm thành phố..."
                palette.placeholderText: theme.primary.dim_foreground

                onActiveFocusChanged: {
                  if (activeFocus) {
                    settingsRoot.isUserSearching = true;
                  } else {
                    hideResultsTimer.restart();
                  }
                }

                onTextChanged: {
                  settingsRoot.location = text;
                  settingsRoot.searchDebounceTimer.stop();
                  if (text.length >= 2) {
                    settingsRoot.searchDebounceTimer.restart();
                  } else {
                    settingsRoot.locationSearchResults = [];
                    settingsRoot.currentLocationIndex = 0;
                  }
                }
              }
            }

            Rectangle {
              Layout.preferredWidth: ScalerService.s(80)
              Layout.preferredHeight: ScalerService.s(48)
              radius: ScalerService.s(Settings.appearance.radius3)
              color: theme.button.background
              border.color: theme.button.border
              opacity: searchMouseArea.pressed ? 0.8 : 1

              IconText {
                name: "search"
                size: "medium"
                anchors.centerIn: parent
                textColor: theme.button.text
              }

              MouseArea {
                id: searchMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: !settingsRoot.isSearchingLocation
                onClicked: settingsRoot.searchLocation(locationInput.text)
              }
            }
          }

          // Location search results
          ListView {
            id: locationResultsList
            visible: settingsRoot.isUserSearching && settingsRoot.locationSearchResults.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(count * ScalerService.s(52), ScalerService.s(208))
            clip: true
            spacing: ScalerService.s(4)
            model: settingsRoot.locationSearchResults
            currentIndex: settingsRoot.currentLocationIndex

            delegate: Rectangle {
              width: ListView.view.width
              height: ScalerService.s(50)
              radius: ScalerService.s(10)
              color: (ListView.isCurrentItem || locationResultMouseArea.containsMouse) ? Qt.rgba(theme.normal.blue.r, theme.normal.blue.g, theme.normal.blue.b, 0.15) : "transparent"
              border.color: (ListView.isCurrentItem || locationResultMouseArea.containsMouse) ? Qt.rgba(theme.normal.blue.r, theme.normal.blue.g, theme.normal.blue.b, 0.3) : "transparent"
              border.width: ScalerService.s(1)

              RowLayout {
                anchors.fill: parent
                anchors.margins: ScalerService.s(12)
                spacing: ScalerService.s(12)

                Column {
                  Layout.fillWidth: true
                  Layout.alignment: Qt.AlignVCenter
                  spacing: ScalerService.s(2)

                  Text {
                    text: modelData.name
                    color: theme.primary.foreground
                    font {
                      pixelSize: ScalerService.s(14)
                      family: "ComicShannsMono Nerd Font"
                      bold: true
                    }
                    width: parent.width
                    elide: Text.ElideRight
                  }

                  Text {
                    text: `${modelData.region}, ${modelData.country}`
                    color: theme.primary.dim_foreground
                    font {
                      pixelSize: ScalerService.s(12)
                      family: "ComicShannsMono Nerd Font"
                    }
                    width: parent.width
                    elide: Text.ElideRight
                  }
                }
              }

              MouseArea {
                id: locationResultMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: {
                  hideResultsTimer.stop();
                }
                onClicked: {
                  locationInput.text = `${modelData.name},${modelData.country}`;
                  settingsRoot.selectLocation(locationInput.text);
                }
              }
            }
          }
        }
      }

      // Spacer để đẩy buttons xuống dưới
      Item {
        Layout.fillHeight: true
      }

      // Save and Cancel Buttons
      RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(50)
        spacing: ScalerService.s(15)

        // Save Button
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: ScalerService.s(50)
          radius: ScalerService.s(12)
          color: theme.button.text
          opacity: saveMouseArea.pressed ? 0.8 : 1

          CustomText {
            anchors.centerIn: parent
            name: "Save Settings"
            size: "medium"
            isBold: true
            textColor: theme.button.background
          }

          MouseArea {
            id: saveMouseArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              settingsRoot.saveAllSettings()
              WeatherService.refresh()
            }
          }
        }

        // Cancel Button
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: ScalerService.s(50)
          radius: ScalerService.s(12)
          color: theme.button.background
          opacity: cancelMouseArea.pressed ? 0.8 : 1

          CustomText {
            anchors.centerIn: parent
            name: "Cancel"
            size: "medium"
            textColor: theme.primary.foreground
          }

          MouseArea {
            id: cancelMouseArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: settingsRoot.showSettings = false
          }
        }
      }
    }
  }

  // Keyboard shortcuts
  Shortcut {
    sequence: "Up"
    enabled: locationSearchResults.length > 0
    onActivated: {
      if (currentLocationIndex > 0)
      currentLocationIndex--;
      else
      currentLocationIndex = locationSearchResults.length - 1;
    }
  }

  Shortcut {
    sequence: "Down"
    enabled: locationSearchResults.length > 0
    onActivated: {
      if (currentLocationIndex < locationSearchResults.length - 1)
      currentLocationIndex++;
      else
      currentLocationIndex = 0;
    }
  }

  Shortcut {
    sequence: "Return"
    enabled: locationSearchResults.length > 0
    onActivated: {
      var item = locationSearchResults[currentLocationIndex];
      if (item) {
        locationInput.text = `${item.name},${item.country}`;
        selectLocation(locationInput.text);
      }
    }
  }
}
