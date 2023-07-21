local zone, vehicleShopZones = {}, {}

function zone.configurePed(action, data)
    local vehicleShopData = Config.VehicleShops[data.vehicleShopKey]

    local cachePed = vehicleShopZones[data.vehicleShopKey]["buyPoints"][data.buyPointIndex].pedEntity

    if cachePed then
        if DoesEntityExist(cachePed) then DeletePed(cachePed) end

        vehicleShopZones[data.vehicleShopKey]["buyPoints"][data.buyPointIndex].pedEntity = nil
    end

    if action == "enter" then
        for i = 1, #vehicleShopData.BuyPoints do
            local buyPointData = vehicleShopData.BuyPoints[i]
            local pedModel = buyPointData.Model or Config.DefaultPed --[[@as number | string]]
            pedModel = type(pedModel) == "string" and joaat(pedModel) or pedModel --[[@as number]]

            lib.requestModel(pedModel, 1000)

            local pedEntity = CreatePed(0, pedModel, buyPointData.Coords.x, buyPointData.Coords.y, buyPointData.Coords.z, buyPointData.Coords.w, false, true)

            SetPedFleeAttributes(pedEntity, 2, true)
            SetBlockingOfNonTemporaryEvents(pedEntity, true)
            SetPedCanRagdollFromPlayerImpact(pedEntity, false)
            SetPedDiesWhenInjured(pedEntity, false)
            FreezeEntityPosition(pedEntity, true)
            SetEntityInvincible(pedEntity, true)
            SetPedCanPlayAmbientAnims(pedEntity, false)

            vehicleShopZones[data.vehicleShopKey]["buyPoints"][data.buyPointIndex].pedEntity = pedEntity
        end

        -- TODO: add target
    elseif action == "exit" then
        -- TODO: remove target
    end
end

local function configureZone(action, data)
    for functionName in pairs(zone) do
        zone[functionName](action, data)
    end

    collectgarbage("collect")
end

local function onVehicleShopBuyPointEnter(data)
    if vehicleShopZones[data.vehicleShopKey]["buyPoints"][data.buyPointIndex].inRange then return end

    vehicleShopZones[data.vehicleShopKey]["buyPoints"][data.buyPointIndex].inRange = true

    if Config.Debug then print("entered buy point index of", data.buyPointIndex, "of vehicle shop zone", data.vehicleShopKey) end

    configureZone("enter", data)
end

local function onVehicleShopBuyPointExit(data)
    if not vehicleShopZones[data.vehicleShopKey]["buyPoints"][data.buyPointIndex].inRange then return end

    vehicleShopZones[data.vehicleShopKey]["buyPoints"][data.buyPointIndex].inRange = false

    if Config.Debug then print("exited buy point index of", data.buyPointIndex, "of vehicle shop zone", data.vehicleShopKey) end

    configureZone("exit", data)
end

local function onVehicleShopBuyPointInside(data)
    local vehicleShopData = Config.VehicleShops[data.vehicleShopKey]
    local buyPoint = vehicleShopData.BuyPoints[data.buyPointIndex]

    if buyPoint.Marker then
        DrawMarker(
            buyPoint.Marker.Type or 1, --[[type]]
            buyPoint.Marker.Coords.x or buyPoint.Coords.x, --[[posX]]
            buyPoint.Marker.Coords.y or buyPoint.Coords.y, --[[posY]]
            buyPoint.Marker.Coords.z or buyPoint.Coords.z, --[[posZ]]
            0.0, --[[dirX]]
            0.0, --[[dirY]]
            0.0, --[[dirZ]]
            0.0, --[[rotX]]
            0.0, --[[rotY]]
            0.0, --[[rotZ]]
            buyPoint.Marker.Size.x or 1.5, --[[scaleX]]
            buyPoint.Marker.Size.y or 1.5, --[[scaleY]]
            buyPoint.Marker.Size.z or 1.5, --[[scaleZ]]
            buyPoint.Marker.Color.r or 255, --[[red]]
            buyPoint.Marker.Color.g or 255, --[[green]]
            buyPoint.Marker.Color.b or 255, --[[blue]]
            buyPoint.Marker.Color.a or 50, --[[alpha]]
            buyPoint.Marker.UpAndDown or false, --[[bobUpAndDown]]
            buyPoint.Marker.FaceCamera or true, --[[faceCamera]]
            2, --[[p19]]
            buyPoint.Marker.Rotate or false, --[[rotate]]
            buyPoint.Marker.TextureDict or nil, --[[textureDict]] ---@diagnostic disable-line: param-type-mismatch
            buyPoint.Marker.TextureName or nil, --[[textureName]] ---@diagnostic disable-line: param-type-mismatch
            false --[[drawOnEnts]]
        )
    end
end

local function setupVehicleShop(vehicleShopKey)
    local vehicleShopData = Config.VehicleShops[vehicleShopKey]

    if type(vehicleShopData?.BuyPoints) ~= "table" then return end

    vehicleShopZones[vehicleShopKey] = { buyPoints = {} }

    for i = 1, #vehicleShopData.BuyPoints do
        local buyPointData = vehicleShopData.BuyPoints[i]

        local point = lib.points.new({
            coords = buyPointData.Coords,
            distance = buyPointData.Distance,
            onEnter = onVehicleShopBuyPointEnter,
            onExit = onVehicleShopBuyPointExit,
            nearby = onVehicleShopBuyPointInside,
            vehicleShopKey = vehicleShopKey,
            buyPointIndex = i
        })

        vehicleShopZones[vehicleShopKey]["buyPoints"][i] = { point = point, inRange = false, pedEntity = nil }
    end
end

-- initializing
SetTimeout(1000, function()
    for key in pairs(Config.VehicleShops) do
        setupVehicleShop(key)
    end
end)
