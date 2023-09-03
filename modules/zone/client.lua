local vehicleShopZones, vehicleSellPoints = {}, {}

local function createBlip(zoneKey)
    local isVehicleShop = type(zoneKey) == "string" and true or false
    local data          = isVehicleShop and Config.VehicleShops[zoneKey] or Config.SellPoints[zoneKey]

    if not data or not data.blip or not data.blip.active then return end

    local blipData   = data.blip
    local blipCoords = blipData.coords or data.marker?.coords
    local blipName   = ("%s_%s"):format(isVehicleShop and "vehicleshop" or "sellpoint", zoneKey)
    local blip       = AddBlipForCoord(blipCoords.x, blipCoords.y, blipCoords.z)

    SetBlipSprite(blip, blipData.type)
    SetBlipScale(blip, blipData.size)
    SetBlipColour(blip, blipData.color)
    SetBlipAsShortRange(blip, true)
    AddTextEntry(blipName, data.label or not isVehicleShop and locale("vehicle_sell")) ---@diagnostic disable-line: param-type-mismatch
    BeginTextCommandSetBlipName(blipName)
    EndTextCommandSetBlipName(blip)

    return blip
end

local function configureZone(action, data)
    TriggerServerEvent(("esx_vehicleshop:%sedRepresentativePoint"):format(action), data.vehicleShopKey, data.representativeCategory, data.representativePedIndex or data.representativeVehicleIndex)
end

local function onVehicleShopRepresentativeEnter(data)
    local representativeCategory = data?.representativeCategory:gsub("^%u", string.lower)
    local representativeIndex    = data.representativePedIndex or data.representativeVehicleIndex

    if vehicleShopZones[data.vehicleShopKey][representativeCategory][representativeIndex].inRange then return end

    vehicleShopZones[data.vehicleShopKey][representativeCategory][representativeIndex].inRange = true

    if Config.Debug then
        ESX.Trace("entered buy point index of" .. representativeIndex .. "of vehicle shop zone" .. data.vehicleShopKey, "trace", true)
    end

    configureZone("enter", data)
end

local function onVehicleShopRepresentativeExit(data)
    local representativeCategory = data?.representativeCategory:gsub("^%u", string.lower)
    local representativeIndex = data.representativePedIndex or data.representativeVehicleIndex

    if not vehicleShopZones[data.vehicleShopKey][representativeCategory][representativeIndex].inRange then return end

    vehicleShopZones[data.vehicleShopKey][representativeCategory][representativeIndex].inRange = false

    if Config.Debug then
        ESX.Trace("exited buy point index of" .. representativeIndex .. "of vehicle shop zone" .. data.vehicleShopKey, "trace", true)
    end

    configureZone("exit", data)
end

local function onVehicleShopRepresentativeInside(data)
    local vehicleShopData = Config.VehicleShops[data.vehicleShopKey]
    local representative  = vehicleShopData[data?.representativeCategory][data.representativePedIndex or data.representativeVehicleIndex]

    if not representative.marker.drawDistance or data.currentDistance <= representative.marker.drawDistance then
        DrawMarker(
            representative.marker.type or 1, --[[type]]
            representative.marker.coords.x or representative.coords.x, --[[posX]]
            representative.marker.coords.y or representative.coords.y, --[[posY]]
            representative.marker.coords.z or representative.coords.z, --[[posZ]]
            0.0, --[[dirX]]
            0.0, --[[dirY]]
            0.0, --[[dirZ]]
            0.0, --[[rotX]]
            0.0, --[[rotY]]
            0.0, --[[rotZ]]
            representative.marker.size.x or 1.5, --[[scaleX]]
            representative.marker.size.y or 1.5, --[[scaleY]]
            representative.marker.size.z or 1.5, --[[scaleZ]]
            representative.marker.color.r or 255, --[[red]]
            representative.marker.color.g or 255, --[[green]]
            representative.marker.color.b or 255, --[[blue]]
            representative.marker.color.a or 50, --[[alpha]]
            representative.marker.UpAndDown or false, --[[bobUpAndDown]]
            representative.marker.FaceCamera or true, --[[faceCamera]]
            2, --[[p19]]
            representative.marker.Rotate or false, --[[rotate]]
            representative.marker.TextureDict or nil, --[[textureDict]] ---@diagnostic disable-line: param-type-mismatch
            representative.marker.TextureName or nil, --[[textureName]] ---@diagnostic disable-line: param-type-mismatch
            false --[[drawOnEnts]]
        )
    end
