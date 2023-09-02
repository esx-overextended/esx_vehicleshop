---@class cVehicleShop : cZone
---@field categories? string[]
---@field representativePeds? representative[]
---@field representativeVehicles? representative[]
---@field vehiclePreviewCoords? vector4
---@field vehicleSpawnCoordsAfterPurchase? vector4

---@class vehicleShop : cVehicleShop
local vehicleShop = {}
vehicleShop.__index = vehicleShop

---@type records
local records = lib.require("server.class.records")

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

---@type zone
local zone = lib.require("server.class.zone")

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
