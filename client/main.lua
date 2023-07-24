---@param entity? number
---@return boolean
local function hasCollisionLoadedAroundEntity(entity)
    if not entity then entity = cache.ped end

    return HasCollisionLoadedAroundEntity(entity) and not IsEntityWaitingForWorldCollision(entity)
end

---@param state boolean
---@param entity? number
---@param atCoords? vector3 | vector4 | table
local function freezeEntity(state, entity, atCoords)
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

        while not hasCollisionLoadedAroundEntity(entity) do
            RequestCollisionAtCoord(collisionCoords.x, collisionCoords.y, collisionCoords.z)
            Wait(100)
        end
    end
end

function OpenShopMenu(data)
    if not data?.vehicleShopKey or not data?.buyPointIndex then return end

    local menuOptions = lib.callback.await("esx_vehicleshops:generateShopMenuBuyingOptions", false, data)

    if type(menuOptions) ~= "table" or not next(menuOptions) then return end

    local vehicleShopData = Config.VehicleShops[data.vehicleShopKey]
    local collisionCoords = vehicleShopData?.VehiclePreviewCoords or Config.DefaultVehiclePreviewCoords
    local pedCoordsBeforeOpeningShopMenu = cache.coords
    local isShopRestrictionEnabled = true

    freezeEntity(true, cache.ped, collisionCoords)

    CreateThread(function()
        while isShopRestrictionEnabled do
            DisableAllControlActions(0)
            DisableAllControlActions(1)
            DisableAllControlActions(2)
            EnableControlAction(0, 1, true) -- Mouse look
            EnableControlAction(0, 2, true) -- Mouse look
            EnableControlAction(0, 71, true) -- W (for accelaration and tesing vehicles' engine sound)
            Wait(0)
        end
    end)

    lib.registerMenu({
        id = "esx_vehicleshops:shopMenu",
        title = vehicleShopData?.Label,
        options = menuOptions,
        onSideScroll = function(selected, scrollIndex, args) end,
        onSelected = function(selected, scrollIndex, args)
        end,
        onClose = function()
            freezeEntity(false, cache.ped, pedCoordsBeforeOpeningShopMenu)
            isShopRestrictionEnabled = false
        end
    })

    lib.showMenu("esx_vehicleshops:shopMenu")
end