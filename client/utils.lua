Utils.Functions.CustomTarget = {}

function Utils.Functions.HideHud()
    if Utils.Functions.HasResource("0r-hud") then
        exports["0r-hud"]:ToggleVisible(false)
    end
    if Utils.Functions.HasResource("pa-hud") then
        exports["pa-hud"]:ToggleVisible(false)
    end
end

function Utils.Functions.VisibleHud()
    if Utils.Functions.HasResource("0r-hud") then
        exports["0r-hud"]:ToggleVisible(true)
    end
    if Utils.Functions.HasResource("pa-hud") then
        exports["pa-hud"]:ToggleVisible(true)
    end
end

function Utils.Functions.GiveVehicleKey(vehicle, plate)
    if Utils.Functions.HasResource("qb-vehiclekeys") then
        TriggerServerEvent("qb-vehiclekeys:server:AcquireVehicleKeys", plate)
    else
        -- # Your vehicle key script export
    end
end

---You can adapt it to your own weather system.
-- If `stop` is true, you should disable the weather.
-- If false, you have to enable it again.
---@param stop boolean
function Utils.Functions.CustomWeatherSync(stop)
    -- #
end

---@param source serverId
---@param title string
---@param type "error" | "success" | "info" | any
---@param text string
---@param duration number miliseconds
---@param icon string
function Utils.Functions.CustomNotify(title, type, text, duration, icon)
    --[[
        If you have set up your own "notify" system. don't forget to set return true !
    ]]
    return false -- If you use this function, do it true !
end

function Utils.Functions.CustomTarget.AddTargetModel(models, options, onSelect)
    --[[
        If you have set up your own "target" system. don't forget to set return true !
    ]]
    return false -- If you use this function, do it true !
end

function Utils.Functions.CustomTarget.AddTargetEntity(entities, options)
    --[[
        If you have set up your own "target" system. don't forget to set return true !
    ]]
    return false -- If you use this function, do it true !
end

---@param entities any
---@param type "model"|"entity"|string
function Utils.Functions.CustomTarget.RemoveTarget(entities, type)
    --[[
        If you have set up your own "target" system. don't forget to set return true !
    ]]
    return false -- If you use this function, do it true !
end

function Utils.Functions.CustomInventory.OpenInventory(type, id, options)
    local maxWeight = options.maxWeight
    local slots = options.slots
    --[[
        If you have set up your own "inventory" system. don't forget to set return true !
    ]]
    return false -- If you use this function, do it true !
end

function Utils.Functions.LockPickGame(cb)
    if Utils.Functions.HasResource("qb-lockpick") then
        TriggerEvent("qb-lockpick:client:openLockpick", function(result)
            cb(result)
        end)
    elseif Utils.Functions.HasResource("2na_lockpick") then
        cb(exports["2na_lockpick"]:createGame(3, 2))
    elseif Utils.Functions.HasResource("qb-minigames") then
        cb(exports["qb-minigames"]:Lockpick(2))
    else
        --[[ Custom lockpick script ]]
        cb(nil)
    end
end

function Utils.Functions.DrawTextUI(text)
    if Utils.Functions.HasResource("ox_lib") then
        lib.hideTextUI()
        lib.showTextUI(text, { icon = "house" })
    elseif Utils.Framework == "qb" then
        exports["qb-core"]:DrawText(text, "right")
    end
end

function Utils.Functions.HideTextUI()
    if Utils.Functions.HasResource("ox_lib") then
        lib.hideTextUI()
    elseif Utils.Framework == "qb" then
        exports["qb-core"]:HideText()
    end
end

---@param message string
---@param coords vector3
function Utils.Functions.showUI(message)
    Utils.Functions.DrawTextUI(message)
end

--- AddBlipForCoord
---@param coords vector3
---@param label string
---@param blip table
function Utils.Functions.AddBlipForCoord(coords, label, blip)
    coords = vec3(coords.x, coords.y, coords.z)
    local createdBlip = AddBlipForCoord(coords)
    SetBlipSprite(createdBlip, blip.sprite)
    SetBlipColour(createdBlip, blip.color)
    SetBlipScale(createdBlip, blip.scale)
    SetBlipAsShortRange(createdBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(label)
    EndTextCommandSetBlipName(createdBlip)
    if label == "Sale House" then
        SetBlipCategory(createdBlip, 10)
    else
        SetBlipCategory(createdBlip, 11)
    end
    return createdBlip
end

function HouseOverrideClockTime()
    CreateThread(function()
        while Client?.Player?.inHouse or Client?.Player?.inVisit do
            local state = Client?.Player?.inHouse?.options?.lights
            if state or state == nil then
                NetworkOverrideClockTime(12, 0, 0)
            else
                NetworkOverrideClockTime(4, 55, 0)
            end
            Wait(0)
        end
    end)
end
