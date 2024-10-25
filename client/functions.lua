--[[ Client ]]

Client = {
    Framework = Utils.Functions.GetFramework(),
    Functions = { CCTV = {} },
    Player = {
        position = {},
        ownedHouses = {},
        guestHouses = {},
        ---@type InHouseType
        inHouse = nil,
        Furniture = {
            inDecorationMode = false,
            createdFurnitures = {}
        },
        inCCTV = false,
        inVisit = false,
        inGarage = false,
        inCreateHouse = false,
    },
    CreatedTargets = {},
    CreatedGarageVehicles = {},
    SoldHouses = {},
    HousesBlips = {},
}

--[[ Core Functions ]]
---@param key string
---@param cb function
---@param ... string
function Client.Functions.Callback(key, cb, ...)
    lib.callback(key, false, cb, ...)
end

---@param key string
---@param cb function
---@param ... string
function Client.Functions.CallbackAwait(key, ...)
    return lib.callback.await(key, false, ...)
end

function Client.Functions.SendReactMessage(action, data)
    SendNUIMessage({ action = action, data = data })
end

function Client.Functions.SendNotify(title, type, duration, icon, text)
    if not Utils.Functions.CustomNotify(title, type, text, duration, icon) then
        if Utils.Functions.HasResource("ox_lib") then
            lib.notify({
                title = title,
                description = text,
                type = type,
            })
        elseif Utils.Framework == "qb" then
            Client.Framework.Functions.Notify(title, type, duration)
        elseif Utils.Framework == "esx" then
            Client.Framework.ShowNotification(title, type, duration)
        end
    end
end

function Client.Functions.GetPlayerData()
    if Utils.Framework == "esx" then
        return Client.Framework.GetPlayerData()
    elseif Utils.Framework == "qb" then
        return Client.Framework.Functions.GetPlayerData()
    end
    return nil
end

function Client.Functions.IsPlayerLoaded()
    if Utils.Framework == "esx" then
        return Client.Framework.IsPlayerLoaded()
    elseif Utils.Framework == "qb" then
        return LocalPlayer.state.isLoggedIn
    end
end

function Client.Functions.OnPlayerLogout()
    TriggerServerEvent(_e("Server:OnPlayerLogout"))
end

--[[ Script Functions ]]

function IsPlayerMetaInsideHouse()
    if Client.Player.inHouse then return false end
    local xPlayer = Client.Functions.GetPlayerData()
    local houseId = nil
    local visitId = nil
    local garageId = nil
    houseId = xPlayer?.metadata?.inside?.pixelhouse
    visitId = xPlayer?.metadata?.inside?.pixelvisit
    garageId = xPlayer?.metadata?.inside?.pixelgarage
    local metaId = houseId or visitId or garageId
    return metaId
end

function Client.Functions.RemoveTarget(id, type)
    if not Utils.Functions.CustomTarget.RemoveTarget(id, type) then
        if Utils.Functions.HasResource("ox_target") then
            if type == "model" then
                exports.ox_target:removeModel(id)
            elseif type == "entity" then
                exports.ox_target:removeLocalEntity(id)
            end
        elseif Utils.Functions.HasResource("qb-target") then
            if type == "model" then
                exports["qb-target"]:RemoveTargetModel(id)
            elseif type == "entity" then
                exports["qb-target"]:RemoveTargetEntity(id)
            end
        end
    end
end

function Client.Functions.DeleteTargets()
    local entities = Client.CreatedTargets
    for _, value in pairs(entities) do
        Client.Functions.RemoveTarget(value.id, value.type)
    end
    Client.CreatedTargets = {}
end

function Client.Functions.AddTargetModel(key, type, models, options, onSelect)
    local targetId = models
    local icon = options.icon
    local label = options.label
    if not Utils.Functions.CustomTarget.AddTargetModel(models, {
            icon = icon,
            label = label,
        }, onSelect)
    then
        if Utils.Functions.HasResource("ox_target") then
            exports.ox_target:addModel(models, { {
                icon = icon,
                label = label,
                onSelect = onSelect,
                distance = 2.0,
            } })
        elseif Utils.Functions.HasResource("qb-target") then
            exports["qb-target"]:AddTargetModel(models,
                {
                    options = {
                        {
                            icon = icon,
                            label = label,
                            action = onSelect,
                        },
                    },
                    distance = 2.0,
                })
        end
    end
    table.insert(Client.CreatedTargets, {
        id = targetId,
        key = key,
        type = type
    })
