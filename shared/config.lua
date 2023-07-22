Config = {}

Config.Debug = true

Config.DefaultPed = `A_M_Y_Business_01`

Config.VehicleShops = {
    ["pdm"] = {
        -- Categories = { "super" },
        Label = "Premium Deluxe Motorsport",
        Blip = {
            Active = true,
            Coords = vector3(-46.08, -1098.30, 26.4),
            Type = 326,
            Size = 0.8,
            Color = 0
        },
        BuyPoints = {
            {
                Model = nil, -- optional
                Coords = vector4(-33.0, -1103.79, 25.41, 76.53),
                Distance = 30.0,
                Marker = {
                    Type = 36,                                      -- optional
                    Size = { x = 1.0, y = 1.0, z = 1.0 },           -- optional
                    Color = { r = 120, g = 120, b = 240, a = 100 }, -- optional
                    Coords = vector3(-33.0, -1103.79, 27.41),       -- optional
                    DrawDistance = 10.0                             -- optional
                }
            },
        }
    }
}
