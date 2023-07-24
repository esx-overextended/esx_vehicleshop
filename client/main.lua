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
    if not state then return BusyspinnerOff() end
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

---@param accountName string
---@return string
local function getAccountIcon(accountName)
    if accountName == "money" then
        return "fa-solid fa-money-bill"
    elseif accountName == "bank" then
        return "fa-solid fa-building-columns"
    end

    return "fa-solid fa-money-check-dollar"
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
            EnableControlAction(0, 1, true)  -- Mouse look
            EnableControlAction(0, 2, true)  -- Mouse look
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

    local function onMenuSelect(selectedIndex, selectedScrollIndex)
        while isSpawning do Wait(0) end

        local selectedVehicle = menuOptions[selectedIndex]?.values?[selectedScrollIndex]
        local selectedVehicleModel, selectedVehicleLabel = selectedVehicle?.value, selectedVehicle?.label

        if not spawnedVehicle then
            lib.notify({ title = ("%s Vehicle Shop"):format(vehicleShopData?.Label), description = ("Cannot load vehicle (%s)!"):format(selectedVehicleLabel), type = "error" })
            return lib.showMenu("esx_vehicleshops:shopMenu", selectedIndex)
        end

        local accounts = { ["bank"] = true, ["money"] = true }
        local options = { {
            label = "Vehicle Color",
        } }

        for i = 1, #ESX.PlayerData.accounts do
            local accountName = ESX.PlayerData.accounts[i]

            if accounts[accountName?.name] then
                accounts[accountName.name] = i
            end
        end

        for _, accountIndex in pairs(accounts) do
            local account = ESX.PlayerData.accounts[accountIndex]

            if not account then goto skipLoop end

            local canUseThisAccount = account.money >= selectedVehicle.price

            options[#options + 1] = {
                label = ("Purchase with %s"):format(account.label),
                icon = getAccountIcon(account.name),
                iconColor = canUseThisAccount and "green" or "red",
                disabled = not canUseThisAccount
            }

            ::skipLoop::
        end

        lib.registerMenu({
            id = "esx_vehicleshops:shopMenuBuyConfirmation",
            title = selectedVehicleLabel,
            options = options,
            onClose = function() lib.showMenu("esx_vehicleshops:shopMenu", selectedIndex) end
        }, function(_selectedIndex)
            if _selectedIndex == 1 then
                return lib.showMenu("esx_vehicleshops:shopMenuBuyConfirmation")
            end

            -- TODO: Purchase
        end)

        lib.showMenu("esx_vehicleshops:shopMenuBuyConfirmation")
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
            onMenuChange = nil ---@diagnostic disable-line: cast-local-type
        end
    }, onMenuSelect)

    lib.showMenu("esx_vehicleshops:shopMenu")
end
