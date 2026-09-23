import QtQuick

QtObject {
    id: root

    property double nowMilliseconds: Date.now()
    property double caffeineUntilMilliseconds: 0
    property Timer caffeineTimer
    readonly property bool caffeineEnabled: caffeineUntilMilliseconds > nowMilliseconds
    readonly property int caffeineRemainingMinutes: caffeineEnabled ? Math.max(1, Math.ceil((caffeineUntilMilliseconds - nowMilliseconds) / 60000)) : 0
    readonly property string caffeineStatusText: caffeineEnabled ? caffeineRemainingMinutes + " min left" : "Idle rules active"

    function startCaffeine(minutes) {
        const duration = Math.max(1, Number(minutes) || 60);
        nowMilliseconds = Date.now();
        caffeineUntilMilliseconds = nowMilliseconds + duration * 60000;
    }

    function stopCaffeine() {
        caffeineUntilMilliseconds = 0;
        nowMilliseconds = Date.now();
    }

    function toggleCaffeine() {
        if (caffeineEnabled)
            stopCaffeine();
        else
            startCaffeine(60);
    }

    caffeineTimer: Timer {
        interval: 1000
        repeat: true
        running: root.caffeineUntilMilliseconds > 0
        triggeredOnStart: true
        onTriggered: {
            root.nowMilliseconds = Date.now();
            if (root.caffeineUntilMilliseconds <= root.nowMilliseconds)
                root.caffeineUntilMilliseconds = 0;

        }
    }

}
