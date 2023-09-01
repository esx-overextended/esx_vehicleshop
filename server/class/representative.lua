---@class cRepresentative
---@field coords vector4

---@class representative : cRepresentative
local representative = {}
representative.__index = representative

---@return vector4
function representative:getCoords()
    return self.coords
end

---@param coords vector4 | table
---@return representative
function representative:__call(coords)
    local object = {
        coords = vector4(coords.x, coords.y, coords.z, coords.w or coords.heading)
    }

    return setmetatable(object, representative)
end

return representative
