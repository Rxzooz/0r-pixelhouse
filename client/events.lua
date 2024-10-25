--[[ Core Events ]]

AddEventHandler("onResourceStart", function(resource)
    if resource == cache.resource then
        Client.Functions.StartCore()
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == cache.resource then
        Client.Functions.StopCore()
    end
end)

--[[ Custom Events ]]

RegisterNetEvent(_e("Client:OpenMainPanel"), function(houses)
    Client.Functions.OpenMainPanel()
end)

RegisterNetEvent(_e("Client:OnUpdateSoldHouses"), function(houses)
    Client.SoldHouses = houses
end)

RegisterNetEvent(_e("Client:SetDefaultHouses"), function(houses)
    Utils.DefaultHouses = houses
end)

RegisterNetEvent(_e("Client:SetPlayerHouses"), function(houses)
    Client.Player.ownedHouses = houses
    Client.Functions.SendReactMessage("ui:setupUI", {
        setOwnedHouses = houses
    })
end)

RegisterNetEvent(_e("Client:OnUpdateHouseBlip"), function(owner, houseId, type, soldHouses)
    Client.SoldHouses = soldHouses
    local PlayerServerId = cache.serverId
    local owner = tonumber(owner)
    local blipConf
    local blipText
    local process
    local category

    if type == "own" then
        if Config.HouseOwnedBlip.active then
            blipConf = Config.HouseOwnedBlip
            if PlayerServerId == owner then
                blipText = "Owned House"
                process = "update"
                category = 11
            else
                process = "delete"
            end
        end
    elseif type == "sale" then
        if Config.SaleHouseBlip.active then
            blipConf = Config.SaleHouseBlip
            blipText = "Sale House"
            process = "update"
            category = 10
        end
    end

    if blipConf then
        local blipId = Client.HousesBlips[houseId]
        if process == "delete" then
            if DoesBlipExist(blipId) then
                RemoveBlip(blipId)
            end
        else
            if DoesBlipExist(blipId) then
                SetBlipSprite(blipId, blipConf.sprite)
                SetBlipColour(blipId, blipConf.color)
                SetBlipScale(blipId, blipConf.scale)
                SetBlipAsShortRange(blipId, true)
                SetBlipCategory(blipId, category)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(blipText)
                EndTextCommandSetBlipName(blipId)
            else
                local House = Utils.DefaultHouses[houseId]
                Utils.Functions.AddBlipForCoord(House.door_coords, "House #" .. houseId, blipConf)
            end
        end
    end
end)

RegisterNetEvent(_e("Client:OnPlayerIntoHouse"), function(inHouse, unauthorized)
    Client.Player.inHouse = inHouse
    Client.Functions.SendReactMessage("ui:setInHouse", inHouse)
    Client.Functions.SendReactMessage("ui:setRouter", "in-house")
    Client.Functions.HouseFrameworkSync(true)
    local options = inHouse and inHouse.options or {}
    local tint = options.tint
    local lights = options?.lights
    local stairs = options.stairs
    local rooms = options?.rooms
    if lights == nil then
        lights = true
    end
    if stairs == nil then
        stairs = true
    end
    if rooms == nil then
        rooms = true
    end
    if tint then
        Client.Functions.ChangeHouseTint(inHouse.type, tint)
    end
    Client.Functions.ChangeHouseStairs(inHouse.type, stairs)
    Client.Functions.SetHouseLights(not lights)
    Client.Functions.ChangeHouseRooms(inHouse.type, rooms)
    Client.Functions.SetupHouseInside(unauthorized)
    Client.Functions.Thread_IntoHouse()
    DoScreenFadeIn(250)
end)

RegisterNetEvent(_e("Client:OnPlayerLeaveHouse"), function()
    Client.Player.inHouse = nil
    Client.Functions.ClearHouseInside()
    Client.Functions.HouseFrameworkSync(false)
    Client.Functions.SendReactMessage("ui:setRouter", "catalog")
    Client.Functions.SendReactMessage("ui:setInHouse", false)
    Client.Functions.SetHouseLights(false)
    DoScreenFadeIn(500)
end)

RegisterNetEvent(_e("Client:OnChangeHouseDetails"), function(inHouse)
    Client.Player.inHouse = inHouse
    Client.Functions.SendReactMessage("ui:setInHouse", inHouse)
end)

RegisterNetEvent(_e("Client:OnUpdateHouseGuest"), function(houseId, state)
    Client.Player.guestHouses[houseId] = state
end)

RegisterNetEvent(_e("Client:SetHouseWallColor"), function(type, tint)
    DoScreenFadeOut(100)
    while not IsScreenFadedOut() do Wait(100) end
    local state = Client.Functions.ChangeHouseTint(type, tint)
    if state then
        Client.Functions.ReLoadFurnitures(true)
    else
        DoScreenFadeIn(100)
    end
end)

