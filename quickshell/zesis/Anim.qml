pragma Singleton
import QtQuick
import Quickshell

// Animation timing tokens, single source of truth for all durations and
// easing curves. Use these instead of magic numbers. Pairs with Colors.qml
// (color) and UIScale.qml (space).
//
// drag   60   Direct-manipulation feedback (slider fill tracks input)
// micro  80   Icon/state flips, tiny reactions
// fast   150  Color transitions, hover feedback
// medium 200  Size and position changes
// slow   300  Overlay and panel transitions
// morph  420  Expand/contract layout morphs
//
// Easing curves follow the Material Design 3 motion spec
// (m3.material.io/styles/motion), QML's Easing.BezierSpline takes the same
// control points as CSS cubic-bezier() (append 1,1 as the through-point for
// a single-segment curve).
//
// standard           General-purpose utility transitions (hover, small state
//                    flips) - M3 "Standard" easing.
// emphasizedDecel/   Asymmetric pair for anything that enters/expands vs.
// emphasizedAccel    exits/collapses - decelerate in, accelerate out. M3
//                    "Emphasized decelerate/accelerate".
// spatial/           Layout, position, and size morphs (container-style
// spatialFast        transforms) - M3's spring-to-curve conversion for
//                    "Expressive spatial" motion. Carries a slight overshoot
//                    (y > 1), which reads as lively rather than mechanical.
//                    spatialFast is snappier/more pronounced overshoot for
//                    quick spatial reactions (draw-ins, small hops).

Singleton {
    readonly property int drag: 60
    readonly property int micro: 80
    readonly property int fast: 150
    readonly property int medium: 200
    readonly property int slow: 300
    readonly property int morph: 420

    readonly property var standard: [0.2, 0.0, 0, 1.0, 1, 1]
    readonly property var emphasizedDecel: [0.05, 0.7, 0.1, 1.0, 1, 1]
    readonly property var emphasizedAccel: [0.3, 0.0, 0.8, 0.15, 1, 1]
    readonly property var spatial: [0.38, 1.21, 0.22, 1.00, 1, 1]
    readonly property var spatialFast: [0.42, 1.67, 0.21, 0.90, 1, 1]
}
