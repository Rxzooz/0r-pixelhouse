function Client.Functions.Thread_Houses()
    CreateThread(function()
        while not Client.Functions.IsPlayerLoaded() do
            Wait(250)
        end

        local ui_message = ""
        local isDrawTextUIOpen = false
        local playerPedId = cache.ped
        local isWithinRangeHouse = nil
        local isWithinRangeGarage = nil
        local vehiclePedIsIn = false

        local function showUI(message)
            if isDrawTextUIOpen then return end
            isDrawTextUIOpen = true
            Utils.Functions.showUI(message)
        end
        local function hideUI()
            Utils.Functions.HideTextUI()
            isDrawTextUIOpen = false
        end

        while Client.Functions.IsPlayerLoaded() do
            local sleep = 1000
            local playerCoords = GetEntityCoords(playerPedId)
            if not Client.Player.Furniture.inDecorationMode and
                not Client.Player.inCCTV
            then
                sleep = 500
                if isWithinRangeHouse then
                    local house = Utils.DefaultHouses[isWithinRangeHouse]
                    if #(playerCoords - vec3(house.door_coords.x, house.door_coords.y, house.door_coords.z)) <= 1.0 then
                        if Client.Player.ownedHouses[isWithinRangeHouse] or Client.Player.guestHouses[isWithinRangeHouse] then
                            sleep = 5
                            if not isDrawTextUIOpen then
                                ui_message = "[E] " .. locale("enter_house")
                            end
                            if IsControlJustPressed(0, 38) then -- [E]
                                Client.Functions.GetIntoHouse(isWithinRangeHouse)
                                Wait(500)
                            end
                        elseif not Client.SoldHouses[isWithinRangeHouse] then
                            sleep = 5
                            if not isDrawTextUIOpen then
                                ui_message = "[E] " .. locale("buy_house")
                            end
                            if IsControlJustPressed(0, 38) then -- [E]
                                Client.Functions.BuyHouse(isWithinRangeHouse)
                                Wait(500)
                            end
                        else
                            sleep = 5
                            local house = Client.SoldHouses[isWithinRangeHouse]
                            if not isDrawTextUIOpen then
                                ui_message = ("%s"):format(locale("x_player_house", house?.owner_name or "Player"))
                                if Config.Raid.enable then
                                    ui_message = ("%s\n[H] - Raid House \n[E] - Ring Door"):format(ui_message)
                                else
                                    ui_message = ("%s\n[E] - Ring Door"):format(ui_message)
                                end
                            end

                            if Config.Raid.enable then
                                if IsControlJustPressed(0, 74) then -- [H]
                                    Client.Functions.UnauthorizedEntry(isWithinRangeHouse)
                                    Wait(500)
                                end
                            end

                            if IsControlJustPressed(0, 38) then -- [E]
                                Client.Functions.RingDoor(isWithinRangeHouse)
                                Wait(500)
                            end
                        end
                        if not isDrawTextUIOpen then
                            showUI(ui_message)
                        end
                    else
                        isWithinRangeHouse = nil
                        if isDrawTextUIOpen then
                            hideUI()
                        end
                    end
                elseif isWithinRangeGarage then
                    local garage = Utils.DefaultHouses[isWithinRangeGarage]
                    if #(playerCoords - vec3(garage.garage_coords.x, garage.garage_coords.y, garage.garage_coords.z)) <= 3.0 then
                        if Client.Player.ownedHouses[isWithinRangeGarage] or Client.Player.guestHouses[isWithinRangeGarage] then
                            sleep = 5
                            ui_message = "[E] " .. locale("enter_garage")
                            if vehiclePedIsIn then
                                ui_message = "[E] " .. locale("add_vehicle_to_garage")
                            end
                            if IsControlJustPressed(0, 38) then -- [E]
                                Wait(500)
                                if vehiclePedIsIn then
                                    Client.Functions.AddVehicleToGarage(isWithinRangeGarage, vehiclePedIsIn)
                                else
                                    Client.Functions.GetIntoGarage(isWithinRangeGarage)
                                end
                                isWithinRangeGarage = nil
                                vehiclePedIsIn = nil
                                Wait(500)
                            end
                            showUI(ui_message)
                        end
                    else
                        isWithinRangeGarage = nil
                        vehiclePedIsIn = nil
                        if isDrawTextUIOpen then
                            hideUI()
                        end
                    end
                else
                    for key, house in pairs(Utils.DefaultHouses) do
                        if #(playerCoords - vec3(house.door_coords.x, house.door_coords.y, house.door_coords.z)) <= 1.5 then
                            isWithinRangeHouse = key
                            break
                        elseif house.garage_coords and #(playerCoords - vec3(house.garage_coords.x, house.garage_coords.y, house.garage_coords.z)) <= 3.0 then
                            isWithinRangeGarage = key
                            local _veh = GetVehiclePedIsIn(playerPedId)
                            if DoesEntityExist(_veh) and GetPedInVehicleSeat(_veh, -1) == playerPedId then
                                vehiclePedIsIn = _veh
                            end
                            break
                        end
                    end
                end

                if (not isWithinRangeGarage and not isWithinRangeHouse) and isDrawTextUIOpen then
                    hideUI()
                end
            end
            Wait(sleep)
        end
    end)
