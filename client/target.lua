Target = {}

function Target.addNetId(netId, data)
    local onSelect
    local vehicleShopData = Config.VehicleShops[data.vehicleShopKey]
    local optionId = ("%s:shop[%s][%s][%s]"):format(cache.resource, data.vehicleShopKey, data.representativeCategory, data.representativeIndex)

    if data.representativeCategory == "RepresentativePeds" then
        data.representativePedIndex = data.representativeIndex
        onSelect = function()
            local representativeCoords = vehicleShopData[data.representativeCategory][data.representativeIndex].Coords
            data.currentDistance = #(cache.coords - vector3(representativeCoords?.x, representativeCoords?.y, representativeCoords?.z))

            OpenShopMenu(data)
        end
    elseif data.representativeCategory == "RepresentativeVehicles" then
        data.representativeVehicleIndex = data.representativeIndex
        onSelect = function() --[[TODO]] end
    end

    exports["ox_target"]:addEntity(netId, {
        {
            name = optionId,
            label = ("Browse %s's Catalog"):format(vehicleShopData?.Label),
            icon = "fa-solid fa-shop",
            distance = 3,
            onSelect = onSelect
        }
    })

    return optionId
end
