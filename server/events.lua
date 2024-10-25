AddEventHandler("onResourceStop", function(resource)
    if resource == cache.resource then
        Server.Functions.SaveDesignSeeds()
    end
end)

RegisterNetEvent(_e("Server:OnPlayerLogout"), function()
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
end)

AddEventHandler("playerDropped", function()
    local src = source
    Server.Functions.OnPlayerLogout(src)
end)

RegisterNetEvent(_e("Server:LeaveHouse"), function(houseId)
    local src = source
    Server.Functions.LeaveHouse(src, houseId)
end)

RegisterNetEvent(_e("Server:SetPlayerRoutingBucket"), function(coords, bucket)
    local src = source
    local playerPedId = GetPlayerPed(src)
    bucket = tonumber(bucket)
    SetEntityCoords(playerPedId, coords.x, coords.y, coords.z)
    SetEntityHeading(playerPedId, coords.w)
    SetPlayerRoutingBucket(src, bucket or 0)
end)

RegisterNetEvent(_e("Server:SetPlayerMeta"), function(key, value)
    local src = source
    Server.Functions.SetPlayerMeta(src, key, value)
end)

RegisterNetEvent(_e("Server:RemovePlayerMeta"), function(key)
    local src = source
    if type(key) == "table" then
        for k, v in pairs(key) do
            Server.Functions.RemovePlayerMeta(src, v)
        end
        return
    end
    Server.Functions.RemovePlayerMeta(src, key)
end)

RegisterNetEvent(_e("Server:OpenStash"), function(stashId, options)
    local src = source
    if not Utils.Functions.CustomInventory.OpenInventory("stash", stashId, {
            maxWeight = options.maxWeight,
            slots = options.slots
        }, src)
    then
        if Utils.Functions.HasResource("qb-inventory") then
            if Config.NewInventoryQB then
                exports["qb-inventory"]:OpenInventory(src, stashId, {
                    maxweight = options.maxWeight,
                    slots = options.slots
                })
            else
                exports["qb-inventory"]:OpenInventory("stash", stashId, {
                    maxweight = options.maxWeight,
                    slots = options.slots
                }, src)
            end
        elseif Utils.Functions.HasResource("origen_inventory") then
            exports.origen_inventory:OpenInventory(src, "stash", stashId)
        end
    end
end)

RegisterNetEvent(_e("Server:UnauthorizedEntryNotify"), function(houseId)
    local src = source
    local House = Server.SoldHouses[houseId]
    if House then
        local xOwnerSource = Server.Functions.GetPlayerSourceByIdentifier(House.owner)
        if xOwnerSource then
            Server.Functions.SendNotify(
                xOwnerSource,
                locale("unauthorized_entry", houseId),
                "info",
                5000)
        end
    end
end)

RegisterNetEvent(_e("Server:PlayerRemoveItem"), function(itemName, count)
    local src = source
    local xPlayer = Server.Functions.GetPlayerBySource(src)
    Utils.Functions.PlayerRemoveItem(xPlayer, itemName, count)
end)

RegisterNetEvent(_e("Server:LeaveGarage"), function(houseId, plate)
    local src = source
    Server.Functions.RemovePlayerToGarage(src, houseId)
    Server.Functions.RemovePlayerMeta(src, "pixelgarage")
    local house = Utils.DefaultHouses[houseId]
    local coords = house?.garage_coords or { 0.0, 0.0, 0.0 }
    local playerPed = GetPlayerPed(src)
    local bucketId = 0
    SetEntityCoords(playerPed, coords.x, coords.y, coords.z)
    SetEntityHeading(playerPed, coords.w or 0.0)
    SetPlayerRoutingBucket(src, bucketId)
    TriggerClientEvent(_e("Client:OnPlayerLeaveGarage"), src, plate)
end)

RegisterNetEvent(_e("Server:RingOnDoor"), function(houseId)
    local src = source
    local guestName = Server.Functions.GetPlayerCharacterName(src)
    local soldHouse = Server.SoldHouses[houseId]
    if soldHouse then
        local inHousePlayers = soldHouse.players
        for _, source in pairs(soldHouse.players) do
            if Server.Functions.IsPlayerOnline(source) then
                TriggerClientEvent(_e("Client:RingOnDoor"), source, guestName, src, houseId)
            end
        end
    end
end)

