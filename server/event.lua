RegisterServerEvent("esx_vehicleshop:sellVehicle", function(data)
    local source = source

    if not data?.sellPointIndex then return end

    local playerPed = GetPlayerPed(source)
    local playerVehicle = GetVehiclePedIsIn(playerPed, false)

    if not CanPlayerSellVehicle(source, playerVehicle, data.sellPointIndex, data.distance) then return end

    local xVehicle = ESX.GetVehicle(playerVehicle)
    local xPlayer = ESX.GetPlayerFromId(source)
    local vehicleData = ESX.GetVehicleData(xVehicle.model)
    local sellPointData = Config.SellPoints[data.sellPointIndex]
    local originalVehiclePrice = GetVehiclePriceByModel(xVehicle.model)
    local resellPrice = math.floor(originalVehiclePrice * (sellPointData.ResellPercentage or 100) / 100)

    if not MakeVehicleEmpty(xVehicle.entity, vehicleData.seats) then return lib.notify(source, { title = "ESX Vehicle Sell", description = "An error happenned during the sell process!", type = "error" }) end

    local message = ("Sold %s (Plate: %s) for $%s"):format(("%s %s"):format(vehicleData?.make, vehicleData?.name), xVehicle.plate, resellPrice)

    xVehicle.delete(true)
    xPlayer.addAccountMoney("bank", resellPrice, message)

    lib.notify(source, { title = "ESX Vehicle Sell", description = message, type = "success" })
end)

local playersNearPoints = {}

local enteredRepresentativePoint = function(_source, shopKey, representativeCategory, representativeIndex)
    local vehicleShopData = Config.VehicleShops[shopKey]

    if not vehicleShopData then return ESX.Trace(("Player(%s) tried to enter Shop[%s] which doesn't exist!"):format(_source, shopKey), "error", true) end
    if not vehicleShopData[representativeCategory] then return ESX.Trace(("Player(%s) tried to enter Shop[%s][%s] which doesn't exist!"):format(_source, shopKey, representativeCategory), "error", true) end
    if not vehicleShopData[representativeCategory][representativeIndex] then
        return ESX.Trace(("Player(%s) tried to enter Shop[%s][%s][%s] which doesn't exist!"):format(_source, shopKey, representativeCategory, representativeIndex), "error", true)
    end

    -- building table structure
    playersNearPoints[shopKey] = playersNearPoints[shopKey] or {}
    playersNearPoints[shopKey][representativeCategory] = playersNearPoints[shopKey][representativeCategory] or {}
    playersNearPoints[shopKey][representativeCategory]["Entities"] = playersNearPoints[shopKey][representativeCategory]["Entities"] or {}
    playersNearPoints[shopKey][representativeCategory][representativeIndex] = playersNearPoints[shopKey][representativeCategory][representativeIndex] or setmetatable({}, {
        __call = function(self)
            local count = 0

            for _ in pairs(self) do
                count += 1
            end

            return count
        end
    })

    local _playersNearPoints = playersNearPoints[shopKey][representativeCategory][representativeIndex]

    if _playersNearPoints[_source] then
        return --[[ESX.Trace(("Player(%s) has already entered Shop[%s][%s][%s]"):format(_source, shopKey, representativeCategory, representativeIndex), "error", true)]]
    end

    local playerPed = GetPlayerPed(_source)
    local playerCoords = GetEntityCoords(playerPed)
    local representative = vehicleShopData[representativeCategory][representativeIndex]
    local representativeCoords = representative.Coords
    local playerDistToRepresentative = #(playerCoords - vector3(representativeCoords.x, representativeCoords.y, representativeCoords.z))

    if playerDistToRepresentative > representative.Distance + 5.0 then -- not superly strict comparison
        return --[[ESX.Trace(("Player(%s) distance to Shop[%s][%s][%s] should be below %s while it is %s"):format(_source, shopKey, representativeCategory, representativeIndex, representative.Distance, playerDistToRepresentative), "warning", true)]]
    end

    local shouldHandleRepresentatives = _playersNearPoints() == 0

    _playersNearPoints[tonumber(_source)] = true

    ESX.Trace(("Player(%s) entered Shop[%s][%s][%s]."):format(_source, shopKey, representativeCategory, representativeIndex), "info", Config.Debug)

    if not shouldHandleRepresentatives then return end

    local entity

    if representativeCategory == "RepresentativePeds" then
        local pedModel = representative.Model or Config.DefaultPed --[[@as number | string]]
        pedModel = type(pedModel) == "string" and joaat(pedModel) or pedModel --[[@as number]]
        entity = CreatePed(0, pedModel, representative.Coords.x, representative.Coords.y, representative.Coords.z, representative.Coords.w, false, true)

        if not entity then return end

        Entity(entity).state:set("esx_vehicleshop:handlePedRepresentative", { coords = representative.Coords, vehicleShopKey = shopKey, representativeCategory = representativeCategory, representativeIndex = representativeIndex }, true)
    elseif representativeCategory == "RepresentativeVehicles" then
        local vehicleModel = GetRandomVehicleModelFromShop(shopKey)
        entity = ESX.OneSync.SpawnVehicle(vehicleModel, vector3(representative.Coords.x, representative.Coords.y, representative.Coords.z), representative.Coords.w)

        if not entity then return end

        FreezeEntityPosition(entity, true)

        Entity(entity).state:set("esx_vehicleshop:handleVehicleRepresentative", { coords = representative.Coords, vehicleShopKey = shopKey, representativeCategory = representativeCategory, representativeIndex = representativeIndex }, true)
    end

    playersNearPoints[shopKey][representativeCategory]["Entities"][representativeIndex] = entity
