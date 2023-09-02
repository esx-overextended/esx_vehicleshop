lib.require("modules.x-config.client")
local utility = lib.require("modules.utility.client") --[[@as utility_client]]

function OpenShopMenu(data)
    if not data?.vehicleShopKey or (not data?.representativePedIndex and not data?.representativeVehicleIndex) then return end

    local menuOptions = ESX.TriggerServerCallback("esx_vehicleshop:generateShopMenu", data)

    if type(menuOptions) ~= "table" or not next(menuOptions) then return end

    local vehicleShopData = Config.VehicleShops[data.vehicleShopKey]

    if data.representativeCategory == "representativePeds" then
        local collisionCoords = vehicleShopData?.vehiclePreviewCoords or Config.DefaultVehiclePreviewCoords
        local pedCoordsBeforeOpeningShopMenu = cache.coords
        local insideShop, isSpawning, spawnedVehicle = true, false, nil

        utility.freezeEntity(true, cache.ped, collisionCoords)

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

            utility.spinner(true, ("Loading %s..."):format(selectedVehicleLabel))

            local isModelLoaded = HasModelLoaded(lib.requestModel(selectedVehicleModel, 1000000))

            utility.spinner(false)
            utility.deleteEntity(spawnedVehicle)

            if isModelLoaded then
                spawnedVehicle = utility.spawnPreviewVehicle(selectedVehicleModel, collisionCoords)

                SetPedIntoVehicle(cache.ped, spawnedVehicle, -1)
            end

            isSpawning = false
        end

        function onMenuSelect(selectedIndex, selectedScrollIndex)
            while isSpawning do Wait(0) end

            local selectedVehicle = menuOptions[selectedIndex]?.values?[selectedScrollIndex]
            local selectedVehicleLabel = selectedVehicle?.label

            menuOptions[selectedIndex].defaultIndex = selectedScrollIndex

            lib.setMenuOptions("esx_vehicleshop:shopMenu", menuOptions[selectedIndex], selectedIndex)

            if not spawnedVehicle then
                ESX.ShowNotification({ locale("vehicle_shop", vehicleShopData?.label), locale("cannot_load_vehicle", selectedVehicleLabel) }, "error")
                return lib.showMenu("esx_vehicleshop:shopMenu", selectedIndex)
            end

            local accounts = { ["bank"] = true, ["money"] = true }
            local options = { {
                label = locale("vehicle_color"),
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
                    label = locale("purchase_with", account.label),
                    icon = utility.getAccountIcon(account.name),
                    iconColor = canUseThisAccount and "green" or "red",
                    close = false,
                    accountName = account.name,
                    accountLabel = account.label,
                    canUseThisAccount = canUseThisAccount,
                    description = locale("vehicle_price", selectedVehicle.price)
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
                    local vehicleCustomPrimaryColor = GetIsVehiclePrimaryColourCustom(spawnedVehicle) and utility.rgbToHex(GetVehicleCustomPrimaryColour(spawnedVehicle)) or nil
                    local vehicleCustomSecondaryColor = GetIsVehicleSecondaryColourCustom(spawnedVehicle) and utility.rgbToHex(GetVehicleCustomSecondaryColour(spawnedVehicle)) or nil

                    local input = lib.inputDialog(selectedVehicleLabel, {
                        { type = "color", label = locale("vehicle_primary_color"),   default = vehicleCustomPrimaryColor,   format = "hex", required = true },
                        { type = "color", label = locale("vehicle_secondary_color"), default = vehicleCustomSecondaryColor, format = "hex", required = true }
                    })

                    if input?[1] then SetVehicleCustomPrimaryColour(spawnedVehicle, utility.hexToRGB(input[1])) end
                    if input?[2] then SetVehicleCustomSecondaryColour(spawnedVehicle, utility.hexToRGB(input[2])) end

                    return lib.showMenu("esx_vehicleshop:shopMenuBuyConfirmation")
                end

                local optionData = options[_selectedIndex]

                if not optionData?.canUseThisAccount then
                    return ESX.ShowNotification({ locale("vehicle_shop", vehicleShopData?.label), locale("not_enough_money", optionData?.accountLabel, selectedVehicleLabel) }, "error")
                end

                local currentMenu = lib.getOpenMenu()

                lib.hideMenu(false)

                local alertDialog = lib.alertDialog({
                    header = ("**%s**" --[[making it bold]]):format(locale("purchase_confirmation_header", selectedVehicleLabel)),
                    content = locale("purchase_confirmation_content", selectedVehicleLabel, selectedVehicle.price, optionData?.accountLabel),
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
                    return ESX.ShowNotification({ locale("vehicle_shop", vehicleShopData?.label), locale("purchase_not_complete", selectedVehicleLabel) }, "error")
                end

                for _ = 1, 2 do
                    lib.hideMenu(true)
                    Wait(10)
                end

                utility.freezeEntity(true, cache.ped, vehicleShopData.vehicleSpawnCoordsAfterPurchase or Config.DefaultVehicleSpawnCoordsAfterPurchase)

                local doesNetIdExist, timeout = false, 0

                while not doesNetIdExist and timeout < 1000 do
                    doesNetIdExist = NetworkDoesEntityExistWithNetworkId(vehicleNetId)
                    timeout += 1
                    Wait(0)
                end

                utility.freezeEntity(false)

                local vehicleEntity = doesNetIdExist and NetworkGetEntityFromNetworkId(vehicleNetId)

                if not vehicleEntity or vehicleEntity == 0 then return end

                for _ = 1, 50 do
                    Wait(0)
                    SetPedIntoVehicle(cache.ped, vehicleEntity, -1)

                    if GetVehiclePedIsIn(cache.ped, false) == vehicleEntity then
                        break
                    end
                end

                ESX.ShowNotification({ locale("vehicle_shop", vehicleShopData?.label), locale("purchase_confirmed", selectedVehicleLabel, ESX.Math.GroupDigits(selectedVehicle.price)) }, "success", 5000)
            end)

            lib.showMenu("esx_vehicleshop:shopMenuBuyConfirmation")
        end

        function onMenuClose()
            while isSpawning do Wait(0) end

            utility.deleteEntity(spawnedVehicle)
            utility.freezeEntity(false, cache.ped, pedCoordsBeforeOpeningShopMenu)

            insideShop = false
        end

        lib.registerMenu({
            id = "esx_vehicleshop:shopMenu",
            title = vehicleShopData?.label,
            options = menuOptions,
            onSideScroll = onMenuChange,
            onSelected = onMenuChange,
            onClose = function()
                onMenuClose()
                onMenuChange, onMenuChange, onMenuSelect = nil, nil, nil ---@diagnostic disable-line: cast-local-type
            end
        }, onMenuSelect)

        lib.showMenu("esx_vehicleshop:shopMenu")
    elseif data.representativeCategory == "representativeVehicles" then
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
            title = vehicleShopData?.label,
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
        title = locale("vehicle_sell"),
        options = contextOptions
    })

    lib.showContext("esx_vehicleshop:sellMenu")
end

-- leave for backward-compatibility with legacy esx_vehicleshop and resources that use its export call
exports("GeneratePlate", function()
    return ESX.TriggerServerCallback("esx:generatePlate")
end)

lib.require("modules.zone.client")
lib.require("modules.representative.client")
