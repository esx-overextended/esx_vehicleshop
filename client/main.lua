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

---@param state boolean
---@param text? string
local function spinner(state, text)
    if not state then return  BusyspinnerOff() end
    if not text then text = "Loading..." end

    AddTextEntry(text, text)
    BeginTextCommandBusyspinnerOn(text)
    EndTextCommandBusyspinnerOn(4)
end

---@param entity number
---@return boolean
local function deleteEntity(entity)
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
local function spawnPreviewVehicle(vehicleModel, atCoords)
    vehicleModel = type(vehicleModel) == "string" and joaat(vehicleModel) or vehicleModel
    local vehicleEntity = CreateVehicle(vehicleModel, atCoords.x, atCoords.y, atCoords.z, atCoords.w, false, false)

    SetVehicleNeedsToBeHotwired(vehicleEntity, false)
    SetVehRadioStation(vehicleEntity, "OFF")
    freezeEntity(true, vehicleEntity, atCoords)

    return vehicleEntity
end

function OpenShopMenu(data)
    if not data?.vehicleShopKey or not data?.buyPointIndex then return end

    local menuOptions = lib.callback.await("esx_vehicleshops:generateShopMenuBuyingOptions", false, data)

    if type(menuOptions) ~= "table" or not next(menuOptions) then return end

    local vehicleShopData = Config.VehicleShops[data.vehicleShopKey]
    local collisionCoords = vehicleShopData?.VehiclePreviewCoords or Config.DefaultVehiclePreviewCoords
    local pedCoordsBeforeOpeningShopMenu = cache.coords
    local insideShop, isSpawning, spawnedVehicle = true, false, nil

    freezeEntity(true, cache.ped, collisionCoords)

    CreateThread(function()
        while insideShop do
            DisableAllControlActions(0)
            DisableAllControlActions(1)
            DisableAllControlActions(2)
            EnableControlAction(0, 1, true) -- Mouse look
            EnableControlAction(0, 2, true) -- Mouse look
            EnableControlAction(0, 71, true) -- W (for accelaration and tesing vehicles' engine sound)
            Wait(0)
        end
    end)

    local function onMenuChange(selectedIndex, selectedScrollIndex)
        while isSpawning do Wait(0) end

        isSpawning = true
        local selectedVehicle = menuOptions[selectedIndex]?.values?[selectedScrollIndex]
        local selectedVehicleModel, selectedVehicleLabel = selectedVehicle?.value, selectedVehicle?.label

        spinner(true, ("Loading %s..."):format(selectedVehicleLabel))

        local isModelLoaded = HasModelLoaded(lib.requestModel(selectedVehicleModel, 1000000))

        spinner(false)
        deleteEntity(spawnedVehicle)

        if isModelLoaded then
            spawnedVehicle = spawnPreviewVehicle(selectedVehicleModel, collisionCoords)

            SetPedIntoVehicle(cache.ped, spawnedVehicle, -1)
        end

        isSpawning = false
    end

    lib.registerMenu({
        id = "esx_vehicleshops:shopMenu",
        title = vehicleShopData?.Label,
        options = menuOptions,
        onSideScroll = onMenuChange,
        onSelected = onMenuChange,
        onClose = function()
            while isSpawning do Wait(0) end

            deleteEntity(spawnedVehicle)
            freezeEntity(false, cache.ped, pedCoordsBeforeOpeningShopMenu)

            insideShop = false
        end
    })

    lib.showMenu("esx_vehicleshops:shopMenu")
end