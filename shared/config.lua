Config = {}

Config.Debug = false

Config.DefaultPed = `A_M_Y_Business_01`

Config.DefaultVehiclePreviewCoords = vector4(-75.21, -819.1, 325.17, 317.48)
Config.DefaultVehicleSpawnCoordsAfterPurchase = vector4(133.25, -3210.30, 5.43, 272.12)

Config.VehicleShops = {
    ["pdm"] = {
        -- Categories = { "super" }, -- optional
        Label = "Premium Deluxe Motorsport",
        Blip = { -- optional
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
            {
                Model = `A_M_Y_Business_03`, -- optional
                Coords = vector4(-56.58, -1098.67, 25.41, 11.34),
                Distance = 30.0,
                Marker = {                                          -- optional
                    Type = 36,                                      -- optional
                    Size = { x = 1.0, y = 1.0, z = 1.0 },           -- optional
                    Color = { r = 120, g = 120, b = 240, a = 100 }, -- optional
                    Coords = vector3(-56.58, -1098.67, 27.41),      -- optional
                    DrawDistance = 10.0                             -- optional
                }
            },
        },
        VehiclePreviewCoords = vector4(-47.5, -1097.2, 25.4, -20.0),           -- optional
        VehicleSpawnCoordsAfterPurchase = vector4(-28.6, -1085.6, 25.5, 330.0) -- optional
    }
}
