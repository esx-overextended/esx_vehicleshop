---@class cRepresentative
---@field coords vector4

---@class representative : cRepresentative
local representative = {}
representative.__index = representative

---@return vector4
function representative:getCoords()
    return self.coords
end

---@param obj table
---@return representative
function representative:__call(obj)
    local object = json.decode(json.encode(obj))

    setmetatable(object, representative)

    return object
end

return representative
