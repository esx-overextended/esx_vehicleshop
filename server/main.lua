local records = lib.require("modules.records.server") --[[@as records]]

MySQL.ready(function()
    records:refresh()
end)

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
    local xPlayer  = ESX.GetPlayerFromId(source)

    if not xVehicle then
        ESX.ShowNotification(source, { locale("vehicle_sell"), locale("cannot_sell_vehicle") }, "error")
        return false
    end

    if xPlayer.identifier ~= xVehicle.owner then
        ESX.ShowNotification(source, { locale("vehicle_sell"), locale("cannot_sell_vehicle_no_ownership") }, "error")
        return false
    end

    local sellPointData   = Config.SellPoints[sellPointIndex]
    local vehicleCategory = records:getVehicleCategory(xVehicle.model)

    if sellPointData.categories then
        local isCategoryValid = false

        for i = 1, #sellPointData.categories do
            if sellPointData.categories[i] == vehicleCategory then
                isCategoryValid = true
                break
            end
        end

        if not isCategoryValid then
            local authorizedCategories, authorizedCategoriesCount = {}, 0

            for i = 1, #sellPointData.categories do
                local categoryLabel = records:getCategoryLabel(sellPointData.categories[i])

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
    local sellPointCoords = sellPointData.marker?.coords
    local distanceToSellPoint = sellPointCoords and #(vector3(sellPointCoords.x, sellPointCoords.y, sellPointCoords.z) - playerCoords)

    if not distanceToSellPoint or math.floor(distanceToSellPoint) ~= math.floor(distance) then
        ESX.Trace(("Player(%s) distance to the sell:%s was supposed to be (^2%s^7), but it is (^1%s^7)!"):format(source, sellPointIndex, distance, distanceToSellPoint), "warning", Config.Debug)
        return false
    end

    local originalVehiclePrice = records:getVehiclePrice(xVehicle.model)

    if not originalVehiclePrice then
        ESX.ShowNotification(source, { locale("vehicle_sell"), locale("cannot_sell_vehicle_show_accepted") }, "error")
        return false
    end

    return true
end
