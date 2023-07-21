Config = {}

Config.Debug = true

Config.DefaultPed = `A_M_Y_Business_01`

Config.VehicleShops = {
    ["pdm"] = {
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
                Model = nil, -- nil, false, or model (if nil it will uses the Config.DefaultPed, if false, it won't spawn any ped for this point)
                Coords = vector4(-33.0, -1103.79, 25.41, 76.53),
                Distance = 20.0,
                Marker = {
                    Type = 36,
                    Size = { x = 1.5, y = 1.5, z = 1.0 },
                    Color = { r = 255, g = 255, b = 255 }
                }
            },
        }
    }
}