end

local exitedRepresentativePoint = function(_source, shopKey, representativeCategory, representativeIndex)
    if not playersNearPoints[shopKey] then return ESX.Trace(("Player(%s) tried to exit Shop[%s] which doesn't exist!"):format(_source, shopKey), "error", true) end
    if not playersNearPoints[shopKey][representativeCategory] then return ESX.Trace(("Player(%s) tried to exit Shop[%s][%s] which doesn't exist!"):format(_source, shopKey, representativeCategory), "error", true) end
    if not playersNearPoints[shopKey][representativeCategory][representativeIndex] then
        return ESX.Trace(("Player(%s) tried to exit Shop[%s][%s][%s] which doesn't exist!"):format(_source, shopKey, representativeCategory, representativeIndex), "error", true)
    end

    local _playersNearPoints = playersNearPoints[shopKey]?[representativeCategory]?[representativeIndex]

    if not _playersNearPoints[_source] then
        return --[[ESX.Trace(("Player(%s) has not already entered Shop[%s][%s][%s]"):format(_source, shopKey, representativeCategory, representativeIndex), "error", true)]]
    end

    local playerPed = GetPlayerPed(_source)
    local playerCoords = GetEntityCoords(playerPed)
    local vehicleShopData = Config.VehicleShops[shopKey]
    local representative = vehicleShopData[representativeCategory][representativeIndex]
    local representativeCoords = representative.Coords
    local playerDistToRepresentative = #(playerCoords - vector3(representativeCoords.x, representativeCoords.y, representativeCoords.z))

    if playerDistToRepresentative < representative.Distance - 5.0 then -- not superly strict comparison
        return --[[ESX.Trace(("Player(%s) distance to Shop[%s][%s][%s] should be above %s while it is %s"):format(_source, shopKey, representativeCategory, representativeIndex, representative.Distance, playerDistToRepresentative), "warning", true)]]
    end

    _playersNearPoints[_source] = nil

    ESX.Trace(("Player(%s) exited Shop[%s][%s][%s]."):format(_source, shopKey, representativeCategory, representativeIndex), "info", Config.Debug)

    local shouldHandleRepresentatives = _playersNearPoints() == 0

    if not shouldHandleRepresentatives then return end

    local entity = playersNearPoints[shopKey][representativeCategory]["Entities"][representativeIndex]
    playersNearPoints[shopKey][representativeCategory]["Entities"][representativeIndex] = nil

    if DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end

local queues = {}
local queueRunning = false

local ensureQueue = function(func, ...)
    table.insert(queues, { func = func, args = { ... } })

    if queueRunning then return end

    queueRunning = true

    while #queues > 0 do
        queues[1].func(table.unpack(queues[1].args))
        table.remove(queues, 1)
    end

    queueRunning = false
end

RegisterServerEvent("esx_vehicleshop:enteredRepresentativePoint", function(...)
    local _source = source

    ensureQueue(enteredRepresentativePoint, _source, ...)
end)
RegisterServerEvent("esx_vehicleshop:exitedRepresentativePoint", function(...)
    local _source = source

    ensureQueue(exitedRepresentativePoint, _source, ...)
end)

AddEventHandler("playerDropped", function(playerId)
    playerId = tonumber(playerId) --[[@as number]]

    for shopKey, data in pairs(playersNearPoints) do
        for representativeCategory, categoryData in pairs(data) do
            for representativeIndex, sources in pairs(categoryData) do
                if type(representativeIndex) == "number" then -- check for not "ENTITIES" index
                    for src in pairs(sources) do
                        if src == playerId then
                            playersNearPoints[shopKey][representativeCategory][representativeIndex][playerId] = nil

                            ESX.Trace(("Removed Player(%s) data from playersNearPoints[%s][%s][%s][%s]"):format(playerId, shopKey, representativeCategory, representativeIndex, playerId), "trace", Config.Debug)

                            if playersNearPoints[shopKey][representativeCategory][representativeIndex]() == 0 then
                                local entity = playersNearPoints[shopKey][representativeCategory]["Entities"][representativeIndex]
                                playersNearPoints[shopKey][representativeCategory]["Entities"][representativeIndex] = nil

                                if DoesEntityExist(entity) then
                                    DeleteEntity(entity)
                                    ESX.Trace(("Removed Entity(%s) data from playersNearPoints[%s][%s][\"Entities\"][%s]"):format(entity, shopKey, representativeCategory, representativeIndex), "trace", Config.Debug)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

local function onResourceStop(resource)
    if resource ~= cache.resource then return end

    for _, data in pairs(playersNearPoints) do
        for _, data2 in pairs(data) do
            for _, entity in pairs(data2["Entities"]) do
                if DoesEntityExist(entity) then
                    DeleteEntity(entity)
                end
            end
        end
    end
end

AddEventHandler("onResourceStop", onResourceStop)
AddEventHandler("onServerResourceStop", onResourceStop)
