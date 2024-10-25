--[[ Functions ]]

function PlaceFurniture(src, houseId, model, pos, rot, category)
    local soldHouses = Server.SoldHouses[houseId]
    local index = nil
    for key, value in pairs(soldHouses.furnitures) do
        if not value.isPlaced and value.model == model then
            index = key
            value.index = key
            value.isPlaced = true
            value.pos = pos
            value.rot = rot
            soldHouses.furnitures[key] = value
            break
        end
    end
    if index then
        local function CreateStashPass(model)
            return generateRandomString(10)
        end
        if isModelStash(model) then
            soldHouses.furnitures[index].stash_pass = soldHouses.furnitures[index].stash_pass or CreateStashPass()
            local stashId = string.format("ph_%s_%s", houseId, soldHouses.furnitures[index].stash_pass)
            Server.Functions.RegisterStash(src, stashId)
        elseif isModelWeedDry(model) then
            soldHouses.furnitures[index].dry_pass = soldHouses.furnitures[index].dry_pass or CreateStashPass()
        end
        Server.Functions.UpdateHouseFurnitures(soldHouses.furnitures, houseId)
        for _, source in pairs(soldHouses.players) do
            if Server.Functions.IsPlayerOnline(source) then
                TriggerClientEvent(_e("Client:Furniture:Place"), source,
                    index, model, pos, rot, category, {
                        stash_pass = soldHouses.furnitures[index]?.stash_pass,
                        dry_pass = soldHouses.furnitures[index]?.dry_pass
                    })
            end
        end
    end
end

function BuyFurniture(src, furniture, houseId)
    local xPlayer = Server.Functions.GetPlayerBySource(src)
    Server.Functions.PlayerRemoveMoney(xPlayer, "bank", furniture.price)
    furniture.isPlaced = false
    local soldHouses = Server.SoldHouses[houseId]
    if not soldHouses.furnitures then
        soldHouses.furnitures = {}
    end
    table.insert(soldHouses.furnitures, furniture)
    Server.Functions.UpdateHouseFurnitures(soldHouses.furnitures, houseId)
end

function OwnedFurnitureReSell(src, furniture, houseId)
    local xPlayer = Server.Functions.GetPlayerBySource(src)
    Server.Functions.PlayerAddMoney(xPlayer, "bank", furniture.price)
    local soldHouses = Server.SoldHouses[houseId]
    for key, value in pairs(soldHouses.furnitures or {}) do
        if not value.isPlaced and value.model == furniture.model then
            table.remove(soldHouses.furnitures, key)
            break
        end
    end
    Server.Functions.UpdateHouseFurnitures(soldHouses.furnitures, houseId)
end

function OwnedFurniturePutInStorage(src, furniture, houseId)
    local xPlayer = Server.Functions.GetPlayerBySource(src)
    local soldHouses = Server.SoldHouses[houseId]
    for key, value in pairs(soldHouses.furnitures or {}) do
        if value.index == furniture.index then
            soldHouses.furnitures[key].isPlaced = false
            break
        end
    end
    Server.Functions.UpdateHouseFurnitures(soldHouses.furnitures, houseId)
    for _, source in pairs(soldHouses.players) do
        if Server.Functions.IsPlayerOnline(source) then
            TriggerClientEvent(_e("Client:Furniture:PutInStorage"), source, furniture.index)
        end
    end
end

--[[ Callbacks ]]

lib.callback.register(_e("Server:PlaceFurniture"), function(source, furniture, houseId)
    local src = source
    if not Utils.DefaultHouses[houseId] then
        return ({ error = locale("house_not_found") })
    end
    if not Server.Functions.PlayerIsGuestInHouse(src, houseId) then
        return ({ error = locale("not_own_house") })
    end
    local model = furniture.model
    local pos = furniture.pos
    local rot = furniture.rot
    local category = furniture.category
    PlaceFurniture(src, houseId, model, pos, rot, category)
    return ({})
end)

lib.callback.register(_e("Server:BuyFurniture"), function(source, furniture, houseId)
    local src = source
    if not Utils.DefaultHouses[houseId] then
        return ({ error = locale("house_not_found") })
    end
    if not Server.Functions.PlayerIsGuestInHouse(src, houseId) then
        return ({ error = locale("not_own_house") })
    end
    local xPlayerBalance = Server.Functions.GetPlayerBalance("bank", src)
    if xPlayerBalance < tonumber(furniture.price) then
        return ({ error = locale("dont_have_enough_money", furniture.price) })
    end
    BuyFurniture(src, furniture, houseId)
    return ({})
end)

lib.callback.register(_e("Server:OwnedFurnitureReSell"), function(source, furniture, houseId)
    local src = source
    if not Utils.DefaultHouses[houseId] then
        return ({ error = locale("house_not_found") })
    end
    if not Server.Functions.PlayerIsGuestInHouse(src, houseId) then
        return ({ error = locale("not_own_house") })
    end
    OwnedFurnitureReSell(src, furniture, houseId)
    return ({})
end)

lib.callback.register(_e("Server:OwnedFurniturePutInStorage"), function(source, furniture, houseId)
    local src = source
    if not Utils.DefaultHouses[houseId] then
        return ({ error = locale("house_not_found") })
    end
    if not Server.Functions.PlayerIsGuestInHouse(src, houseId) then
        return ({ error = locale("not_own_house") })
    end
    OwnedFurniturePutInStorage(src, furniture, houseId)
    return ({})
end)
