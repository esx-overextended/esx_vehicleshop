ESX.RegisterServerCallback("esx_vehicleshops:generateShopMenu", function(source, cb, data)
    if not data?.vehicleShopKey or not data?.buyPointIndex or not data?.currentDistance then return cb() end

    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    local vehicleShopData = Config.VehicleShops[data.vehicleShopKey]
    local buyPointCoords = vehicleShopData.BuyPoints?[data.buyPointIndex]?.Coords
    local distanceToBuyPoint = buyPointCoords and #(vector3(buyPointCoords.x, buyPointCoords.y, buyPointCoords.z) - playerCoords)

    if not distanceToBuyPoint or math.floor(distanceToBuyPoint) ~= math.floor(data.currentDistance) then
        ESX.Trace(("Player distance to the %s:%s was supposed to be (^2%s^7), but it is (^1%s^7)!"):format(data.vehicleShopKey, data.buyPointIndex, data.currentDistance, distanceToBuyPoint), "error", true)
        return cb()
    end

    local menuOptions, menuOptionsCount = {}, 0
    local _, allCategories = GetVehiclesAndCategories()
    local vehiclesByCategory = GetVehiclesByCategoryForShop(data.vehicleShopKey)

    for i = 1, #allCategories do
        local category = allCategories[i]

        if vehiclesByCategory[category.name] then
            local categoryVehicles = vehiclesByCategory[category.name]
            local options, optionsCount = {}, 0

            for j = 1, #categoryVehicles do
                local vehicle = categoryVehicles[j]

                optionsCount += 1
                options[optionsCount] = {
                    label = vehicle.name,
                    value = vehicle.model,
                    price = vehicle.price,
                    category = category.name,
                    description = ("Price: $%s"):format(ESX.Math.GroupDigits(vehicle.price))
                }
            end

            menuOptionsCount += 1
            menuOptions[menuOptionsCount] = {
                label = category.name,
                values = options
            }
        end
    end

    return cb(menuOptions)
end)

ESX.RegisterServerCallback("esx_vehicleshops:purchaseVehicle", function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer or not data?.vehicleIndex or not data?.vehicleShopKey or not data?.vehicleCategory or not data?.purchaseAccount or not data?.vehicleProperties then return cb() end

    local vehicleShopData = Config.VehicleShops[data.vehicleShopKey]
    local playerCoords = xPlayer.getCoords()
    local shopPreviewCoords = vehicleShopData?.VehiclePreviewCoords or Config.DefaultVehiclePreviewCoords

    if #(vector3(playerCoords.x, playerCoords.y, playerCoords.z) - vector3(shopPreviewCoords.x, shopPreviewCoords.y, shopPreviewCoords.z)) > 3 then
        CheatDetected(xPlayer.source)
        return cb()
    end

    local vehiclesByCategory = GetVehiclesByCategoryForShop(data.vehicleShopKey)
    local vehicleData = vehiclesByCategory[data.vehicleCategory]?[data.vehicleIndex]

    if not vehicleData or data.vehicleProperties.model ~= joaat(vehicleData.model) or xPlayer.getAccount(data.purchaseAccount)?.money < vehicleData.price then
        CheatDetected(xPlayer.source)
        return cb()
    end

    xPlayer.removeAccountMoney(data.purchaseAccount, vehicleData.price, ("Purchase of vehicle (%s) from %s"):format(vehicleData.name, vehicleShopData.Label))

    local spawnCoords = vehicleShopData.VehicleSpawnCoordsAfterPurchase or Config.DefaultVehicleSpawnCoordsAfterPurchase
    local xVehicle = ESX.CreateVehicle({
        model = vehicleData.model,
        owner = xPlayer.getIdentifier(),
        properties = data.vehicleProperties
    }, spawnCoords, spawnCoords.w)

    if not xVehicle then
        ESX.Trace(("There was an issue in creating vehicle (%s) for player(%s) while purchasing!"):format(vehicleData.model, xPlayer.source), "error", true)
        return cb()
    end

    return cb(xVehicle.netId)
end)

ESX.RegisterServerCallback("esx_vehicleshops:generateSellMenu", function(source, cb, data)
    if not data?.sellPointIndex then return cb() end

    local playerPed = GetPlayerPed(source)
    local playerVehicle = GetVehiclePedIsIn(playerPed, false)

    if not CanPlayerSellVehicle(source, playerVehicle, data.sellPointIndex, data.distance) then return cb() end

    local xVehicle = ESX.GetVehicle(playerVehicle)
    local vehicleData = ESX.GetVehicleData(xVehicle.model)
    local sellPointData = Config.SellPoints[data.sellPointIndex]
    local originalVehiclePrice = GetVehiclePriceByModel(xVehicle.model)
    local resellPrice = math.floor(originalVehiclePrice * (sellPointData.ResellPercentage or 100) / 100)
    local contextOptions = {
        {
            title = ("Selling %s"):format(("%s %s"):format(vehicleData?.make, vehicleData?.name)),
            icon = "fa-solid fa-square-poll-horizontal",
            description = ("- Factory Price: $%s\n- Sell Price: $%s"):format(originalVehiclePrice, resellPrice)
        },
        {
            title = ("Confirm to Sell & Receive $%s"):format(resellPrice),
            icon = "fa-solid fa-circle-check",
            iconColor = "green",
            serverEvent = "esx_vehicleshops:sellVehicle",
            args = data,
        }
    }

    return cb(contextOptions)
end)

RegisterServerEvent("esx_vehicleshops:sellVehicle", function(data)
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

    local message = ("Sold %s (Plate: %s) for $%s"):format(("%s %s"):format(vehicleData?.make, vehicleData?.name), xVehicle.plate, resellPrice)

    xVehicle.delete(true)
    xPlayer.addAccountMoney("bank", resellPrice, message)

    lib.notify(source, { title = "ESX Vehicle Sell", description = message, type = "success" })
end)
