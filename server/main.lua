local vehicles, categories

function RefreshVehiclesAndCategories()
    vehicles = MySQL.query.await("SELECT * FROM vehicles")
    categories = MySQL.query.await("SELECT * FROM vehicle_categories")
    local generatedVehicles = ESX.GetVehicleData()
    local validVehicles, validVehiclesCount = {}, 0

    for i = 1, #vehicles do
        local vehicleData = vehicles[i]

        if not generatedVehicles[vehicleData?.model] then
            ESX.Trace(
                ("Vehicle (^5%s^7) with the model of (^1%s^7) is ^1NOT KNOWN^7 to the framework!\nEither it's an invalid model or has not been parsed/generated yet! Refer to the documentation(https://esx-overextended.github.io/es_extended/Commands/parseVehicles)\n")
                :format(vehicleData?.name, vehicleData?.model), "warning", true)
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

---@param vehicleShopKey string
---@return number
function GetRandomVehicleModelFromShop(vehicleShopKey)
    local vehicleModel
    local vehicleShopData = Config.VehicleShops[vehicleShopKey]

    while not vehicleModel do
        local found = false
        local randomVehicle = vehicles[math.random(0, #vehicles)]

        if type(vehicleShopData.Categories) == "table" and next(vehicleShopData.Categories) then
            for i = 1, #vehicleShopData.Categories do
                local category = vehicleShopData.Categories[i]

                if randomVehicle?.category == category then
                    found = true
                    break
                end
            end
        elseif randomVehicle then
            found = true
        end

        if found then
            vehicleModel = randomVehicle.model
            break
        end

        Wait(0)
    end

    return vehicleModel
end

---@param source number
---@param vehicle number
---@param sellPointIndex number
---@param distance number
---@return boolean
function CanPlayerSellVehicle(source, vehicle, sellPointIndex, distance)
    local playerPed = GetPlayerPed(source)

    if not vehicle or vehicle <= 0 or GetPedInVehicleSeat(vehicle, -1) ~= playerPed then
        ESX.ShowNotification(source, { locale("vehicle_sell"), locale("must_be_driver_to_sell") }, "warning")
        return false
    end

    local xVehicle = ESX.GetVehicle(vehicle)
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xVehicle then
        ESX.ShowNotification(source, { locale("vehicle_sell"), locale("cannot_sell_vehicle") }, "error")
        return false
    end

    if xPlayer.identifier ~= xVehicle.owner then
        ESX.ShowNotification(source, { locale("vehicle_sell"), locale("cannot_sell_vehicle_no_ownership") }, "error")
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

            ESX.ShowNotification(source, { locale("vehicle_sell"), ("%s\n\n%s"):format(locale("cannot_sell_vehicle_type"), locale("accepted_vehicle_categories_to_sell", table.concat(authorizedCategories, ", "))) }, "warning", 5000)

            return false
        end
    end

    local playerCoords = GetEntityCoords(playerPed)
    local sellPointCoords = sellPointData.Marker?.Coords
    local distanceToSellPoint = sellPointCoords and #(vector3(sellPointCoords.x, sellPointCoords.y, sellPointCoords.z) - playerCoords)

    if not distanceToSellPoint or math.floor(distanceToSellPoint) ~= math.floor(distance) then
        ESX.Trace(("Player(%s) distance to the sell:%s was supposed to be (^2%s^7), but it is (^1%s^7)!"):format(source, sellPointIndex, distance, distanceToSellPoint), "warning", Config.Debug)
        return false
    end

    local originalVehiclePrice = GetVehiclePriceByModel(xVehicle.model)

    if not originalVehiclePrice then
        ESX.ShowNotification(source, { locale("vehicle_sell"), locale("cannot_sell_vehicle_show_accepted") }, "error")
        return false
    end

    return true
end

---@param vehicleEntity number
---@param maxNoSeats number
---@return boolean (indicating whether the action was successfull or not)
function MakeVehicleEmpty(vehicleEntity, maxNoSeats)
    while DoesEntityExist(vehicleEntity) do
        local freeNoSeats = 0

        for i = -1, maxNoSeats - 2 do
            local pedAtSeat = GetPedInVehicleSeat(vehicleEntity, i)

            if DoesEntityExist(pedAtSeat) then
                TaskLeaveVehicle(pedAtSeat, vehicleEntity, 0)
            else
                freeNoSeats += 1
            end
        end

        if freeNoSeats == maxNoSeats then
            Wait(500)
            return true
        end

        Wait(0)
    end

    return false
end

function DoesVehicleExistInShop(vehicleModel, shopkey)
    local vehicleShopData = Config.VehicleShops[shopkey]
    local shopCategories = vehicleShopData?.Categories

    if not shopCategories then
        return vehicleShopData and true or false
    end

    for i = 1, #vehicles do
        local vehicle = vehicles[i]

        if vehicle.model == vehicleModel then
            for j = 1, #shopCategories do
                if vehicle.category == shopCategories[j] then
                    return true
                end
            end
        end
    end

    return false
end

---@param source string | number
function CheatDetected(source)
    print(("[^1CHEATING^7] Player (^5%s^7) with the identifier of (^5%s^7) is detected ^1cheating^7!"):format(source, GetPlayerIdentifierByType(source --[[@as string]], "license")))
end

MySQL.ready(function()
    RefreshVehiclesAndCategories()
end)
