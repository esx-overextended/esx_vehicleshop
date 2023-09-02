lib.locale()

Config = {}

Config.Debug = false

Config.DefaultPed = `A_M_Y_Business_01`

Config.DefaultVehiclePreviewCoords = vector4(-75.21, -819.1, 325.17, 317.48)
Config.DefaultVehicleSpawnCoordsAfterPurchase = vector4(133.25, -3210.30, 5.43, 272.12)

Config.VehicleShops = {
    ["pdm"] = {
        categories = { "compacts", "coupes", "motorcycles", "muscle", "offroad", "sedans", "sports", "sportsclassics", "suvs", "vans" }, -- optional
        label = "Premium Deluxe Motorsport",
        blip = {                                                                                                                         -- optional
            active = true,
            coords = vector3(-46.08, -1098.30, 26.4),
            type = 810,
            size = 0.8,
            color = 0
        },
        representativePeds = {
            {
                model = nil, -- optional - if omitted, it will use the Config.DefaultPed
                coords = vector4(-33.0, -1103.79, 25.41, 76.53),
                distance = 30.0,
                marker = {                                          -- optional
                    type = 36,                                      -- optional
                    size = { x = 1.0, y = 1.0, z = 1.0 },           -- optional
                    color = { r = 120, g = 120, b = 240, a = 100 }, -- optional
                    coords = vector3(-33.0, -1103.79, 27.41),       -- optional
                    drawDistance = 10.0                             -- optional
                }
            },
            {
                model = `A_F_Y_Business_01`, -- optional - if omitted, it will use the Config.DefaultPed
                coords = vector4(-56.58, -1098.67, 25.41, 11.34),
                distance = 30.0,
                marker = {                                          -- optional
                    type = 36,                                      -- optional
                    size = { x = 1.0, y = 1.0, z = 1.0 },           -- optional
                    color = { r = 120, g = 120, b = 240, a = 100 }, -- optional
                    coords = vector3(-56.58, -1098.67, 27.41),      -- optional
                    drawDistance = 10.0                             -- optional
                }
            },
        },
        vehiclePreviewCoords = vector4(-47.5, -1097.2, 25.4, -20.0),           -- optional - if omitted, it will use the Config.DefaultVehiclePreviewCoords
        vehicleSpawnCoordsAfterPurchase = vector4(-28.6, -1085.6, 25.5, 330.0) -- optional - if omitted, it will use the Config.DefaultVehicleSpawnCoordsAfterPurchase
    },
    ["pdm_highend"] = {
        categories = { "super" }, -- optional
        label = "Premium Deluxe Motorsport - High End",
        blip = {                  -- optional
            active = true,
            coords = vector3(-1256.20, -362.24, 36.89),
            type = 810,
            size = 0.8,
            color = 0
        },
        representativePeds = {
            {
                model = `S_F_M_Shop_HIGH`, -- optional - if omitted, it will use the Config.DefaultPed
                coords = vector4(-1252.37, -349.14, 35.89, 119.05),
                distance = 30.0,
                marker = {                                          -- optional
                    type = 36,                                      -- optional
                    size = { x = 1.0, y = 1.0, z = 1.0 },           -- optional
                    color = { r = 120, g = 120, b = 240, a = 100 }, -- optional
                    coords = vector3(-1252.37, -349.14, 37.89),     -- optional
                    drawDistance = 28.0                             -- optional
                }
            },
        },
        representativeVehicles = {
            {
                coords = vector4(-1262.909, -353.173, 36.272, 178.694),
                distance = 100.0,
            },
            {
                coords = vector4(-1267.627, -355.330, 36.272, 239.634),
                distance = 100.0,
            },
            {
                coords = vector4(-1271.13, -358.78, 36.272, 255.12),
                distance = 100.0,
            },
            {
                coords = vector4(-1269.559, -364.349, 36.108, 319.256),
                distance = 100.0,
            },
            {
                coords = vector4(-1249.098, -350.528, 39.663, 206.351),
                distance = 100.0,
            },
            {
                coords = vector4(-1246.203, -354.344, 39.663, 117.634),
                distance = 100.0,
            },
            {
                coords = vector4(-1244.934, -358.844, 39.663, 26.534),
                distance = 100.0,
            },
        },
        vehiclePreviewCoords = vector4(-1256.1, -366.80, 36.74, 297.0),           -- optional - if omitted, it will use the Config.DefaultVehiclePreviewCoords
        vehicleSpawnCoordsAfterPurchase = vector4(-1250.24, -358.39, 36.5, 264.0) -- optional - if omitted, it will use the Config.DefaultVehicleSpawnCoordsAfterPurchase
    },
    ["beach_bike"] = {
        categories = { "cycles" },
        label = "Bicycle Shop",
        blip = {
            active = true,
            coords = vector3(-1109.61, -1694.15, 3.5),
            type = 494,
            size = 0.8,
            color = 2
        },
        representativePeds = {
            {
                model = `U_M_M_BikeHire_01`,
                coords = vector4(-1107.995605, -1694.268066, 3.359009, 314.645660),
                distance = 30.0,
                marker = {
                    type = 38,
                    size = { x = 1.0, y = 1.0, z = 1.0 },
                    color = { r = 120, g = 120, b = 240, a = 100 },
                    coords = vector3(-1107.995605, -1694.268066, 5.359009),
                    drawDistance = 20.0
                }
            },
        },
        vehiclePreviewCoords = vector4(-1114.747192, -1687.094482, 3.752441, 34.015747),
        vehicleSpawnCoordsAfterPurchase = vector4(-1096.457153, -1711.661499, 3.752441, 306.141724)
    }
}

Config.SellPoints = {
    {
        categories = { "compacts", "coupes", "motorcycles", "muscle", "offroad", "sedans", "sports", "sportsclassics", "suvs", "vans" }, -- optional
        label = nil,                                                                                                                     -- optional
        blip = {                                                                                                                         -- optional
            active = true,
            type = 810,
            size = 0.7,
            color = 1
        },
        marker = {
            type = 1,
            size = { x = 2.5, y = 2.5, z = 1.5 },
            color = { r = 120, g = 0, b = 0, a = 100 },
            coords = vector3(-36.29, -1088.59, 25.4),
            drawDistance = 20.0
        },
        resellPercentage = 40
    },
    {
        categories = { "super" }, -- optional
        label = nil,              -- optional
        blip = {                  -- optional
            active = true,
            type = 810,
            size = 0.7,
            color = 1
        },
        marker = {
            type = 1,
            size = { x = 2.5, y = 2.5, z = 1.5 },
            color = { r = 120, g = 0, b = 0, a = 100 },
            coords = vector3(-1223.58, -347.97, 36.33),
            drawDistance = 30.0
        },
        resellPercentage = 40
    },
    {
        categories = { "cycles" }, -- optional
        label = "Bicycle Sell",    -- optional
        blip = {                   -- optional
            active = true,
            type = 494,
            size = 0.7,
            color = 1
        },
        marker = {
            type = 1,
            size = { x = 1.5, y = 1.5, z = 1.0 },
            color = { r = 120, g = 0, b = 0, a = 100 },
            coords = vector3(-1105.37, -1700.96, 3.35),
            drawDistance = 20.0
        },
        resellPercentage = 80
    }
}
