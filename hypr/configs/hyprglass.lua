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
        refraction_strength = 1.10,
        chromatic_aberration = 0.50,
        fresnel_strength = 0.50,
        specular_strength = 0.55,
        glass_opacity = 0.25,


        -- Edge band
        edge_thickness = 0.5,


        -- NO center dome
        lens_distortion = 0.0,


        dark = {
            brightness = 0.95,
            contrast = 1.0,
            saturation = 1.0,
            vibrancy = 0.15,
            vibrancy_darkness = 0.0,
            adaptive_dim = 0.05,
            adaptive_boost = 0.0,
        },


        layers = { enabled = true },
    })


    hg.preset("liquid_true", {
        blur_strength = 0.5,
        blur_iterations = 1,


        refraction_strength = 1.10,
        chromatic_aberration = 0.50,
        fresnel_strength = 0.50,
        specular_strength = 0.55,
        glass_opacity = 0.25,


        edge_thickness = 0.5,


        lens_distortion = 0.0,


        dark = {
            brightness = 0.95,
            contrast = 1.0,
            saturation = 1.0,
            vibrancy = 0.15,
            vibrancy_darkness = 0.0,
            adaptive_dim = 0.05,
            adaptive_boost = 0.0,
        },
    })


    hg.layer("macos:dock", {
        preset = "liquid_true",
        mask_mode = "alpha",
        mask_threshold = 0.01,
        live_resample = true,
        blur_strength = 1.2,
        blur_iterations = 5,
        lens_distortion = 1.0,
        edge_thickness = 0.5,
        refraction_strength = 3.0,
        chromatic_aberration = 0.75,
    })


    hg.layer("macos:topbar", {
        preset = "liquid_true",
        mask_threshold = 0.1,
        blur_strength = 2.0,
        blur_iterations = 3,
    })


    hg.layer("eqsh:spotlight", {
        preset = "liquid_true",
        mask_threshold = 0.15,
    })


    hg.layer("eqsh:ddm-blur", {
        preset = "liquid_true",
        mask_threshold = 0.15,
    })


    hg.layer("eqsh:blur", {
        preset = "liquid_true",
        mask_mode = "alpha",
        mask_threshold = 0.01,
        live_resample = true,
        blur_strength = 3.5,
        blur_iterations = 5,
        glass_opacity = 0.15,
    })


    hg.layer("quickshell", {
        preset = "liquid_true",
        mask_threshold = 0.1,
    })


    hg.layer("macos:launchpad", {
        preset = "liquid_true",
        mask_threshold = 0.15,
    })
end