local function GetHouseById(houseId)
    return Server.SoldHouses[houseId]
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
local function UpdateHouseIndicator(houseId, indicator, value)
    if not Utils.DefaultHouses[houseId] then
        return false
    end
    if not Config.Indicators[indicator] then
        return false
    end
    local House = Server.SoldHouses[houseId]
    if not House?.indicators[indicator] or (House.indicators[indicator] + value < 0) then
        return false
    end
    return Server.Functions.UpdateHouseIndicator(indicator, value, houseId)
end

---@param houseId number
---@param indicator "electricity"|"power"|"gas"|"water"
---@return number
local function GetHouseIndicatorValue(houseId, indicator)
    local House = Server.SoldHouses[houseId]
    if House then
        local indicator = House.indicators?[indicator]
        if indicator then
            return indicator
        end
    end
    return 0
end

local function GetAvailableHouses()
    local defaultHouses = Utils.DefaultHouses
    local soldHouses = Server.SoldHouses

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

exports("GetHouseById", GetHouseById)
exports("UpdateHouseIndicator", UpdateHouseIndicator)
exports("GetAvailableHouses", GetAvailableHouses)
