hl.config({
    general = {
        gaps_out = 20,
        border_size = 3,
        col = {
            active_border = { colors = { "rgba(e0e0e0ff)", "rgba(ffffffff)" }, angle = 45 },
            inactive_border = "rgba(1e1e1eaa)"
        }
    },
    decoration = {
        rounding = 18,
        screen_shader = ""
    }
})

hl.layer_rule({
    name = "synoptik-shell",
    match = { namespace = "^synoptik-shell.*" },
    blur = true,
    xray = true,
    ignore_alpha = 0.6
})

hl.bind("SUPER + B", hl.dsp.exec_cmd("qs -c Synoptik ipc call wallpaper toggle"))
hl.bind("SUPER + A", hl.dsp.exec_cmd("qs -c Synoptik ipc call launcher toggle"))
hl.bind("SUPER + Space", hl.dsp.exec_cmd("qs -c Synoptik ipc call settings toggle"))
hl.bind("SUPER + TAB", hl.dsp.exec_cmd("qs -c Synoptik ipc call workspaceoverview toggle"))
hl.bind("SUPER + SHIFT + V", hl.dsp.exec_cmd("qs -c Synoptik ipc call clipboard toggle"))
hl.bind("SUPER + L", hl.dsp.exec_cmd("qs -c Synoptik ipc call lockscreen toggle"))
hl.bind("CTRL + ALT + P", hl.dsp.exec_cmd("qs -c Synoptik ipc call shader toggle"))
