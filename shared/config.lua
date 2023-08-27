lib.locale()

Config = {}

Config.Debug = false

Config.DefaultPed = `A_M_Y_Business_01`

Config.DefaultVehiclePreviewCoords = vector4(-75.21, -819.1, 325.17, 317.48)
Config.DefaultVehicleSpawnCoordsAfterPurchase = vector4(133.25, -3210.30, 5.43, 272.12)

Config.VehicleShops = {
    ["pdm"] = {
        Categories = { "compacts", "coupes", "motorcycles", "muscle", "offroad", "sedans", "sports", "sportsclassics", "suvs", "vans" }, -- optional
        Label = "Premium Deluxe Motorsport",
        Blip = {                                                                                                                         -- optional
            Active = true,
            Coords = vector3(-46.08, -1098.30, 26.4),
            Type = 810,
            Size = 0.8,
            Color = 0
        },
        RepresentativePeds = {
            {
                Model = nil, -- optional - if omitted, it will use the Config.DefaultPed
                Coords = vector4(-33.0, -1103.79, 25.41, 76.53),
                Distance = 30.0,
                Marker = {                                          -- optional
                    Type = 36,                                      -- optional
                    Size = { x = 1.0, y = 1.0, z = 1.0 },           -- optional
                    Color = { r = 120, g = 120, b = 240, a = 100 }, -- optional
                    Coords = vector3(-33.0, -1103.79, 27.41),       -- optional
                    DrawDistance = 10.0                             -- optional
                }
            },
            {
                Model = `A_F_Y_Business_01`, -- optional - if omitted, it will use the Config.DefaultPed
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
        VehiclePreviewCoords = vector4(-47.5, -1097.2, 25.4, -20.0),           -- optional - if omitted, it will use the Config.DefaultVehiclePreviewCoords
        VehicleSpawnCoordsAfterPurchase = vector4(-28.6, -1085.6, 25.5, 330.0) -- optional - if omitted, it will use the Config.DefaultVehicleSpawnCoordsAfterPurchase
    },
    ["pdm_highend"] = {
        Categories = { "super" }, -- optional
        Label = "Premium Deluxe Motorsport - High End",
        Blip = {                  -- optional
            Active = true,
            Coords = vector3(-1256.20, -362.24, 36.89),
            Type = 810,
            Size = 0.8,
            Color = 0
        },
        RepresentativePeds = {
            {
                Model = `S_F_M_Shop_HIGH`, -- optional - if omitted, it will use the Config.DefaultPed
                Coords = vector4(-1252.37, -349.14, 35.89, 119.05),
                Distance = 30.0,
                Marker = {                                          -- optional
                    Type = 36,                                      -- optional
                    Size = { x = 1.0, y = 1.0, z = 1.0 },           -- optional
                    Color = { r = 120, g = 120, b = 240, a = 100 }, -- optional
                    Coords = vector3(-1252.37, -349.14, 37.89),     -- optional
                    DrawDistance = 28.0                             -- optional
                }
            },
        },
        RepresentativeVehicles = {
            {
                Coords = vector4(-1262.909, -353.173, 36.772, 178.694),
                Distance = 100.0,
            },
            {
                Coords = vector4(-1267.627, -355.330, 36.772, 239.634),
                Distance = 100.0,
            },
            {
                Coords = vector4(-1271.299, -359.559, 36.487, 261.21),
                Distance = 100.0,
            },
            {
                Coords = vector4(-1269.559, -364.349, 36.608, 319.256),
                Distance = 100.0,
            },
            {
                Coords = vector4(-1249.098, -350.528, 40.163, 206.351),
                Distance = 100.0,
            },
            {
                Coords = vector4(-1246.203, -354.344, 40.163, 117.634),
                Distance = 100.0,
            },
            {
                Coords = vector4(-1244.934, -358.844, 40.163, 26.534),
                Distance = 100.0,
            },
        },
        VehiclePreviewCoords = vector4(-1256.1, -366.80, 36.74, 297.0),           -- optional - if omitted, it will use the Config.DefaultVehiclePreviewCoords
        VehicleSpawnCoordsAfterPurchase = vector4(-1250.24, -358.39, 36.5, 264.0) -- optional - if omitted, it will use the Config.DefaultVehicleSpawnCoordsAfterPurchase
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
        RepresentativePeds = {
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

Config.SellPoints = {
    {
        Categories = { "compacts", "coupes", "motorcycles", "muscle", "offroad", "sedans", "sports", "sportsclassics", "suvs", "vans" }, -- optional
        Label = nil,                                                                                                                     -- optional
        Blip = {                                                                                                                         -- optional
            Active = true,
            Type = 810,
            Size = 0.7,
            Color = 1
        },
        Marker = {
            Type = 1,
            Size = { x = 2.5, y = 2.5, z = 1.5 },
            Color = { r = 120, g = 0, b = 0, a = 100 },
            Coords = vector3(-36.29, -1088.59, 25.4),
            DrawDistance = 20.0
        },
        ResellPercentage = 40
    },
    {
        Categories = { "super" }, -- optional
        Label = nil,              -- optional
        Blip = {                  -- optional
            Active = true,
            Type = 810,
            Size = 0.7,
            Color = 1
        },
        Marker = {
            Type = 1,
            Size = { x = 2.5, y = 2.5, z = 1.5 },
            Color = { r = 120, g = 0, b = 0, a = 100 },
            Coords = vector3(-1223.58, -347.97, 36.33),
            DrawDistance = 30.0
        },
        ResellPercentage = 40
    },
    {
        Categories = { "cycles" }, -- optional
        Label = "Bicycle Sell",    -- optional
        Blip = {                   -- optional
            Active = true,
            Type = 494,
            Size = 0.7,
            Color = 1
        },
        Marker = {
            Type = 1,
            Size = { x = 1.5, y = 1.5, z = 1.0 },
            Color = { r = 120, g = 0, b = 0, a = 100 },
            Coords = vector3(-1105.37, -1700.96, 3.35),
            DrawDistance = 20.0
        },
        ResellPercentage = 80
    }
}
