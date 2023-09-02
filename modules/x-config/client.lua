local x_configResourceName, x_configResourceState, x_config = "x-config", nil, nil

local function refreshXConfig()
    x_config = exports[x_configResourceName]
    x_configResourceState = GetResourceState(x_configResourceName):find("start") ~= nil
end

---Enables/Disables vehicles from generating in an area
---@param state boolean
---@param coords vector3
---@param range? number defaults to 100.0 if not provided
local function vehicleGenerator(state, coords, range)
    if not x_configResourceState then return end

    x_config:generateVehiclesInArea(state, coords, range) ---@diagnostic disable-line: need-check-nil
end

---Enables/Disables vehicles from generating in vehicle preview areas
---@param state boolean
local function applyVehicleGenerator(state)
    vehicleGenerator(state, Config.DefaultVehiclePreviewCoords)

    for _, vehicleShopData in pairs(Config.VehicleShops) do
        vehicleGenerator(state, vehicleShopData.vehiclePreviewCoords)
    end
end

---@param resource string
---@param state "start" | "stop"
local function onResourceStateModified(resource, state)
    local shouldApplyVehicleGenerator = resource == cache.resource

    if resource == x_configResourceName then
        refreshXConfig()

        shouldApplyVehicleGenerator = true
    end

    return shouldApplyVehicleGenerator and applyVehicleGenerator(state == "start")
end

---@param resource string
local function onResourceStart(resource)
    onResourceStateModified(resource, "start")
end

---@param resource string
local function onResourceStop(resource)
    onResourceStateModified(resource, "stop")
end

AddEventHandler("onResourceStart", onResourceStart)
AddEventHandler("onClientResourceStart", onResourceStart)

AddEventHandler("onResourceStop", onResourceStop)
AddEventHandler("onClientResourceStop", onResourceStop)

do refreshXConfig() end
