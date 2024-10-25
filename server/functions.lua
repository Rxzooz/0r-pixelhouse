--[[ Server ]]

Server = {
    Framework = Utils.Functions.GetFramework(),
    Functions = {},
    Players = {},
    ---@type table<number, SoldHouseType>
    SoldHouses = {},
    GeneratedSeeds = {},
    loaded = false,
}

--[[ Core Functions ]]

--- Function that executes database queries
---
--- @param query: The SQL query to execute
--- @param params: Parameters for the SQL query (in table form)
--- @param type ("insert" | "update" | "query" | "scalar" | "single" | "prepare"): Parameters for the SQL query (in table form)
--- @return query any Results of the SQL query
function Server.Functions.ExecuteSQLQuery(query, params, type)
    type = type or "query"
    return MySQL[type].await(query, params)
end

function Server.Functions.SendNotify(source, title, type, duration, icon, text)
    if not duration then duration = 1000 end
    if not Utils.Functions.CustomNotify(title, type, text, duration, icon) then
        if Utils.Functions.HasResource("ox_lib") then
            TriggerClientEvent("ox_lib:notify", source, {
                title = title,
                description = text,
                type = type,
                icon = icon,
                duration = duration
            })
        elseif Utils.Framework == "qb" then
            TriggerClientEvent("QBCore:Notify", source, title, type)
        elseif Utils.Framework == "esx" then
            TriggerClientEvent("esx:showNotification", source, title, type, duration)
        end
    end
end

function Server.Functions.GetPlayerBySource(source)
    local source = tonumber(source)
    if Utils.Framework == "esx" then
        return Server.Framework.GetPlayerFromId(source)
    elseif Utils.Framework == "qb" then
        return Server.Framework.Functions.GetPlayer(source)
    end
end

function Server.Functions.GetPlayerSourceByIdentifier(identifier)
    local source = nil
    if Utils.Framework == "esx" then
        local xPlayer = Server.Framework.GetPlayerFromIdentifier(identifier)
        if xPlayer then
            source = xPlayer.source
        end
    elseif Utils.Framework == "qb" then
        local xPlayer = Server.Framework.Functions.GetPlayerByCitizenId(identifier)
        if xPlayer and xPlayer.PlayerData then
            source = xPlayer.PlayerData.source
        end
    end
    return source
end

function Server.Functions.GetPlayerIdentity(source)
    if Utils.Framework == "qb" then
        return Server.Framework.Functions.GetPlayer(source)?.PlayerData?.citizenid
    elseif Utils.Framework == "esx" then
        return Server.Framework.GetPlayerFromId(source)?.identifier
    end
end

function Server.Functions.GetPlayerCharacterName(source)
    local xPlayer = nil
    if Utils.Framework == "esx" then
        xPlayer = Server.Framework.GetPlayerFromId(source)
        return xPlayer.name
    elseif Utils.Framework == "qb" then
        xPlayer = Server.Framework.Functions.GetPlayer(source)
        return xPlayer.PlayerData.charinfo.firstname .. " " .. xPlayer.PlayerData.charinfo.lastname
    end
end

function Server.Functions.GetPlayerBalance(type, source)
    local xPlayer = nil
    if Utils.Framework == "esx" then
        xPlayer = Server.Framework.GetPlayerFromId(source)
        type = (type == "cash") and "money" or type
        return xPlayer.getAccount(type).money
    elseif Utils.Framework == "qb" then
        xPlayer = Server.Framework.Functions.GetPlayer(source)
        return xPlayer.PlayerData.money[type]
    end
end

function Server.Functions.IsPlayerOnline(source)
    if Utils.Framework == "qb" then
        return Server.Framework.Functions.GetPlayer(source)
    elseif Utils.Framework == "esx" then
        return Server.Framework.GetPlayerFromId(source)
    end
end

function Server.Functions.PlayerRemoveMoney(Player, type, amount)
    if Utils.Framework == "qb" then
        local result = Player.Functions.RemoveMoney(type, tonumber(amount), cache.resource)
        return result
    elseif Utils.Framework == "esx" then
        type = type == "cash" and "money" or type
        Player.removeAccountMoney(type, tonumber(amount))
        return true
    end