end

function Client.Functions.Thread_IntoHouse()
    if not Client.Player.inHouse then return end
    CreateThread(function()
        local isDrawTextUIOpen = false

        local interiorCoords = Config.InteriorHouseTypes[string.lower(Client.Player.inHouse?.type)]
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

        while Client.Player.inHouse do
            local sleep = 1000
            local playerCoords = GetEntityCoords(playerPedId)

            if not Client.Player.Furniture.inDecorationMode and
                not Client.Player.inCCTV
            then
                sleep = 500
                if #(playerCoords - interiorCoords.door_coords) <= 0.8 then
                    sleep = 5
                    showUI("[E] " .. locale("leave_house"))
                    if IsControlJustPressed(0, 38) then -- [E]
                        Client.Functions.LeaveHouse()
                        break
                    end
                elseif isDrawTextUIOpen then
                    hideUI()
                    isDrawTextUIOpen = false
                end
                if sleep == 500 then
                    SetInteriorProbeLength(150.0)
                end
            end
            Wait(sleep)
        end
        if isDrawTextUIOpen then
            hideUI()
        end
    end)
end

function Client.Functions.Thread_IntoGarage()
    if not Client.Player.inGarage then return end
    CreateThread(function()
        local isDrawTextUIOpen = false
        local interiorCoords = Config.InteriorHouseGarage.coords
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

        while Client.Player.inGarage do
            local sleep = 500
            local playerCoords = GetEntityCoords(playerPedId)

            if #(playerCoords - interiorCoords.exit) <= 3.0 then
                sleep = 5
                showUI("[E] " .. locale("leave_garage"))
                if IsControlJustPressed(0, 38) then -- [E]
                    Client.Functions.LeaveGarage()
                    break
                end
            elseif isDrawTextUIOpen then
                hideUI()
                isDrawTextUIOpen = false
            end
            Wait(sleep)
        end
        if isDrawTextUIOpen then
            hideUI()
        end
    end)
end

