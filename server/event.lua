lib.callback.register("esx_vehicleshops:generateShopMenuBuyingOptions", function(source, data)
    if not data?.vehicleShopKey or not data?.buyPointIndex or not data?.currentDistance then return end

    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    local vehicleShopData = Config.VehicleShops[data.vehicleShopKey]
    local buyPointCoords = vehicleShopData.BuyPoints?[data.buyPointIndex]?.Coords
    local distanceToBuyPoint = buyPointCoords and #(vector3(buyPointCoords.x, buyPointCoords.y, buyPointCoords.z) - playerCoords)

    if not distanceToBuyPoint or math.floor(distanceToBuyPoint) ~= math.floor(data.currentDistance) then
        return ESX.Trace(("Player distance to the %s:%s was supposed to be (^2%s^7), but it is (^1%s^7)!"):format(data.vehicleShopKey, data.buyPointIndex, data.currentDistance, distanceToBuyPoint), "error", true)
    end

    local vehiclesByCategory, menuOptions, menuOptionsCount = {}, {}, 0
    local allVehicles, allCategories = GetVehiclesAndCategories()

    if type(vehicleShopData.Categories) == "table" and next(vehicleShopData.Categories) then
        for i = 1, #vehicleShopData.Categories do
            for j = 1, #allCategories, 1 do
                if vehicleShopData.Categories[i] == allCategories[j].name then
                    vehiclesByCategory[allCategories[j].name] = {}
                    break
                end
            end
        end
    else
        for i = 1, #allCategories do
            vehiclesByCategory[allCategories[i].name] = {}
        end
    end

    for i = 1, #allVehicles do
        local vehicleCategory = allVehicles[i].category

        if vehiclesByCategory[vehicleCategory] then
            vehiclesByCategory[vehicleCategory][#vehiclesByCategory[vehicleCategory] + 1] = allVehicles[i]
        end
    end

    for _, v in pairs(vehiclesByCategory) do
        table.sort(v, function(a, b)
            return a.name < b.name
        end)
    end

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