end

local function setupVehicleShop(vehicleShopKey)
    local vehicleShopData = Config.VehicleShops[vehicleShopKey]
    local representativePeds, representativeVehicles

    if type(vehicleShopData.representativePeds) == "table" then
        representativePeds = {}

        for i = 1, #vehicleShopData.representativePeds do
            local representativePedData = vehicleShopData.representativePeds[i]
            local point                 = lib.points.new({
                coords                 = representativePedData.coords,
                distance               = representativePedData.distance,
                onEnter                = onVehicleShopRepresentativeEnter,
                onExit                 = onVehicleShopRepresentativeExit,
                nearby                 = representativePedData.marker and onVehicleShopRepresentativeInside,
                vehicleShopKey         = vehicleShopKey,
                representativeCategory = "representativePeds",
                representativePedIndex = i
            })

            representativePeds[i]       = { point = point, inRange = false, pedEntity = nil }
        end
    end

    if type(vehicleShopData.representativeVehicles) == "table" then
        representativeVehicles = {}

        for i = 1, #vehicleShopData.representativeVehicles do
            local representativeVehicleData = vehicleShopData.representativeVehicles[i]
            local point                     = lib.points.new({
                coords                     = representativeVehicleData.coords,
                distance                   = representativeVehicleData.distance,
                onEnter                    = onVehicleShopRepresentativeEnter,
                onExit                     = onVehicleShopRepresentativeExit,
                nearby                     = representativeVehicleData.marker and onVehicleShopRepresentativeInside,
                vehicleShopKey             = vehicleShopKey,
                representativeCategory     = "representativeVehicles",
                representativeVehicleIndex = i
            })

            representativeVehicles[i]       = { point = point, inRange = false, vehicleEntity = nil }
        end
    end

    vehicleShopZones[vehicleShopKey] = { blip = createBlip(vehicleShopKey), representativePeds = representativePeds, representativeVehicles = representativeVehicles }
end

local function onSellPointMarkerEnter(_)
    ESX.TextUI(locale("on_sale_point_marker_enter"))
end

local function onSellPointMarkerExit(_)
    ESX.HideUI()

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
    local markerData    = sellPointData?.marker
    local radius

    for _, value in pairs(markerData.size) do
        if not radius or value >= radius then
            radius = value
        end
    end

    local markerSphere = lib.zones.sphere({
        coords         = markerData.coords,
        radius         = radius,
        onEnter        = onSellPointMarkerEnter,
        onExit         = onSellPointMarkerExit,
        inside         = onSellPointMarkerInside,
        debug          = Config.Debug,
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
    local markerData    = sellPointData?.marker

    if not markerData.drawDistance or data.currentDistance <= markerData.drawDistance then
        DrawMarker(
            markerData.type or 1, --[[type]]
            markerData.coords.x, --[[posX]]
            markerData.coords.y, --[[posY]]
            markerData.coords.z, --[[posZ]]
            0.0, --[[dirX]]
            0.0, --[[dirY]]
            0.0, --[[dirZ]]
            0.0, --[[rotX]]
            0.0, --[[rotY]]
            0.0, --[[rotZ]]
            markerData.size.x or 1.5, --[[scaleX]]
            markerData.size.y or 1.5, --[[scaleY]]
            markerData.size.z or 1.5, --[[scaleZ]]
            markerData.color.r or 255, --[[red]]
            markerData.color.g or 255, --[[green]]
            markerData.color.b or 255, --[[blue]]
            markerData.color.a or 50, --[[alpha]]
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
    local markerData    = sellPointData?.marker

    if type(markerData) ~= "table" then return end

    local point = lib.points.new({
        coords         = markerData.coords,
        distance       = markerData.drawDistance,
        onEnter        = onSellPointEnter,
        onExit         = onSellPointExit,
        nearby         = onSellPointInside,
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

    Wait(5000)
    collectgarbage("collect")
end)
