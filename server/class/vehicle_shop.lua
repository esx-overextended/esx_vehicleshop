---@class cVehicleShop : cZone
---@field categories string[]?
---@field representatives representative[]

---@class vehicleShop : cVehicleShop
local vehicleShop = {}
vehicleShop.__index = vehicleShop
local zone = lib.require("server.class.zone") --[[@as zone]]

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

---@param category string
function vehicleShop:addCategory(category)
    if type(self.categories) ~= "table" then
        self.categories = {}
    end

    if self:hasCategory(category) then return end

    table.insert(self.categories, category)
end

---@param category string
function vehicleShop:removeCategory(category)
    if type(self.categories) ~= "table" then
        self.categories = {}
    end

    if not self:hasCategory(category) then return end

    for i = 1, #self.categories do
        if self.categories[i] == category then
            table.remove(self.categories, i)
            break
        end
    end
end

---@return representative[]
function vehicleShop:getRepresentatives()
    return self.representatives
end

---@return vehicleShop
function vehicleShop:__call(shopKey, shopLabel, blipData, vehicleCategories, allRepresentatives)
    local object = zone(shopKey, shopLabel, blipData) --[[@as zone]]

    ---@cast object -zone, +vehicleShop
    object.categories = vehicleCategories
    object.representatives = allRepresentatives

    return setmetatable(object, vehicleShop)
end

return vehicleShop