end

function Server.Functions.PlayerAddMoney(Player, type, amount)
    if Utils.Framework == "qb" then
        local result = Player.Functions.AddMoney(type, tonumber(amount), cache.resource)
        return result
    elseif Utils.Framework == "esx" then
        type = type == "cash" and "money" or type
        Player.addAccountMoney(type, tonumber(amount))
        return true
    end
end

function Server.Functions.DoesPlayerHaveMoney(source, amount)
    local balance = Server.Functions.GetPlayerBalance("bank", source)
    return balance >= amount
end

--[[ Script Functions ]]

function Server.Functions.OnPlayerLogout(source)
    local src = source
    local player = Server.Players[src]
    if player then
        local houseId = player.houseId
        if houseId then
            local house = Server.SoldHouses[houseId]
            if house then
                for key, value in pairs(house.players or {}) do
                    if value == src then
                        house.players[key] = nil
                        break
                    end
                end
            end
        end
    end
    Server.Players[src] = nil
end

function Server.Functions.GetDefaultHouses()
    local result = Resmon.Lib.PixelHouse.GetDefaultHouses(Config.Houses)
    local count = 0
    for key, value in pairs(result) do
        count += 1
        if type(value?.meta) ~= "table" then
            value.meta = json.decode(value?.meta or "{}")
        end
    end
    Utils.DefaultHouses = result
    lib.print.info(string.format("%s Houses loaded.", count))
end

function Server.Functions.GetSoldHouses()
    Server.SoldHouses = {}
    local result = Resmon.Lib.PixelHouse.GetSoldHouses()
    if result then
        for _, row in pairs(result) do
            Server.SoldHouses[row.houseId] = row
        end
    end
    return Server.SoldHouses
end

function Server.Functions.GetGeneratedSeed()
    local function _file()
        local filePath = "./data/design_seeds.json"
        local loadedFile = LoadResourceFile(cache.resource, filePath)
        if loadedFile then
            return json.decode(loadedFile)
        end
        return {}
    end
    Server.GeneratedSeeds = _file()
end

function Server.Functions.GetPlayerHouses(source)
    local soldHouses = Server.SoldHouses
    local identity = Server.Functions.GetPlayerIdentity(source)
    local playerHouses = {}
    for _, house in pairs(soldHouses) do
        if Server.Functions.PlayerIsOwnerInHouse(source, house.houseId) then
            playerHouses[house.houseId] = house
        end
    end
    return playerHouses
end

function Server.Functions.GetPlayerHouseCount(src)
    local playerHouses = Server.Functions.GetPlayerHouses(src)
    local count = 0
    for key, value in pairs(playerHouses) do
        count += 1
    end
    return count
end

function Server.Functions.GetPlayerGuestHouses(source)
    local soldHouses = Server.SoldHouses
    local identity = Server.Functions.GetPlayerIdentity(source)
    local guestHouses = {}
    for _, house in pairs(soldHouses) do
        if not Server.Functions.PlayerIsOwnerInHouse(source, house.houseId) then
            if Server.Functions.PlayerIsGuestInHouse(identity, house.houseId) then
                guestHouses[house.houseId] = house
            end
        end
    end
    return guestHouses
end

function Server.Functions.IsHouseSold(houseId)
    return Server.SoldHouses[houseId]
end

function Server.Functions.OnNewHouseSold(src, houseId, type, owner, owner_name)
    Server.Functions.ExecuteSQLQuery(
        "INSERT INTO `0resmon_ph_owned_houses` (houseId, type, owner, owner_name) VALUES (?, ?, ?, ?)",
        { houseId, type, owner, owner_name },
        "insert"
    )
    local result = {
        houseId = houseId,
        type = type,
        owner = owner,
        owner_name = owner_name,
        options = {},
        permissions = {},
        indicators = {},
        furnitures = {},
        players = {},
    }
    Server.SoldHouses[houseId] = result
    TriggerClientEvent(_e("Client:SetPlayerHouses"), src, Server.Functions.GetPlayerHouses(src))
    TriggerClientEvent(_e("Client:OnUpdateHouseBlip"), -1, src, houseId, "own", Server.SoldHouses)
