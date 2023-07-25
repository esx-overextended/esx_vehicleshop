lib.callback.register("esx_vehicleshops:generateShopMenu", function(source, data)
    if not data?.vehicleShopKey or not data?.buyPointIndex or not data?.currentDistance then return end

    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    local vehicleShopData = Config.VehicleShops[data.vehicleShopKey]
    local buyPointCoords = vehicleShopData.BuyPoints?[data.buyPointIndex]?.Coords
    local distanceToBuyPoint = buyPointCoords and #(vector3(buyPointCoords.x, buyPointCoords.y, buyPointCoords.z) - playerCoords)

    if not distanceToBuyPoint or math.floor(distanceToBuyPoint) ~= math.floor(data.currentDistance) then
        return ESX.Trace(("Player distance to the %s:%s was supposed to be (^2%s^7), but it is (^1%s^7)!"):format(data.vehicleShopKey, data.buyPointIndex, data.currentDistance, distanceToBuyPoint), "error", true)
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

    return menuOptions
end)

lib.callback.register("esx_vehicleshops:purchaseVehicle", function(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer or not data?.vehicleIndex or not data?.vehicleShopKey or not data?.vehicleCategory or not data?.purchaseAccount or not data?.vehicleProperties then return end

    local vehicleShopData = Config.VehicleShops[data.vehicleShopKey]
    local playerCoords = xPlayer.getCoords()
    local shopPreviewCoords = vehicleShopData?.VehiclePreviewCoords or Config.DefaultVehiclePreviewCoords

    if #(vector3(playerCoords.x, playerCoords.y, playerCoords.z) - vector3(shopPreviewCoords.x, shopPreviewCoords.y, shopPreviewCoords.z)) > 3 then return CheatDetected(xPlayer.source) end

    local vehiclesByCategory = GetVehiclesByCategoryForShop(data.vehicleShopKey)
    local vehicleData = vehiclesByCategory[data.vehicleCategory]?[data.vehicleIndex]

    if not vehicleData or data.vehicleProperties.model ~= joaat(vehicleData.model) or xPlayer.getAccount(data.purchaseAccount)?.money < vehicleData.price then CheatDetected(xPlayer.source) end

    xPlayer.removeAccountMoney(data.purchaseAccount, vehicleData.price, ("Purchase of vehicle (%s) from %s"):format(vehicleData.name, vehicleShopData.Label))

    local spawnCoords = vehicleShopData.VehicleSpawnCoordsAfterPurchase or Config.DefaultVehicleSpawnCoordsAfterPurchase
    local xVehicle = ESX.CreateVehicle({
        model = vehicleData.model,
        owner = xPlayer.getIdentifier(),
        properties = data.vehicleProperties
    }, spawnCoords, spawnCoords.w)

    if not xVehicle then return ESX.Trace(("There was an issue in creating vehicle (%s) for player(%s) while purchasing!"):format(vehicleData.model, xPlayer.source), "error", true) end

    return xVehicle.netId
end)
