-- Exports the function "GetPlayerHouseId". This function returns the house ID of the player's current house.
-- If the player is inside a house, it gets the house ID of that house. Otherwise, it returns nil.
---@return number | nil
local function GetPlayerHouseId()
    return Client.Player?.inHouse?.houseId
end

-- Exports the function "GetPlayerHouse". This function returns the house the player is currently in.
-- If the player is inside a house, it gets the information of that house. Otherwise, it returns nil.
---@return InHouseType | nil
local function GetPlayerHouse()
    return Client.Player?.inHouse
end

-- Defines a local function "GetPlayerHouses". This function returns the houses owned by the player.
-- If the player owns any houses, it gets the list of those houses. Otherwise, it returns nil.
local function GetPlayerHouses()
    return Client.Player?.ownedHouses
end

-- Updates the specified indicator for a given house by adding or subtracting the provided value.
-- The `houseId` parameter specifies the ID of the house.
-- The `indicator` parameter specifies which indicator to update (e.g., "electricity", "power", "gas", or "water").
-- The `value` parameter specifies the amount to add to (positive value) or subtract from (negative value) the current indicator value.
-- The function returns the updated indicator value.
---@param houseId number
---@param indicator "electricity"|"power"|"gas"|"water"
---@param value number
---@return number
local function UpdateHouseIndicator(indicator, value)
    if Client.Player.inHouse then
        local response = Client.Functions.CallbackAwait(_e("Server:UpdateIndicator"),
            indicator, value, Client.Player.inHouse.houseId)
        if response.error then
            Client.Functions.SendNotify(locale("error", response.error), "error")
            return false
        end
        return true
    end
end

---Get available houses
---@return table
local function GetAvailableHouses()
    local defaultHouses = Client.Functions.GetDefaultHouses()
    local soldHouses = Client.Functions.GetSoldHouses()

    local soldHousesIds = {}
    for _, house in pairs(soldHouses) do
        if house ~= nil then
            table.insert(soldHousesIds, house.houseId)
        end
    end
    local availableHouses = {}
    for _, house in pairs(defaultHouses) do
        if house ~= nil and not lib.table.contains(soldHousesIds, house.houseId) then
            table.insert(availableHouses, house)
        end
    end
    return availableHouses
end

---@param houseId number
---@param houseType "square"|"rectangle"|"furnished"|"apa_v_mp_h"|nil
local function PurchaseHouse(houseId, houseType)
    if not houseId then return false end
    if not houseType then
        houseType = "furnished"
    end
    Client.Functions.Callback(_e("Server:PurchaseHouse"), function(response)
        if not response.error then
            Client.Functions.SendNotify(locale("house_purchased", houseId), "success")
            return true
        else
            Client.Functions.SendNotify(locale("error", response.error), "error")
            return false
        end
    end, houseId, houseType)
end

exports("GetPlayerHouseId", GetPlayerHouseId)
exports("GetPlayerHouse", GetPlayerHouse)
exports("GetPlayerHousePlacedFurnitures", function()
    if Client?.Player?.inHouse then
        return Client?.Player?.Furniture?.createdFurnitures
    end
    return {}
end)
exports("GetPlayerHouses", GetPlayerHouses)
exports("UpdateHouseIndicator", UpdateHouseIndicator)
exports("GetAvailableHouses", GetAvailableHouses)
exports("PurchaseHouse", PurchaseHouse)