end

function Server.Functions.ReceiptNewSale(src, houseId, houseType, price)
    local xPlayer = Server.Functions.GetPlayerBySource(src)
    if xPlayer then
        if Server.Functions.PlayerRemoveMoney(xPlayer, "bank", price) then
            local owner = Server.Functions.GetPlayerIdentity(src)
            local owner_name = Server.Functions.GetPlayerCharacterName(src)
            Server.Functions.OnNewHouseSold(src, houseId, houseType, owner, owner_name)
            return true
        end
    end
    return false
end

function Server.Functions.PlayerIsGuestInHouse(identity, houseId)
    local identity = identity
    if type(identity) == "number" then
        identity = Server.Functions.GetPlayerIdentity(identity)
    end
    local soldHouses = Server.SoldHouses[houseId]
    if not soldHouses then return false end
    if Server.Functions.PlayerIsOwnerInHouse(identity, houseId) then
        return true
    end
    for _, value in pairs(soldHouses.permissions) do
        if value.user == identity then
            return true
        end
    end
    return false
end

function Server.Functions.PlayerIsOwnerInHouse(identity, houseId)
    local identity = identity
    if type(identity) == "number" then
        identity = Server.Functions.GetPlayerIdentity(identity)
    end
    local soldHouses = Server.SoldHouses[houseId]
    if not soldHouses then return false end
    return soldHouses.owner == identity
end

function Server.Functions.SetPlayerMeta(src, key, value)
    local tree = "inside"
    if Utils.Framework == "qb" then
        local xPlayer = Server.Framework.Functions.GetPlayer(src)
        if xPlayer then
            local insideMeta = xPlayer?.PlayerData?.metadata?[tree] or {}
            insideMeta[key] = value
            return xPlayer.Functions.SetMetaData(tree, insideMeta)
        end
        return false
    else
        local xPlayer = Server.Framework.GetPlayerFromId(src)
        if not Config.MetaKeys or
            not xPlayer?.getMeta or
            not xPlayer?.setMeta
        then
            return false
        end
        if xPlayer then
            local insideMeta = xPlayer.getMeta(tree)
            if not insideMeta then
                insideMeta = {}
            end
            insideMeta[key] = value
            return xPlayer.setMeta(tree, insideMeta)
        end
        return false
    end
end

function Server.Functions.RemovePlayerMeta(src, key)
    local tree = "inside"
    if Utils.Framework == "qb" then
        local xPlayer = Server.Framework.Functions.GetPlayer(src)
        if xPlayer then
            local insideMeta = xPlayer?.PlayerData?.metadata?[tree] or {}
            insideMeta[key] = nil
            return xPlayer.Functions.SetMetaData(tree, insideMeta)
        end
        return false
    else
        local xPlayer = Server.Framework.GetPlayerFromId(src)
        if not Config.MetaKeys or
            not xPlayer?.getMeta or
            not xPlayer?.setMeta
        then
            return false
        end
        if xPlayer then
            local insideMeta = xPlayer.getMeta(tree, {})
            if not insideMeta then
                insideMeta = {}
            end
            insideMeta[key] = nil
            return xPlayer.setMeta(tree, insideMeta)
        end
        return false
    end
end

function Server.Functions.AddPlayerToHouse(src, houseId)
    local soldHouses = Server.SoldHouses[houseId]
    if soldHouses then
        if not soldHouses.players then
            soldHouses.players = {}
        end
        table.insert(soldHouses.players, src)
    end
    Server.Functions.SetPlayerMeta(src, "pixelhouse", houseId)
    if not Server.Players[src] then
        Server.Players[src] = {}
    end
    Server.Players[src].houseId = houseId
end

function Server.Functions.RemovePlayerToHouse(src, houseId)
    local soldHouses = Server.SoldHouses[houseId]
    if soldHouses then
        for i = #soldHouses.players, 1, -1 do
            if soldHouses.players[i] == src then
                table.remove(soldHouses.players, i)
                break
            end
        end
    end
    Server.Functions.RemovePlayerMeta(src, "pixelhouse")
    if Server.Players[src] then
        Server.Players[src].houseId = nil
    end
end

