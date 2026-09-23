import QtQuick
import QtQuick.Controls

// DEV env for DEVS. We don't make pretty UI here boi
Item {
    id: root

    property bool stressTestEnabled: false
    property int stressTestCount: 5000
    property var stressTestPoints: []

    readonly property var stressCities: [
        {
            lat: 51.5074,
            lon: -0.1278,
            weight: 5,
            spread: 1.5
        }   // London
        ,
        {
            lat: 48.8566,
            lon: 2.3522,
            weight: 5,
            spread: 1.5
        }    // Paris
        ,
        {
            lat: 52.5200,
            lon: 13.4050,
            weight: 4,
            spread: 1.5
        }   // Berlin
        ,
        {
            lat: 52.3676,
            lon: 4.9041,
            weight: 3,
            spread: 1.2
        }    // Amsterdam
        ,
        {
            lat: 55.6761,
            lon: 12.5683,
            weight: 3,
            spread: 1.2
        }   // Copenhagen
        ,
        {
            lat: 59.3293,
            lon: 18.0686,
            weight: 3,
            spread: 1.2
        }   // Stockholm
        ,
        {
            lat: 40.4168,
            lon: -3.7038,
            weight: 3,
            spread: 1.5
        }   // Madrid
        ,
        {
            lat: 41.9028,
            lon: 12.4964,
            weight: 3,
            spread: 1.5
        }   // Rome
        ,
        {
            lat: 52.2297,
            lon: 21.0122,
            weight: 2,
            spread: 1.5
        }   // Warsaw
        ,
        {
            lat: 40.7128,
            lon: -74.0060,
            weight: 4,
            spread: 1.8
        }  // New York
        ,
        {
            lat: 37.7749,
            lon: -122.4194,
            weight: 3,
            spread: 1.8
        } // San Francisco
        ,
        {
            lat: 35.6762,
            lon: 139.6503,
            weight: 3,
            spread: 1.5
        }  // Tokyo
        ,
        {
            lat: -33.8688,
            lon: 151.2093,
            weight: 1,
            spread: 2.0
        } // Sydney
        ,
        {
            lat: -23.5505,
            lon: -46.6333,
            weight: 2,
            spread: 2.0
        } // Sao Paulo
        ,
        {
            lat: 19.0760,
            lon: 72.8777,
            weight: 2,
            spread: 1.8
        }   // Mumbai
        ,
        {
            lat: 6.5244,
            lon: 3.3792,
            weight: 1,
            spread: 2.0
        }      // Lagos
    ]

    function generateStressTestPoints(count) {
        var totalWeight = 0;
        for (var c = 0; c < stressCities.length; c++)
            totalWeight += stressCities[c].weight;

        var pts = [];
        for (var n = 0; n < count; n++) {
            var r = Math.random() * totalWeight;
            var city = stressCities[0];
            for (var c2 = 0; c2 < stressCities.length; c2++) {
                r -= stressCities[c2].weight;
                if (r <= 0) {
                    city = stressCities[c2];
                    break;
                }
            }
            var jitterLat = ((Math.random() + Math.random() + Math.random()) / 3 - 0.5) * 2 * city.spread;
            var jitterLon = ((Math.random() + Math.random() + Math.random()) / 3 - 0.5) * 2 * city.spread;
            var lat = Math.max(-89, Math.min(89, city.lat + jitterLat));
            var lon = city.lon + jitterLon;
            if (lon > 180)
                lon -= 360;
            if (lon < -180)
                lon += 360;
            pts.push({
                lat: lat,
                lon: lon
            });
        }
        return pts;
    }

    function regenerateStressTest() {
        root.stressTestPoints = root.generateStressTestPoints(root.stressTestCount);
    }

    AssemblyGlobeView {
        id: engine
        anchors.fill: parent
        aaMode: AssemblyTestSettings.aaMode
        useImageCache: AssemblyTestSettings.useImageCache
        points: root.stressTestEnabled ? root.stressTestPoints : []
    }

    Column {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 8
        spacing: 6

        Text {
            color: "white"
            font.pixelSize: 14
            text: "Assembled globe - " + engine.rodCount + " instanced rods"
        }

        Text {
            color: "#7fff7f"
            font.pixelSize: 14
            font.family: "monospace"
            text: "draw calls: " + engine.drawCallCount + "  vertices: " + engine.drawVertexCount
        }

        Row {
            spacing: 8
            Button {
                text: "Scatter"
                onClicked: engine.triggerScatter()
            }
            Button {
                text: "Assemble"
                onClicked: engine.triggerAssemble()
            }
            Button {
                text: "Re-scatter (new random)"
                onClicked: engine.triggerReScatter()
            }
            CheckBox {
                text: "image cache"
                checked: engine.useImageCache
                onToggled: engine.useImageCache = checked
            }
            Text {
                color: "white"
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "AA"
            }
            ComboBox {
                width: 100
                model: ["Off", "Medium", "High", "VeryHigh"]
                currentIndex: model.indexOf(engine.aaMode)
                onActivated: index => engine.aaMode = model[index]
            }
            Button {
                text: "Blow up"
                onClicked: engine.triggerBlowUp()
            }
            Button {
                text: engine.flattenT > 0.5 ? "Globe-ify" : "Flatten"
                onClicked: engine.triggerFlattenToggle()
            }
        }

        Row {
            spacing: 8
            Text {
                color: "white"
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "height x" + engine.heightExaggeration.toFixed(2)
            }
            Slider {
                width: 200
                from: 0.0
                to: 3.0
                value: engine.heightExaggeration
                onMoved: engine.heightExaggeration = value
            }
            CheckBox {
                text: "close gaps"
                checked: engine.closeHeightGaps
                onToggled: engine.closeHeightGaps = checked
            }
            Text {
                visible: engine.closeHeightGaps
                color: "white"
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "flare " + engine.flareGain.toFixed(2)
            }
            Slider {
                visible: engine.closeHeightGaps
                width: 120
                from: 0.0
                to: 5.0
                value: engine.flareGain
                onMoved: engine.flareGain = value
            }
        }

        Row {
            spacing: 8
            Text {
                color: "white"
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "drift " + engine.driftAmplitude.toFixed(0)
            }
            Slider {
                width: 200
                from: 0.0
                to: 60.0
                value: engine.driftAmplitude
                onMoved: engine.driftAmplitude = value
            }
        }

        Row {
            spacing: 8
            Text {
                color: "white"
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "flatten " + engine.flattenT.toFixed(2)
            }
            Slider {
                width: 200
                from: 0.0
                to: 1.0
                value: engine.flattenT
                onMoved: engine.setFlattenT(value)
            }
        }

        Row {
            spacing: 8
            Text {
                color: "white"
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "effect"
            }
            ComboBox {
                width: 150
                model: ["None", "Scanner", "Ripple (click globe)"]
                currentIndex: engine.effectMode
                onActivated: index => engine.effectMode = index
            }
        }

        Row {
            spacing: 8
            CheckBox {
                text: "stress dots"
                checked: root.stressTestEnabled
                onToggled: {
                    root.stressTestEnabled = checked;
                    if (checked && root.stressTestPoints.length === 0)
                        root.regenerateStressTest();
                }
            }
            Text {
                color: "white"
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
                text: root.stressTestCount + " pts"
            }
            Slider {
                width: 160
                from: 100
                to: 10240
                stepSize: 100
                value: root.stressTestCount
                onMoved: root.stressTestCount = value
            }
            Button {
                text: "Regenerate"
                enabled: root.stressTestEnabled
                onClicked: root.regenerateStressTest()
            }
        }

        Row {
            spacing: 8
            visible: root.stressTestEnabled
            CheckBox {
                text: "glow"
                checked: engine.glowEnabled
                onToggled: engine.glowEnabled = checked
            }
            CheckBox {
                text: "track rod"
                checked: engine.dotsFollowRodHeight
                onToggled: engine.dotsFollowRodHeight = checked
            }
            Text {
                color: "white"
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "size " + engine.dotSize.toFixed(1)
            }
            Slider {
                width: 120
                from: 0.5
                to: 25.0
                value: engine.dotSize
                onMoved: engine.dotSize = value
            }
            Text {
                color: "white"
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "emit " + engine.dotIntensity.toFixed(1)
            }
            Slider {
                width: 120
                from: 0.2
                to: 8.0
                value: engine.dotIntensity
                onMoved: engine.dotIntensity = value
            }
        }

        Row {
            spacing: 8
            CheckBox {
                text: "stars"
                checked: engine.starsEnabled
                onToggled: engine.starsEnabled = checked
            }
            Text {
                color: "white"
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "count " + engine.starCount
            }
            Slider {
                width: 120
                from: 0
                to: 20000
                value: engine.starCount
                onMoved: engine.starCount = Math.round(value)
            }
        }

        Row {
            spacing: 8
            visible: root.stressTestEnabled && engine.glowEnabled
            Text {
                color: "white"
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "strength " + engine.glowStrength.toFixed(2)
            }
            Slider {
                width: 120
                from: 0.0
                to: 2.0
                value: engine.glowStrength
                onMoved: engine.glowStrength = value
            }
            Text {
                color: "white"
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "intensity " + engine.glowIntensity.toFixed(2)
            }
            Slider {
                width: 120
                from: 0.0
                to: 2.0
                value: engine.glowIntensity
                onMoved: engine.glowIntensity = value
            }
            Text {
                color: "white"
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "bloom " + engine.glowBloom.toFixed(2)
            }
            Slider {
                width: 120
                from: 0.0
                to: 1.0
                value: engine.glowBloom
                onMoved: engine.glowBloom = value
            }
            Text {
                color: "white"
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "hdr min " + engine.glowHDRMin.toFixed(1)
            }
            Slider {
                width: 120
                from: 0.5
                to: 8.0
                value: engine.glowHDRMin
                onMoved: engine.glowHDRMin = value
            }
        }

        Row {
            spacing: 8
            Text {
                color: "white"
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "light " + engine.lightBrightness.toFixed(2)
            }
            Slider {
                width: 200
                from: 0.0
                to: 2.0
                value: engine.lightBrightness
                onMoved: engine.lightBrightness = value
            }
        }

        Row {
            spacing: 8
            CheckBox {
                text: "audio reactive"
                checked: engine.audioReactiveEnabled
                onToggled: engine.audioReactiveEnabled = checked
            }
            Text {
                color: "white"
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "intensity " + engine.audioIntensity.toFixed(2)
            }
            Slider {
                width: 200
                from: 0.0
                to: 1.5
                value: engine.audioIntensity
                onMoved: engine.audioIntensity = value
            }
        }
    }
}