end

function Client.Functions.AddTargetEntity(type, entities, options)
    if not Utils.Functions.CustomTarget.AddTargetEntity(entities, options) then
        local opt = {}
        if Utils.Functions.HasResource("ox_target") then
            for _, option in pairs(options) do
                table.insert(opt, {
                    icon = option.icon,
                    label = option.label,
                    onSelect = option.onSelect,
                    distance = 2.0
                })
            end
            exports.ox_target:addLocalEntity(entities, opt)
        elseif Utils.Functions.HasResource("qb-target") then
            for _, option in pairs(options) do
                table.insert(opt, {
                    icon = option.icon,
                    label = option.label,
                    action = option.onSelect,
                })
            end
            exports["qb-target"]:AddTargetEntity(entities,
                { options = opt, distance = 2.0, })
        end
    end
    table.insert(Client.CreatedTargets, {
        id = entities,
        type = type
    })
end

function Client.Functions.SetupUI()
    Client.Functions.SendReactMessage("ui:setupUI", {
        setLocale = {
            locale = Config.Locale,
            languages = locales.ui or {}
        },
        setWallColors = Config.WallColors or {},
        setIndicatorSettings = Config.Indicators or {},
        setDefaultHouses = Utils.DefaultHouses or {},
        setFurnitureItems = Config.FurnitureItems or {},
        setHasDlc = {
            [1] = {
                dlc = "weed",
                value = Utils.Functions.HasResource("0r-weed")
            },
        },
        setOwnedHouses = Client.Player?.ownedHouses or {},
        setHouseTypes = Config.InteriorHouseTypes
    })
end

function Client.Functions.GetDefaultHouses()
    local houses = Client.Functions.CallbackAwait(_e("Server:GetDefaultHouses"))
    Utils.DefaultHouses = houses or {}
    return houses
end

function Client.Functions.GetSoldHouses()
    local houses = Client.Functions.CallbackAwait(_e("Server:GetSoldHouses"))
    Client.SoldHouses = houses or {}
    return houses
end

function Client.Functions.OpenMainPanel()
    Client.Functions.SetupUI()
    if not Client.Player.inCCTV then
        local dHouses = Client.Functions.GetDefaultHouses()
        local sHouses = Client.Functions.GetSoldHouses()
        Client.Functions.SendReactMessage("ui:setupUI", {
            setDefaultHouses = dHouses,
            setSoldHouses = sHouses
        })
        Client.Functions.SendReactMessage("ui:setVisible", true)
        SetNuiFocus(true, true)
    end
    Wait(1000)
end

function Client.Functions.CloseMainPanel()
    Client.Functions.SendReactMessage("ui:setVisible", false)
    SetNuiFocus(false, false)
end

function Client.Functions.LoadPlayerData()
    local playerData = Client.Functions.CallbackAwait(_e("Server:LoadPlayerData"))
    Client.Player.ownedHouses = playerData.ownedHouses
    Client.Player.guestHouses = playerData.guestHouses
    --[[ HouseOwnedBlip ]]
    if Config?.HouseOwnedBlip?.active then
        ---@param id number
        for id, house in pairs(Client.Player.ownedHouses) do
            local coords = Utils.DefaultHouses[id]?.door_coords
            if coords then
                local label = "Owned House"
                Client.HousesBlips[id] = Utils.Functions.AddBlipForCoord(coords, label, Config.HouseOwnedBlip)
            end
        end
        ---@param id number
        for id, house in pairs(Client.Player.guestHouses) do
            local coords = Utils.DefaultHouses[id]?.door_coords
            if coords then
                local label = "Owned House"
                Client.HousesBlips[id] = Utils.Functions.AddBlipForCoord(coords, label, Config.HouseOwnedBlip)
            end
        end
    end
end

function Client.Functions.OpenDoorAnim()
    local PlayerPedId = cache.ped
    if pcall(lib.requestAnimDict, "anim@heists@keycard@", 500) then
        TaskPlayAnim(PlayerPedId, "anim@heists@keycard@", "exit", 5.0, 1.0, -1, 16, 0, 0, 0, 0)
    end
    Wait(500)
    ClearPedTasks(PlayerPedId)
end

