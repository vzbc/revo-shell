import QtQuick

// ── Liquid Glass panel using custom shaders (glass.vert / glass.frag) ──
// Qt 5.15 compatible — all uniforms bound as individual QML properties.
// Backdrop:着色 rectangle (glassColor) rendered via ShaderEffectSource,
// bound to the shader's backdropTexture sampler via a variant property.
//
// Usage:
//   LiquidGlassShader {
//       anchors.fill: parent
//       radius: 26
//       specularIntensity: 0.55
//       blurAmount: 0.2
//       rimIntensity: 0.25
//       glassOpacity: 0.52
//   }

Item {
    id: root

    // ── Public API ──
    property real radius: 26
    property color glassColor: Qt.rgba(255, 255, 255, 0.12)
    property real specularIntensity: 0.55
    property real blurAmount: 0.2
    property real rimIntensity: 0.25
    property real aoIntensity: 0.35
    property real shadowIntensity: 0.12
    property real shadowRadius: 0.6
    property real glassOpacity: 0.52
    property real lightAngle: 55.0

    // ── Backdrop renderer ──
    // Renders a colored rectangle to a texture. This texture is bound
    // to the shader's backdropTexture sampler.
    Rectangle {
        id: backdropRect
        width: 4
        height: 4
        color: root.glassColor
    }

    ShaderEffectSource {
        id: backdropRenderer
        sourceItem: backdropRect
        hideSource: true
    }

    // ── Glass shader ──
    ShaderEffect {
        id: glassShader
        anchors.fill: parent
        fragmentShader: "shaders/glass.frag"
        vertexShader: "shaders/glass.vert"

        // ── Sampler binding (Qt 5: use variant property for sampler2D) ──
        property variant backdropTexture: backdropRenderer

        // ── Screen resolution ──
        property real resolution_x: 2560
        property real resolution_y: 1600

        // ── Mouse / interaction ──
        property real pointer_x: 0
        property real pointer_y: 0
        property real intensity: 1.0
        property real mouse_radius: 60.0

        // ── Glass SDF profile ──
        property real corner_radius: root.radius
        property real max_z: 0.06
        property real displacement_scale: 0.015
        property real edge_smoothing: 1.5
        property real profile_shape_n: 3.0

        // ── Refraction optics ──
        property real ior: 1.5
        property real chroma_strength: 0.0015

        // ── Backdrop processing ──
        property real blur_strength: root.blurAmount
        property real brightness: 1.0
        property real contrast: 1.0
        property real saturation: 1.0

        // ── Tint (base color for the glass) ──
        property real tint_strength: 1.0
        property real tint_r: root.glassColor.red
        property real tint_g: root.glassColor.green
        property real tint_b: root.glassColor.blue

        // ── Specular ──
        property real specular_intensity: root.specularIntensity
        property real shininess: 48.0

        // ── Rim light ──
        property real rim_width: 1.5
        property real rim_intensity: root.rimIntensity
        property real rim_directional_power: 1.0
        property real rim_power: 1.8
        property real rim_light_color_intensity: 1.0

        // ── Sheen ──
        property real sheen_intensity: 0.12

        // ── Surface lighting ──
        property real surface_light_enabled: 1.0

        // ── Ambient occlusion ──
        property real ao_intensity: root.aoIntensity
        property real ao_radius: 7.0

        // ── Lighting direction ──
        property real light_angle_deg: root.lightAngle

        // ── BG glow (disabled) ──
        property real bg_glow_intensity: 0.0

        // ── Shadow ──
        property real shadow_radius: root.shadowRadius
        property real shadow_intensity: root.shadowIntensity
        property real shadow_max_radius: 24.0

        // ── SDF padding ──
        property real padding: 3.0

        // ── Dock flag ──
        property real isDock: 1.0

        // ── Glass opacity ──
        property real glass_opacity: root.glassOpacity
    }

    // ── Mouse tracking ──
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        propagateComposedEvents: true
        onPositionChanged: {
            glassShader.pointer_x = mouse.x
            glassShader.pointer_y = mouse.y
        }
        onEntered: {
            glassShader.pointer_x = mouse.x
            glassShader.pointer_y = mouse.y
        }
        onExited: {
            glassShader.pointer_x = -9999
            glassShader.pointer_y = -9999
        }
    }
}
