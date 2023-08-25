AddStateBagChangeHandler("esx_vehicleshop:handlePedRepresentative", "", function(bagName, key, value)
    Wait(0)
    if not value then return end

    local entity = GetEntityFromStateBagName(bagName)

    if entity == 0 then return end

    SetEntityInvincible(entity, true)
    FreezeEntityPosition(entity, true)
    SetPedDiesWhenInjured(entity, false)
    SetPedFleeAttributes(entity, 2, true)
    SetPedCanPlayAmbientAnims(entity, false)
    SetPedCanLosePropsOnDamage(entity, false, 0)
    -- SetPedRelationshipGroupHash(entity, `PLAYER`)
    SetBlockingOfNonTemporaryEvents(entity, true)
    SetPedCanRagdollFromPlayerImpact(entity, false)
end)

AddStateBagChangeHandler("esx_vehicleshop:handleVehicleRepresentative", "", function(bagName, key, value)
    Wait(0)
    if not value then return end

    local entity = GetEntityFromStateBagName(bagName)

    if entity == 0 then return end

    SetEntityInvincible(entity, true)
    FreezeEntityPosition(entity, true)
    SetVehicleCanBeUsedByFleeingPeds(entity, false)
    SetEntityProofs(entity, true, true, true, false, true, true, true, true)
end)
