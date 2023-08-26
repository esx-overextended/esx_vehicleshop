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
            RequestCollisionAtCoord(atCoords.x, atCoords.y, atCoords.z)
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

---@param entity? number
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

    SetModelAsNoLongerNeeded(vehicleModel)
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

---@param hex string
---@return number, number, number
local function hexToRGB(hex)
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
local function rgbToHex(r, g, b)
    return string.format("#%02X%02X%02X", r, g, b)
end

function OpenShopMenu(data)
    if not data?.vehicleShopKey or (not data?.representativePedIndex and not data?.representativeVehicleIndex) then return end

    local menuOptions = ESX.TriggerServerCallback("esx_vehicleshop:generateShopMenu", data)

    if type(menuOptions) ~= "table" or not next(menuOptions) then return end

    local vehicleShopData = Config.VehicleShops[data.vehicleShopKey]

    if data.representativeCategory == "RepresentativePeds" then
        local collisionCoords = vehicleShopData?.VehiclePreviewCoords or Config.DefaultVehiclePreviewCoords
        local pedCoordsBeforeOpeningShopMenu = cache.coords
        local insideShop, isSpawning, spawnedVehicle = true, false, nil

        freezeEntity(true, cache.ped, collisionCoords)

        CreateThread(function()
            SetEntityVisible(cache.ped, false, false)

            while insideShop do
                DisableAllControlActions(0)
                DisableAllControlActions(1)
                DisableAllControlActions(2)
                EnableControlAction(0, 1, true)  -- Mouse look
                EnableControlAction(0, 2, true)  -- Mouse look
                EnableControlAction(0, 71, true) -- W (for accelaration and testing vehicles' engine sound)

                SetLocalPlayerVisibleLocally(true)

                Wait(0)
            end

            SetEntityVisible(cache.ped, true, false)
        end)

        local onMenuClose, onMenuChange, onMenuSelect

        function onMenuChange(selectedIndex, selectedScrollIndex)
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

        function onMenuSelect(selectedIndex, selectedScrollIndex)
            while isSpawning do Wait(0) end

            local selectedVehicle = menuOptions[selectedIndex]?.values?[selectedScrollIndex]
            local selectedVehicleLabel = selectedVehicle?.label

            if not spawnedVehicle then
                lib.notify({ title = ("%s Vehicle Shop"):format(vehicleShopData?.Label), description = ("Cannot load vehicle (%s)!"):format(selectedVehicleLabel), type = "error" })
                return lib.showMenu("esx_vehicleshop:shopMenu", selectedIndex)
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
                    close = false,
                    accountName = account.name,
                    accountLabel = account.label,
                    canUseThisAccount = canUseThisAccount,
                    description = ("Price: $%s"):format(selectedVehicle.price)
                }

                ::skipLoop::
            end

            lib.registerMenu({
                id = "esx_vehicleshop:shopMenuBuyConfirmation",
                title = selectedVehicleLabel,
                options = options,
                onClose = function() lib.showMenu("esx_vehicleshop:shopMenu", selectedIndex) end
            }, function(_selectedIndex)
                if _selectedIndex == 1 then
                    local vehicleCustomPrimaryColor = GetIsVehiclePrimaryColourCustom(spawnedVehicle) and rgbToHex(GetVehicleCustomPrimaryColour(spawnedVehicle)) or nil
                    local vehicleCustomSecondaryColor = GetIsVehicleSecondaryColourCustom(spawnedVehicle) and rgbToHex(GetVehicleCustomSecondaryColour(spawnedVehicle)) or nil

                    local input = lib.inputDialog(selectedVehicleLabel, {
                        { type = "color", label = "Primary Color",   default = vehicleCustomPrimaryColor,   format = "hex", required = true },
                        { type = "color", label = "Secondary Color", default = vehicleCustomSecondaryColor, format = "hex", required = true }
                    })

                    if input?[1] then SetVehicleCustomPrimaryColour(spawnedVehicle, hexToRGB(input[1])) end
                    if input?[2] then SetVehicleCustomSecondaryColour(spawnedVehicle, hexToRGB(input[2])) end

                    return lib.showMenu("esx_vehicleshop:shopMenuBuyConfirmation")
                end

                local optionData = options[_selectedIndex]

                if not optionData?.canUseThisAccount then
                    return lib.notify({
                        title = ("%s Vehicle Shop"):format(vehicleShopData?.Label),
                        description = ("Your %s account does not have enough money in it to purchase %s!"):format(optionData?.accountLabel, selectedVehicleLabel),
                        type = "error"
                    })
                end

                local currentMenu = lib.getOpenMenu()

                lib.hideMenu(false)

                local alertDialog = lib.alertDialog({
                    header = ("**%s Purchase Confirmation**"):format(selectedVehicleLabel),
                    content = ("Are you sure you want to purchase the vehicle %s for $%s with %s?"):format(selectedVehicleLabel, selectedVehicle.price, optionData?.accountLabel),
                    centered = true,
                    cancel = true
                })

                lib.showMenu(currentMenu, _selectedIndex)

                if alertDialog ~= "confirm" then return end

                local vehicleNetId = ESX.TriggerServerCallback("esx_vehicleshop:purchaseVehicle", {
                    vehicleIndex      = selectedScrollIndex,
                    vehicleShopKey    = data.vehicleShopKey,
                    vehicleCategory   = selectedVehicle.category,
                    purchaseAccount   = optionData?.accountName,
                    vehicleProperties = ESX.Game.GetVehicleProperties(spawnedVehicle)
                })

                if not vehicleNetId then
                    return lib.notify({ title = ("%s Vehicle Shop"):format(vehicleShopData?.Label), description = ("The purchase of %s could NOT be completed..."):format(selectedVehicleLabel), type = "error" })
                end

                for _ = 1, 2 do
                    lib.hideMenu(true)
                    Wait(10)
                end

                freezeEntity(true, cache.ped, vehicleShopData.VehicleSpawnCoordsAfterPurchase or Config.DefaultVehicleSpawnCoordsAfterPurchase)

                local doesNetIdExist, timeout = false, 0

                while not doesNetIdExist and timeout < 1000 do
                    doesNetIdExist = NetworkDoesEntityExistWithNetworkId(vehicleNetId)
                    timeout += 1
                    Wait(0)
                end

                freezeEntity(false)

                local vehicleEntity = doesNetIdExist and NetworkGetEntityFromNetworkId(vehicleNetId)

                if not vehicleEntity or vehicleEntity == 0 then return end

                for _ = 1, 50 do
                    Wait(0)
                    SetPedIntoVehicle(cache.ped, vehicleEntity, -1)

                    if GetVehiclePedIsIn(cache.ped, false) == vehicleEntity then
                        break
                    end
                end
            end)

            lib.showMenu("esx_vehicleshop:shopMenuBuyConfirmation")
        end

        function onMenuClose()
            while isSpawning do Wait(0) end

            deleteEntity(spawnedVehicle)
            freezeEntity(false, cache.ped, pedCoordsBeforeOpeningShopMenu)

            insideShop = false
            onMenuChange, onMenuChange, onMenuSelect = nil, nil, nil ---@diagnostic disable-line: cast-local-type
        end

        lib.registerMenu({
            id = "esx_vehicleshop:shopMenu",
            title = vehicleShopData?.Label,
            options = menuOptions,
            onSideScroll = onMenuChange,
            onSelected = onMenuChange,
            onClose = onMenuClose
        }, onMenuSelect)

        lib.showMenu("esx_vehicleshop:shopMenu")
    elseif data.representativeCategory == "RepresentativeVehicles" then
        for i = 1, #menuOptions do
            local categoryOption = menuOptions[i]

            if type(categoryOption.args?.subMenuOptions) == "table" then
                local vehicleOptions = categoryOption.args.subMenuOptions

                for j = 1, #vehicleOptions do
                    local _option = vehicleOptions[j]

                    lib.registerContext({
                        id = ("esx_vehicleshop:shopMenu_%s"):format(_option.category),
                        title = _option.categoryLabel,
                        menu = "esx_vehicleshop:shopMenu",
                        canClose = true,
                        options = vehicleOptions
                    })
                end
            end
        end

        lib.registerContext({
            id = "esx_vehicleshop:shopMenu",
            title = vehicleShopData?.Label,
            canClose = true,
            options = menuOptions
        })

        lib.showContext("esx_vehicleshop:shopMenu")
    end
end

function OpenSellMenu(data)
    if not data?.sellPointIndex then return end

    local contextOptions = ESX.TriggerServerCallback("esx_vehicleshop:generateSellMenu", data)

    if type(contextOptions) ~= "table" then return end

    lib.registerContext({
        id = "esx_vehicleshop:sellMenu",
        title = "ESX Vehicle Sell",
        options = contextOptions
    })
    lib.showContext("esx_vehicleshop:sellMenu")
end

-- leave for backward-compatibility with legacy esx_vehicleshop and resources that use its export call
exports("GeneratePlate", function()
    return ESX.TriggerServerCallback("esx:generatePlate")
end)
