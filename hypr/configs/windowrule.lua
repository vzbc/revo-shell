local inFocusOpacity = 0.9
local notInFocusOpacity = 0.7

hl.window_rule({
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

hl.window_rule({
    match = { class = ".*" },
    opacity = tostring(inFocusOpacity) .. " " .. tostring(notInFocusOpacity),
})

hl.window_rule({
    match = { class = "^kitty$" },
    opacity = "1 1",
})

hl.window_rule({
    match = { class = "^(firefox|brave|chromium|librewolf|qutebrowser|zen-browser)$" },
    opacity = tostring(inFocusOpacity) .. " " .. tostring(notInFocusOpacity),
})

hl.window_rule({
    match = { title = ".*Spotify.*" },
    opacity = tostring(inFocusOpacity) .. " " .. tostring(notInFocusOpacity),
})

hl.window_rule({
    match = { title = ".*Discord.*" },
    opacity = tostring(inFocusOpacity) .. " " .. tostring(notInFocusOpacity),
})

hl.window_rule({
    match = { title = ".*Telegram.*" },
    opacity = tostring(inFocusOpacity) .. " " .. tostring(notInFocusOpacity),
})

hl.window_rule({
    match = { title = ".*Code.*" },
    opacity = tostring(inFocusOpacity) .. " " .. tostring(notInFocusOpacity),
})

hl.window_rule({
    match = { title = ".*(Thunar|nemo).*" },
    opacity = tostring(inFocusOpacity) .. " " .. tostring(notInFocusOpacity),
})

hl.window_rule({
    match = { class = "^(gamescope)$" },
    immediate = true,
    fullscreen = true,
})

hl.window_rule({
    match = { class = "^(pearos-settings-app)$" },
    float = true,
    center = true,
    size = "700 600",
    no_shadow = true,
    tag = "+hyprglass_preset_liquid_true",
})
hl.window_rule({
    match = {
        class = "^(pcmanfm)$",
        title = "^(Desktop)$"
    },
    float = true,
    fullscreen = false,
    pin = true,
    no_focus = true,
    -- إعدادات إضافية لجعلها ثابتة تماماً بالخلفية بدون تأثيرات شفافة تزعجك
    suppress_event = "maximize",
})
