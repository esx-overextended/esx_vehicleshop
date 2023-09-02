Target = {}

function Target.addNetId(netId, data)
    local vehicleShopData = Config.VehicleShops[data.vehicleShopKey]
    local optionId = ("%s:shop[%s][%s][%s]"):format(cache.resource, data.vehicleShopKey, data.representativeCategory, data.representativeIndex)

    if data.representativeCategory == "representativePeds" then
        data.representativePedIndex = data.representativeIndex
    elseif data.representativeCategory == "representativeVehicles" then
        data.representativeVehicleIndex = data.representativeIndex
    end

    exports["ox_target"]:addEntity(netId, {
        {
            name = optionId,
            label = locale("browse_shop_catalog", vehicleShopData?.label),
            icon = "fa-solid fa-shop",
            distance = 3,
            onSelect = function()
                local representativeCoords = vehicleShopData[data.representativeCategory][data.representativeIndex].coords
                data.currentDistance = #(cache.coords - vector3(representativeCoords?.x, representativeCoords?.y, representativeCoords?.z))

                OpenShopMenu(data)
            end
        }
    })

    return optionId
end

function Target.addEntity(entity, data)
    local vehicleShopData = Config.VehicleShops[data.vehicleShopKey]
    local optionId = ("%s:shop[%s][%s][%s]"):format(cache.resource, data.vehicleShopKey, data.representativeCategory, data.representativeIndex)

    if data.representativeCategory == "representativePeds" then
        data.representativePedIndex = data.representativeIndex
    elseif data.representativeCategory == "representativeVehicles" then
        data.representativeVehicleIndex = data.representativeIndex
    end

    exports["ox_target"]:addLocalEntity(entity, {
        {
            name = optionId,
            label = locale("browse_shop_catalog", vehicleShopData?.label),
            icon = "fa-solid fa-shop",
            distance = 3,
            onSelect = function()
                local representativeCoords = vehicleShopData[data.representativeCategory][data.representativeIndex].coords
                data.currentDistance = #(cache.coords - vector3(representativeCoords?.x, representativeCoords?.y, representativeCoords?.z))

                OpenShopMenu(data)
            end
        }
    })

    return optionId
end
