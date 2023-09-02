local target = lib.require("modules.target.client") --[[@as target]]

AddStateBagChangeHandler("esx_vehicleshop:handleRepresentative", "", function(bagName, _, value)
    if type(value) ~= "table" then return end

    local entity, netId = ESX.OneSync.GetEntityFromStateBag(bagName)

    if not entity or not netId then return end

    SetEntityInvincible(entity, true)
    FreezeEntityPosition(entity, true)
    SetEntityCoords(entity, value.coords?.x, value.coords?.y, value.coords?.z, false, false, false, true)
    SetEntityHeading(entity, value.coords?.w)
    SetEntityProofs(entity, true, true, true, false, true, true, true, true)

    if value.representativeCategory == "representativePeds" then
        SetPedDiesWhenInjured(entity, false)
        SetPedFleeAttributes(entity, 2, true)
        SetPedCanPlayAmbientAnims(entity, false)
        SetPedCanLosePropsOnDamage(entity, false, 0)
        SetPedRelationshipGroupHash(entity, `PLAYER`)
        SetBlockingOfNonTemporaryEvents(entity, true)
        SetPedCanRagdollFromPlayerImpact(entity, false)
    elseif value.representativeCategory == "representativeVehicles" then
        SetVehicleCanBeUsedByFleeingPeds(entity, false)
    end

    -- target.addNetId(netId, value) -- Should works but sometimes isn't working correctly! Removes the target option after couple of seconds
    target.addEntity(entity, value) -- Same code as above but works...
end)
