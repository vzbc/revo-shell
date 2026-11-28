-- monitors.lua: every screen at its own best mode (highest refresh rate at its
-- native resolution), placed automatically, with Hyprland's scale for its size.
-- Never force one machine's mode here: a 2560x1600 mode on a 1920x1080 panel
-- becomes a custom mode that the panel letterboxes (black edges).
-- To pin a screen, add a block before this one, e.g.
--   hl.monitor({ output = "eDP-1", mode = "2560x1600@120", position = "auto", scale = 1, vrr = 2 })

hl.monitor({
    output   = "",
    mode     = "highrr",
    position = "auto",
    scale    = "auto",
})
