---@class utility_client
local utility = {}

---@param entity? number
---@return boolean
function utility.hasCollisionLoadedAroundEntity(entity)
    if not entity then entity = cache.ped end

    return HasCollisionLoadedAroundEntity(entity) and not IsEntityWaitingForWorldCollision(entity)
end

---@param state boolean
---@param entity? number
---@param atCoords? vector3 | vector4 | table
function utility.freezeEntity(state, entity, atCoords)
    if not entity then entity = cache.ped end
    if IsEntityAPed(entity) and IsPedAPlayer(entity) then ClearPedTasksImmediately(entity) end

    SetEntityCollision(entity, not state, true)
    FreezeEntityPosition(entity, state)
    SetEntityInvincible(entity, state)

    if atCoords then
        SetEntityCoords(entity, atCoords.x, atCoords.y, atCoords.z, false, false, false, false)

        if atCoords.w or atCoords.heading then
            SetEntityHeading(entity, atCoords.w or atCoords.heading)
        end

        while not utility.hasCollisionLoadedAroundEntity(entity) do
            RequestCollisionAtCoord(atCoords.x, atCoords.y, atCoords.z)
            Wait(100)
        end
    end
end

---@param state boolean
---@param text? string
function utility.spinner(state, text)
    if not state then return BusyspinnerOff() end
    if not text then text = "Loading..." end

    AddTextEntry(text, text)
    BeginTextCommandBusyspinnerOn(text)
    EndTextCommandBusyspinnerOn(4)
end

---@param entity? number
---@return boolean
function utility.deleteEntity(entity)
    if not entity then return false end

    while DoesEntityExist(entity) do
        DeleteEntity(entity)
        Wait(0)
    end

    return true
end

---@param vehicleModel string | number
---@param atCoords any
---@return number
function utility.spawnPreviewVehicle(vehicleModel, atCoords)
    vehicleModel = type(vehicleModel) == "string" and joaat(vehicleModel) or vehicleModel
    local vehicleEntity = CreateVehicle(vehicleModel, atCoords.x, atCoords.y, atCoords.z, atCoords.w, false, false)

    SetModelAsNoLongerNeeded(vehicleModel)
    SetVehRadioStation(vehicleEntity, "OFF")
    utility.freezeEntity(true, vehicleEntity, atCoords)

    return vehicleEntity
end

---@param accountName string
---@return string
function utility.getAccountIcon(accountName)
    if accountName == "money" then
        return "fa-solid fa-money-bill"
    elseif accountName == "bank" then
        return "fa-solid fa-building-columns"
    end

    return "fa-solid fa-money-check-dollar"
end

---@param hex string
---@return number, number, number
function utility.hexToRGB(hex)
    hex = hex:gsub("#", "")
    local r = tonumber(hex:sub(1, 2), 16) or 0
    local g = tonumber(hex:sub(3, 4), 16) or 0
    local b = tonumber(hex:sub(5, 6), 16) or 0

    return r, g, b
end

---@param r number
---@param g number
---@param b number
---@return string
function utility.rgbToHex(r, g, b)
    return string.format("#%02X%02X%02X", r, g, b)
end

return utility
