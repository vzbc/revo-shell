if hl.plugin.hyprglass then    local hg = hl.plugin.hyprglass


    -- Real Liquid Glass (matching shojiwm/liquid-glass.frag)
    hg.config({
        default_theme = "dark",
        default_preset = "liquid_true",
        tint_color = 0x00000000,
        manage_window_blur = 0,


        -- NO blur — pure refraction like the real effect
        blur_strength = 0.5,
        blur_iterations = 1,


        -- Edge refraction (matching real Liquid Glass quarter-circle curve)
        refraction_strength = 0.85,
        chromatic_aberration = 0.70,
        fresnel_strength = 0.50,
        specular_strength = 0.70,
        glass_opacity = 0.85,


        -- Edge band
        edge_thickness = 0.10,


        -- NO center dome
        lens_distortion = 0.0,


        dark = {
            brightness = 0.82,
            contrast = 0.90,
            saturation = 0.80,
            vibrancy = 0.15,
            vibrancy_darkness = 0.0,
            adaptive_dim = 0.4,
            adaptive_boost = 0.0,
        },


        layers = { enabled = true },
    })


    hg.preset("liquid_true", {
        blur_strength = 0.5,
        blur_iterations = 1,


        refraction_strength = 0.85,
        chromatic_aberration = 0.70,
        fresnel_strength = 0.50,
        specular_strength = 0.70,
        glass_opacity = 0.85,


        edge_thickness = 0.10,


        lens_distortion = 0.0,


        dark = {
            brightness = 0.82,
            contrast = 0.90,
            saturation = 0.80,
            vibrancy = 0.15,
            vibrancy_darkness = 0.0,
            adaptive_dim = 0.4,
            adaptive_boost = 0.0,
        },
    })


    hg.layer("macos:dock", {
        preset = "liquid_true",
        mask_mode = "alpha",
        mask_threshold = 0.01,
        live_resample = true,
    })


    hg.layer("macos:topbar", {
        preset = "liquid_true",
        mask_threshold = 0.1,
    })


    hg.layer("macos:spotlight", {
        preset = "liquid_true",
        mask_threshold = 0.15,
    })


    hg.layer("macos:controlcenter", {
        preset = "liquid_true",
        mask_threshold = 0.15,
    })


    hg.layer("macos:notifications", {
        preset = "liquid_true",
        mask_threshold = 0.1,
    })


    
    hg.layer("macos:controlcenter", {
    preset = "liquid_true",
    mask_threshold = 0.15,
})
end