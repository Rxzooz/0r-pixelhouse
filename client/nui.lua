---@param data boolean
---@param resultCallback function
RegisterNUICallback("nui:hideFrame", function(data, resultCallback)
    SetNuiFocus(false, false)
    if not data then
        Client.Functions.SendReactMessage("ui:setVisible", false)
    end
    resultCallback(true)
end)

---@param coords vector3
---@param resultCallback function
RegisterNUICallback("nui:setNewWayPoint", function(coords, resultCallback)
    SetNewWaypoint(coords.x, coords.y)
    Client.Functions.SendNotify(locale("coord_marked_on_map"), "success")
    resultCallback(true)
end)

---@param data {houseId: number, type: string}
---@param resultCallback function
RegisterNUICallback("nui:purchaseHouse", function(data, resultCallback)
    local houseId = data.houseId
    local houseType = data.type
    Client.Functions.Callback(_e("Server:PurchaseHouse"), function(response)
        if not response.error then
            Client.Functions.SendNotify(locale("house_purchased", houseId), "success")
            Client.Functions.CloseMainPanel()
            resultCallback(true)
        else
            Client.Functions.SendNotify(locale("error", response.error), "error")
            resultCallback(false)
        end
    end, houseId, houseType)
end)

---@param state boolean
---@param resultCallback function
RegisterNUICallback("nui:toggleHouseLights", function(state, resultCallback)
    if Client.Player.inHouse then
        Client.Functions.Callback(_e("Server:UpdateHouseLights"), function(response)
            if response.error then
                Client.Functions.SendNotify(locale("error", response.error), "error")
                return resultCallback({ result = false })
            end
            return resultCallback({ result = true, state = state })
        end, state, Client.Player.inHouse.houseId)
    end
end)

---@param state boolean
---@param resultCallback function
RegisterNUICallback("nui:toggleHouseStairs", function(state, resultCallback)
    if Client.Player.inHouse and Config.EditableStairs then
        Client.Functions.Callback(_e("Server:UpdateHouseStairs"), function(response)
            if response.error then
                Client.Functions.SendNotify(locale("error", response.error), "error")
                return resultCallback({ result = false })
            end
            return resultCallback({ result = true, state = state })
        end, state, Client.Player.inHouse.houseId)
    end
end)

---@param state boolean
---@param resultCallback function
RegisterNUICallback("nui:toggleHouseRooms", function(state, resultCallback)
    if Client.Player.inHouse and Config.EditableRooms then
        Client.Functions.Callback(_e("Server:UpdateHouseRooms"), function(response)
            if response.error then
                Client.Functions.SendNotify(locale("error", response.error), "error")
                return resultCallback({ result = false })
            end
            return resultCallback({ result = true, state = state })
        end, state, Client.Player.inHouse.houseId)
    end
end)

---@param color number
---@param resultCallback function
RegisterNUICallback("nui:changeWallColor", function(color, resultCallback)
    if Client.Player.inHouse then
        Client.Functions.Callback(_e("Server:ChangeHouseTint"), function(response)
            if response.error then
                Client.Functions.SendNotify(locale("error", response.error), "error")
                return resultCallback({ result = false })
            end
            return resultCallback({ result = true, state = color })
        end, color, Client.Player.inHouse.houseId)
    end
end)

---@param sourceId number
---@param resultCallback function
RegisterNUICallback("nui:addPermission", function(sourceId, resultCallback)
    if Client.Player.inHouse then
        Client.Functions.Callback(_e("Server:AddPermission"), function(response)
            if response.error then
                Client.Functions.SendNotify(locale("error", response.error), "error")
                return resultCallback({ result = false })
            end
            return resultCallback({ result = true, state = response.state })
        end, tonumber(sourceId), Client.Player.inHouse.houseId)
    end
end)

---@param userId number
---@param resultCallback function
RegisterNUICallback("nui:removePermission", function(userId, resultCallback)
    if Client.Player.inHouse then
        Client.Functions.Callback(_e("Server:RemovePermission"), function(response)
            if response.error then
                Client.Functions.SendNotify(locale("error", response.error), "error")
                return resultCallback({ result = false })
            end
            return resultCallback({ result = true, state = userId })
        end, userId, Client.Player.inHouse.houseId)
    end
end)

---@param resultCallback function
RegisterNUICallback("nui:leaveHousePermanently", function(_, resultCallback)
    if Client.Player.inHouse then
        Client.Functions.CloseMainPanel()
        Client.Functions.Callback(_e("Server:LeaveHousePermanently"), function(response)
            if response.error then
                Client.Functions.SendNotify(locale("error", response.error), "error")
                return resultCallback({ result = false })
            end
            return resultCallback({ result = true })
        end, Client.Player.inHouse.houseId)
    end
end)