function Client.Functions.GetIntoHouse(houseId, forceOut, unauthorized)
    Client.Functions.OpenDoorAnim()
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(500) end
    Client.Functions.Callback(_e("Server:GetIntoHouse"), function(response)
        if response.error then
            Client.Functions.SendNotify(locale("error", response.error), "error")
            DoScreenFadeIn(500)
            if forceOut then
                local coords = Utils.DefaultHouses[houseId]?.door_coords or vec3(0.0, 0.0, 0.0)
                TriggerServerEvent(_e("Server:SetPlayerRoutingBucket"), coords, 0)
            end
        end
    end, houseId, unauthorized)
end

function Client.Functions.GetIntoGarage(houseId)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(500) end
    Client.Functions.Callback(_e("Server:GetIntoGarage"), function(response)
        if response.error then
            Client.Functions.SendNotify(locale("error", response.error), "error")
            DoScreenFadeIn(500)
        end
    end, houseId)
end

local function GetVehicleMods(vehicle)
    if Utils.Framework == "qb" then
        return Client.Framework.Functions.GetVehicleProperties(vehicle)
    else
        return Client.Framework.Game.GetVehicleProperties(vehicle)
    end
end

function Client.Functions.AddVehicleToGarage(houseId, vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)
    local mods = GetVehicleMods(vehicle)
    Client.Functions.Callback(_e("Server:AddVehicleToGarage"), function(response)
        if response.error then
            return Client.Functions.SendNotify(locale("error", response.error), "error")
        end
        Client.Functions.SendNotify(locale("added_to_vehicle"), "success")
        while DoesEntityExist(vehicle) do
            DeleteEntity(vehicle)
            Wait(5)
        end
    end, houseId, plate, mods)
end

function Client.Functions.BuyHouse(houseId)
    local House = Utils.DefaultHouses[houseId]
    if House then
        Client.Functions.SetupUI()
        Client.Functions.SendReactMessage("ui:setRouter", "purchase-house")
        Client.Functions.SendReactMessage("ui:setPreviewHouse", House)
        Wait(1)
        Client.Functions.SendReactMessage("ui:setVisible", true)
        SetNuiFocus(true, true)
    end
end

function Client.Functions.SetupHouses()
    Client.Functions.GetDefaultHouses()
    Client.Functions.GetSoldHouses()
    local Houses = Utils.DefaultHouses
    --[[ SaleHouseBlip ]]
    if Config?.SaleHouseBlip?.active then
        for _, house in pairs(Houses) do
            if not Client.SoldHouses[house.houseId] and house?.door_coords then
                local coords = house?.door_coords
                local label = "Sale House"
                Client.HousesBlips[house.houseId] = Utils.Functions.AddBlipForCoord(coords, label, Config.SaleHouseBlip)
            end
        end
    end
    Client.Functions.Thread_Houses()
end

function Client.Functions.HouseFrameworkSync(entry)
    if Utils.Functions.HasResource("cd_easytime") then
        TriggerEvent("cd_easytime:PauseSync", entry)
    elseif Utils.Functions.HasResource("qb-weathersync") then
        if entry then
            TriggerEvent("qb-weathersync:client:DisableSync")
        else
            TriggerEvent("qb-weathersync:client:EnableSync")
        end
    elseif Utils.Functions.HasResource("vSync") then
        TriggerEvent("vSync:toggle", entry)
    end
    Utils.Functions.CustomWeatherSync(entry)
    HouseOverrideClockTime()
end

function Client.Functions.SetHouseLights(state, wait)
    SetTimeout(wait or 100, function()
        SetArtificialLightsState(state)
    end)
end

function Client.Functions.CheckPlayerMeta()
    local metaId = IsPlayerMetaInsideHouse()
    if not metaId then return end
    local House = Utils.DefaultHouses[metaId]
    local keys = { "pixelhouse", "pixelgarage", "pixelvisit" }
    if House then
        TriggerServerEvent(_e("Server:RemovePlayerMeta"), keys)
        TriggerServerEvent(_e("Server:SetPlayerRoutingBucket"), House?.door_coords, 0)
    else
        TriggerServerEvent(_e("Server:RemovePlayerMeta"), keys)
    end
end

