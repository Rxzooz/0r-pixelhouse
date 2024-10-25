-- Register "useCreateHouse" command and open create house panel
lib.addCommand(Config.Commands.useCreateHouse, {
    help = "Create a new pixel house",
}, function(source, args, raw)
    local src = source
    if IsPlayerAceAllowed(src, "command") then
        TriggerClientEvent(_e("Client:OpenCreateHousePanel"), src)
    elseif Config.RealEstate.enable then
        local xPlayer = Server.Functions.GetPlayerBySource(src)
        local xPlayerJob = nil
        if Utils.Framework == "qb" then
            xPlayerJob = xPlayer?.PlayerData?.job?.name
        else
            xPlayerJob = xPlayer?.job?.name
        end
        if Config.RealEstate.jobs[xPlayerJob] then
            TriggerClientEvent(_e("Client:OpenCreateHousePanel"), src)
        end
    end
end)

-- Register "useAnswerDoorBell" command
lib.addCommand(Config.Commands.useAnswerDoorBell, {
    help = "Let the player who rings the bell into the house",

}, function(source, args, raw)
    local src = source
    TriggerClientEvent(_e("Client:AnswerDoorBell"), src)
end)

-- Register "Config.Tablet.itemName" usable item
if Config.OpenPanelWithTablet.active then
    Resmon.Lib.RegisterUsableItem(Config.OpenPanelWithTablet.itemName, function(source)
        TriggerClientEvent(_e("Client:OpenMainPanel"), source)
    end)
end
