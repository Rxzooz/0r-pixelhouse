--[[ Events ]]
AddStateBagChangeHandler("isLoggedIn", nil, function(_, _, value)
    if value then
        Client.Functions.StartCore()
    else
        Client.Functions.OnPlayerLogout()
        Client.Functions.StopCore()
    end
end)
