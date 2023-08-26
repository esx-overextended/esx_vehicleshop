ESX.RegisterServerCallback("esx_vehicleshop:generateShopMenu", function(source, cb, data)
    if not data?.vehicleShopKey or (not data?.representativePedIndex and not data?.representativeVehicleIndex) or not data?.currentDistance then return cb() end

    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    local vehicleShopData = Config.VehicleShops[data.vehicleShopKey]
    local representativeCoords = vehicleShopData[data.representativeCategory]?[data.representativePedIndex or data.representativeVehicleIndex]?.Coords
    local distanceToRepresentative = representativeCoords and #(vector3(representativeCoords.x, representativeCoords.y, representativeCoords.z) - playerCoords)

    if not distanceToRepresentative or math.floor(distanceToRepresentative) ~= math.floor(data.currentDistance) then
        ESX.Trace(("Player distance to the %s:%s was supposed to be (^2%s^7), but it is (^1%s^7)!"):format(data.vehicleShopKey, data.representativePedIndex or data.representativeVehicleIndex, data.currentDistance, distanceToRepresentative), "error",
            true)
        return cb()
    end

    local menuOptions, menuOptionsCount = {}, 0
    local allVehicleData = ESX.GetVehicleData()
    local _, allCategories = GetVehiclesAndCategories()
    local vehiclesByCategory = GetVehiclesByCategoryForShop(data.vehicleShopKey)

    for i = 1, #allCategories do
        local category = allCategories[i]

        if vehiclesByCategory[category.name] then
            local categoryVehicles = vehiclesByCategory[category.name]
            local options, optionsCount = {}, 0

            for j = 1, #categoryVehicles do
                local vehicle = categoryVehicles[j]

                if data.representativeCategory == "RepresentativePeds" then
                    optionsCount += 1
                    options[optionsCount] = {
                        label = vehicle.name,
                        value = vehicle.model,
                        price = vehicle.price,
                        category = category.name,
                        description = ("Price: $%s"):format(ESX.Math.GroupDigits(vehicle.price))
                    }
                elseif data.representativeCategory == "RepresentativeVehicles" then
                    local _data = json.decode(json.encode(data))

                    _data.vehicleModel = vehicle.model

                    optionsCount += 1
                    options[optionsCount] = {
                        title = vehicle.name,
                        model = vehicle.model,
                        price = vehicle.price,
                        category = category.name,
                        categoryLabel = category.label,
                        description = ("Price: $%s"):format(ESX.Math.GroupDigits(vehicle.price)),
                        image = allVehicleData[vehicle.model]?.image,
                        serverEvent = "esx_vehicleshop:changeVehicleRepresentative",
                        args = _data
                    }
                end
            end

            if data.representativeCategory == "RepresentativePeds" then
                menuOptionsCount += 1
                menuOptions[menuOptionsCount] = {
                    label = category.name,
                    values = options
                }
            elseif data.representativeCategory == "RepresentativeVehicles" then
                menuOptionsCount += 1
                menuOptions[menuOptionsCount] = {
                    title = category.label,
                    args = { subMenuOptions = options },
                    menu = ("esx_vehicleshop:shopMenu_%s"):format(category.name),
                    arrow = true
                }
            end
        end
    end

    return cb(menuOptions)
end)

ESX.RegisterServerCallback("esx_vehicleshop:purchaseVehicle", function(source, cb, data)
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

ESX.RegisterServerCallback("esx_vehicleshop:generateSellMenu", function(source, cb, data)
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
            serverEvent = "esx_vehicleshop:sellVehicle",
            args = data,
            arrow = true
        }
    }

    return cb(contextOptions)
end)
