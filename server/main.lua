local vehicles, categories

function RefreshVehiclesAndCategories()
    vehicles = MySQL.query.await("SELECT * FROM vehicles")
    categories = MySQL.query.await("SELECT * FROM vehicle_categories")
end

function GetVehiclesAndCategories()
    return vehicles, categories
end

MySQL.ready(function()
    RefreshVehiclesAndCategories()
end)
