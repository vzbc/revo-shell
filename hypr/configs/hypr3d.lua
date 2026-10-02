if hl.plugin.hypr3d then
    -- binds
    hl.bind("SUPER + F12", hl.plugin.hypr3d.toggle)
    -- parameters
    hl.plugin.hypr3d.config({
        -- every key is optional
        world = {
            panorama = "/home/revo/Pictures/apple_park_360.png", -- 360° room background (equirectangular)
            grid = true,                      -- base 40x40 grid platform
        },
        windows = {
            window_scale = 0.5,   -- window size multiplier (real px at 100 px/m)
            spawn_distance = 5,   -- distance from the camera new windows spawn at
        },
        player = {
            look_sensitivity = 0.0025, -- mouse look, radians per pointer count
            look_inertia = 0.03,       -- look glide after the mouse stops, sec
            move_inertia = 0.05,       -- walk glide after keys release, sec
            move_speed = 4.0,          -- walking speed, m/s
            spawn = { x = 0, y = 0, z = 0 }, -- player position
            flying = true,             -- on alse: gravity, Space jumps off the ground, Shift does nothing
        },
        map = {
            path = "/home/revo/Downloads/anime_stylized_room_free/scene.gltf",   -- glTF 2.0 map (.glb/.gltf)
            transform = {
                position = { x = 0, y = 0, z = 0 },
                rotation = { x = 0, y = 0, z = 0 },
                scale    = { x = 1, y = 1, z = 1 },
            },
            emissive_scale = 1.0, -- emission multiplier
            flat = true,          -- textures carry all lighting
            collision = true,     -- collide with the map
        },
    })
    -- That's all for now :p
end