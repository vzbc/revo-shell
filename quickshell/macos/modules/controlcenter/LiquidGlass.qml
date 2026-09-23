import QtQuick
import QtQuick.Effects

Item {
    id: root

    property real radius: 28
    property color glassColor: Qt.rgba(1, 1, 1, 0.015) // خلفية شبه مخفية
    property color strokeHighlight: Qt.rgba(1, 1, 1, 0.25) // لمعة الزجاج العلوي
    property color strokeShadow: Qt.rgba(0, 0, 0, 0.2)     // ظل الانكسار السفلي

    default property alias content: containerLayout.children

    // 1. جسم الزجاج الأساسي
    Rectangle {
        id: glassBody
        anchors.fill: parent
        radius: root.radius
        color: root.glassColor
        opacity: 0.9

        // 2. محاكاة تأثير Backdrop Blur
        MultiEffect {
            anchors.fill: parent
            source: glassBody
            blurEnabled: true
            blur: 0.15
            blurMax: 12
        }

        // 3. طبقة التوهج والحدود الانكسارية (Liquid Stroke & Inset Shadows)
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.12)

            // التدرج اللوني الداخلي لإعطاء انطباع الانحناء المائي 3D
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"

                gradient: Gradient {
                    orientation: Gradient.TopLeftToBottomRight
                    GradientStop { position: 0.0; color: root.strokeHighlight }
                    GradientStop { position: 0.5; color: "transparent" }
                    GradientStop { position: 1.0; color: root.strokeShadow }
                }
            }
        }

        // حاوي العناصر الداخلية
        Item {
            id: containerLayout
            anchors.fill: parent
            anchors.margins: 12
        }
    }
}
