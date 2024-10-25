--[[ Events ]]
RegisterNetEvent("esx:playerLoaded", function(xPlayer)
    Client.Functions.StartCore()
end)
RegisterNetEvent("esx:onPlayerLogout", function(xPlayer)
    Client.Functions.OnPlayerLogout()
    Client.Functions.StopCore()
end)