function Client.Functions.ChangeHouseTint(type, tint)
    if type == "furnished" then
        if Utils.Functions.HasResource("qua_luxemotel") then
            exports["qua_luxemotel"]:ChangeTint(tint)
            return true
        end
    elseif type == "square" or type == "rectangle" then
        if Utils.Functions.HasResource("qua_0r_house") then
            exports["qua_0r_house"]:ChangeTint(type, tint)
            return true
        end
    elseif type == 'apa_v_mp_h' then
        local apa_v_tints = {
            { interiorId = 227841, ipl = "apa_v_mp_h_01_c" },
            { interiorId = 228609, ipl = "apa_v_mp_h_02_c" },
            { interiorId = 229377, ipl = "apa_v_mp_h_03_c" },
            { interiorId = 230145, ipl = "apa_v_mp_h_04_c" },
            { interiorId = 230913, ipl = "apa_v_mp_h_05_c" },
            { interiorId = 231681, ipl = "apa_v_mp_h_06_c" },
            { interiorId = 232449, ipl = "apa_v_mp_h_07_c" },
            { interiorId = 233217, ipl = "apa_v_mp_h_08_c" }
        }
        for k,v in pairs(apa_v_tints) do
            if IsIplActive(apa_v_tints[k].ipl) then
               RemoveIpl(apa_v_tints[k].ipl)
               RefreshInterior(apa_v_tints[k].interiorId)
               PinInteriorInMemory(apa_v_tints[k].interiorId)
               SetEntityCoordsNoOffset(cache.ped, GetEntityCoords(cache.ped))
               SetEntityHeading(cache.ped, GetEntityHeading(cache.ped))
            end
         end
        local _theme = tint
        if _theme < 1 then
            _theme = 1
        elseif _theme > #apa_v_tints then
            _theme = ((_theme - 1) % #apa_v_tints) + 1
        end
        RequestIpl(apa_v_tints[_theme].ipl)
        RefreshInterior(apa_v_tints[_theme].interiorId)
        return true
    end
    return false
end

function Client.Functions.ChangeHouseStairs(type, state)
    if type == "square" or type == "rectangle" then
        if Utils.Functions.HasResource("qua_0r_house") then
            exports["qua_0r_house"]:ToggleStairs(type, state)
            return true
        end
    end
    return false
end

function Client.Functions.ChangeHouseRooms(type, state)
    if type == "square" or type == "rectangle" then
        if Utils.Functions.HasResource("qua_0r_house") then
            exports["qua_0r_house"]:ToggleRooms(type, state)
            return true
        end
    end
    return false
end

function Client.Functions.OpenWardrobe()
    if not Client.Player.inHouse then return end
    if Config.ClothMenuEventName then
        TriggerEvent(Config.ClothMenuEventName)
    elseif Utils.Functions.HasResource("qb-clothing") then
        TriggerEvent("qb-clothing:client:openOutfitMenu")
    elseif Utils.Functions.HasResource("esx_skin") then
        TriggerEvent("esx_skin:openSaveableRestrictedMenu", nil, nil,
            {
                "tshirt_1", "tshirt_2",
                "torso_1", "torso_2",
                "decals_1", "decals_2",
                "arms", "arms_2",
                "pants_1", "pants_2",
                "shoes_1", "shoes_2",
                "bags_1", "bags_2",
                "chain_1", "chain_2",
                "helmet_1", "helmet_2",
                "glasses_1", "glasses_2",
                "watches_1", "watches_2"
            }
        )
    elseif Utils.Functions.HasResource("illenium-appearance") then
        TriggerEvent("illenium-appearance:client:openOutfitMenu")
    end
end

function Client.Functions.OpenStash(key)
    if not Client.Player.inHouse then return end
    local stashId = key
    local slots = Config.StashOptions.slots
    local maxWeight = Config.StashOptions.maxWeight
    if not Utils.Functions.CustomInventory.OpenInventory("stash", stashId, {
            maxWeight = maxWeight,
            slots = slots
        })
    then
        if Utils.Functions.HasResource("ox_inventory") then
            exports.ox_inventory:openInventory("stash", stashId)
        elseif Utils.Functions.HasResource("qb-inventory") then
            TriggerServerEvent(_e("Server:OpenStash"), stashId, {
                maxWeight = maxWeight,
                slots = slots
            })
            TriggerEvent("inventory:client:SetCurrentStash", stashId)
        elseif Utils.Functions.HasResource("qs-inventory") then
            local other = {}
            other.maxweight = maxWeight
            other.slots = slots
            TriggerServerEvent("inventory:server:OpenInventory", "stash", stashId, other)
            TriggerEvent("inventory:client:SetCurrentStash", stashId)
        elseif Utils.Functions.HasResource("codem-inventory") then
            TriggerServerEvent("codem-inventory:server:openstash", stashId, slots, maxWeight, stashId)
            TriggerEvent("inventory:client:SetCurrentStash", stashId)
        elseif Utils.Functions.HasResource("origen_inventory") then
            TriggerServerEvent(_e("Server:OpenStash"), stashId, {
                maxWeight = maxWeight,
                slots = slots
            })
            TriggerEvent("inventory:client:SetCurrentStash", stashId)
        end
    end
end

function Client.Functions.ClearHouseInside(noDlc)
    Client.Functions.DeleteTargets()
    for _, value in pairs(Client.Player.Furniture.createdFurnitures) do
        if DoesEntityExist(value.objectId) then
            DeleteEntity(value.objectId)
        end
    end
    Client.Player.Furniture.createdFurnitures = {}
    if not noDlc then
        Client.Functions.Dlc_Weed_ClearZone()
    end
end

function Client.Functions.CreateStashTarget(entity, model, pass)
    if not Config.StashOptions.active then return end
    local inHouse = Client.Player.inHouse
    if inHouse then
        Client.Functions.RemoveTarget(entity, "entity")
        local openStash = function(stashId)
            Client.Functions.OpenStash(stashId)
        end
        local options = {
            [1] = {
                icon = "fa-solid fa-boxes-stacked",
                label = locale("open_stash"),
                onSelect = function()
                    local stashId = string.format("ph_%s_%s", inHouse.houseId, pass)
                    openStash(stashId)
                end
            },
        }
        Client.Functions.AddTargetEntity("entity", entity, options)
    end
end

function Client.Functions.CreateWardrobeTargets()
    if not Config.WardrobeOptions.active then return end
    local inHouse = Client.Player.inHouse
    if inHouse then
        local models = {}
        for _, item in pairs(Config.FurnitureItems["wardrobe"].items) do
            table.insert(models, item.model)
        end
        Client.Functions.AddTargetModel("ph_wardrobe", "model", models, {
            icon = "fa-solid fa-shirt",
            label = locale("open_wardrobe"),
        }, function()
            Client.Functions.OpenWardrobe()
        end)
    end
end

function Client.Functions.SetupHouseInside(unauthorized, noDlc)
    Wait(250)
    local function createFurnitures()
        local furnitures = Client.Player.inHouse.furnitures
        for _, furniture in pairs(furnitures or {}) do
            if furniture.isPlaced then
                local model = furniture.model
                local pos = furniture.pos
                local rot = furniture.rot
                local index = furniture.index
                if pcall(lib.requestModel, model, 500) then
                    local createdObject = CreateObject(model, pos.x, pos.y, pos.z, false, false, false)
                    if createdObject ~= 0 then
                        SetEntityCoords(createdObject, pos.x, pos.y, pos.z)
                        SetEntityRotation(createdObject, rot.x, rot.y, rot.z)
                        SetEntityAsMissionEntity(createdObject, true, true)
                        FreezeEntityPosition(createdObject, true)
                        SetEntityInvincible(createdObject, true)
                        SetModelAsNoLongerNeeded(model)
                        table.insert(Client.Player.Furniture.createdFurnitures, {
                            index = index,
                            isPlaced = true,
                            objectId = createdObject,
                            model = model,
                            pos = pos,
                            rot = rot,
                            meta = {
                                dry_pass = furniture?.dry_pass,
                                stash_pass = furniture?.stash_pass,
                            }
                        })
                        if isModelStash(model) then
                            if not unauthorized or Config.Raid.canUseStash then
                                Client.Functions.CreateStashTarget(createdObject, model, furniture.stash_pass)
                            end
                        end
                    end
                end
            end
        end
    end
    -- # --
    createFurnitures()
    if not unauthorized then
        Client.Functions.CreateWardrobeTargets()
    end
    if not noDlc then
        Client.Functions.Dlc_Weed_LoadZone()
    end
end

function Client.Functions.LeaveHouse()
    local houseId = Client.Player.inHouse.houseId
    Client.Functions.OpenDoorAnim()
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(500) end
    TriggerServerEvent(_e("Server:LeaveHouse"), houseId)
    SetInteriorProbeLength(0.0)
end

function Client.Functions.VisitHouse(houseId, type)
    Client.Player.inVisit = true
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(500) end
    Client.Functions.HouseFrameworkSync(true)
    Client.Functions.ChangeHouseStairs(type, true)
    Client.Functions.ChangeHouseRooms(type, true)
    Client.Functions.SetHouseLights(false)
    local houseType = Config.InteriorHouseTypes[string.lower(type)]
    if houseType then
        TriggerServerEvent(_e("Server:SetPlayerMeta"), "pixelvisit", houseId)
        TriggerServerEvent(_e("Server:SetPlayerRoutingBucket"), houseType.enter_coords, "8" .. houseId)
        CreateThread(function()
            local House = Utils.DefaultHouses[houseId]
            DoScreenFadeIn(1000)
            while not IsScreenFadedIn() do Wait(1000) end
            Client.Functions.SendNotify(locale("visiting_house"), "success", 2500)
            local isDrawTextUIOpen = false
            local playerPedId = cache.ped

            local function showUI(message)
                if isDrawTextUIOpen then return end
                isDrawTextUIOpen = true
                Utils.Functions.showUI(message)
            end
            local function hideUI()
                Utils.Functions.HideTextUI()
                isDrawTextUIOpen = false
            end
            while Client.Player.inVisit do
                local playerCoords = GetEntityCoords(playerPedId)

                if #(playerCoords - houseType.door_coords) <= 0.8 then
                    sleep = 5
                    showUI("[E] " .. locale("leave_house"))
                    if IsControlJustPressed(0, 38) then -- [E]
                        Client.Player.inVisit = false
                        Client.Functions.OpenDoorAnim()
                        TriggerServerEvent(_e("Server:RemovePlayerMeta"), "pixelvisit")
                        TriggerServerEvent(_e("Server:SetPlayerRoutingBucket"), House?.door_coords, 0)
                        break
                    end
                elseif isDrawTextUIOpen then
                    hideUI()
                end
                Wait(5)
            end
            if isDrawTextUIOpen then
                hideUI()
            end
            Client.Functions.HouseFrameworkSync(false)
        end)
    end
end

function Client.Functions.UnauthorizedEntry(houseId)
    local item = Config.Raid.itemRequired
    Client.Functions.Callback(_e("Server:PlayerHasItem"), function(hasItem)
        if not hasItem then
            return Client.Functions.SendNotify(locale("donot_have_enough_items", item.label), "error")
        end
        TriggerServerEvent(_e("Server:UnauthorizedEntryNotify"), houseId)
        local apartmentId = apartmentId
        local roomId = roomId
        Utils.Functions.LockPickGame(function(state)
            if not state then
                return Client.Functions.SendNotify(locale("couldnot_lock_pick"), "error")
            end
            if item.removeItem then
                TriggerServerEvent(_e("Server:PlayerRemoveItem"), item.name, item.itemCount)
            end
            if state then
                Client.Functions.GetIntoHouse(houseId, false, true)
            end
        end)
    end, item.name, item.itemCount)
end

function Client.Functions.ClearGarageInside()
    Client.Functions.DeleteTargets()
    for k, v in pairs(Client.CreatedGarageVehicles) do
        if DoesEntityExist(v) then
            DeleteEntity(v)
        end
    end
    Client.CreatedGarageVehicles = {}
end

function Client.Functions.LeaveGarage(plate)
    local houseId = Client.Player.inGarage
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(500) end
    Client.Functions.ClearGarageInside()
    TriggerServerEvent(_e("Server:LeaveGarage"), houseId, plate)
end

function Client.Functions.TakeOutVehicleFromGarage(plate)
    DoScreenFadeOut(0)
    Client.Functions.Callback(_e("Server:TakeOutVehicleFromGarage"), function(response)
        if response.error then
            return Client.Functions.SendNotify(locale("error", response.error), "error")
        end
        Client.Functions.ClearGarageInside()
        local vehicleData = response.vehicleData
        local coords = GetEntityCoords(cache.ped)
        local coords_w = GetEntityHeading(cache.ped)
        if Utils.Framework == "qb" then
            Client.Framework.Functions.SpawnVehicle(vehicleData.vehicle, function(veh)
                SetVehicleNumberPlateText(veh, vehicleData.plate)
                SetEntityHeading(veh, coords_w)
                TaskWarpPedIntoVehicle(cache.ped, veh, -1)
                SetVehicleEngineOn(veh, true, true)
                Client.Framework.Functions.SetVehicleProperties(veh, json.decode(vehicleData.mods))
                Utils.Functions.GiveVehicleKey(veh, plate)
            end, coords, true)
        else
            Client.Framework.Game.SpawnVehicle(json.decode(vehicleData.vehicle)?.model, coords, coords_w, function(veh)
                SetVehicleNumberPlateText(veh, vehicleData.plate)
                SetEntityHeading(veh, coords_w)
                TaskWarpPedIntoVehicle(cache.ped, veh, -1)
                SetVehicleEngineOn(veh, true, true)
                Client.Framework.Game.SetVehicleProperties(veh, json.decode(vehicleData.vehicle))
                Utils.Functions.GiveVehicleKey(veh, plate)
            end)
        end
        DoScreenFadeIn(500)
    end, plate, Client.Player.inGarage)
end

function Client.Functions.SetupGarageInside(vehicles)
    ---@param key number
    for key, value in pairs(vehicles) do
        local coords = Config.InteriorHouseGarage.coords.vehicles[key]
        if coords then
            local targetId = string.format("ph_g_veh_%s", key)
            local model = nil
            local garage = nil
            if Utils.Framework == "qb" then
                model = value.vehicle
                garage = value.garage
            else
                model = json.decode(value.vehicle)?.model
                garage = value.parking
            end
            if pcall(lib.requestModel, model, 500) then
                local veh = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, false, false)
                if DoesEntityExist(veh) then
                    SetEntityCoords(veh, coords.x, coords.y, coords.z)
                    SetEntityHeading(veh, coords.w)
                    SetModelAsNoLongerNeeded(model)
                    SetEntityInvincible(veh, true)
                    SetVehicleDirtLevel(veh, 0.0)
                    SetVehicleDoorsLocked(veh, 3)
                    FreezeEntityPosition(veh, true)
                    SetVehicleNumberPlateText(veh, value.plate)
                    CreateThread(function()
                        while not SetVehicleOnGroundProperly(veh) do
                            Wait(5)
                        end
                    end)
                    if Utils.Framework == "qb" then
                        Client.Framework.Functions.SetVehicleProperties(veh, json.decode(value.mods))
                    else
                        Client.Framework.Game.SetVehicleProperties(veh, json.decode(value.vehicle))
                    end
                    Client.Functions.AddTargetModel(targetId, "model", model, {
                        icon = "fa-solid fa-arrow-right-from-bracket",
                        label = locale("vehicle_take_out"),
                    }, function()
                        Client.Functions.LeaveGarage(value.plate)
                    end)
                    table.insert(Client.CreatedGarageVehicles, veh)
                end
            end
        end
    end
