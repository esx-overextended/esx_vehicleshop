---@class cVehicle
---@field model string
---@field price number
---@field category string

---@class cCategory
---@field name string
---@field label string

---@class cRecords
---@field vehicles cVehicle[]
---@field categories cCategory[]

_G.vehicles   = _G.vehicles or {} --[[@as cVehicle[] ]]
_G.categories = _G.categories or {} --[[@as cCategory[] ]]

---@class records : cRecords
local records = { vehicles = _G.vehicles, categories = _G.categories }

function records:refresh()
    local dbVehicles = MySQL.query.await("SELECT * FROM vehicles")
    local dbCategories = MySQL.query.await("SELECT * FROM vehicle_categories")
    local generatedVehicles = ESX.GetVehicleData()
    local validVehicles, validVehiclesCount = {}, 0

    for i = 1, #dbVehicles do
        local vehicleData = dbVehicles[i]

        if not generatedVehicles[vehicleData?.model] then
            ESX.Trace(("The vehicle model of (^1%s^7) is ^1UNKNOWN^7 to the framework!"):format(vehicleData?.model), "warning", true)
            ESX.Trace(("Either (^1%s^7) is an invalid model or its data has not been parsed/generated yet! Refer to the documentation (https://esx-overextended.github.io/es_extended/Commands/parseVehicles)"):format(vehicleData?.model), "info", true)
        else
            validVehiclesCount += 1
            validVehicles[validVehiclesCount] = vehicleData
        end
    end

    self.vehicles = validVehicles
    self.categories = dbCategories
end

---@return cVehicle[]
function records:getVehicles()
    return self.vehicles
end

---@param model string
---@return cVehicle?
function records:getVehicle(model)
    for i = 1, #self.vehicles do
        local vehicle = self.vehicles[i]

        if vehicle.model == model then
            return vehicle
        end
    end
end

---@param model string
---@return number?
function records:getVehiclePrice(model)
    return self:getVehicle(model)?.price
end

---@param model string
---@return string?
function records:getVehicleCategory(model)
    return self:getVehicle(model)?.category
end

---@return cCategory[]
function records:getCategories()
    return self.categories
end

---@param name string
---@return cCategory?
function records:getCategory(name)
    for i = 1, #self.categories do
        local category = self.categories[i]

        if category.name == name then
            return category
        end
    end
end

---@param category string
---@return string?
function records:getCategoryLabel(category)
    return self:getCategory(category)?.label
end

---@param category string | string[]
---@return table[]
function records:getVehiclesByCategory(category)
    ---@type table<string, cVehicle[]>
    local vehiclesByCategory = {}

    if type(category) == "string" then
        category = { category }
    end

    if type(category) == "table" then
        for i = 1, #category do
            local _category = category[i]

            for j = 1, #self.categories do
                local __category = self.categories[j]

                if _category == __category.name then
                    vehiclesByCategory[__category.name] = {}
                    break
                end
            end
        end
    else
        for i = 1, #self.categories do
            vehiclesByCategory[self.categories[i].name] = {}
        end
    end

    for i = 1, #self.vehicles do
        local vehicleCategory = self.vehicles[i].category

        if vehiclesByCategory[vehicleCategory] then
            vehiclesByCategory[vehicleCategory][#vehiclesByCategory[vehicleCategory] + 1] = self.vehicles[i]
        end
    end

    for _, v in pairs(vehiclesByCategory) do
        table.sort(v, function(a, b)
            return a.name < b.name
        end)
    end

    return vehiclesByCategory
end

return records
