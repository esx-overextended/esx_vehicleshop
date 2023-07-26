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

---@param source string | number
function CheatDetected(source)
    print(("[^1CHEATING^7] Player (^5%s^7) with the identifier of (^5%s^7) is detected ^1cheating^7!"):format(source, GetPlayerIdentifierByType(source --[[@as string]], "license")))
end

MySQL.ready(function()
    RefreshVehiclesAndCategories()
end)