end

local isDoorCoolDown = false
function Client.Functions.RingDoor(houseId)
    Client.Functions.SendNotify(locale("ring_on_door"), "success")
    if isDoorCoolDown then return end
    isDoorCoolDown = true
    TriggerServerEvent("InteractSound_SV:PlayOnSource", "doorbell", 0.1)
    TriggerServerEvent(_e("Server:RingOnDoor"), houseId)
    Citizen.SetTimeout(5000, function()
        isDoorCoolDown = false
    end)
end

--[[ DLC WEED ]]

function Client.Functions.Dlc_Weed_ClearZone()
    if Utils.Functions.HasResource("0r-weed") then
        TriggerEvent("0r-weed:Client:ClearZonePlants")
    end
end

function Client.Functions.Dlc_Weed_LoadZone()
    if not Client.Player.inHouse?.houseId then return end
    if Utils.Functions.HasResource("0r-weed") then
        local zoneId = string.format("pixelhouse_%s", Client.Player.inHouse.houseId)
        TriggerEvent("0r-weed:Client:LoadZonePlants", zoneId)
    end
end

function Client.Functions.DLC_Weed_AnyFurnitureUpdated(model, objectId, removed, meta)
    if Utils.Functions.HasResource("0r-weed") then
        local lastCoords = GetEntityCoords(objectId)
        TriggerEvent("0r-weed:Client:OnWeedPropsUpdated", objectId, lastCoords, model, removed, meta)
    end
