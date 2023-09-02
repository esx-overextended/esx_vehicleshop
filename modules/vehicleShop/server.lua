---@class cVehicleShop : cZone
---@field categories? string[]
---@field representativePeds? representative[]
---@field representativeVehicles? representative[]
---@field vehiclePreviewCoords? vector4
---@field vehicleSpawnCoordsAfterPurchase? vector4

---@class vehicleShop : cVehicleShop
local vehicleShop = {}
vehicleShop.__index = vehicleShop

local shared = lib.require("shared.shared") --[[@as shared]]
local records = lib.require("modules.records.server") --[[@as records]]
local representative = lib.require("modules.representative.server") --[[@as representative]]

---@return string[]?
function vehicleShop:getCategories()
    return self.categories
end

---@param category string
---@return boolean
function vehicleShop:hasCategory(category)
    if type(self.categories) ~= "table" then return false end

    for i = 1, #self.categories do
        if self.categories[i] == category then
            return true
        end
    end

    return false
end

---@param model string
---@return boolean
function vehicleShop:hasVehicle(model)
    local allVehicles = records:getVehicles()

    for i = 1, #allVehicles do
        local vehicle = allVehicles[i]

        if vehicle.model == model and self:hasCategory(vehicle.category) then
            return true
        end
    end

    return false
end

---@return string
function vehicleShop:getRandomVehicleModel()
    local vehicleModel
    local allVehicles = records:getVehicles()
    local allVehiclesCount = #allVehicles

    repeat
        local randomVehicle = allVehicles[math.random(1, allVehiclesCount)]

        if self:hasVehicle(randomVehicle?.model) then
            vehicleModel = randomVehicle.model
        end
    until vehicleModel

    return vehicleModel
end

---@param representativeCategory string
---@param representativeIndex number
---@return representative?
function vehicleShop:getRepresentative(representativeCategory, representativeIndex)
    return representative(self[representativeCategory]?[representativeIndex])
end

---@param playerId number
---@return boolean
function vehicleShop:isPlayerNearShopPreview(playerId)
    local playerPed = GetPlayerPed(playerId)
    local playerCoords = GetEntityCoords(playerPed)
    local vehiclePreviewCoords = self.vehiclePreviewCoords or Config.DefaultVehiclePreviewCoords

    return #(playerCoords - vector3(vehiclePreviewCoords.x, vehiclePreviewCoords.y, vehiclePreviewCoords.z)) <= shared.DISTANCE_TO_VEHICLE_PREVIEW
end

---@param representativeCategory "representativePeds" | "representativeVehicles"
---@param representativeIndex? number
---@return table
function vehicleShop:generateShopMenu(representativeCategory, representativeIndex)
    local menuOptions, menuOptionsCount = {}, 0
    local allVehicleData = ESX.GetVehicleData()
    local allCategories = records:getCategories()
    local vehiclesByCategory = records:getVehiclesByCategory(self.categories)

    for i = 1, #allCategories do
        local category = allCategories[i]

        if vehiclesByCategory[category.name] then
            local categoryVehicles = vehiclesByCategory[category.name]
            local options, optionsCount = {}, 0

            for j = 1, #categoryVehicles do
                local vehicle = categoryVehicles[j]

                if representativeCategory == "representativePeds" then
                    optionsCount += 1
                    options[optionsCount] = { -- menu options to show for peds
                        label = vehicle.name,
                        value = vehicle.model,
                        price = vehicle.price,
                        category = category.name,
                        description = locale("vehicle_price", ESX.Math.GroupDigits(vehicle.price))
                    }
                elseif representativeCategory == "representativeVehicles" then
                    optionsCount += 1
                    options[optionsCount] = { -- context menu options to show for vehicles
                        title = vehicle.name,
                        model = vehicle.model,
                        price = vehicle.price,
                        category = category.name,
                        categoryLabel = category.label,
                        description = locale("vehicle_price", ESX.Math.GroupDigits(vehicle.price)),
                        image = allVehicleData[vehicle.model]?.image,
                        serverEvent = "esx_vehicleshop:changeVehicleRepresentative",
                        args = {
                            vehicleShopKey = self.key,
                            representativeCategory = representativeCategory,
                            representativeVehicleIndex = representativeIndex,
                            vehicleModel = vehicle.model
                        }
                    }
                end
            end

            if representativeCategory == "representativePeds" then
                menuOptionsCount += 1
                menuOptions[menuOptionsCount] = {
                    label = category.name,
                    values = options
                }
            elseif representativeCategory == "representativeVehicles" then
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

    return menuOptions
end

---@type zone
local zone = lib.require("modules.zone.server")

return setmetatable({}, {
    __index = vehicleShop,
    __call = function(_, shopKey)
        local vehicleShopData = Config.VehicleShops[shopKey]

        if not vehicleShopData then return end

        local object = zone(shopKey, vehicleShopData.label, vehicleShopData.blip) --[[@as zone]]

        ---@cast object -zone, +vehicleShop
        object.categories = vehicleShopData.categories
        object.representativePeds = vehicleShopData.representativePeds
        object.representativeVehicles = vehicleShopData.representativeVehicles
        object.vehiclePreviewCoords = vehicleShopData.vehiclePreviewCoords
        object.vehicleSpawnCoordsAfterPurchase = vehicleShopData.vehicleSpawnCoordsAfterPurchase

        setmetatable(object, vehicleShop)

        return object
    end
})
