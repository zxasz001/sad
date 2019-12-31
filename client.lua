local script_name = "scotty-casino-pokdeng"
-- local script_active = false

-- RegisterNetEvent("scotty:license_"..script_name)
-- AddEventHandler("scotty:license_"..script_name, function(state)
--     if script_active ~= true and state then
--         LoadScript()
--     end
    
--     if not state then
--         print("checking license server fail")
--     end
-- end)

-- Citizen.CreateThread(function()
--     Citizen.Wait(5000)

--     TriggerServerEvent("scotty:license_"..script_name)
-- end)

-- function LoadScript()
    -- print("Loading " .. script_name)

    if Config == nil then
        print("Failed to load " .. script_name .. " because of config is nil")
        return
    end
    
    script_active = true
    ESX = nil
    
    Citizen.CreateThread(function()
        while ESX == nil do
            TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
            Citizen.Wait(0)
        end
        
        SendNUIMessage({
            action = 'config',
            unique = "game_time",
            data = Config["game_time"]
        })
    end)
    
    local sarabunFont
    
    Citizen.CreateThread(function()
        RegisterFontFile('sarabun')
        sarabunFont = RegisterFontId('Sarabun')
    end)
    
    local GD = {} 
	GD.Table = -1
    local menu_active = nil
    local menu_cd = nil
    
    RegisterCommand("jointable", function()
        TriggerServerEvent("scotty-cpk:gameReceive", 1, "join")
        SetNuiFocus(true, true)
    end)
    
    RegisterCommand("leavetable", function()
        TriggerServerEvent("scotty-cpk:gameReceive", GD.Table, "leave")
        SetNuiFocus(false, false)
    end)
    
    RegisterNUICallback("PokDeng", function(data, cb)
        if data.action == "bet" then
            local money = tonumber(ESX.GetPlayerData().money) or 0
            if money and tonumber(money) >= tonumber(data.amount) then
                TriggerServerEvent("scotty-cpk:gameReceive", GD.Table, "bet", tonumber(data.amount))
            else
                SendNUIMessage({
                    action = 'dialog',
                    title = "กรุณาเปลี่ยนเงินเดิมพัน",
                    message = "เงินเดิมพันของคุณไม่เพียงพอที่จะลง คุณมี $"..string.Comma(money),
                })
            end
        elseif data.action == "morecard" then
            TriggerServerEvent("scotty-cpk:gameReceive", GD.Table, "morecard")
        elseif data.action == "pass" then
            TriggerServerEvent("scotty-cpk:gameReceive", GD.Table, "pass")
        elseif data.action == "close" then
            TriggerServerEvent("scotty-cpk:gameReceive", GD.Table, "leave")
            menu_active = nil 
			menu_cd = GetGameTimer() + 1000
            SetNuiFocus(false, false)
        end
    end)
    
    function JoinDeskTable(num)
        TriggerServerEvent("scotty-cpk:gameReceive", num, "join")
    end
    
    function LeaveDeskTable(no_fetch)
        if not no_fetch then
            TriggerServerEvent("scotty-cpk:gameReceive", num, "leave")
        end

        menu_active = nil
        menu_cd = GetGameTimer() + 1000
        SetNuiFocus(false, false)

        SendNUIMessage({
            action = 'close'
        })
    end
    
    RegisterNetEvent("scotty-cpk:fetchGame")
    AddEventHandler("scotty-cpk:fetchGame", function(desk, action, data)
        if action == "playerCount" then
            local config = Config["desk"][desk]
            config.pl_count = data or 0
        elseif action == "fetchGame" then
            local config = Config["desk"][desk]
            data.config = config
            
            SendNUIMessage({
                action = 'fetchGame',
                data = data
            })
            
            GD.Table = desk
            if menu_active == nil then
                menu_active = true
                
                SendNUIMessage({
                    action = 'show'
                })
                
                SetNuiFocus(true, true)
            end
        elseif action == "player_join" then
            SendNUIMessage({
                action = 'player_join',
                name = data.name or "UNKNOWN",
                seat = data.seat, 
				src = data.src,
                desk = desk,
                isply = (data.src == GetPlayerServerId(PlayerId()))
            })
            GD.Table = desk
        elseif action == "player_leave" then
            SendNUIMessage({
                action = 'player_leave',
                seat = data.seat,
            })
            if data.src == GetPlayerServerId(PlayerId()) then
            GD.Table = -1 end
        elseif action == "player_bet" then
            SendNUIMessage({
                action = 'player_bet',
                seat = data.seat,
                chip = data.chip,
            })
        elseif action == "kickPlayer" then
            print("kick this player")
            LeaveDeskTable(true)
        elseif action == "state" then
            SendNUIMessage({
                action = 'state',
                state = data
            })
        elseif action == "dealcard" then
            local desk = {}
            for k, v in pairs(data.player) do
                if v[1] then
                    table.insert(desk, {
                        player = "player"..k,
                        card = {
                            card1 = v[1],
                            card2 = v[2],
                            score = v[4]
                        }
                    })
                end
            end
            
            table.insert(desk, {
                player = "dealer",
                card = {
                    card1 = data.dealer[1],
                    card2 = data.dealer[2],
                    score = data.dealer[4]
                }
            })
            
            SendNUIMessage({
                action = 'dealcard',
                data = desk
            })
        elseif action == "morecard_deal" then
            local seat = (data.isply and "player" .. data.seat or "dealer")
            
            SendNUIMessage({
                action = 'morecard_deal',
                seat = seat,
                card = data.data
            })
        elseif action == "morecard_turn" then
            SendNUIMessage({
                action = 'morecard_turn',
                state = data.state,
                seat = data.seat,
                dura = data.dura
            })
        elseif action == "result" then
            SendNUIMessage({
                action = 'result',
                data = data,
            })
        elseif action == "dealer_text" then
            SendNUIMessage({
                action = 'dealer_text',
                text = data,
            })
        elseif action == "dealer_closed" then
            SendNUIMessage({
                action = 'dealer_closed',
            })
        end
        
        local money = ESX.GetPlayerData().money
        SendNUIMessage({
            action = 'money_fetch',
            money = money
        })
    end)
    
    local delay
    
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            local pos = GetEntityCoords(PlayerPedId())

            if not IsEntityDead(PlayerPedId()) then
                for k, v in ipairs(Config["desk"]) do
                    if v.position ~= nil then
                        if v.ent == nil then
                            if ESX then v.ent = true
                                if v.map_blip then
                                    v.blip = AddBlipForCoord(v.position.x, v.position.y, v.position.z)
                                    SetBlipSprite(v.blip, v.blip_id or 431)
                                    SetBlipDisplay(v.blip, 2)
                                    SetBlipScale(v.blip, v.blip_scale or 0.5)
                                    SetBlipColour(v.blip, v.blip_color or 35)
                                    SetBlipAsShortRange(v.blip, true)
                                    BeginTextCommandSetBlipName("STRING")
                                    AddTextComponentString(v.blip_name or "Pok Deng Table")
                                    EndTextCommandSetBlipName(v.blip)
                                end
                                
                                Citizen.CreateThread(function()
                                    local bench = GetHashKey("vw_prop_casino_blckjack_01")
                                    local ped = GetHashKey("s_m_m_highsec_02")
                                    RequestModel(bench)
                                    RequestModel(ped)
                                    
                                    while not HasModelLoaded(bench) or not HasModelLoaded(ped) do
                                        Citizen.Wait(1)
                                    end
                                    
                                    local ent = CreateObject(bench, v.position.x, v.position.y, v.position.z, false, false, true)
                                    SetEntityHeading(ent, v.position.h or 0)
                                    FreezeEntityPosition(ent, true)
                                    SetEntityInvincible(ent, true)
                                    SetModelAsNoLongerNeeded(bench)
                                    local pos = GetOffsetFromEntityInWorldCoords(ent, 0.0, 1.0, 0.0)
                                    local cassy = CreatePed(5, ped, pos.x, pos.y, pos.z, v.position.h + 180, false, false)
                                    FreezeEntityPosition(cassy, true)
                                    SetEntityInvincible(cassy, true)
                                    SetBlockingOfNonTemporaryEvents(cassy, true)
                                    SetModelAsNoLongerNeeded(ped)
                                    Config["desk"][k].ent = ent
                                    Config["desk"][k].ped = cassy
                                end)
                            end
                        end
                        
                        local dist = GetDistanceBetweenCoords(v.position["x"], v.position["y"], v.position["z"], pos.x, pos.y, pos.z, true)
                        
                        if v.ent and type(v.ent) == "number" and not menu_active and dist <= (v.name_distance or 7.0) then
                            draw.Simple3DText(v.position["x"], v.position["y"], v.position["z"] + (v.name_height or 2), v.name, (v.name_scale or 2))
                            local count = v.pl_count or 0
                            draw.Simple3DText(v.position["x"], v.position["y"], v.position["z"] + (v.name_height and v.name_height - 0.4 or 1.6), string.format(Config["translate"]["player_count"], count, 5), (v.name_scale and v.name_scale / 2 or 1))
                            draw.Simple3DText(v.position["x"], v.position["y"], v.position["z"] + (v.name_height and v.name_height - 1 or 1.5), string.format("ขั้นต่ำ $%s สูงสุด $%s", string.Comma(v.minimum), string.Comma(v.maximum)), (v.name_scale and v.name_scale / 4 or 0.5))
                        end
                        
                        if dist <= (v.max_distance or 2.05) and not menu_active and (not menu_cd or menu_cd and menu_cd <= GetGameTimer())then
                            SetTextComponentFormat('STRING')
                            AddTextComponentString("press ~INPUT_CONTEXT~ to join ~y~Pok Deng")
                            DisplayHelpTextFromStringLabel(0, 0, 1, -1)
                            if IsControlPressed(0, 38) and (not delay or delay and delay < GetGameTimer()) then
                                JoinDeskTable(k) 
								delay = GetGameTimer() + 1000
                            end
                        end
                    end
                end
            elseif menu_active then
                LeaveDeskTable()
            end
        end
    end)
    
    draw = draw or {}
    
    function draw.Simple3DText(x, y, z, text, sc)
        local onScreen, _x, _y = World3dToScreen2d(x, y, z)
        local p = GetGameplayCamCoords()
        local distance = GetDistanceBetweenCoords(p.x, p.y, p.z, x, y, z, 1)
        local scale = (1 / distance) * 2
        local fov = (1 / GetGameplayCamFov()) * 100 scale = scale * fov
        
        if sc then
            scale = scale * sc
        end
        
        if onScreen then
            SetTextScale(0.0 * scale, 0.35 * scale)
            SetTextFont(sarabunFont)
            SetTextProportional(1)
            SetTextColour(255, 255, 255, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(2, 0, 0, 0, 150)
            SetTextDropShadow()
            SetTextOutline()
            SetTextEntry("STRING")
            SetTextCentre(1)
            AddTextComponentString(text)
            DrawText(_x, _y)
        end
    end
    
    function PlayAnim(anim, param, duration, flag)
        Citizen.CreateThread(function()
            RequestAnimDict(anim)
            local time = GetGameTimer() + 1000
            while not (HasAnimDictLoaded(anim) and time > GetGameTimer()) do
                Citizen.Wait(0)
            end
            
            ClearPedTasks(PlayerPedId())
            TaskPlayAnim(PlayerPedId(), anim, param or "Loop", 8.0, 8.0, duration, flag or 63, 0, 0, 0, 0)
        end)
    end
    
    if Config["developer"] then
        RegisterCommand("sc_pokdeng", function()
            local ped = PlayerPedId()
            local pos = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.0, 0.0)
            local heading = GetEntityHeading(ped)
            
            Citizen.CreateThread(function()
                local bench = GetHashKey("vw_prop_casino_blckjack_01")
                local ped = GetHashKey("s_m_m_highsec_02")
                RequestModel(bench)
                RequestModel(ped)
                
                while not HasModelLoaded(bench) or not HasModelLoaded(ped) do
                    Citizen.Wait(1)
                end
                
                local ent = CreateObject(bench, pos.x, pos.y, pos.z, false, false, true)
                SetEntityHeading(ent, heading or 0)
                FreezeEntityPosition(ent, true)
                SetEntityInvincible(ent, true)
                PlaceObjectOnGroundProperly(ent)
                SetModelAsNoLongerNeeded(bench)
                pos = GetEntityCoords(ent)
                heading = GetEntityHeading(ent)
                local text = string.format("{ x = %.2f, y = %.2f, z = %.2f, h = %.2f }", pos.x, pos.y, pos.z, heading)
                SendNUIMessage({action = "copy-clipboard", text = text})
                local pos = GetOffsetFromEntityInWorldCoords(ent, 0.0, 1.0, 0.0)
                local cassy = CreatePed(5, ped, pos.x, pos.y, pos.z, heading + 180, false, false)
                SetModelAsNoLongerNeeded(ped)
                
                print(text)
                print("Copied to clipboard!")
                
                Citizen.Wait(5000)
                DeleteObject(ent)
                DeletePed(cassy)
            end)
        end, true)
    end

    function string.Comma(number)
        if tonumber(number) then
            number = string.format("%f", number)
            number = string.match(number, "^(.-)%.?0*$")
        end
        
        local k
        while true do
            number, k = string.gsub(number, "^(-?%d+)(%d%d%d)", "%1,%2")
            if (k == 0) then
                break
            end
        end
        
        return number
    end
    
-- end