end

--[[ # ]]

function Client.Functions.ReLoadFurnitures(noDlc)
    Client.Functions.ClearHouseInside(noDlc)
    Wait(1)
    Client.Functions.SetupHouseInside(false, noDlc)
    DoScreenFadeIn(100)
end

--[[ CCTV ]]

function Client.Functions.CCTV.Open()
    local PlayerPedId = cache.ped
    Client.Player.position = GetEntityCoords(PlayerPedId)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(500) end
    Client.Functions.Callback(_e("Server:CCTV:Toggle"), function(response)
        if response.error then
            return Client.Functions.SendNotify(locale("error", response.error), "error")
        end
        Client.Player.inCCTV = true
        FreezeEntityPosition(PlayerPedId, true)
        SetEntityVisible(PlayerPedId, false)
        Utils.Functions.HideHud()
        Client.Functions.Thread__CCTV()
    end, true, Client.Player.inHouse.houseId)
end

function Client.Functions.CCTV.CloseCameraMode(noq)
    ClearPedTasks(cache.ped)
    DetachEntity(cache.ped, true, false)
    if noq then
        local PlayerPedId = cache.ped
        Client.Player.inCCTV = false
        ClearFocus()
        ClearTimecycleModifier()
        ClearExtraTimecycleModifier()
        RenderScriptCams(false, false, 0, true, false)
        SetFocusEntity(PlayerPedId)
        FreezeEntityPosition(PlayerPedId, false)
        SetEntityCollision(PlayerPedId, true, true)
        SetEntityVisible(PlayerPedId, true)
        SetEntityCoords(PlayerPedId, Client.Player.position)
        EnableAllControlActions(0)
        Utils.Functions.VisibleHud()
        DoScreenFadeIn(1000)
    end
    Client.Functions.Callback(_e("Server:CCTV:Toggle"), function(response)
        if response then
            local PlayerPedId = cache.ped
            Client.Player.inCCTV = false
            ClearFocus()
            ClearTimecycleModifier()
            ClearExtraTimecycleModifier()
            RenderScriptCams(false, false, 0, true, false)
            SetFocusEntity(PlayerPedId)
            FreezeEntityPosition(PlayerPedId, false)
            SetEntityCollision(PlayerPedId, true, true)
            SetEntityVisible(PlayerPedId, true)
            SetEntityCoords(PlayerPedId, Client.Player.position)
            EnableAllControlActions(0)
            Utils.Functions.VisibleHud()
            DoScreenFadeIn(1000)
        end
    end, false, Client.Player.inHouse.houseId, Client.Player.position)
end

--[[ Core Functions ]]

function Client.Functions.StartCore()
    local frozen = false
    if IsPlayerMetaInsideHouse() then
        frozen = true
        FreezeEntityPosition(cache.ped, true)
    end
    Wait(1000)
    Client.Functions.SetupHouses()
    Client.Functions.LoadPlayerData()
    Client.Functions.CheckPlayerMeta()
    if frozen then
        FreezeEntityPosition(cache.ped, false)
    end
end

function Client.Functions.StopCore()
    DoScreenFadeIn(0)
    Client.Functions.DeleteTargets()
    Utils.Functions.HideTextUI()
    Client.Functions.SetHouseLights(false)
    Client.Functions.HouseFrameworkSync(false)
    Client.Functions.ClearHouseInside()
    if Client.Player.inGarage then
        Client.Functions.ClearGarageInside()
    end
    if Client.Player.Furniture.inDecorationMode then
        Client.Functions.CloseFurnitureMode()
    end
    if Client.Player.inCCTV then
        Client.Functions.CCTV.CloseCameraMode(true)
    end
    --[[ Clear Variables ]]
    Client.Player = {
        position = {},
        ownedHouses = {},
        guestHouses = {},
        inHouse = nil,
        Furniture = {
            inDecorationMode = false,
            createdFurnitures = {}
        },
        inCCTV = false,
        inVisit = false,
        inGarage = false,
        inCreateHouse = false,
    }
end

--[[ Core Thread]]

CreateThread(function()
    lib.locale()
    if not Client.Framework then
        for i = 1, 10, 1 do
            if Client.Framework then break end
            Client.Framework = Utils.Functions.GetFramework()
            Wait(100)
        end
    end
end)