lib.callback.register(_e("Server:GetSoldHouses"), function(source)
    while not Server.loaded do
        Wait(5)
    end
    return Server.SoldHouses
end)

lib.callback.register(_e("Server:GetDefaultHouses"), function(source)
    while not Server.loaded do
        Wait(5)
    end
    return Utils.DefaultHouses
end)

lib.callback.register(_e("Server:LoadPlayerData"), function(source)
    local xPlayer = Server.Functions.GetPlayerBySource(source)
    if xPlayer then
        return {
            ownedHouses = Server.Functions.GetPlayerHouses(source),
            guestHouses = Server.Functions.GetPlayerGuestHouses(source),
        }
    end
    return { guestHouses = {}, ownedHouses = {} }
end)

lib.callback.register(_e("Server:PurchaseHouse"), function(source, houseId, houseType)
    local House = Utils.DefaultHouses[houseId]
    if not House then
        return ({ error = locale("house_not_found") })
    end
    if Server.Functions.IsHouseSold(houseId) then
        TriggerClientEvent(_e("Client:OnUpdateSoldHouses"), source, Server.SoldHouses)
        return ({ error = locale("house_already_sold") })
    end
    if Config.MaxHouseLimitPerPlayer and Server.Functions.GetPlayerHouseCount(source) >= Config.MaxHouseLimitPerPlayer then
        return ({ error = locale("max_house_limit") })
    end
    if not Server.Functions.DoesPlayerHaveMoney(source, House.price) then
        return ({ error = locale("dont_have_enough_money", House.price) })
    end
    local result = Server.Functions.ReceiptNewSale(source, houseId, houseType, House.price)
    if not result then
        return ({ error = locale("fail_receipt") })
    end
    return {}
end)

lib.callback.register(_e("Server:GetIntoHouse"), function(source, houseId, unauthorized)
    if not Utils.DefaultHouses[houseId] or not Server.Functions.IsHouseSold(houseId) then
        return ({ error = locale("house_not_found") })
    end
    Server.Functions.GetIntoHouse(source, houseId, unauthorized)
    return {}
end)

lib.callback.register(_e("Server:UpdateHouseLights"), function(source, state, houseId)
    if not Utils.DefaultHouses[houseId] then
        return ({ error = locale("house_not_found") })
    end
    local xPlayerIdentity = Server.Functions.GetPlayerIdentity(source)
    if not Server.Functions.PlayerIsGuestInHouse(xPlayerIdentity, houseId) then
        return ({ error = locale("not_own_house") })
    end
    Server.Functions.UpdateHouseLights(state, houseId)
    return {}
end)

lib.callback.register(_e("Server:UpdateHouseStairs"), function(source, state, houseId)
    if not Utils.DefaultHouses[houseId] then
        return ({ error = locale("house_not_found") })
    end
    local xPlayerIdentity = Server.Functions.GetPlayerIdentity(source)
    if not Server.Functions.PlayerIsGuestInHouse(xPlayerIdentity, houseId) then
        return ({ error = locale("not_own_house") })
    end
    Server.Functions.UpdateHouseStairs(state, houseId)
    return {}
end)

lib.callback.register(_e("Server:UpdateHouseRooms"), function(source, state, houseId)
    if not Utils.DefaultHouses[houseId] then
        return ({ error = locale("house_not_found") })
    end
    local xPlayerIdentity = Server.Functions.GetPlayerIdentity(source)
    if not Server.Functions.PlayerIsGuestInHouse(xPlayerIdentity, houseId) then
        return ({ error = locale("not_own_house") })
    end
    Server.Functions.UpdateHouseRooms(state, houseId)
    return {}
end)

lib.callback.register(_e("Server:ChangeHouseTint"), function(source, color, houseId)
    if not Utils.DefaultHouses[houseId] then
        return ({ error = locale("house_not_found") })
    end
    local xPlayerIdentity = Server.Functions.GetPlayerIdentity(source)
    if not Server.Functions.PlayerIsGuestInHouse(xPlayerIdentity, houseId) then
        return ({ error = locale("not_own_house") })
    end
    Server.Functions.UpdateHouseTint(color, houseId)
    return {}
end)

