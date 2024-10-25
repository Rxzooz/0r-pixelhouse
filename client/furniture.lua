--[[ Functions ]]

local gPreviewObject = nil
local gLastEditedFurniture = nil
local gPedPosition = vec3(0, 0, 0)
local gDecorationCam = nil
local gInGizmo = false

local function ClearPreviewObject()
    if gPreviewObject and DoesEntityExist(gPreviewObject) then
        DeleteEntity(gPreviewObject)
    end
    gPreviewObject = nil
    gLastEditedFurniture = nil
end

local function degToRad(degs)
    return degs * 3.141592653589793 / 180
end

local function CheckCamRotationInput(cam)
    local rightAxisX = 0.0
    local rightAxisY = 0.0

    if IsControlPressed(0, 188) then     -- W
        rightAxisY = -0.2
    elseif IsControlPressed(0, 187) then -- S
        rightAxisY = 0.2
    end

    if IsControlPressed(0, 189) then     -- A
        rightAxisX = -0.2
    elseif IsControlPressed(0, 190) then -- D
        rightAxisX = 0.2
    end

    local oldRotation = GetCamRot(cam, 2)
    local rotation = GetCamRot(cam, 2)

    if rightAxisX ~= 0.0 or rightAxisY ~= 0.0 then
        local new_z = rotation.z + rightAxisX * -1.0 * (2.0) * (4.0 + 0.1)
        local minRotation = -45.5
        local maxRotation = 45.0
        local sensitivity = 2.0
        local axisMultiplier = -1.0
        local additionalMultiplier = 4.0
        local clampMargin = 0.1
        local new_x = math.max(
            math.min(
                maxRotation,
                rotation.x + rightAxisY * axisMultiplier * sensitivity * (additionalMultiplier + clampMargin)
            ),
            minRotation
        )
        if oldRotation.z ~= new_z or oldRotation.x ~= new_x then
            SetCamRot(cam, new_x, 0.0, new_z, 2)
        end
    end
end

local function CheckCamMovementInput(cam)
    if not IsControlPressed(0, 32) and
        not IsControlPressed(0, 33) and
        not IsControlPressed(0, 34) and
        not IsControlPressed(0, 35)
    then
        return
    end
    local speed = 0.05

    local rotation = GetCamRot(cam, 2)
    local maxDistance = 20.0

    local degToRadZ = degToRad(rotation.z)
    local sinZ = math.sin(degToRadZ)
    local cosZ = math.cos(degToRadZ)
    local tanXMinusY = math.tan(degToRad(rotation.x) - degToRad(rotation.y))

    local xVect = speed * sinZ * -1.0
    local yVect = speed * cosZ
    local zVect = speed * tanXMinusY

    local playerPos = {
        x = gPedPosition.x,
        y = gPedPosition.y,
        z = gPedPosition.z,
    }

    if IsControlPressed(0, 32) then -- W
        playerPos.x = playerPos.x + xVect
        playerPos.y = playerPos.y + yVect
        playerPos.z = playerPos.z + zVect
    elseif IsControlPressed(0, 33) then -- S
        playerPos.x = playerPos.x - xVect
        playerPos.y = playerPos.y - yVect
        playerPos.z = playerPos.z - zVect
    end
    if IsControlPressed(0, 34) then -- A
        playerPos.x = playerPos.x - yVect
        playerPos.y = playerPos.y + xVect
    elseif IsControlPressed(0, 35) then -- D
        playerPos.x = playerPos.x + yVect
        playerPos.y = playerPos.y - xVect
    end

    local camPos = vec3(playerPos.x, playerPos.y, playerPos.z)
    local currentCamPos = GetCamCoord(cam)
    if camPos ~= currentCamPos then
        local houseType = Config.InteriorHouseTypes[string.lower(Client.Player.inHouse.type)]
        local intEnterCoords = vec3(houseType.enter_coords.x, houseType.enter_coords.y, houseType.enter_coords.z)
        local distance = #(intEnterCoords - currentCamPos)
        if distance < maxDistance then
            SetCamCoord(cam, camPos)
            gPedPosition = camPos
        else
            local _coord = vec3(intEnterCoords.x, intEnterCoords.y, intEnterCoords.z + 1.5)
            SetCamCoord(cam, _coord)
            gPedPosition = _coord
        end
    end