function Server.Functions.AddPlayerToGarage(src, houseId)
    local soldHouses = Server.SoldHouses[houseId]
    if soldHouses then
        if not soldHouses.garage_players then
            soldHouses.garage_players = {}
        end
        table.insert(soldHouses.garage_players, src)
    end
end

function Server.Functions.RemovePlayerToGarage(src, houseId)
    local soldHouses = Server.SoldHouses[houseId]
    if soldHouses and soldHouses.garage_players then
        for key, source in pairs(soldHouses.garage_players) do
            if source == src then
                table.remove(soldHouses.garage_players, key)
                break
            end
        end
    end
end

function Server.Functions.RegisterStash(src, stashId)
    local slots = Config.StashOptions.slots
    local maxWeight = Config.StashOptions.maxWeight
    if not Utils.Functions.CustomInventory.RegisterStash(src, stashId, {
            maxWeight = maxWeight,
            slots = slots,
        })
    then
        if Utils.Functions.HasResource("ox_inventory") then
            exports.ox_inventory:RegisterStash(stashId, stashId,
                slots, maxWeight,
                nil, false
            )
        elseif Utils.Functions.HasResource("qs-inventory") then
            -- exports["qs-inventory"]:RegisterStash(src, stashId, slots, maxWeight)
        elseif Utils.Functions.HasResource("origen_inventory") then
            exports.origen_inventory:RegisterStash(stashId, {
                label = stashId,
                slots = slots,
                weight = maxWeight
            })
        end
    end
end

function Server.Functions.RegisterFurnituresToStash(src, houseId)
    local House = Server.SoldHouses[houseId]
    if House.furnitures then
        local function CreateStashPass()
            return generateRandomString(10)
        end
        for _, value in pairs(House.furnitures or {}) do
            if isModelStash(value.model) then
                value.stash_pass = value.stash_pass or CreateStashPass()
                local stashId = string.format("ph_%s_%s", houseId, value.stash_pass)
                Server.Functions.RegisterStash(src, stashId)
            end
        end
    end
end

---@param src number
---@param houseId number
function Server.Functions.GetIntoHouse(src, houseId, unauthorized)
    local xPlayerIdentity = Server.Functions.GetPlayerIdentity(src)
    local houseSQL        = Utils.Functions.deepCopy(Server.SoldHouses[houseId])
    local house           = Utils.Functions.deepCopy(Utils.DefaultHouses[houseId])

    local inHouse         = house
    inHouse.houseId       = houseId
    inHouse.owner         = houseSQL.owner == xPlayerIdentity
    inHouse.owner_name    = houseSQL.owner_name
    inHouse.guest         = Server.Functions.PlayerIsGuestInHouse(xPlayerIdentity, houseId)
    inHouse.options       = houseSQL.options
    inHouse.permissions   = houseSQL.permissions
    inHouse.furnitures    = houseSQL.furnitures
    inHouse.indicators    = houseSQL.indicators
    inHouse.type          = houseSQL.type
    local coords          = Config.InteriorHouseTypes[string.lower(inHouse.type)].enter_coords
    Server.Functions.AddPlayerToHouse(src, houseId)
    Server.Functions.RegisterFurnituresToStash(src, houseId)
    local PlayerPedId = GetPlayerPed(src)
    SetEntityCoords(PlayerPedId, coords.x, coords.y, coords.z)
    SetEntityHeading(PlayerPedId, coords.w)
    SetPlayerRoutingBucket(src, tonumber("22" .. houseId))
    TriggerClientEvent(_e("Client:OnPlayerIntoHouse"), src, inHouse, unauthorized)
end

---@param src number
---@param houseId number
function Server.Functions.LeaveHouse(src, houseId)
    Server.Functions.RemovePlayerToHouse(src, houseId)
    local house = Utils.DefaultHouses[houseId]
    local coords = house?.door_coords or { 0.0, 0.0, 0.0 }
    local playerPed = GetPlayerPed(src)
    local bucketId = 0
    SetEntityCoords(playerPed, coords.x, coords.y, coords.z)
    SetEntityHeading(playerPed, coords.w or 0.0)
    SetPlayerRoutingBucket(src, bucketId)
    TriggerClientEvent(_e("Client:OnPlayerLeaveHouse"), src)