lib.callback.register(_e("Server:AddPermission"), function(source, targetId, houseId)
    local xTarget = Server.Functions.GetPlayerBySource(targetId)
    if not xTarget then
        return ({ error = locale("player_not_found") })
    end
    if not Utils.DefaultHouses[houseId] then
        return ({ error = locale("house_not_found") })
    end
    if not Server.Functions.PlayerIsOwnerInHouse(source, houseId) then
        return ({ error = locale("not_own_house") })
    end
    local xTargetIdentity = Server.Functions.GetPlayerIdentity(targetId)
    if Server.Functions.PlayerIsGuestInHouse(xTargetIdentity, houseId) then
        return ({ error = locale("already_guest_house") })
    end
    local newPermission = Server.Functions.GivePermToTarget(source, targetId, houseId)
    return ({ state = newPermission })
end)

lib.callback.register(_e("Server:RemovePermission"), function(source, userId, houseId)
    if not Utils.DefaultHouses[houseId] then
        return ({ error = locale("house_not_found") })
    end
    if not Server.Functions.PlayerIsOwnerInHouse(source, houseId) then
        return ({ error = locale("not_own_house") })
    end
    if not Server.Functions.PlayerIsGuestInHouse(userId, houseId) then
        return ({ error = locale("already_not_guest_house") })
    end
    Server.Functions.DeletePermToTarget(source, userId, houseId)
    return ({})
end)

lib.callback.register(_e("Server:LeaveHousePermanently"), function(source, houseId)
    if not Utils.DefaultHouses[houseId] then
        return ({ error = locale("house_not_found") })
    end
    if not Server.Functions.PlayerIsOwnerInHouse(source, houseId) then
        return ({ error = locale("not_own_house") })
    end
    Server.Functions.LeaveHousePermanently(source, houseId)
    return ({})
end)

lib.callback.register(_e("Server:HouseOwnerTransfer"), function(source, targetIdentity, houseId)
    local xPlayerIdentity = Server.Functions.GetPlayerIdentity(source)
    if not Utils.DefaultHouses[houseId] then
        return ({ error = locale("house_not_found") })
    end
    if not Server.Functions.PlayerIsOwnerInHouse(source, houseId) then
        return ({ error = locale("not_own_house") })
    end
    if xPlayerIdentity == targetIdentity then
        return ({ error = "xD" })
    end
    if not Server.Functions.PlayerIsGuestInHouse(targetIdentity, houseId) then
        cb({ error = locale("already_not_guest_house") })
        return
    end
    Server.Functions.UpdateHouseOwner(source, targetIdentity, houseId)
    return ({})
end)

