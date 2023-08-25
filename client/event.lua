AddStateBagChangeHandler("esx_vehicleshop:handlePedRepresentative", "", function(bagName, key, value)
    if not value then return end

    local netId = tonumber(bagName:gsub("entity:", ""), 10)
    local doesNetIdExist, timeout = false, 0

    while not doesNetIdExist and timeout < 1000 do
        doesNetIdExist = NetworkDoesEntityExistWithNetworkId(netId)
        timeout += 1
        Wait(0)
    end

    if not doesNetIdExist then
        return ESX.Trace(("Statebag (^3%s^7) timed out after waiting %s ticks for entity creation on %s!"):format(bagName, timeout, key), "warning", true)
    end

    local entity = NetworkDoesEntityExistWithNetworkId(netId) and NetworkGetEntityFromNetworkId(netId)

    if not entity or entity == 0 then return end

    SetEntityInvincible(entity, true)
    FreezeEntityPosition(entity, true)
    SetEntityCoords(entity, value.x, value.y, value.z, false, false, false, true)
    SetEntityHeading(entity, value.w)
    SetPedDiesWhenInjured(entity, false)
    SetPedFleeAttributes(entity, 2, true)
    SetPedCanPlayAmbientAnims(entity, false)
    SetPedCanLosePropsOnDamage(entity, false, 0)
    SetPedRelationshipGroupHash(entity, `PLAYER`)
    SetBlockingOfNonTemporaryEvents(entity, true)
    SetPedCanRagdollFromPlayerImpact(entity, false)
end)

AddStateBagChangeHandler("esx_vehicleshop:handleVehicleRepresentative", "", function(bagName, key, value)
    if type(value) ~= "vector4" then return end

    local netId = tonumber(bagName:gsub("entity:", ""), 10)
    local doesNetIdExist, timeout = false, 0

    while not doesNetIdExist and timeout < 1000 do
        doesNetIdExist = NetworkDoesEntityExistWithNetworkId(netId)
        timeout += 1
        Wait(0)
    end

    if not doesNetIdExist then
        return ESX.Trace(("Statebag (^3%s^7) timed out after waiting %s ticks for entity creation on %s!"):format(bagName, timeout, key), "warning", true)
    end

    local entity = NetworkDoesEntityExistWithNetworkId(netId) and NetworkGetEntityFromNetworkId(netId)

    if not entity or entity == 0 then return end

    SetEntityInvincible(entity, true)
    FreezeEntityPosition(entity, true)
    SetEntityCoords(entity, value.x, value.y, value.z, false, false, false, true)
    SetEntityHeading(entity, value.w)
    SetVehicleCanBeUsedByFleeingPeds(entity, false)
    SetEntityProofs(entity, true, true, true, false, true, true, true, true)
end)
