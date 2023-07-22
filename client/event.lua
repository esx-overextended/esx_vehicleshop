function OpenShopMenu(data)
    if not data?.vehicleShopKey or not data?.buyPointIndex then return end

    local vehicleShopData = Config.VehicleShops[data.vehicleShopKey]
    local menuOptions = lib.callback.await("esx_vehicleshops:generateShopMenuBuyingOptions", false, data)

    if type(menuOptions) ~= "table" or not next(menuOptions) then return end

    lib.registerMenu({
        id = "esx_vehicleshops:shopMenu",
        title = vehicleShopData.Label,
        options = menuOptions,
        onSideScroll = function(selected, scrollIndex, args) end,
        onSelected = function(selected, scrollIndex, args) end,
        onClose = function(keyPressed) end
    })

    lib.showMenu("esx_vehicleshops:shopMenu")
end