RegisterNetEvent(_e("Client:SetHouseLights"), function(state)
    Client.Functions.SetHouseLights(not state)
end)

RegisterNetEvent(_e("Client:SetHouseStairs"), function(type, state)
    DoScreenFadeOut(100)
    while not IsScreenFadedOut() do Wait(100) end
    local state = Client.Functions.ChangeHouseStairs(type, state)
    if state then
        Client.Functions.ReLoadFurnitures(true)
    else
        DoScreenFadeIn(100)
    end
end)

RegisterNetEvent(_e("Client:SetHouseRooms"), function(type, state)
    DoScreenFadeOut(100)
    while not IsScreenFadedOut() do Wait(100) end
    local state = Client.Functions.ChangeHouseRooms(type, state)
    if state then
        Client.Functions.ReLoadFurnitures(true)
    else
        DoScreenFadeIn(100)
    end
end)

RegisterNetEvent(_e("Client:OnLeaveHousePermanently"), function(houseId)
    Client.Player.guestHouses[houseId] = nil
    Client.Player.ownedHouses[houseId] = nil
    Client.SoldHouses[houseId] = nil
end)

RegisterNetEvent(_e("Client:OnUpdateGuestHouses"), function(houseId, state)
    Client.Player.guestHouses[houseId] = state
    TriggerEvent(_e("Client:OnUpdateHouseBlip"), houseId, "own", state)
end)

RegisterNetEvent(_e("Client:OnUpdateOwnedHouses"), function(houseId, state)
    Client.Player.ownedHouses[houseId] = state
    TriggerEvent(_e("Client:OnUpdateHouseBlip"), houseId, "own", state)
end)

RegisterNetEvent(_e("Client:Furniture:UseDesignSeed"), function()
    Client.Functions.CloseMainPanel()
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(500) end
    Client.Functions.ReLoadFurnitures()
    DoScreenFadeIn(500)
end)

RegisterNetEvent(_e("Client:OpenCreateHousePanel"), function()
    Client.Player.inCreateHouse = true
    Client.Functions.SetupUI()
    Client.Functions.SendReactMessage("ui:setRouter", "create-house")
    Client.Functions.SendReactMessage("ui:setVisible", true)
    SetNuiFocus(true, true)
    CreateThread(function()
        while Client.Player.inCreateHouse do
            if IsControlJustPressed(0, 217) then -- [Caps]
                SetNuiFocus(true, true)
                Client.Functions.SendNotify(locale("lFurniture.focus_on_ui"), "info", 2500)
            end
            Wait(5)
        end
    end)
end)

RegisterNetEvent(_e("Client:OnPlayerIntoGarage"), function(houseId, vehicles)
    Client.Player.inGarage = houseId
    Client.Functions.SetHouseLights(false)
    Client.Functions.Thread_IntoGarage()
    Client.Functions.SetupGarageInside(vehicles)
    DoScreenFadeIn(500)
end)

RegisterNetEvent(_e("Client:OnPlayerLeaveGarage"), function(plate)
    Client.Player.inGarage = nil
    if plate then
        Client.Functions.TakeOutVehicleFromGarage(plate)
    else
        DoScreenFadeIn(500)
    end
end)

RegisterNetEvent(_e("Client:DeleteVehicleInGarage"), function(plate)
    for key, value in pairs(Client.CreatedGarageVehicles) do
        local targetPlate = GetVehicleNumberPlateText(value)
        if targetPlate == plate then
            DeleteEntity(targetPlate)
            Client.CreatedGarageVehicles[key] = nil
            break
        end
    end
end)

local lastDoorBellPlayer = nil
RegisterNetEvent(_e("Client:RingOnDoor"), function(guestName, guestSource, houseId)
    if Client.Player.inHouse and Client.Player.inHouse.houseId == houseId then
        TriggerServerEvent("InteractSound_SV:PlayOnSource", "doorbell", 0.1)
        lastDoorBellPlayer = guestSource
        Client.Functions.SendNotify(locale("player_ring_door", guestName))
    end
end)

RegisterNetEvent(_e("Client:AnswerDoorBell"), function()
    if Client.Player.inHouse and lastDoorBellPlayer then
        local response = Client.Functions.CallbackAwait(_e("Server:AnswerDoorBell"),
            lastDoorBellPlayer,
            Client.Player.inHouse.houseId)
        lastDoorBellPlayer = nil
        if response.error then
            return Client.Functions.SendNotify(locale("error", response.error), "error")
        end
        Client.Functions.SendNotify(locale("came_to_house"))
    end
end)
