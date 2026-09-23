import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property var configRef: null

    property Process shaderUpdater: Process {
        id: proc
        property string script: ""
        command: ["python3", "-c", script]
    }

    function updateShader() {
        if (!configRef || !configRef.isLoaded) return

        if (!configRef.pixelShaderEnabled) {
            proc.script = "import subprocess\nsubprocess.run(['hyprctl', 'eval', 'hl.config({ decoration = { screen_shader = \"\" } })'])"
            proc.running = true
            return
        }

        const mode = configRef.pixelShaderMode || "pixelate"
        const pixelSize = (configRef.pixelShaderSize || 2.0).toFixed(1)
        const levels = (configRef.pixelShaderLevels || 32.0).toFixed(1)
        const dither = configRef.pixelShaderDither !== false
        const grid = configRef.pixelShaderGrid === true
        const boost = configRef.pixelShaderBoost !== false
        const palette = configRef.pixelShaderPalette || "default"

        let glsl = ""

        if (mode === "pixelate") {
            glsl = `#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

float get_bayer(vec2 coord) {
    int x = int(mod(coord.x, 4.0));
    int y = int(mod(coord.y, 4.0));
    vec4 row;
    if (y == 0)      row = vec4(0.0, 12.0, 3.0, 15.0);
    else if (y == 1) row = vec4(8.0, 4.0, 11.0, 7.0);
    else if (y == 2) row = vec4(2.0, 14.0, 1.0, 13.0);
    else             row = vec4(10.0, 6.0, 9.0, 5.0);
    float val = row.w;
    if (x == 0) val = row.x; else if (x == 1) val = row.y; else if (x == 2) val = row.z;
    return val / 16.0;
}

void main() {
    float pixel_size = ${pixelSize};
    float color_levels = ${levels};

    vec2 pixel_uv = vec2(abs(dFdx(v_texcoord.x)), abs(dFdy(v_texcoord.y)));
    vec2 step_size = pixel_uv * pixel_size;
    vec2 blockCoord = (floor(v_texcoord / step_size) + 0.5) * step_size;
    vec4 baseColor = texture(tex, blockCoord);

    vec2 grid_pos = floor(v_texcoord / step_size);
    ${dither ? "float dither = (get_bayer(grid_pos) - 0.5) * (1.0 / color_levels);" : "float dither = 0.0;"}

    vec3 color = floor((baseColor.rgb + dither) * color_levels) / color_levels;
    ${boost ? "color = clamp((color - 0.5) * 1.08 + 0.5, 0.0, 1.0);" : ""}
    ${grid ? `vec2 block_uv = fract(v_texcoord / step_size);
    float border = step(0.12, block_uv.x) * step(0.12, block_uv.y) * step(block_uv.x, 0.88) * step(block_uv.y, 0.88);
    color *= mix(0.85, 1.0, border);` : ""}

    ${palette === "gameboy" ? `float lum = dot(color, vec3(0.299, 0.587, 0.114));
    float shade = floor(lum * 4.0) / 3.0;
    color = mix(vec3(0.06, 0.22, 0.06), vec3(0.61, 0.73, 0.06), shade);` : ""}
    ${palette === "amber" ? `float lum = dot(color, vec3(0.299, 0.587, 0.114));
    color = vec3(lum * 1.0, lum * 0.7, lum * 0.1);` : ""}

    fragColor = vec4(color, baseColor.a);
}`
        } else if (mode === "crt") {
            glsl = `#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

vec2 curve(vec2 uv) {
    vec2 c = (uv - 0.5) * 2.0;
    c *= 1.05;
    c.x *= 1.0 + pow((abs(c.y) / 5.2), 2.0);
    c.y *= 1.0 + pow((abs(c.x) / 4.4), 2.0);
    return (c / 2.0) + 0.5;
}

void main() {
    vec2 uv = curve(v_texcoord);

    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        fragColor = vec4(0.01, 0.01, 0.01, 1.0);
        return;
    }

    vec2 pixel_uv = vec2(abs(dFdx(v_texcoord.x)), abs(dFdy(v_texcoord.y)));
    vec2 screen_pos = v_texcoord / pixel_uv;

    vec2 dist_from_center = uv - vec2(0.5);
    float ca = length(dist_from_center) * 0.002;
    float r = texture(tex, uv + dist_from_center * ca).r;
    float g = texture(tex, uv).g;
    float b = texture(tex, uv - dist_from_center * ca).b;
    vec3 color = vec3(r, g, b);

    float scanline = sin(screen_pos.y * 1.5) * 0.08;
    color -= scanline;

    int mask_col = int(mod(screen_pos.x, 3.0));
    vec3 mask = vec3(0.88);
    if (mask_col == 0)      mask = vec3(1.08, 0.88, 0.88);
    else if (mask_col == 1) mask = vec3(0.88, 1.08, 0.88);
    else                    mask = vec3(0.88, 0.88, 1.08);
    color *= mask;

    float vig = uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y);
    color *= clamp(pow(16.0 * vig, 0.25), 0.0, 1.0);

    color = clamp((color - 0.5) * 1.08 + 0.5, 0.0, 1.0);

    fragColor = vec4(color, 1.0);
}`
        } else if (mode === "mac1bit") {
            glsl = `#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

float get_bayer(vec2 coord) {
    int x = int(mod(coord.x, 4.0));
    int y = int(mod(coord.y, 4.0));
    vec4 row;
    if (y == 0)      row = vec4(0.0, 12.0, 3.0, 15.0);
    else if (y == 1) row = vec4(8.0, 4.0, 11.0, 7.0);
    else if (y == 2) row = vec4(2.0, 14.0, 1.0, 13.0);
    else             row = vec4(10.0, 6.0, 9.0, 5.0);
    float val = row.w;
    if (x == 0) val = row.x; else if (x == 1) val = row.y; else if (x == 2) val = row.z;
    return val / 16.0;
}

void main() {
    float pixel_size = 2.0;
    vec2 pixel_uv = vec2(abs(dFdx(v_texcoord.x)), abs(dFdy(v_texcoord.y)));
    vec2 step_size = pixel_uv * pixel_size;
    vec2 blockCoord = (floor(v_texcoord / step_size) + 0.5) * step_size;
    vec4 baseColor = texture(tex, blockCoord);

    float lum = dot(baseColor.rgb, vec3(0.299, 0.587, 0.114));
    vec2 grid_pos = floor(v_texcoord / step_size);
    float threshold = get_bayer(grid_pos);
    float bw = step(threshold, lum);

    vec3 ink = vec3(0.12, 0.12, 0.14);
    vec3 paper = vec3(0.92, 0.93, 0.90);
    fragColor = vec4(mix(ink, paper, bw), baseColor.a);
}`
        }

        let py = "import os, subprocess\n" +
            "p = os.path.expanduser('~/.config/hypr/shaders/pixelate.frag')\n" +
            "os.makedirs(os.path.dirname(p), exist_ok=True)\n" +
            "with open(p, 'w') as f:\n" +
            "    f.write(" + JSON.stringify(glsl) + ")\n" +
            "subprocess.run(['hyprctl', 'eval', 'hl.config({ decoration = { screen_shader = \"\" } })'])\n" +
            "cmd = 'hl.config({ decoration = { screen_shader = \"' + (p if " + (configRef.pixelShaderEnabled ? "True" : "False") + " else '') + '\" } })'\n" +
            "subprocess.run(['hyprctl', 'eval', cmd])\n"

        proc.script = py
        proc.running = true
        if (typeof configRef.syncHyprlandBorders === "function") {
            configRef.syncHyprlandBorders()
        }
    }
}