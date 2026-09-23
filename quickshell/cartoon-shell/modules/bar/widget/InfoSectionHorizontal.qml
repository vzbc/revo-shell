import qs.components
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.commons

Item {
    id: root
    property real animationProgress: 0
    RowLayout {
        anchors.fill: parent
        anchors {
            leftMargin: ScalerService.s(10)
            rightMargin: ScalerService.s(10)
        }
        spacing: ScalerService.s(5)

        // Phần datetime - căn trái
        Item {
            id: timeContainer
            Layout.preferredWidth: textCurrentDate.implicitWidth + ScalerService.s(20)
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: ScalerService.s(10)
                spacing: 0
                CustomText {
                    name: DateTimeService.currentTime
                    isBold: true
                    size: "small"
                    opacity: root.animationProgress > 0.3 ? 1 : 0
                }
                CustomText {
                    id: textCurrentDate
                    name: DateTimeService.currentDate
                    size: "xs"
                    color: theme.primary.dim_foreground
                    opacity: root.animationProgress > 0.35 ? 1 : 0
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    SoundService.playSound("pick");
                    VisibleService.togglePanel("calendar");
                }

                // Hiệu ứng hover
                onEntered: {
                    timeContainer.scale = 1.04;
                }
                onExited: {
                    timeContainer.scale = 1.0;
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 100
                }
            }
        }

        // Spacer để đẩy phần giữa ra chính giữa
        Item {
            Layout.fillWidth: true
        }

        // Phần weather - căn giữa
        Item {
            id: weatherContainer
            Layout.preferredWidth: contentWeather.implicitWidth
            Layout.fillHeight: true

            RowLayout {
                id: contentWeather
                anchors.centerIn: parent
                IconImage {
                    path: WeatherService.getWeatherIcon(WeatherService.dataModel.current.condition.code, WeatherService.dataModel.current.is_day)
                    size: "normal"
                    opacity: root.animationProgress > 0.4 ? 1 : 0
                }

                ColumnLayout {
                    spacing: ScalerService.s(1)
                    CustomText {
                        name: `${WeatherService.dataModel.current.temp_c}°C` || "Loading..."
                        Layout.alignment: Qt.AlignVCenter
                        size: "small"
                        opacity: root.animationProgress > 0.45 ? 1 : 0
                    }
                    CustomText {
                        id: textCondition

                        opacity: root.animationProgress > 0.5 ? 1 : 0
                        name: WeatherService.dataModel.current.condition.text.slice(0, 15) || "..."
                        size: "xs"
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    SoundService.playSound("pick");
                    VisibleService.togglePanel("weather");
                }

                onEntered: {
                    weatherContainer.scale = 1.04;
                }
                onExited: {
                    weatherContainer.scale = 1.0;
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 100
                }
            }
        }

        // Spacer để đẩy phần flag sang bên phải
        Item {
            Layout.fillWidth: true
        }

        // Flag Selector - căn phải
        Item {
            id: flagContainer
            Layout.preferredWidth: ScalerService.s(32)
            Layout.fillHeight: parent

            ButtonIconImage {
                path: `flags/${Settings.appearance.countryFlag}.png`
                opacity: root.animationProgress > 0.5 ? 1 : 0
                size: "large"
                anchors.centerIn: parent
                onClicked: {
                    VisibleService.togglePanel("flag");
                }
            }
        }
    }
}