end

function Server.Functions.GetHouseDetails(src, houseId)
    local xPlayerIdentity = Server.Functions.GetPlayerIdentity(src)
    local inHouse         = Utils.Functions.deepCopy(Server.SoldHouses[houseId])
    inHouse.houseId       = houseId
    inHouse.owner         = Server.Functions.PlayerIsOwnerInHouse(src, houseId)
    inHouse.guest         = Server.Functions.PlayerIsGuestInHouse(xPlayerIdentity, houseId)
    return inHouse
end

function Server.Functions.UpdateHouseOptions(options, houseId)
    local House = Server.SoldHouses[houseId]
    for _, source in pairs(House.players) do
        if Server.Functions.IsPlayerOnline(source) then
            local inHouse = Server.Functions.GetHouseDetails(source, houseId)
            TriggerClientEvent(_e("Client:OnChangeHouseDetails"), source, inHouse)
        end
    end
    local options = Utils.Functions.deepCopy(options)
    options = json.encode(options) or "{}"
    Server.Functions.ExecuteSQLQuery(
        "UPDATE `0resmon_ph_owned_houses` SET options = ? WHERE houseId = ?",
        { options, houseId },
        "update"
    )
end

function Server.Functions.UpdateHouseLights(state, houseId)
    local House = Server.SoldHouses[houseId]
    if not House then return end
    if not House.options then
        House.options = {}
    end
    House.options.lights = state
    Server.Functions.UpdateHouseOptions(House.options, houseId)
    for _, source in pairs(House.players) do
        if Server.Functions.IsPlayerOnline(source) then
            TriggerClientEvent(_e("Client:SetHouseLights"), source, state)
        end
    end
end

function Server.Functions.UpdateHouseStairs(state, houseId)
    local House = Server.SoldHouses[houseId]
    if not House then return end
    if not House.options then
        House.options = {}
    end
    House.options.stairs = state
    Server.Functions.UpdateHouseOptions(House.options, houseId)
    for _, source in pairs(House.players) do
        if Server.Functions.IsPlayerOnline(source) then
            TriggerClientEvent(_e("Client:SetHouseStairs"), source, House.type, state)
        end
    end
end

function Server.Functions.UpdateHouseRooms(state, houseId)
    local House = Server.SoldHouses[houseId]
    if not House then return end
    if not House.options then
        House.options = {}
    end
    House.options.rooms = state
    Server.Functions.UpdateHouseOptions(House.options, houseId)
    for _, source in pairs(House.players) do
        if Server.Functions.IsPlayerOnline(source) then
            TriggerClientEvent(_e("Client:SetHouseRooms"), source, House.type, state)
        end
    end
end

function Server.Functions.UpdateHouseIndicator(type, unit, houseId)
    local House = Server.SoldHouses[houseId]
    if not House then return end
    if not House.indicators then
        House.indicators = {}
    end
    if not House.indicators[type] then
        House.indicators[type] = 0
    end
    House.indicators[type] = House.indicators[type] + unit
    -- [[ Update ]]
    CreateThread(function()
        for _, source in pairs(House.players) do
            if Server.Functions.IsPlayerOnline(source) then
                local inHouse = Server.Functions.GetHouseDetails(source, houseId)
                TriggerClientEvent(_e("Client:OnChangeHouseDetails"), source, inHouse)
            end
        end
        local indicators = Utils.Functions.deepCopy(House.indicators)
        indicators = json.encode(indicators) or "{}"
        Server.Functions.ExecuteSQLQuery(
            "UPDATE `0resmon_ph_owned_houses` SET indicators = ? WHERE houseId = ?",
            { indicators, houseId },
            "update"
        )
    end)
    return House.indicators[type]
end

function Server.Functions.UpdateHouseTint(color, houseId)
    local House = Server.SoldHouses[houseId]
    if not House then return end
    if not House.options then
        House.options = {}
    end
    House.options.tint = color
    Server.Functions.UpdateHouseOptions(House.options, houseId)
    for _, source in pairs(House.players) do
        if Server.Functions.IsPlayerOnline(source) then
            TriggerClientEvent(_e("Client:SetHouseWallColor"), source, House.type, color)
        end
    end
