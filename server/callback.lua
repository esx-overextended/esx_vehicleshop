local shared = lib.require("shared.shared") --[[@as shared]]
local records = lib.require("modules.records.server") --[[@as records]]
local utility = lib.require("modules.utility.server") --[[@as utility_server]]
local vehicleShop = lib.require("modules.vehicleShop.server") --[[@as vehicleShop]]

ESX.RegisterServerCallback("esx_vehicleshop:generateShopMenu", function(source, cb, data)
    if not data?.vehicleShopKey or (not data?.representativePedIndex and not data?.representativeVehicleIndex) or not data?.currentDistance then return cb() end

    local vehicleShopData = vehicleShop(data.vehicleShopKey) --[[@as vehicleShop]]

    if not vehicleShopData then
        return cb(utility.cheatDetected(source))
    end

    local representative = vehicleShopData:getRepresentative(data.representativeCategory, data.representativePedIndex or data.representativeVehicleIndex)

    if not representative then
        return cb(utility.cheatDetected(source))
    end

    if not representative:isPlayerNearby(source) then
        return cb(ESX.Trace(("Player(%s) distance to %s:%s was supposed to be below (%s) but it is (^1%s^7)!"):format(source, data.vehicleShopKey, data.representativePedIndex or data.representativeVehicleIndex, shared.DISTANCE_TO_REPRESENTATIVE,
            representative:getDistanceToPlayer(source)), "warning", Config.Debug))
    end

    return cb(vehicleShopData:generateShopMenu(data.representativeCategory, data.representativePedIndex or data.representativeVehicleIndex))
end)

ESX.RegisterServerCallback("esx_vehicleshop:purchaseVehicle", function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer or not data?.vehicleIndex or not data?.vehicleShopKey or not data?.vehicleCategory or not data?.purchaseAccount or not data?.vehicleProperties then return cb() end

    local vehicleShopData = vehicleShop(data.vehicleShopKey) --[[@as vehicleShop]]

    if not vehicleShopData then return cb(utility.cheatDetected(source)) end

    if not vehicleShopData:isPlayerNearShopPreview(source) then return cb(utility.cheatDetected(source)) end

    local vehiclesByCategory = records:getVehiclesByCategory(vehicleShopData.categories)
    local vehicleData        = vehiclesByCategory[data.vehicleCategory]?[data.vehicleIndex] --[[@as cVehicle?]]

    if not vehicleData or data.vehicleProperties.model ~= joaat(vehicleData.model) or xPlayer.getAccount(data.purchaseAccount)?.money < vehicleData.price then return cb(utility.cheatDetected(source)) end

    local spawnCoords = vehicleShopData.vehicleSpawnCoordsAfterPurchase or Config.DefaultVehicleSpawnCoordsAfterPurchase
    local xVehicle = ESX.CreateVehicle({
        model      = vehicleData.model,
        owner      = xPlayer.getIdentifier(),
        properties = data.vehicleProperties
    }, spawnCoords, spawnCoords.w)

    if not xVehicle then return cb(ESX.Trace(("There was an issue in creating vehicle (%s) for player(%s) while purchasing!"):format(vehicleData.model, xPlayer.source), "error", true)) end

    xPlayer.removeAccountMoney(data.purchaseAccount, vehicleData.price, locale("purchase_transaction_info", vehicleData.name, vehicleShopData.label, xVehicle.plate, ESX.Math.GroupDigits(vehicleData.price)))

    return cb(xVehicle.netId)
end)

ESX.RegisterServerCallback("esx_vehicleshop:generateSellMenu", function(source, cb, data)
    if not data?.sellPointIndex then return cb() end

    local playerPed     = GetPlayerPed(source)
    local playerVehicle = GetVehiclePedIsIn(playerPed, false)

    if not CanPlayerSellVehicle(source, playerVehicle, data.sellPointIndex, data.distance) then return cb() end

    local xVehicle             = ESX.GetVehicle(playerVehicle)
    local vehicleData          = ESX.GetVehicleData(xVehicle.model)
    local sellPointData        = Config.SellPoints[data.sellPointIndex]
    local originalVehiclePrice = records:getVehiclePrice(xVehicle.model)
    local resellPrice          = math.floor(originalVehiclePrice * (sellPointData.resellPercentage or 100) / 100)
    local contextOptions       = {
        {
            title = locale("selling_vehicle", ("%s %s"):format(vehicleData?.make, vehicleData?.name)),
            icon = "fa-solid fa-square-poll-horizontal",
            description = ("- %s\n- %s"):format(locale("vehicle_factory_price", originalVehiclePrice), locale("vehicle_sell_price", resellPrice))
        },
        {
            title = locale("sell_confirmation", resellPrice),
            icon = "fa-solid fa-circle-check",
            iconColor = "green",
            serverEvent = "esx_vehicleshop:sellVehicle",
            args = data,
            arrow = true
        }
    }

    return cb(contextOptions)
end)
