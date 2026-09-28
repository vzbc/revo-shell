-- hyprliquid (zaregototsukai) — Liquid Glass material for layers
-- Loaded instead of HyprGlass for comparison; switch back via:
--   hyprland.lua: pcall(hl.plugin.load, ".../HyprGlass/hyprglass.so") + require("configs.hyprglass")
if hl.plugin.hyprliquid then
    hl.config(
    {
        plugin =
        {
            hyprliquid =
            {
                watch_system_color_scheme = false,
                background_sharing = false,
            }
        }
    });

    -- Dock: alpha-shaped surface with icons (radius 26 in QML)
    hl.layer_rule(
    {
        name = "macos-dock",
        match = { namespace = "macos:dock" },
        ["hyprliquid:effect"] = "liquid_glass",
        ["hyprliquid:corner_radius"] = 26,
        ["hyprliquid:z_radius"] = 26,
        ["hyprliquid:highlight_style"] = 4,
        ["hyprliquid:glass_dispersion"] = true,
        ["hyprliquid:vdf_map_mode"] = 1,
        ["hyprliquid:vdf_map_update_policy"] = "onchange",
    });

    -- (topbar + spotlight: disabled by request — effect kept on dock only)

    -- Control center + eqsh popovers (Pop with blur=true)
    hl.layer_rule(
    {
        name = "eqsh-blur",
        match = { namespace = "eqsh:blur" },
        ["hyprliquid:effect"] = "liquid_glass",
        ["hyprliquid:corner_radius"] = 24,
        ["hyprliquid:highlight_style"] = 4,
        ["hyprliquid:glass_dispersion"] = true,
        ["hyprliquid:vdf_map_mode"] = 1,
        ["hyprliquid:vdf_map_update_policy"] = "onchange",
    });

    -- Quickshell popups / secondary shell surfaces (top strip) — disabled by request

    -- Launchpad / launcher
    hl.layer_rule(
    {
        name = "macos-launchpad",
        match = { namespace = "macos:launchpad" },
        ["hyprliquid:effect"] = "liquid_glass",
        ["hyprliquid:corner_radius"] = 30,
        ["hyprliquid:highlight_style"] = 4,
        ["hyprliquid:vdf_map_mode"] = 1,
        ["hyprliquid:vdf_map_update_policy"] = "onchange",
    });
end