function Client.Functions.Thread__CCTV()
    CreateThread(function()
        local function destroyCCTV()
            ClearFocus()
            ClearTimecycleModifier()
            ClearExtraTimecycleModifier()
            RenderScriptCams(false, false, 0, true, false)
            DestroyCam(currentCam, false)
            SetFocusEntity(cache.ped)
            Client.Functions.CCTV.CloseCameraMode()
        end

        local camCoords = Utils.DefaultHouses[Client.Player?.inHouse?.houseId]?.door_coords
        if not camCoords then return end
        local cmc = vec3(camCoords.x, camCoords.y, camCoords.z + 0.5)
        local currentCam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", cmc, vec3(0.0, 0.0, 0.0), 60.0)

        local function InstructionButtonMessage(text)
            BeginTextCommandScaleformString("STRING")
            AddTextComponentScaleform(text)
            EndTextCommandScaleformString()
        end

        local function CreateInstuctionScaleform(scaleform)
            local scaleform = RequestScaleformMovie(scaleform)
            while not HasScaleformMovieLoaded(scaleform) do
                Wait(1)
            end
            PushScaleformMovieFunction(scaleform, "CLEAR_ALL")
            PopScaleformMovieFunctionVoid()

            PushScaleformMovieFunction(scaleform, "SET_CLEAR_SPACE")
            PushScaleformMovieFunctionParameterInt(200)
            PopScaleformMovieFunctionVoid()

            PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
            PushScaleformMovieFunctionParameterInt(2)
            ScaleformMovieMethodAddParamPlayerNameString(GetControlInstructionalButton(1, Config.CCTV.Controls.ZoomOut,
                true))
            ScaleformMovieMethodAddParamPlayerNameString(GetControlInstructionalButton(1, Config.CCTV.Controls.ZoomIn,
                true))
            InstructionButtonMessage(locale("cctv.zoom"))
            PopScaleformMovieFunctionVoid()

            PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
            PushScaleformMovieFunctionParameterInt(0)
            ScaleformMovieMethodAddParamPlayerNameString(GetControlInstructionalButton(1, Config.CCTV.Controls.Exit, true))
            InstructionButtonMessage(locale("cctv.exit"))
            PopScaleformMovieFunctionVoid()

            PushScaleformMovieFunction(scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
            PopScaleformMovieFunctionVoid()

            PushScaleformMovieFunction(scaleform, "SET_BACKGROUND_COLOUR")
            PushScaleformMovieFunctionParameterInt(0)
            PushScaleformMovieFunctionParameterInt(0)
            PushScaleformMovieFunctionParameterInt(0)
            PushScaleformMovieFunctionParameterInt(80)
            PopScaleformMovieFunctionVoid()

            return scaleform
        end
        local instructions = CreateInstuctionScaleform("instructional_buttons")

        local function CheckCamRotationInput(cam)
            local rightAxisX = GetDisabledControlNormal(0, 220)
            local rightAxisY = GetDisabledControlNormal(0, 221)
            if rightAxisX ~= 0.0 or rightAxisY ~= 0.0 then
                local rotation = GetCamRot(cam, 2)
                local new_z = rotation.z + rightAxisX * -1.0 * 2.0 * (4.0 + 0.1)
                local new_x = math.max(
                    math.min(40.0, rotation.x + rightAxisY * -1.0 * 2.0 * (4.0 + 0.1)),
                    -40.5
                )
                SetCamRot(cam, new_x, 0.0, new_z, 2)
            end
        end

        SetNuiFocus(false, false)
        ClearFocus()
        SetCamActive(currentCam, true)
        RenderScriptCams(true, false, 0, true, false)
        SetCamFov(currentCam, 70.0)
        SetFocusEntity(vehicle, true)
        SetTimecycleModifier("scanline_cam_cheap")
        SetTimecycleModifierStrength(2.0)
        Wait(500)
        DoScreenFadeIn(250)
        RequestAmbientAudioBank("Phone_Soundset_Franklin", 0, 0)
        RequestAmbientAudioBank("HintCamSounds", 0, 0)

        while Client.Player.inCCTV do
            Wait(5)
            DisableAllControlActions(0)
            HideHudAndRadarThisFrame()

            CheckCamRotationInput(currentCam)
            DrawScaleformMovieFullscreen(instructions, 255, 255, 255, 255, 0)

            if IsDisabledControlPressed(0, Config.CCTV.Controls.ZoomOut) then
                local fov = GetCamFov(currentCam)
                if fov < Config.CCTV.MinZoom then
                    SetCamFov(currentCam, fov + 1.0)
                end
            end

            if IsDisabledControlPressed(0, Config.CCTV.Controls.ZoomIn) then
                local fov = GetCamFov(currentCam)
                if fov > Config.CCTV.MaxZoom then
                    SetCamFov(currentCam, fov - 1.0)
                end
            end

            if IsDisabledControlJustPressed(0, Config.CCTV.Controls.Exit) then
                DoScreenFadeOut(500)
                while not IsScreenFadedOut() do Wait(100) end
                destroyCCTV()
                Wait(1000)
                DoScreenFadeIn(500)
                break
            end
        end
    end)
end
