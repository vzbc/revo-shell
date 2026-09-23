#version 310 es
// Qt ShaderEffect-compatible vertex shader for liquid-glass.
// Qt injects qt_Matrix automatically; all other uniforms are declared
// individually so they bind to QML properties on the ShaderEffect.
precision highp float;

uniform highp mat4 qt_Matrix;

// ── Custom uniforms ( mirrored from glass.frag — both shaders must agree ) ──
uniform highp float resolution_x;
uniform highp float resolution_y;
uniform highp float pointer_x;
uniform highp float pointer_y;
uniform highp float intensity;
uniform highp float corner_radius;
uniform highp float max_z;
uniform highp float displacement_scale;
uniform highp float edge_smoothing;
uniform highp float profile_shape_n;
uniform highp float ior;
uniform highp float chroma_strength;
uniform highp float blur_strength;
uniform highp float tint_strength;
uniform highp float tint_r;
uniform highp float tint_g;
uniform highp float tint_b;
uniform highp float specular_intensity;
uniform highp float rim_width;
uniform highp float rim_intensity;
uniform highp float rim_directional_power;
uniform highp float rim_power;
uniform highp float rim_light_color_intensity;
uniform highp float sheen_intensity;
uniform highp float shininess;
uniform highp float surface_light_enabled;
uniform highp float ao_intensity;
uniform highp float ao_radius;
uniform highp float light_angle_deg;
uniform highp float mouse_radius;
uniform highp float bg_glow_intensity;
uniform highp float shadow_radius;
uniform highp float shadow_intensity;
uniform highp float shadow_max_radius;
uniform highp float padding;
uniform highp float isDock;
uniform highp float glass_opacity;
uniform highp float brightness;
uniform highp float contrast;
uniform highp float saturation;

layout(location = 0) in vec4 qt_Vertex;
layout(location = 1) in vec2 qt_MultiTexCoord0;
layout(location = 0) out vec2 qt_TexCoord0;

void main() {
    qt_TexCoord0 = qt_MultiTexCoord0;
    gl_Position = qt_Matrix * qt_Vertex;
}
