if not Config.Debug then return end

local function refreshVehiclesName()
    RefreshVehiclesAndCategories()

    local queries, queryCount = {}, 0
    local allVehicles, _ = GetVehiclesAndCategories()
    local generatedVehicles = ESX.GetVehicleData()

    for i = 1, #allVehicles do
        local vehicleModel = allVehicles[i]?.model
        local generatedVehicleData = generatedVehicles[vehicleModel]

        queryCount += 1
        queries[queryCount] = {
            query = "UPDATE `vehicles` SET `name` = ? WHERE `model` = ?",
            values = { ("%s %s"):format(generatedVehicleData?.make, generatedVehicleData?.name), vehicleModel }
        }
    end

    if not MySQL.transaction.await(queries) then return ESX.Trace("Could ^1NOT^7 refresh database vehicles name...", "error", true) end

    ESX.Trace("Refreshed database vehicles name.", "info", true)
end

ESX.RegisterCommand("refreshVehiclesName", "admin", refreshVehiclesName, true, { help = "Refreshes database vehicles name based on framework's known vehicles data" })