lib.callback.register(_e("Server:GenerateDesignSeed"), function(source, houseId)
    if not Utils.DefaultHouses[houseId] then
        return ({ error = locale("house_not_found") })
    end
    if not Server.Functions.PlayerIsOwnerInHouse(source, houseId) then
        return ({ error = locale("not_own_house") })
    end
    if not Server.GeneratedSeeds then
        Server.GeneratedSeeds = {}
    end
    local function GenerateUUID()
        local chars = "a01b23c45d67e89f"
        local uuid
        local isUnique
        repeat
            uuid = ""
            for i = 1, 16 do
                local randIndex = math.random(1, #chars)
                uuid = uuid .. chars:sub(randIndex, randIndex)
            end
            isUnique = true
            if Server.GeneratedDesignSeeds then
                isUnique = Server.GeneratedDesignSeeds[uuid]
            end
        until isUnique

        return uuid
    end
    local House = Server.SoldHouses[houseId]
    local xPlayerIdentity = Server.Functions.GetPlayerIdentity(source)
    local xPlayerName = Server.Functions.GetPlayerCharacterName(source)
    local newSeed = GenerateUUID()
    local furnitures = Utils.Functions.deepCopy(House?.furnitures)
    for key, value in pairs(furnitures) do
        if value.objectId then
            furnitures[key].objectId = nil
        end
        if value.index then
            furnitures[key].index = nil
        end
    end
    furnitures = json.encode(furnitures) or "{}"
    local _data = {
        creator = xPlayerIdentity,
        created_at = os.date("%Y-%m-%d %H:%M:%S"),
        type = House.type,
        design = furnitures
    }
    Server.GeneratedSeeds[newSeed] = _data
    return ({ state = newSeed })
end)

lib.callback.register(_e("Server:UseDesignSeed"), function(source, seed, houseId)
    if not Utils.DefaultHouses[houseId] then
        return ({ error = locale("house_not_found") })
    end
    if not Server.Functions.PlayerIsOwnerInHouse(source, houseId) then
        return ({ error = locale("not_own_house") })
    end
    if not Server.GeneratedSeeds then
        return ({ error = "Not found Server.GeneratedSeeds" })
    end
    seed = string.lower(seed)
    if not Server.GeneratedSeeds[seed] then
        return ({ error = locale("invalid_seed") })
    end
    local fSeed = Server.GeneratedSeeds[seed]
    local soldHouses = Server.SoldHouses[houseId]
    if fSeed.type ~= soldHouses.type then
        return ({ error = locale("not_use_diff_seed") })
    end
    soldHouses.furnitures = json.decode(fSeed?.design or "{}")
    Server.Functions.UpdateHouseFurnitures(soldHouses.furnitures, houseId)
    for _, source in pairs(soldHouses.players) do
        if Server.Functions.IsPlayerOnline(source) then
            TriggerClientEvent(_e("Client:Furniture:UseDesignSeed"), source)
        end
    end
    Server.GeneratedSeeds[seed] = nil
    return ({})
end)

lib.callback.register(_e("Server:BuyIndicator"), function(source, type, houseId)
    if not Utils.DefaultHouses[houseId] then
        return ({ error = locale("house_not_found") })
    end
    local xPlayer = Server.Functions.GetPlayerBySource(source)
    if not xPlayer then
        return ({ error = locale("player_not_found") })
    end
    local xPlayerIdentity = Server.Functions.GetPlayerIdentity(source)
    if not Server.Functions.PlayerIsGuestInHouse(xPlayerIdentity, houseId) then
        return ({ error = locale("not_own_house") })
    end
    if not Config.Indicators[type] then
        return ({ error = "Not found Indicator type" })
    end
    local House = Server.SoldHouses[houseId]
    local indicator = Config.Indicators[type]
    local unit = 100
    if House?.indicators[type] and House.indicators[type] + unit > indicator.maxValue then
        unit = indicator.maxValue - House.indicators[type]
        if unit <= 0 then
            return ({ error = locale("have_enough") })
        end
    end
    local price = unit * indicator.unitPrice
    if not Server.Functions.DoesPlayerHaveMoney(source, price) then
        return ({ error = locale("dont_have_enough_money", price) })
    end
    if Server.Functions.PlayerRemoveMoney(xPlayer, "bank", price) then
        Server.Functions.UpdateHouseIndicator(type, unit, houseId)

        exports.JD_logs:createLog({
          EmbedMessage = "**شراء بيت جديد**\nالبيت: ".. houseId .."\nالقيمة: ``$".. price .."``",
          player_id = source,
          channel = "houseBuy",
          screenshot = false
        })
    end
    return ({})
end)

lib.callback.register(_e("Server:PlayerHasItem"), function(source, item, count)
    count = count or 0
    local xPlayer = Server.Functions.GetPlayerBySource(source)
    if xPlayer then
        return (Utils.Functions.PlayerHasItem(xPlayer, item, count))
    end
    return (false)
end)

lib.callback.register(_e("Server:GetIntoGarage"), function(source, houseId)
    if not Utils.DefaultHouses[houseId] or not Server.Functions.IsHouseSold(houseId) then
        return ({ error = locale("house_not_found") })
    end
    local xPlayerIdentity = Server.Functions.GetPlayerIdentity(source)
    if not xPlayerIdentity then
        return ({ error = locale("player_not_found") })
    end
    if not Server.Functions.PlayerIsGuestInHouse(xPlayerIdentity, houseId) then
        return ({ error = locale("not_own_house") })
    end
    local vehicles = Server.Functions.GetGarageVehicles(source, houseId)
    local coords = Config.InteriorHouseGarage.coords.enter
    Server.Functions.AddPlayerToGarage(source, houseId)
    Server.Functions.SetPlayerMeta(source, "pixelgarage", houseId)
    local PlayerPedId = GetPlayerPed(source)
    SetEntityCoords(PlayerPedId, coords.x, coords.y, coords.z)
    SetEntityHeading(PlayerPedId, coords.w)
    SetPlayerRoutingBucket(source, tonumber("22" .. houseId))
    TriggerClientEvent(_e("Client:OnPlayerIntoGarage"), source, houseId, vehicles)
    return {}
end)

lib.callback.register(_e("Server:AddVehicleToGarage"), function(source, houseId, plate, mods)
    plate = string.match(plate, "^%s*(.-)%s*$")
    if not Utils.DefaultHouses[houseId] or not Server.Functions.IsHouseSold(houseId) then
        return ({ error = locale("house_not_found") })
    end
    local xPlayerIdentity = Server.Functions.GetPlayerIdentity(source)
    if not xPlayerIdentity then
        return ({ error = locale("player_not_found") })
    end
    if not Server.Functions.PlayerIsGuestInHouse(xPlayerIdentity, houseId) then
        return ({ error = locale("not_own_house") })
    end
    local vehicleQuery
    if Utils.Framework == "qb" then
        vehicleQuery = "SELECT citizenid FROM player_vehicles WHERE plate = ? LIMIT 1"
    else
        vehicleQuery = "SELECT owner FROM owned_vehicles WHERE plate = ? LIMIT 1"
    end
    local result = Server.Functions.ExecuteSQLQuery(vehicleQuery, { plate }, "scalar")
    local isOwned = result == xPlayerIdentity
    if not isOwned then
        return ({ error = locale("not_own_vehicle") })
    end
    local garage = string.format("pixel_garage_%s", houseId)
    local state = 3
    local vehicleTable = Utils.Framework == "qb" and "player_vehicles" or "owned_vehicles"
    local garageField = Utils.Framework == "qb" and "garage" or "parking"
    local stateField = Utils.Framework == "qb" and "state" or "stored"
    local modsFiled = Utils.Framework == "qb" and "mods" or "vehicle"
    local checkGarageQuery = string.format("SELECT * FROM %s WHERE %s = ? AND %s = ?", vehicleTable, garageField,
        stateField)
    local garageVehicles = Server.Functions.ExecuteSQLQuery(checkGarageQuery, { garage, state }, "query")
    local totalVehicleInGarage = #garageVehicles

    if totalVehicleInGarage >= #Config.InteriorHouseGarage.coords.vehicles then
        return ({ error = locale("no_more_room_garage") })
    end
    local updateVehicleQuery = string.format("UPDATE %s SET %s = ?, %s = ?, %s = ? WHERE plate = ?",
        vehicleTable, garageField, stateField, modsFiled)
    Server.Functions.ExecuteSQLQuery(updateVehicleQuery, { garage, state, json.encode(mods), plate }, "update")
    return {}
end)

lib.callback.register(_e("Server:TakeOutVehicleFromGarage"), function(source, plate, houseId)
    plate = string.match(plate, "^%s*(.-)%s*$")
    local vehicleTable = Utils.Framework == "qb" and "player_vehicles" or "owned_vehicles"
    local garageField = Utils.Framework == "qb" and "garage" or "parking"
    local stateField = Utils.Framework == "qb" and "state" or "stored"
    local queryParams = { plate }

    local vehicleQuery
    if stateField then
        vehicleQuery = string.format("SELECT * FROM %s WHERE plate = ? AND %s = 3 LIMIT 1", vehicleTable, stateField)
    else
        vehicleQuery = string.format("SELECT * FROM %s WHERE plate = ? AND %s = 3 LIMIT 1", vehicleTable, stateField)
    end

    local vehicleData = Server.Functions.ExecuteSQLQuery(vehicleQuery, queryParams, "query")

    if #vehicleData == 0 then
        return { error = locale("vehicle_not_found") }
    end

    local vehicleInfo = vehicleData[1]
    local state = 0

    local updateVehicleQuery
    if stateField then
        updateVehicleQuery = string.format("UPDATE %s SET %s = NULL, %s = ? WHERE plate = ?",
            vehicleTable, garageField, stateField)
        Server.Functions.ExecuteSQLQuery(updateVehicleQuery, { state, plate }, "update")
    else
        updateVehicleQuery = string.format("UPDATE %s SET %s = NULL WHERE plate = ?",
            vehicleTable, garageField)
        Server.Functions.ExecuteSQLQuery(updateVehicleQuery, { plate }, "update")
    end

    local soldHouses = Server.SoldHouses[houseId]
    if soldHouses then
        for key, playerSrc in pairs(soldHouses.garage_players) do
            if playerSrc ~= source then
                TriggerClientEvent(_e("Client:DeleteVehicleInGarage"), playerSrc, plate)
            end
        end
    end

    return { vehicleData = vehicleInfo }
end)


lib.callback.register(_e("Server:UpdateIndicator"), function(source, indicator, value, houseId)
    if not Utils.DefaultHouses[houseId] then
        return ({ error = locale("house_not_found") })
    end
    local xPlayer = Server.Functions.GetPlayerBySource(source)
    if not xPlayer then
        return ({ error = locale("player_not_found") })
    end
    if not Config.Indicators[indicator] then
        return ({ error = "Not found Indicator type" })
    end
    local House = Server.SoldHouses[houseId]
    if House?.indicators[indicator] and House.indicators[indicator] + value < 0 then
        return ({ error = locale("not_have_enough") })
    end
    Server.Functions.UpdateHouseIndicator(indicator, value, houseId)
    return ({})
end)

lib.callback.register(_e("Server:AnswerDoorBell"), function(source, guestSource, houseId)
    local House = Utils.DefaultHouses[houseId]

    if not House then
        return ({ error = locale("house_not_found") })
    end
    local xPlayer = Server.Functions.GetPlayerBySource(guestSource)
    if not xPlayer then
        return ({ error = locale("player_not_found") })
    end
    local xPlayerCoords = GetEntityCoords(GetPlayerPed(guestSource))
    if #(xPlayerCoords - vec3(House.door_coords.x, House.door_coords.y, House.door_coords.z)) > 2.5 then
        return ({ error = locale("player_not_found") })
    end
    Server.Functions.GetIntoHouse(guestSource, houseId, true)
    return ({})
end)

--[[ CCTV ]]

lib.callback.register(_e("Server:CCTV:Toggle"), function(source, state, houseId, coords)
    local House = Utils.DefaultHouses[houseId]
    if not House then
        return ({ error = locale("house_not_found") })
    end
    local bucketId = 0
    local coords = coords
    if not state then
        bucketId = tonumber("22" .. houseId)
    else
        local houseDoorCoords = House.door_coords
        coords = vec3(houseDoorCoords.x, houseDoorCoords.y, houseDoorCoords.z)
    end
    SetEntityCoords(GetPlayerPed(source), coords)
    SetPlayerRoutingBucket(source, bucketId)
    return ({})
end)

-- [[ Admin ]]

---@param source number
---@param data HouseType
---@return table
lib.callback.register(_e("Server:CreateNewHouse"), function(source, data)
    local data = data
    local insertQuery =
    "INSERT INTO `0resmon_ph_houses` (label, price, type, door_coords, garage_coords, coords_label, meta) VALUES (?, ?, ?, ?, ?, ?, ?)"
    local insertParams = {
        data.label,
        data.price,
        data.type,
        json.encode(data.door_coords or {}),
        data.garage_coords and json.encode(data.garage_coords) or nil,
        data.coords_label,
        json.encode({ image = data.image })
    }
    local insertedId = Server.Functions.ExecuteSQLQuery(insertQuery, insertParams, "insert")
    if insertedId then
        data.houseId = insertedId
        data.meta = {
            image = data.image
        }
        data.image = nil
        Utils.DefaultHouses[insertedId] = data
        TriggerClientEvent(_e("Client:SetDefaultHouses"), -1, Utils.DefaultHouses)
        return ({ state = insertedId })
    end
    return ({ error = "Could not be added to the database." })
end)
