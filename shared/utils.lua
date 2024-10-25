--[[ Types ]]

---@class HouseType
---@field houseId number
---@field label string
---@field price number
---@field type string
---@field door_coords vector4
---@field garage_coords vector4|nil
---@field coords_label string

---@class Options
---@field lights boolean|nil
---@field tint number|nil
---@field stairs boolean|nil

---@class Permission
---@field user string --- Player identifier,
---@field playerName string,

---@class Furniture

---@class Indicators
---@field electricity number|nil
---@field power number|nil
---@field gas number|nil
---@field water number|nil

---@class InHouseType
---@field houseId number
---@field label string
---@field price number
---@field type string
---@field door_coords vector4
---@field garage_coords vector4|nil
---@field coords_label string
---@field owner boolean
---@field owner_name string
---@field guest boolean
---@field options Options
---@field permissions table<number, Permission>
---@field furnitures table<number, Furniture>
---@field indicators Indicators

---@class SoldHouseType
---@field houseId number
---@field owner string
---@field owner_name string
---@field options Options
---@field permissions table<number, Permission>
---@field furnitures table<number, Furniture>
---@field indicators Indicators

--[[ # ]]

--[[ Utils ]]
Resmon = exports["0r_lib"]:GetCoreObject()
Utils = {}
---@type table<number, HouseType>
Utils.DefaultHouses = {}
Utils.Framework = nil ---@type "esx" | "qb"
Utils.Functions = {}
Utils.Functions.CustomInventory = {}

function Utils.Functions.GetFrameworkType()
    if Utils.Functions.HasResource("qb-core") then
        return "qb"
    end
    if Utils.Functions.HasResource("es_extended") then
        return "esx"
    end
end

---@param name string resource name
---@return boolean
function Utils.Functions.HasResource(name)
    return GetResourceState(name):find("start") ~= nil
end

function Utils.Functions.deepCopy(tbl)
    return lib.table.deepclone(tbl)
end

function Utils.Functions.GetFramework()
    if Utils.Functions.HasResource("qb-core") then
        return exports["qb-core"]:GetCoreObject()
    end
    if Utils.Functions.HasResource("es_extended") then
        return exports["es_extended"]:getSharedObject()
    end
end

function _e(event)
    local scriptName = cache.resource
    return scriptName .. ":" .. event
end

function generateRandomString(length)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local numbers = "0123456789"
    local randomString = ""
    math.randomseed(os.time())

    for i = 1, length do
        if math.random(1, 2) == 1 then
            local index = math.random(1, #chars)
            randomString = randomString .. chars:sub(index, index)
        else
            local index = math.random(1, #numbers)
            randomString = randomString .. numbers:sub(index, index)
        end
    end

    return randomString
end

function isModelStash(model)
    for _, item in pairs(Config.FurnitureItems["stashes"]?.items or {}) do
        if item.model == model then
            return true
        end
    end
    return false
end

function isModelWeedDry(model)
    for _, item in pairs(Config.FurnitureItems["weed_dryer"].items or {}) do
        if item.model == model then
            return true
        end
    end
    return false
end

--[[ Core Thread]]
Utils.Framework = Utils.Functions.GetFrameworkType()

CreateThread(function()
    for i = 1, 10, 1 do
        if Resmon then break end
        Resmon = exports["0r_lib"]:GetCoreObject()
        Wait(500)
    end
end)
