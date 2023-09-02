---@class cZone
---@field key string
---@field label string
---@field blip table?

---@class zone : cZone
local zone = {}
zone.__index = zone

---@return string
function zone:getKey()
    return self.key
end

---@return string
function zone:getLabel()
    return self.label
end

---@return table?
function zone:getBlipData()
    return self.blip
end

---@return boolean?
function zone:isBlipActive()
    return self.blip?.active
end

---@return vector3?
function zone:getBlipCoords()
    return self.blip?.coords
end

---creates an instance of zone
---@param zoneKey string
---@param zoneLabel string
---@param blipData table?
---@return zone
function zone:__call(zoneKey, zoneLabel, blipData)
    local object = {
        key = zoneKey,
        label = zoneLabel,
        blip = blipData
    }

    setmetatable(object, zone)

    return object
end

return zone
