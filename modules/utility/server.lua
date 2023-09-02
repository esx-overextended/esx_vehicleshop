---@class utility_server
local utility = {}

---@param source string | number
function utility.cheatDetected(source)
    print(("[^1CHEATING^7] Player (^5%s^7) with the identifier of (^5%s^7) is detected ^1cheating^7!"):format(source, GetPlayerIdentifierByType(source --[[@as string]], "license")))
end

---@param vehicleEntity number
---@param maxNoSeats number
---@return boolean (indicating whether the action was successfull or not)
function utility.makeVehicleEmptyOfPassengers(vehicleEntity, maxNoSeats)
    while DoesEntityExist(vehicleEntity) do
        local freeNoSeats = 0

        for i = -1, maxNoSeats - 2 do
            local pedAtSeat = GetPedInVehicleSeat(vehicleEntity, i)

            if DoesEntityExist(pedAtSeat) then
                TaskLeaveVehicle(pedAtSeat, vehicleEntity, 0)
            else
                freeNoSeats += 1
            end
        end

        if freeNoSeats == maxNoSeats then
            Wait(500)
            return true
        end

        Wait(0)
    end

    return false
end

return utility
