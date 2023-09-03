---@class utility_server
local utility = {}

---@param source string | number
function utility.cheatDetected(source)
    print(("[^1CHEATING^7] Player (^5%s^7) with the identifier of (^5%s^7) is detected ^1cheating^7!"):format(source, GetPlayerIdentifierByType(source --[[@as string]], "license")))
end

---@class utility
---@field makeVehicleEmptyOfPassengers fun(vehicleEntity: number, seatsToEmpty?: number | number[]): boolean
utility.makeVehicleEmptyOfPassengers = ESX.OneSync.MakeVehicleEmptyOfPassengers

return utility
