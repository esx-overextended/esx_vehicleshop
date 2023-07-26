Config = {}

Config.Debug = false

Config.DefaultPed = `A_M_Y_Business_01`

Config.DefaultVehiclePreviewCoords = vector4(-75.21, -819.1, 325.17, 317.48)
Config.DefaultVehicleSpawnCoordsAfterPurchase = vector4(133.25, -3210.30, 5.43, 272.12)

Config.VehicleShops = {
    ["pdm"] = {
        Categories = { "compacts", "coupes", "motorcycles", "muscle", "offroad", "sedans", "sports", "sportsclassics", "super", "suvs", "vans" }, -- optional
        Label = "Premium Deluxe Motorsport",
        Blip = {                                                                                                                                  -- optional
            Active = true,
            Coords = vector3(-46.08, -1098.30, 26.4),
            Type = 810,
            Size = 0.8,
            Color = 0
        },
        BuyPoints = {
            {
                Model = nil, -- optional
                Coords = vector4(-33.0, -1103.79, 25.41, 76.53),
                Distance = 30.0,
                Marker = { -- optional
                    Type = 36,
                    Size = { x = 1.0, y = 1.0, z = 1.0 },
                    Color = { r = 120, g = 120, b = 240, a = 100 },
                    Coords = vector3(-33.0, -1103.79, 27.41), -- optional
                    DrawDistance = 10.0
                }
            },
            {
                Model = `A_M_Y_Business_03`, -- optional
                Coords = vector4(-56.58, -1098.67, 25.41, 11.34),
                Distance = 30.0,
                Marker = { -- optional
                    Type = 36,
                    Size = { x = 1.0, y = 1.0, z = 1.0 },
                    Color = { r = 120, g = 120, b = 240, a = 100 },
                    Coords = vector3(-56.58, -1098.67, 27.41), -- optional
                    DrawDistance = 10.0
                }
            },
        },
        VehiclePreviewCoords = vector4(-47.5, -1097.2, 25.4, -20.0), -- optional
        -- VehicleSpawnCoordsAfterPurchase = vector4(-28.6, -1085.6, 25.5, 330.0) -- optional
    },
    ["beach_bike"] = {
        Categories = { "cycles" },
        Label = "Bicycle Shop",
        Blip = {
            Active = true,
            Coords = vector3(-1109.61, -1694.15, 3.5),
            Type = 494,
            Size = 0.8,
            Color = 2
        },
        BuyPoints = {
            {
                Model = `U_M_M_BikeHire_01`,
                Coords = vector4(-1107.995605, -1694.268066, 3.359009, 314.645660),
                Distance = 30.0,
                Marker = {
                    Type = 38,
                    Size = { x = 1.0, y = 1.0, z = 1.0 },
                    Color = { r = 120, g = 120, b = 240, a = 100 },
                    Coords = vector3(-1107.995605, -1694.268066, 5.359009),
                    DrawDistance = 20.0
                }
            },
        },
        VehiclePreviewCoords = vector4(-1114.747192, -1687.094482, 3.752441, 34.015747),
        VehicleSpawnCoordsAfterPurchase = vector4(-1096.457153, -1711.661499, 3.752441, 306.141724)
    }
}
