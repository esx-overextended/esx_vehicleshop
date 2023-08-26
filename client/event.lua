---@param bagName string
---@return number?, number?
local function getEntityFromBag(bagName)
    local netId = tonumber(bagName:gsub("entity:", ""), 10)
    local doesNetIdExist, timeout = false, 0

    while not doesNetIdExist and timeout < 1000 do
        Wait(10)
        timeout += 1
        doesNetIdExist = NetworkDoesEntityExistWithNetworkId(netId)
    end

    if not doesNetIdExist then
        return ESX.Trace(("Statebag (^3%s^7) timed out after waiting %s ticks for entity creation on %s!"):format(bagName, timeout, key), "warning", true)
    end

    local entity = NetworkDoesEntityExistWithNetworkId(netId) and NetworkGetEntityFromNetworkId(netId)

    if not entity or entity == 0 then return end

    return entity, netId
end

AddStateBagChangeHandler("esx_vehicleshop:handleRepresentative", "", function(bagName, _, value)
    if type(value) ~= "table" then return end

    local entity, netId = getEntityFromBag(bagName)

    if not entity or not netId then return end

    SetEntityInvincible(entity, true)
    FreezeEntityPosition(entity, true)
    SetEntityCoords(entity, value.coords?.x, value.coords?.y, value.coords?.z, false, false, false, true)
    SetEntityHeading(entity, value.coords?.w)
    SetEntityProofs(entity, true, true, true, false, true, true, true, true)

    if value.representativeCategory == "RepresentativePeds" then
        SetPedDiesWhenInjured(entity, false)
        SetPedFleeAttributes(entity, 2, true)
        SetPedCanPlayAmbientAnims(entity, false)
        SetPedCanLosePropsOnDamage(entity, false, 0)
        SetPedRelationshipGroupHash(entity, `PLAYER`)
        SetBlockingOfNonTemporaryEvents(entity, true)
        SetPedCanRagdollFromPlayerImpact(entity, false)
    elseif value.representativeCategory == "RepresentativeVehicles" then
        SetVehicleCanBeUsedByFleeingPeds(entity, false)
    end

    -- Target.addNetId(netId, value) -- Should works but sometimes isn't! Removes the target after couple of seconds
    Target.addEntity(entity, value) -- Same code as above but works...
end)
