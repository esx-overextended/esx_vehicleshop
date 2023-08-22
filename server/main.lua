local vehicles, categories

function RefreshVehiclesAndCategories()
    vehicles = MySQL.query.await("SELECT * FROM vehicles")
    categories = MySQL.query.await("SELECT * FROM vehicle_categories")
    local generatedVehicles = ESX.GetVehicleData()
    local validVehicles, validVehiclesCount = {}, 0

    for i = 1, #vehicles do
        local vehicleData = vehicles[i]

        if not generatedVehicles[vehicleData?.model] then
            ESX.Trace(("Vehicle (^5%s^7) with the model of (^1%s^7) is ^1NOT KNOWN^7 to the framework!\nEither it's an invalid model or has not been parsed/generated yet!\n"):format(vehicleData?.name, vehicleData?.model), "warning", true)
        else
            validVehiclesCount += 1
            validVehicles[validVehiclesCount] = vehicleData
        end
    end

    vehicles = validVehicles
end

function GetVehiclesAndCategories()
    return vehicles, categories
end

---@param categoryName string
---@return string?
function GetCategoryLabel(categoryName)
    for i = 1, #categories do
        local category = categories[i]

        if category.name == categoryName then
            return category.label
        end
    end
end

---@param vehicleShopKey string
---@return table
function GetVehiclesByCategoryForShop(vehicleShopKey)
    local vehiclesByCategory = {}
    local vehicleShopData = Config.VehicleShops[vehicleShopKey]

    if vehicleShopData then
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
    end

    return vehiclesByCategory
end

---@param model string
---@return number?
function GetVehiclePriceByModel(model)
    for i = 1, #vehicles do
        local vehicle = vehicles[i]

        if vehicle.model == model then
            return vehicle.price
        end
    end
end

---@param model string
---@return table?
function GetVehicleCategoryByModel(model)
    for i = 1, #vehicles do
        local vehicle = vehicles[i]

        if vehicle.model == model then
            for j = 1, #categories do
                local category = categories[j]

                if category.name == vehicle.category then
                    return { name = category.name, category.label }
                end
            end
        end
    end
end

---@param source number
---@param vehicle number
---@param sellPointIndex number
---@param distance number
---@return boolean
function CanPlayerSellVehicle(source, vehicle, sellPointIndex, distance)
    local playerPed = GetPlayerPed(source)

    if not vehicle or vehicle <= 0 or GetPedInVehicleSeat(vehicle, -1) ~= playerPed then
        lib.notify(source, { title = "ESX Vehicle Sell", description = "You must be in the driver seat of a vehicle to be able to sell it!", type = "warning" })
        return false
    end

    local xVehicle = ESX.GetVehicle(vehicle)
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xVehicle or xPlayer?.identifier ~= xVehicle.owner then
        lib.notify(source, { title = "ESX Vehicle Sell", description = "You cannot sell this vehicle!", type = "error" })
        return false
    end

    local sellPointData = Config.SellPoints[sellPointIndex]
    local vehicleCategory = GetVehicleCategoryByModel(xVehicle.model)

    if sellPointData.Categories then
        local isCategoryValid = false

        for i = 1, #sellPointData.Categories do
            if sellPointData.Categories[i] == vehicleCategory?.name then
                isCategoryValid = true
                break
            end
        end

        if not isCategoryValid then
            local authorizedCategories, authorizedCategoriesCount = {}, 0

            for i = 1, #sellPointData.Categories do
                local categoryLabel = GetCategoryLabel(sellPointData.Categories[i])

                if categoryLabel then
                    authorizedCategoriesCount += 1
                    authorizedCategories[authorizedCategoriesCount] = categoryLabel
                end
            end

            lib.notify(source, {
                title = "ESX Vehicle Sell",
                description = ("This vehicle cannot be sold here!\nAccepted categories are: %s"):format(table.concat(authorizedCategories, ", ")),
                type = "warning",
                duration = 5000
            })

            return false
        end
    end

    local playerCoords = GetEntityCoords(playerPed)
    local sellPointCoords = sellPointData.Marker?.Coords
    local distanceToSellPoint = sellPointCoords and #(vector3(sellPointCoords.x, sellPointCoords.y, sellPointCoords.z) - playerCoords)

    if not distanceToSellPoint or math.floor(distanceToSellPoint) ~= math.floor(distance) then
        ESX.Trace(("Player(%s) distance to the sell:%s was supposed to be (^2%s^7), but it is (^1%s^7)!"):format(source, sellPointIndex, distance, distanceToSellPoint), "warning", true)
        return false
    end

    local originalVehiclePrice = GetVehiclePriceByModel(xVehicle.model)

    if not originalVehiclePrice then
        lib.notify(source, { title = "ESX Vehicle Sell", description = "This vehicle's factory price is unknown!", type = "error" })
        return false
    end

    return true
end

---@param source string | number
function CheatDetected(source)
    print(("[^1CHEATING^7] Player (^5%s^7) with the identifier of (^5%s^7) is detected ^1cheating^7!"):format(source, GetPlayerIdentifierByType(source --[[@as string]], "license")))
end

MySQL.ready(function()
    RefreshVehiclesAndCategories()
end)