---@param targetIdentity string
---@param resultCallback function
RegisterNUICallback("nui:ownerTransfer", function(targetIdentity, resultCallback)
    if Client.Player.inHouse then
        Client.Functions.Callback(_e("Server:HouseOwnerTransfer"), function(response)
            if response.error then
                Client.Functions.SendNotify(locale("error", response.error), "error")
                return resultCallback({ result = false })
            end
            Client.Functions.CloseMainPanel()
            return resultCallback({ result = true })
        end, targetIdentity, Client.Player.inHouse.houseId)
    end
end)

---@param resultCallback function
RegisterNUICallback("nui:generateDesignSeed", function(_, resultCallback)
    if Client.Player.inHouse then
        Client.Functions.Callback(_e("Server:GenerateDesignSeed"), function(response)
            if response.error then
                Client.Functions.SendNotify(locale("error", response.error), "error")
                return resultCallback({ result = false })
            end
            return resultCallback({ result = true, state = response.state })
        end, Client.Player.inHouse.houseId)
    end
end)

---@param seed number
---@param resultCallback function
RegisterNUICallback("nui:useDesignSeed", function(seed, resultCallback)
    if Client.Player.inHouse then
        Client.Functions.Callback(_e("Server:UseDesignSeed"), function(response)
            if response.error then
                Client.Functions.SendNotify(locale("error", response.error), "error")
                return resultCallback({ result = false })
            end
            return resultCallback({ result = true })
        end, seed, Client.Player.inHouse.houseId)
    end
end)

---@param type "electricity" | "power" | "gas" | "water"
---@param resultCallback function
RegisterNUICallback("nui:buyIndicatorByType", function(type, resultCallback)
    if Client.Player.inHouse then
        Client.Functions.Callback(_e("Server:BuyIndicator"), function(response)
            if response.error then
                Client.Functions.SendNotify(locale("error", response.error), "error")
                return resultCallback({ result = false })
            end
            return resultCallback({ result = true })
        end, type, Client.Player.inHouse.houseId)
    end
end)

---@param resultCallback function
RegisterNUICallback("nui:openCCTV", function(_, resultCallback)
    if Config.CCTV.Enabled and Client.Player.inHouse then
        Client.Functions.SendReactMessage("ui:setVisible", false)
        if not Client.Player.inCCTV then
            Client.Functions.CCTV.Open()
        end
    end
    resultCallback(true)
end)

---@param data {houseId: number, type: string}
---@param resultCallback function
RegisterNUICallback("nui:visitHouse", function(data, resultCallback)
    local houseId = data.houseId
    local type = data.type
    Client.Functions.VisitHouse(houseId, type)
    Client.Functions.CloseMainPanel()
    resultCallback(true)
end)

---@param resultCallback function
RegisterNUICallback("nui:getPlayerCoords", function(_, resultCallback)
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local w = GetEntityHeading(ped)
    local street1, street2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local info = string.format("%s %s",
        GetStreetNameFromHashKey(street1),
        GetStreetNameFromHashKey(street2))
    resultCallback({
        coords = {
            x = coords.x,
            y = coords.y,
            z = coords.z,
            w = w
        },
        info = info
    })
end)

---@param data HouseType
---@param resultCallback function
RegisterNUICallback("nui:createNewHouse", function(data, resultCallback)
    Client.Functions.Callback(_e("Server:CreateNewHouse"), function(response)
        if response.error then
            Client.Functions.SendNotify(locale("error", response.error), "error")
            return resultCallback(false)
        end
        Client.Functions.SendNotify(locale("created_new_house"), "success")
        return resultCallback(true)
    end, data)
    resultCallback(true)
end)

---@param resultCallback function
RegisterNUICallback("nui:outInCreateHouse", function(_, resultCallback)
    Client.Player.inCreateHouse = false
    resultCallback(true)
end)

---@param colorId id
---@param resultCallback function
RegisterNUICallback("nui:changeGarageWallColor", function(colorId, resultCallback)
    local function GarageTint(id)
        local interiorID = GetInteriorAtCoords(520.00000000, -2625.00000000, -39.69168000)
        if IsValidInterior(interiorID) then
            SetInteriorEntitySetColor(interiorID, "tint", tonumber(id))
            RefreshInterior(interiorID)
        end
    end
    GarageTint(tonumber(colorId))
    Client.Functions.SendNotify(locale("garage_theme_changed"), "success")
    resultCallback(true)
end)

---@param data {type:string,message:string}
---@param resultCallback function
RegisterNUICallback("nui:sendNotify", function(data, resultCallback)
    Client.Functions.SendNotify(data.message, data.type)
    resultCallback(true)
end)
