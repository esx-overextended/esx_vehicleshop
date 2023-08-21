local zone, vehicleShopZones, vehicleSellPoints = {}, {}, {}

local function createBlip(vehicleShopKey)
    local vehicleShopData = Config.VehicleShops[vehicleShopKey]

    if not vehicleShopData or not vehicleShopData.Blip or not vehicleShopData.Blip.Active then return end

    local blipData = vehicleShopData.Blip
    local blipCoords = blipData.Coords
    local blipName = ("vehicleshop_%s"):format(vehicleShopKey)
    local blip = AddBlipForCoord(blipCoords.x, blipCoords.y, blipCoords.z)

    SetBlipSprite(blip, blipData.Type)
    SetBlipScale(blip, blipData.Size)
    SetBlipColour(blip, blipData.Color)
    SetBlipAsShortRange(blip, true)
    AddTextEntry(blipName, vehicleShopData.Label)
    BeginTextCommandSetBlipName(blipName)
    EndTextCommandSetBlipName(blip)

    return blip
end

function zone.configurePed(action, data)
    local vehicleShopData = Config.VehicleShops[data.vehicleShopKey]

    local pointData = vehicleShopZones[data.vehicleShopKey]["buyPoints"][data.buyPointIndex]
    local cachePed = pointData.pedEntity

    if cachePed then
        if DoesEntityExist(cachePed) then DeletePed(cachePed) end

        pointData.pedEntity = nil
    end

    if action == "enter" then
        local buyPointData = vehicleShopData.BuyPoints[data.buyPointIndex]
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

        pointData.pedEntity = pedEntity
        pointData.pedTargetId = Target.addPed(pedEntity, data)
    elseif action == "exit" then
        Target.removePed(pointData.pedEntity, pointData.pedTargetId)
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

    if not buyPoint.Marker.DrawDistance or data.currentDistance <= buyPoint.Marker.DrawDistance then
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

    vehicleShopZones[vehicleShopKey] = { blip = createBlip(vehicleShopKey), buyPoints = {} }

    for i = 1, #vehicleShopData.BuyPoints do
        local buyPointData = vehicleShopData.BuyPoints[i]
        local point = lib.points.new({
            coords = buyPointData.Coords,
            distance = buyPointData.Distance,
            onEnter = onVehicleShopBuyPointEnter,
            onExit = onVehicleShopBuyPointExit,
            nearby = buyPointData.Marker and onVehicleShopBuyPointInside,
            vehicleShopKey = vehicleShopKey,
            buyPointIndex = i
        })

        vehicleShopZones[vehicleShopKey]["buyPoints"][i] = { point = point, inRange = false, pedEntity = nil }
    end
end

local function onSellPointMarkerEnter(_)
    lib.showTextUI("[E] - Press to sell vehicle")
end

local function onSellPointMarkerExit(_)
    lib.hideTextUI()
end

local function onSellPointMarkerInside(data)
    if IsControlJustReleased(0, 38) then
        OpenSellMenu(data)
    end
end

local function onSellPointEnter(data)
    local sellPointData = Config.SellPoints[data.sellPointIndex]
    local markerData = sellPointData?.Marker
    local radius

    for _, value in pairs(markerData.Size) do
        if not radius or value >= radius then
            radius = value
        end
    end

    local markerSphere = lib.zones.sphere({
        coords = markerData.Coords,
        radius = radius,
        onEnter = onSellPointMarkerEnter,
        onExit = onSellPointMarkerExit,
        inside = onSellPointMarkerInside,
        debug = Config.Debug,
        sellPointIndex = data.sellPointIndex
    })

    vehicleSellPoints[data.sellPointIndex]["marker"] = markerSphere
end

local function onSellPointExit(data)
    local markerSphere = vehicleSellPoints[data.sellPointIndex]["marker"]
    vehicleSellPoints[data.sellPointIndex]["marker"] = nil

    markerSphere:remove()
end

local function onSellPointInside(data)
    local sellPointData = Config.SellPoints[data.sellPointIndex]
    local markerData = sellPointData?.Marker

    if not markerData.DrawDistance or data.currentDistance <= markerData.DrawDistance then
        DrawMarker(
            markerData.Type or 1, --[[type]]
            markerData.Coords.x, --[[posX]]
            markerData.Coords.y, --[[posY]]
            markerData.Coords.z, --[[posZ]]
            0.0, --[[dirX]]
            0.0, --[[dirY]]
            0.0, --[[dirZ]]
            0.0, --[[rotX]]
            0.0, --[[rotY]]
            0.0, --[[rotZ]]
            markerData.Size.x or 1.5, --[[scaleX]]
            markerData.Size.y or 1.5, --[[scaleY]]
            markerData.Size.z or 1.5, --[[scaleZ]]
            markerData.Color.r or 255, --[[red]]
            markerData.Color.g or 255, --[[green]]
            markerData.Color.b or 255, --[[blue]]
            markerData.Color.a or 50, --[[alpha]]
            markerData.UpAndDown or false, --[[bobUpAndDown]]
            markerData.FaceCamera or true, --[[faceCamera]]
            2, --[[p19]]
            markerData.Rotate or false, --[[rotate]]
            markerData.TextureDict or nil, --[[textureDict]] ---@diagnostic disable-line: param-type-mismatch
            markerData.TextureName or nil, --[[textureName]] ---@diagnostic disable-line: param-type-mismatch
            false --[[drawOnEnts]]
        )
    end
end

local function setupSellPoint(sellPointIndex)
    local sellPointData = Config.SellPoints[sellPointIndex]
    local markerData = sellPointData?.Marker

    if type(markerData) ~= "table" then return end

    local point = lib.points.new({
        coords = markerData.Coords,
        distance = markerData.DrawDistance,
        onEnter = onSellPointEnter,
        onExit = onSellPointExit,
        nearby = onSellPointInside,
        sellPointIndex = sellPointIndex
    })

    vehicleSellPoints[sellPointIndex] = { point = point, marker = nil }
end

-- initializing
SetTimeout(1000, function()
    for key in pairs(Config.VehicleShops) do
        setupVehicleShop(key)
    end

    for i = 1, #Config.SellPoints do
        setupSellPoint(i)
    end
end)
