---@class cRepresentative
---@field coords vector4

---@class representative : cRepresentative
local representative = {}
representative.__index = representative

local shared = lib.require("shared.shared") --[[@as shared]]

---@param playerId number
---@return number
function representative:getDistanceToPlayer(playerId)
    local playerPed = GetPlayerPed(playerId)
    local playerCoords = GetEntityCoords(playerPed)

    return #(playerCoords - vector3(self.coords.x, self.coords.y, self.coords.z))
end

---@param playerId number
---@return boolean
function representative:isPlayerNearby(playerId)
    return self:getDistanceToPlayer(playerId) <= shared.DISTANCE_TO_REPRESENTATIVE
end

return setmetatable({}, {
    __index = representative,
    __call = function(_, obj)
        if type(obj) == "table" then
            obj = setmetatable(obj, representative)
        end

        return obj
    end
})
