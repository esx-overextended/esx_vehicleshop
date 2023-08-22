local zone, vehicleShopZones, vehicleSellPoints = {}, {}, {}

local function createBlip(zoneKey)
    local isVehicleShop = type(zoneKey) == "string" and true or false
    local data = isVehicleShop and Config.VehicleShops[zoneKey] or Config.SellPoints[zoneKey]

    if not data or not data.Blip or not data.Blip.Active then return end

    local blipData = data.Blip
    local blipCoords = blipData.Coords or data.Marker?.Coords
    local blipName = ("%s_%s"):format(isVehicleShop and "vehicleshop" or "sellpoint", zoneKey)
    local blip = AddBlipForCoord(blipCoords.x, blipCoords.y, blipCoords.z)

    SetBlipSprite(blip, blipData.Type)
    SetBlipScale(blip, blipData.Size)
    SetBlipColour(blip, blipData.Color)
    SetBlipAsShortRange(blip, true)
    AddTextEntry(blipName, data.Label or not isVehicleShop and "Vehicle Sell") ---@diagnostic disable-line: param-type-mismatch
    BeginTextCommandSetBlipName(blipName)
    EndTextCommandSetBlipName(blip)

    return blip
end

function zone.configurePed(action, data)
    local vehicleShopData = Config.VehicleShops[data.vehicleShopKey]

    local pointData = vehicleShopZones[data.vehicleShopKey]["representativePeds"][data.representativePedIndex]
    local cachePed = pointData.pedEntity

    if cachePed then
        if DoesEntityExist(cachePed) then DeletePed(cachePed) end

        pointData.pedEntity = nil
    end

    if action == "enter" then
        local representativePedData = vehicleShopData.RepresentativePeds[data.representativePedIndex]
        local pedModel = representativePedData.Model or Config.DefaultPed --[[@as number | string]]
        pedModel = type(pedModel) == "string" and joaat(pedModel) or pedModel --[[@as number]]

        lib.requestModel(pedModel, 1000)

        local pedEntity = CreatePed(0, pedModel, representativePedData.Coords.x, representativePedData.Coords.y, representativePedData.Coords.z, representativePedData.Coords.w, false, true)

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

local function onVehicleShopRepresentativePedEnter(data)
    if vehicleShopZones[data.vehicleShopKey]["representativePeds"][data.representativePedIndex].inRange then return end

    vehicleShopZones[data.vehicleShopKey]["representativePeds"][data.representativePedIndex].inRange = true

    if Config.Debug then print("entered buy point index of", data.representativePedIndex, "of vehicle shop zone", data.vehicleShopKey) end

    configureZone("enter", data)
end

local function onVehicleShopRepresentativePedExit(data)
    if not vehicleShopZones[data.vehicleShopKey]["representativePeds"][data.representativePedIndex].inRange then return end

    vehicleShopZones[data.vehicleShopKey]["representativePeds"][data.representativePedIndex].inRange = false

    if Config.Debug then print("exited buy point index of", data.representativePedIndex, "of vehicle shop zone", data.vehicleShopKey) end

    configureZone("exit", data)
end

local function onVehicleShopRepresentativePedInside(data)
    local vehicleShopData = Config.VehicleShops[data.vehicleShopKey]
    local representativePed = vehicleShopData.RepresentativePeds[data.representativePedIndex]

    if not representativePed.Marker.DrawDistance or data.currentDistance <= representativePed.Marker.DrawDistance then
        DrawMarker(
            representativePed.Marker.Type or 1, --[[type]]
            representativePed.Marker.Coords.x or representativePed.Coords.x, --[[posX]]
            representativePed.Marker.Coords.y or representativePed.Coords.y, --[[posY]]
            representativePed.Marker.Coords.z or representativePed.Coords.z, --[[posZ]]
            0.0, --[[dirX]]
            0.0, --[[dirY]]
            0.0, --[[dirZ]]
            0.0, --[[rotX]]
            0.0, --[[rotY]]
            0.0, --[[rotZ]]
            representativePed.Marker.Size.x or 1.5, --[[scaleX]]
            representativePed.Marker.Size.y or 1.5, --[[scaleY]]
            representativePed.Marker.Size.z or 1.5, --[[scaleZ]]
            representativePed.Marker.Color.r or 255, --[[red]]
            representativePed.Marker.Color.g or 255, --[[green]]
            representativePed.Marker.Color.b or 255, --[[blue]]
            representativePed.Marker.Color.a or 50, --[[alpha]]
            representativePed.Marker.UpAndDown or false, --[[bobUpAndDown]]
            representativePed.Marker.FaceCamera or true, --[[faceCamera]]
            2, --[[p19]]
            representativePed.Marker.Rotate or false, --[[rotate]]
            representativePed.Marker.TextureDict or nil, --[[textureDict]] ---@diagnostic disable-line: param-type-mismatch
            representativePed.Marker.TextureName or nil, --[[textureName]] ---@diagnostic disable-line: param-type-mismatch
            false --[[drawOnEnts]]
        )
    end
end

local function setupVehicleShop(vehicleShopKey)
    local vehicleShopData = Config.VehicleShops[vehicleShopKey]

    if type(vehicleShopData?.RepresentativePeds) ~= "table" then return end

    vehicleShopZones[vehicleShopKey] = { blip = createBlip(vehicleShopKey), representativePeds = {} }

    for i = 1, #vehicleShopData.RepresentativePeds do
        local representativePedData = vehicleShopData.RepresentativePeds[i]
        local point = lib.points.new({
            coords = representativePedData.Coords,
            distance = representativePedData.Distance,
            onEnter = onVehicleShopRepresentativePedEnter,
            onExit = onVehicleShopRepresentativePedExit,
            nearby = representativePedData.Marker and onVehicleShopRepresentativePedInside,
            vehicleShopKey = vehicleShopKey,
            representativePedIndex = i
        })

        vehicleShopZones[vehicleShopKey]["representativePeds"][i] = { point = point, inRange = false, pedEntity = nil }
    end
end

local function onSellPointMarkerEnter(_)
    lib.showTextUI("[E] - Press to sell vehicle")
end

local function onSellPointMarkerExit(_)
    lib.hideTextUI()

    local menuId = lib.getOpenContextMenu()

    if menuId and menuId:find(cache.resource) then
        lib.hideContext(true)
    end
end

local function onSellPointMarkerInside(data)
    if not IsControlJustReleased(0, 38) then return end

    OpenSellMenu(data)
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

    collectgarbage("collect")
end

local function onSellPointExit(data)
    local markerSphere = vehicleSellPoints[data.sellPointIndex]["marker"]
    vehicleSellPoints[data.sellPointIndex]["marker"] = nil

    markerSphere:remove()

    collectgarbage("collect")
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

    vehicleSellPoints[sellPointIndex] = { point = point, marker = nil, blip = createBlip(sellPointIndex) }
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
