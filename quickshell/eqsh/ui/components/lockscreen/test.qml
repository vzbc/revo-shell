import QtQuick
import Quickshell

ShellRoot {
	LockContext {
		id: lockContext
		onUnlocked: Qt.quit();

		onUnlocking: {
			locksur.unlock();
		}
	}

	FloatingWindow {
		color: "transparent"
		width: Quickshell.screens[0].width
		height: Quickshell.screens[0].height
		LockSurface {
			id: locksur
			anchors.fill: parent
			context: lockContext
		}
	}

	Connections {
		target: Quickshell

		function onLastWindowClosed() {
			Qt.quit();
		}
	}
}