end

local function Thread__Furniture()
    CreateThread(function()
        while Client.Player.Furniture.inDecorationMode do
            if IsControlJustPressed(0, 217) then -- [Caps]
                SetNuiFocus(true, true)
                Client.Functions.SendNotify(locale("lFurniture.focus_on_ui"), "info", 2500)
            end
            HideHudAndRadarThisFrame()
            CheckCamRotationInput(gDecorationCam)
            CheckCamMovementInput(gDecorationCam)
            local previewObject = gPreviewObject
            if previewObject and DoesEntityExist(previewObject) then
                if IsControlJustPressed(0, 194) or IsControlJustPressed(0, 214) then
                    ClearPreviewObject()
                    Client.Functions.SendReactMessage("ui:furniture:setPD", nil)
                end
            end
            Wait(5)
        end
    end)
end

local function Thread_IfInGizmo()
    local _Models = {
        [GetHashKey("qua_0r_house_floor")] = true,
        [GetHashKey("qua_0r_house_floor_2")] = true,
        [GetHashKey("qua_0r_house_floor_3")] = true,
        [GetHashKey("qua_0r_house_floor_4")] = true,
        [GetHashKey("qua_0r_house_floor_5")] = true,
        [GetHashKey("qua_0r_house_floor_6")] = true,
        [GetHashKey("qua_0r_house_circlefloor")] = true,
        [GetHashKey("qua_0r_house_doorwall")] = true,
        [GetHashKey("qua_0r_house_wall")] = true,
        [GetHashKey("qua_0r_house_wall_2")] = true,
        [GetHashKey("qua_0r_house_wall_3")] = true,
        [GetHashKey("qua_0r_house_longwall")] = true,
        [GetHashKey("qua_0r_house_longwall_2")] = true,
        [GetHashKey("qua_0r_house_tallwall")] = true,
        [GetHashKey("qua_0r_house_stair_extra")] = true,
    }
    gInGizmo = true
    CreateThread(function()
        local lastEntityPosition = nil
        local lastEntityRotation = nil
        local objectId = gLastEditedFurniture?.objectId
        local model = GetHashKey(gLastEditedFurniture?.model)
        local objectPool = Client.Player.Furniture.createdFurnitures

        while gInGizmo do
            if objectId then
                local position = GetEntityCoords(objectId)
                local rotation = GetEntityRotation(objectId)

                if (not lastEntityPosition or #(lastEntityPosition - position) > 0.0) or
                    (not lastEntityRotation or #(lastEntityRotation - rotation) > 0.0)
                then
                    local isWithinRange = false
                    for _, furniture in pairs(objectPool or {}) do
                        local nearbyObject = furniture.objectId
                        if nearbyObject ~= objectId and _Models[GetEntityModel(nearbyObject)] then
                            if #(GetEntityCoords(nearbyObject) - position) < 5.0 then
                                isWithinRange = true
                                local nearbyPosition = GetEntityCoords(nearbyObject)
                                local absX, absY, absZ = 0, 0, 0
                                local drawNeeded = false
                                SetEntityDrawOutline(objectId, true)
                                SetEntityDrawOutline(nearbyObject, true)
                                absZ = math.abs(nearbyPosition.z - position.z)
                                absX = math.abs(nearbyPosition.x - position.x)
                                absY = math.abs(nearbyPosition.y - position.y)
                                if lastEntityPosition then
                                    if lastEntityPosition.y - position.y == 0.0 and lastEntityPosition.z - position.z == 0.0 then
                                        if absX < 0.005 then
                                            SetEntityDrawOutlineColor(255, 0, 0, 200)
                                            drawNeeded = true
                                        end
                                    elseif lastEntityPosition.x - position.x == 0.0 and lastEntityPosition.z - position.z == 0.0 then
                                        if absY < 0.005 then
                                            SetEntityDrawOutlineColor(0, 255, 0, 200)
                                            drawNeeded = true
                                        end
                                    elseif lastEntityPosition.x - position.x == 0.0 and lastEntityPosition.y - position.y == 0.0 then
                                        if absZ < 0.005 then
                                            SetEntityDrawOutlineColor(0, 0, 255, 200)
                                            drawNeeded = true
                                        end
                                    end
                                end
                                if not drawNeeded then
                                    SetEntityDrawOutline(nearbyObject, false)
                                end
                            else
                                SetEntityDrawOutline(nearbyObject, false)
                            end
                        end
                    end
                    lastEntityPosition = position
                    lastEntityRotation = rotation
                    if not isWithinRange then
                        SetEntityDrawOutline(objectId, false)
                    end
                end
            else
                objectId = gLastEditedFurniture?.objectId
            end
            Wait(200)
        end
        for _, value in pairs(Client.Player.Furniture.createdFurnitures) do
            SetEntityDrawOutline(value.objectId, false)
        end
    end)
end

local function CreateDecorationCamera()
    local PlayerPedId = cache.ped
    local rot = GetEntityRotation(PlayerPedId)
    local pos = GetEntityCoords(PlayerPedId, true)
    gDecorationCam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA",
        pos.x, pos.y, pos.z,
        rot.x, rot.y, rot.z,
        60.00, false, 0
    )
    SetCamActive(gDecorationCam, true)
    RenderScriptCams(true, false, 1, true, true)
end

local function SetDefaultCamera()
    RenderScriptCams(false, true, 500, true, true)
    SetCamActive(gDecorationCam, false)
    DestroyCam(gDecorationCam, true)
    DestroyAllCams(true)
end

local function OpenDecorationMode()
    Client.Player.Furniture.inDecorationMode = true
    local PlayerPedId = cache.ped
    gPedPosition = GetEntityCoords(PlayerPedId, true)
    SetEntityVisible(PlayerPedId, false)
    FreezeEntityPosition(PlayerPedId, true)
    CreateDecorationCamera()
    Utils.Functions.HideHud()
    Thread__Furniture()
    if not IsRadarHidden() then
        CreateThread(function()
            while Client.Player.Furniture.inDecorationMode do
                DisplayRadar(false)
                Wait(5)
            end
            DisplayRadar(true)
        end)
    end
end

local function CloseDecorationMode()
    Client.Player.Furniture.inDecorationMode = false
    ClearPreviewObject()
    local PlayerPedId = cache.ped
    SetEntityVisible(PlayerPedId, true)
    FreezeEntityPosition(PlayerPedId, false)
    SetDefaultCamera()
    Client.Functions.SendReactMessage("ui:furniture:setPD", nil)
    Utils.Functions.VisibleHud()
end

local function PlaceLastSelectedFurniture(position, rotation)
    local furniture = gLastEditedFurniture
    if furniture then
        local objectId = furniture.objectId
        furniture.pos = position or GetEntityCoords(objectId)
        furniture.rot = rotation or GetEntityRotation(objectId)
        ClearPreviewObject()
        Client.Functions.Callback(_e("Server:PlaceFurniture"), function(response)
            if response.error then
                return Client.Functions.SendNotify(locale("error", response.error), "error")
            end
            Client.Functions.SendNotify(locale("lFurniture.furniture_placed"), "success")
        end, furniture, Client.Player.inHouse.houseId)
    end
end

local function GetOffsetInFront(cam, distance)
    local distance = distance or 4.0
    local camCoords = GetCamCoord(cam)
    local camRot = GetCamRot(cam, 2)
    local heading = math.rad(camRot.z)
    local pitch = math.rad(camRot.x)
    local x = camCoords.x + distance * -math.sin(heading) * math.cos(pitch)
    local y = camCoords.y + distance * math.cos(heading) * math.cos(pitch)
    local z = camCoords.z + distance * math.sin(pitch)
    return vector3(x, y, z)
end

local function GetHouseStashCount()
    local furnitures = Client.Player.inHouse.furnitures
    local count = 0
    for key, furniture in pairs(furnitures) do
        local model = furniture.model
        if isModelStash(model) then
            count += 1
        end
    end
    return count
end

local function PreviewFurniture(furniture, place, buy, category)
    ClearPreviewObject()
    Wait(100)
    local modelHash = furniture.model
    if pcall(lib.requestModel, modelHash, 500) then
        if isModelStash(modelHash) then
            local houseType = Config.InteriorHouseTypes[string.lower(Client.Player.inHouse.type)]
            local max_stash_count = houseType?.max_stash_count or 10
            if GetHouseStashCount() >= max_stash_count then
                Client.Functions.SendNotify(locale("cant_place_more_stash"), "error")
                return false
            end
        end
        local offset = GetOffsetInFront(gDecorationCam, distance)
        local previewObject = CreateObject(modelHash,
            offset.x, offset.y, offset.z,
            false, false, false)
        if previewObject ~= 0 then
            gPreviewObject = previewObject
            SetEntityAsMissionEntity(previewObject, true, true)
            SetEntityCollision(previewObject, true, true)
            SetEntityCompletelyDisableCollision(previewObject, false)
            SetModelAsNoLongerNeeded(modelHash)
            CreateThread(function()
                local state = exports.object_gizmo:useGizmo(previewObject)
                gInGizmo = false
                if place then
                    PlaceLastSelectedFurniture(state.position, state.rotation)
                else
                    if DoesEntityExist(previewObject) then
                        if buy then
                            Client.Functions.Callback(_e("Server:BuyFurniture"), function(response)
                                if response.error then
                                    Client.Functions.SendNotify(locale("error", response.error), "error")
                                    ClearPreviewObject()
                                else
                                    Client.Functions.SendNotify(locale("lFurniture.new_furniture_purchased"), "success")
                                    PlaceLastSelectedFurniture(state.position, state.rotation)
                                end
                                Client.Functions.SendReactMessage("ui:furniture:setPD", nil)
                            end, furniture, Client.Player.inHouse.houseId)
                        else
                            ClearPreviewObject()
                        end
                    end
                end
            end)
            return gPreviewObject
        end
    end
    return false
end

local function OwnedFurniturePutInStorage(furniture)
    Client.Functions.Callback(_e("Server:OwnedFurniturePutInStorage"), function(response)
        if response.error then
            Client.Functions.SendNotify(locale("error", response.error), "error")
        else
            Client.Functions.SendNotify(locale("lFurniture.removed_storage"), "success")
        end
    end, furniture, Client.Player.inHouse.houseId)
end

function Client.Functions.CloseFurnitureMode()
    CloseDecorationMode()
end

--[[ Events ]]

RegisterNetEvent(_e("Client:Furniture:Place"), function(index, model, pos, rot, category, meta)
    if pcall(lib.requestModel, model, 500) then
        local createdObject = CreateObject(model, pos.x, pos.y, pos.z, false, false, false)
        if createdObject ~= 0 then
            SetEntityCoords(createdObject, pos.x, pos.y, pos.z)
            SetEntityRotation(createdObject, rot.x, rot.y, rot.z)
            SetEntityAsMissionEntity(createdObject, true, true)
            FreezeEntityPosition(createdObject, true)
            SetModelAsNoLongerNeeded(model)
            table.insert(Client.Player.Furniture.createdFurnitures, {
                index = index,
                isPlaced = true,
                objectId = createdObject,
                model = model,
                pos = pos,
                rot = rot,
                meta = meta
            })
            Client.Functions.DLC_Weed_AnyFurnitureUpdated(model, createdObject, false, meta)
            if isModelStash(model) then
                Client.Functions.CreateStashTarget(createdObject, model, meta?.stash_pass)
            end
        end
    end
end)

RegisterNetEvent(_e("Client:Furniture:PutInStorage"), function(fIndex)
    for key, value in pairs(Client.Player.Furniture.createdFurnitures) do
        if value.index == fIndex then
            Client.Functions.DLC_Weed_AnyFurnitureUpdated(value.model, value.objectId, true)
            if DoesEntityExist(value.objectId) then
                DeleteEntity(value.objectId)
            end
            table.remove(Client.Player.Furniture.createdFurnitures, key)
            break
        end
    end
end)

--[[ NUI ]]

---@param resultCallback function
RegisterNUICallback("nui:openDecorationMode", function(_, resultCallback)
    if Client.Player.inHouse then
        OpenDecorationMode()
        Client.Functions.SendReactMessage("ui:setRouter", "furniture")
    end
    resultCallback(true)
end)

---@param resultCallback function
RegisterNUICallback("nui:setNuiFocusToFalse", function(_, resultCallback)
    SetNuiFocus(false, false)
    Client.Functions.SendNotify(locale("lFurniture.focus_on_game"), "info", 2500)
    resultCallback(true)
end)

---@param resultCallback function
RegisterNUICallback("nui:closeDecorationMode", function(_, resultCallback)
    ClearPreviewObject()
    CloseDecorationMode()
    SetNuiFocus(false, false)
    Client.Functions.SendReactMessage("ui:setVisible", false)
    Client.Functions.SendReactMessage("ui:setRouter", "in-house")
    resultCallback(true)
end)

---@param furniture any
---@param resultCallback function
RegisterNUICallback("nui:previewFurniture", function(data, resultCallback)
    local furniture = data.furniture
    local category = data.category
    resultCallback(true)
    local objectId = PreviewFurniture(furniture, false, true, category)
    if objectId then
        gLastEditedFurniture = {
            category = category,
            objectId = objectId,
            model = furniture.model,
        }
        Thread_IfInGizmo()
    end
end)

---@param furniture any
---@param category string
---@param resultCallback function
RegisterNUICallback("nui:ownedFurniturePlaceGround", function(data, resultCallback)
    local furniture = data.furniture
    local category = data.category
    resultCallback(true)
    local objectId = PreviewFurniture(furniture, true)
    if objectId then
        gLastEditedFurniture = {
            category = category,
            objectId = objectId,
            model = furniture.model,
        }
        Thread_IfInGizmo()
    end
end)

---@param furniture any
---@param category string
---@param resultCallback function
RegisterNUICallback("nui:ownedFurnitureReSell", function(furniture, resultCallback)
    Client.Functions.Callback(_e("Server:OwnedFurnitureReSell"), function(response)
        if response.error then
            Client.Functions.SendNotify(locale("error", response.error), "error")
            resultCallback(false)
        else
            ClearPreviewObject()
            Client.Functions.SendNotify(locale("lFurniture.furniture_refund"), "success")
            resultCallback(true)
        end
    end, furniture, Client.Player.inHouse.houseId)
end)

---@param furniture any
---@param category string
---@param resultCallback function
RegisterNUICallback("nui:ownedFurniturePutInStorage", function(furniture, resultCallback)
    OwnedFurniturePutInStorage(furniture)
    resultCallback(true)
end)

---@param furniture any
---@param category string
---@param resultCallback function
RegisterNUICallback("nui:ownedFurnitureEdit", function(data, resultCallback)
    local _furniture, category = data.furniture, data.selectedCategory
    local furniture = Utils.Functions.deepCopy(_furniture)
    OwnedFurniturePutInStorage(furniture)
    Wait(1)
    resultCallback(true)
    local objectId = PreviewFurniture(furniture, true)
    if objectId then
        local pos = furniture.pos
        local rot = furniture.rot
        SetEntityCoords(objectId, pos.x, pos.y, pos.z)
        SetEntityRotation(objectId, rot.x, rot.y, rot.z)
        gLastEditedFurniture = {
            category = category,
            objectId = objectId,
            model = furniture.model,
        }
        Thread_IfInGizmo()
    end
end)

---@param furniture any
---@param category string
---@param resultCallback function
RegisterNUICallback("nui:furniture:clearpreview", function(_, resultCallback)
    resultCallback(true)
    ClearPreviewObject()
end)
