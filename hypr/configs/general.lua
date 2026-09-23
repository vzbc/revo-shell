hl.config({
    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo = true,
    },

    general = {
        gaps_in = 6,
        gaps_out = 12,
        ["col.active_border"] = "rgba(ffffff10)", 
        ["col.inactive_border"] = "rgba(00000000)", 
    },

    decoration = {
        rounding = 14, 

        -- إعدادات الشفافية (ضرورية لظهور الـ Blur داخل النوافذ)
        active_opacity = 0.92,   -- درجة شفافية النافذة النشطة (زدها أو قللها حسب رغبتك)
        inactive_opacity = 0.85, -- درجة شفافية النوافذ الخلفية

        shadow = {
            enabled = true,
            range = 25, 
            render_power = 4,
            color = "rgba(00000040)",
        },

        blur = {
            enabled = true,
            size = 8,
            passes = 3,
            new_optimizations = true,
            ignore_opacity = true, -- إجبار الـ Blur على الظهور حتى لو تغيرت الشفافية
        },
    },
})
