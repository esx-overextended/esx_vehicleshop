local zone, vehicleShopZones = {}, {}

function zone.configurePed(action, data)
    local vehicleShopData = Config.VehicleShops[data.vehicleShopKey]

    if type(vehicleShopData?.BuyPoints) ~= "table" then return end

    local cachePed = vehicleShopZones[data.vehicleShopKey]["buyPoints"][data.buyPointIndex].pedEntity

    if cachePed then
        if DoesEntityExist(cachePed) then DeletePed(cachePed) end

        vehicleShopZones[data.vehicleShopKey]["buyPoints"][data.buyPointIndex].pedEntity = nil
    end

    if action == "enter" then
        for i = 1, #vehicleShopData.BuyPoints do
            local buyPointData = vehicleShopData.BuyPoints[i]

            if buyPointData.Model == false then goto skipLoop end

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

            ::skipLoop::
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