end

function Server.Functions.UpdateHousePermissions(permissions, houseId)
    local House = Server.SoldHouses[houseId]
    for _, source in pairs(House.players) do
        if Server.Functions.IsPlayerOnline(source) then
            local inHouse = Server.Functions.GetHouseDetails(source, houseId)
            TriggerClientEvent(_e("Client:OnChangeHouseDetails"), source, inHouse)
        end
    end
    local permissions = Utils.Functions.deepCopy(permissions)
    permissions = json.encode(permissions) or "{}"
    Server.Functions.ExecuteSQLQuery(
        "UPDATE `0resmon_ph_owned_houses` SET permissions = ? WHERE houseId = ?",
        { permissions, houseId },
        "update"
    )
end

function Server.Functions.UpdateHouseFurnitures(furnitures, houseId)
    local House = Server.SoldHouses[houseId]
    for _, source in pairs(House.players) do
        if Server.Functions.IsPlayerOnline(source) then
            local inHouse = Server.Functions.GetHouseDetails(source, houseId)
            TriggerClientEvent(_e("Client:OnChangeHouseDetails"), source, inHouse)
        end
    end
    local furnitures = Utils.Functions.deepCopy(furnitures)
    for key, value in pairs(furnitures) do
        if value.objectId then
            furnitures[key].objectId = nil
        end
        if value.index then
            furnitures[key].index = nil
        end
    end
    furnitures = json.encode(furnitures) or "{}"
    Server.Functions.ExecuteSQLQuery(
        "UPDATE `0resmon_ph_owned_houses` SET furnitures = ? WHERE houseId = ?",
        { furnitures, houseId },
        "update"
    )
end

function Server.Functions.UpdateHouseOwner(src, targetIdentity, houseId)
    local function GetGuestInfo(permissions, identity)
        for _, value in pairs(permissions) do
            if value.user == identity then
                return value
            end
        end
        return {}
    end
    local xPlayerIdentity = Server.Functions.GetPlayerIdentity(src)
    local xPlayerName = Server.Functions.GetPlayerCharacterName(src)
    local House = Server.SoldHouses[houseId]
    local GuestInfo = GetGuestInfo(House.permissions, targetIdentity)
    -->
    for key, perm in pairs(House.permissions) do
        if perm.user == targetIdentity then
            table.remove(House.permissions, key)
            break
        end
    end
    table.insert(House.permissions, {
        user = xPlayerIdentity,
        playerName = xPlayerName,
    })
    House.owner_name = GuestInfo?.playerName
    House.owner = targetIdentity
    Server.Functions.ExecuteSQLQuery(
        "UPDATE `0resmon_ph_owned_houses` SET owner = ?, owner_name = ?, permissions = ? WHERE houseId = ?",
        { targetIdentity, GuestInfo?.playerName, json.encode(House.permissions), houseId },
        "update"
    )
    local xNewOwnerSource = Server.Functions.GetPlayerSourceByIdentifier(targetIdentity)
    if xNewOwnerSource then
        TriggerClientEvent(_e("Client:OnUpdateGuestHouses"), xNewOwnerSource, houseId, nil)
        TriggerClientEvent(_e("Client:OnUpdateOwnedHouses"), xNewOwnerSource, houseId, true)
        Server.Functions.SendNotify(xNewOwnerSource, locale("owner_transfered_house"), "success", 2500)
    end
    TriggerClientEvent(_e("Client:OnUpdateGuestHouses"), src, houseId, true)
    TriggerClientEvent(_e("Client:OnUpdateOwnedHouses"), src, houseId, nil)
    Server.Functions.SendNotify(src, locale("owner_transfered_house"), "success", 2500)
    for _, source in pairs(House.players) do
        if Server.Functions.IsPlayerOnline(source) then
            local inHouse = Server.Functions.GetHouseDetails(source, houseId)
            TriggerClientEvent(_e("Client:OnChangeHouseDetails"), source, inHouse)
        end
    end
end

