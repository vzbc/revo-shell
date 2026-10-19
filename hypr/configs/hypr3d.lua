if hl.plugin.hypr3d then
    hl.bind("SUPER + F12", hl.plugin.hypr3d.toggle)
    hl.plugin.hypr3d.config({
        world = {
            panorama = (os.getenv("HOME") or "") .. "/Pictures/apple_park_360.png",
            grid = false,
        },
        windows = {
            window_scale = 0.25,
            spawn_distance = 2,
        },
        player = {
            mesh = {
                path = "~/player.gltf",
                transform = {
                    rotation = {0, 90, 0},
                    scale =    {1.5, 1.5, 1.5},
                },
                emissive_scale = 1.0,
                flat = true,
                center = "origin",
            },
            animations = {
                idle = {source = "Idle"},
                walk = {source = "Walking"},
                run = {source = 2},
                jump = {source = 3, duration_scale=2.4},
            },
            collision = true,
            move_speed = 1.5,
            spawn = {0, 67, 0},
            flying = false,
            walk_bob = true
        },
        scene = {
            mymap = {
                mesh = {
                    path = "",
                    transform = {
                        position = {1, 0, 0},
                    },
                    emissive_scale = 1.0,
                    center_offset = {0, 34, 0},
                },
                collision = true,
                static = true,
            },
            anyname = {
                mesh = {
                    path = (os.getenv("HOME") or "") .. "/Downloads/cute_anime_girl_3d_model__stylized_blue_hair/scene.gltf",
                    transform = {
                        position = {y = 3},
                        scale =    {2, 2, 2},
                    },
                    emissive_scale = 1.0,
                    flat = true,
                    center = "origin",
                    center_offset = {0, 20, 0},
                },
                collision = true,
                static = false,
                physics = true,
            },
        }
    })
end