function Server.Functions.GivePermToTarget(src, targetId, houseId)
    local xTargetIdentity = Server.Functions.GetPlayerIdentity(targetId)
    local xTargetName = Server.Functions.GetPlayerCharacterName(targetId)
    local house = Server.SoldHouses[houseId]
    local newPerm = {
        user = xTargetIdentity,
        playerName = xTargetName,
    }
    table.insert(house.permissions, newPerm)
    Server.Functions.UpdateHousePermissions(house.permissions, houseId)
    Server.Functions.SendNotify(src, locale("gived_perm_to_player"), "success")
    TriggerClientEvent(_e("Client:OnUpdateHouseGuest"), targetId, houseId, true)
    return newPerm
end

function Server.Functions.DeletePermToTarget(src, userId, houseId)
    local xTargetIdentity = userId
    local house = Server.SoldHouses[houseId]
    for key, perm in pairs(house.permissions) do
        if perm.user == xTargetIdentity then
            table.remove(house.permissions, key)
            break
        end
    end
    Server.Functions.UpdateHousePermissions(house.permissions, houseId)
    Server.Functions.SendNotify(src, locale("deleted_perm_to_player"), "success")
    local xTargetSource = Server.Functions.GetPlayerSourceByIdentifier(xTargetIdentity)
    if xTargetSource then
        TriggerClientEvent(_e("Client:OnUpdateHouseGuest"), xTargetSource, houseId, nil)
    end
    return newPerm
end

function Server.Functions.LeaveHousePermanently(src, houseId)
    local house = Server.SoldHouses[houseId]
    Server.Functions.ExecuteSQLQuery(
        "DELETE FROM `0resmon_ph_owned_houses` WHERE houseId = ?",
        { houseId },
        "query"
    )
    local players = Utils.Functions.deepCopy(house.players)
    for _, source in pairs(players) do
        if Server.Functions.IsPlayerOnline(source) then
            Server.Functions.LeaveHouse(source, houseId)
            TriggerClientEvent(_e("Client:OnLeaveHousePermanently"), source, houseId)
        end
    end
    Server.SoldHouses[houseId] = nil
    TriggerClientEvent(_e("Client:OnUpdateHouseBlip"), -1, src, houseId, "sale", Server.SoldHouses)
    --[[ WEED DLC ]]
    if Utils.Functions.HasResource("0r-weed") then
        local zoneId = string.format("pixelhouse_%s", houseId)
        Server.Functions.ExecuteSQLQuery(
            "DELETE FROM `0resmon_weed_plants` WHERE zoneId = ?",
            { zoneId },
            "query"
        )
        Server.Functions.ExecuteSQLQuery(
            "DELETE FROM `0resmon_weed_dryers` WHERE zoneId = ?",
            { zoneId },
            "query"
        )
    end
end

function Server.Functions.SaveDesignSeeds()
    local filePath = "data/design_seeds.json"
    local seeds = Server.GeneratedSeeds
    seeds = json.encode(seeds or "{}")
    SaveResourceFile(cache.resource, filePath, seeds, -1)
end

function Server.Functions.GetGarageVehicles(src, houseId)
    local garage = string.format("pixel_garage_%s", houseId)
    local state = 3
    local vehicleTable = Utils.Framework == "qb" and "player_vehicles" or "owned_vehicles"
    local garageField = Utils.Framework == "qb" and "garage" or "parking"
    local stateField = Utils.Framework == "qb" and "state" or "stored"

    local checkGarageQuery = string.format("SELECT * FROM %s WHERE %s = ? AND %s = ?", vehicleTable, garageField,
        stateField)
    local garageVehicles = Server.Functions.ExecuteSQLQuery(checkGarageQuery, { garage, state }, "query")
    return garageVehicles
end

--[[ Core Thread]]
CreateThread(function()
    lib.locale()
    Server.loaded = false
    while Resmon == nil do
        Wait(100)
    end
    if not Server.Framework then
        for i = 1, 10, 1 do
            if Server.Framework then break end
            Server.Framework = Utils.Functions.GetFramework()
            Wait(100)
        end
    end
    Server.Functions.GetDefaultHouses()
    Server.Functions.GetSoldHouses()
    Server.Functions.GetGeneratedSeed()
    Server.loaded = true
end)
