NoVR = NoVR or {}

DoIncludeScript("novr_config.lua", nil)
if not NOVR_LUA then
    return
end

if GlobalSys:CommandLineCheck("-novr") then
    function NovrAdsZoomed()
        return NoVR.AdsZoomed ~= nil and NoVR.AdsZoomed() ~= nil
    end

    function NovrHipViewmodelName(name)
        if not name then return "" end
        return (string.gsub(name, "_ads%.vmdl$", ".vmdl"))
    end

    function NovrClearAds()
        if NovrAdsZoomed() then
            SendToConsole("+customattack2;-customattack2")
            return
        end
        local viewmodel = Entities:FindByClassname(nil, "viewmodel")
        if viewmodel and string.match(viewmodel:GetModelName(), "_ads%.vmdl$") then
            ViewmodelAnimation_ADStoHIP()
        end
        if NoVR.AdsZoom then NoVR.AdsZoom(0) end
    end

    require "storage"
    collidable_props = {
        "models/props_c17/oildrum001.vmdl",
        "models/props/plastic_container_1.vmdl",
        "models/industrial/industrial_board_01.vmdl",
        "models/industrial/industrial_board_02.vmdl",
        "models/industrial/industrial_board_03.vmdl",
        "models/industrial/industrial_board_04.vmdl",
        "models/industrial/industrial_board_05.vmdl",
        "models/industrial/industrial_board_06.vmdl",
        "models/industrial/industrial_board_07.vmdl",
        "models/industrial/industrial_chemical_barrel_02.vmdl",
        "models/props/barrel_plastic_1.vmdl",
        "models/props/barrel_plastic_1_open.vmdl",
        "models/props_c17/oildrum001_explosive.vmdl",
        "models/props_junk/wood_crate001a.vmdl",
        "models/props_junk/wood_crate002a.vmdl",
        "models/props_junk/wood_crate004.vmdl",
        "models/props/interior_furniture/interior_shelving_001_b.vmdl",
        "models/props/interior_chairs/interior_chair_001.vmdl",
        "models/props_junk/trashbin02_open.vmdl",
    }
    DoIncludeScript("flashlight.lua", nil)
    DoIncludeScript("wristpockets.lua", nil)
    DoIncludeScript("viewmodels.lua", nil)
    DoIncludeScript("viewmodels_animation.lua", nil)

    local function NovrFireKey()
        return NoVR.KeyForCommand("+customattack")
            or NoVR.KeyForCommand("novr_shootcombinegun")
            or NoVR.KeyForCommand("shootvortenergy")
            or NoVR.KeyForCommand("shootadvisorvortenergy")
    end
    local function NovrBorrowFire(verb)
        NoVR.BorrowKey(NovrFireKey(), verb)
    end
    local function NovrReturnFire()
        NoVR.ReturnBorrowed("novr_shootcombinegun")
        NoVR.ReturnBorrowed("shootvortenergy")
        NoVR.ReturnBorrowed("shootadvisorvortenergy")
    end

    if player_hurt_ev ~= nil then
        StopListeningToGameEvent(player_hurt_ev)
    end

    player_hurt_ev = ListenToGameEvent('player_hurt', function(info)
        local player = Entities:GetLocalPlayer()

        if info.health == 0 then
            PlayerDied()
            player:SetThink(function()
                PlayerDied()
            end, "UnpauseOnDeath1", 0)
            player:SetThink(function()
                PlayerDied()
            end, "UnpauseOnDeath2", 0.02)
        elseif player:Attribute_GetIntValue("syringe_tutorial_shown_damage", 0) == 0 then
            if GetMapName() ~= "a1_intro_world_2" then
                NoVR.ShowHint("syringe")
                player:Attribute_SetIntValue("syringe_tutorial_shown_damage", 1)
            end
        end

    end, nil)

    if entity_killed_ev ~= nil then
        StopListeningToGameEvent(entity_killed_ev)
    end

    entity_killed_ev = ListenToGameEvent('entity_killed', function(info)
        local player = Entities:GetLocalPlayer()
        player:SetThink(function()
            function GibBecomeRagdoll(classname)
                ent = Entities:FindByClassname(nil, classname)
                while ent do
                    if vlua.find(ent:GetModelName(), "models/creatures/headcrab_classic/headcrab_classic_gib") or vlua.find(ent:GetModelName(), "models/creatures/headcrab_armored/armored_hc_gib") then
                        DoEntFireByInstanceHandle(ent, "BecomeRagdoll", "", 0.01, nil, nil)
                    end
                    ent = Entities:FindByClassname(ent, classname)
                end
            end

            GibBecomeRagdoll("prop_physics")
            GibBecomeRagdoll("prop_ragdoll")
        end, "GibBecomeRagdoll", 0)

        local ent = EntIndexToHScript(info.entindex_killed):GetChildren()[1]
        if ent and ent:GetClassname() == "weapon_smg1" then
            ent:SetThink(function()
                if ent:GetMoveParent() then
                    return 0
                else
                    DoEntFireByInstanceHandle(ent, "BecomeRagdoll", "", 0.02, nil, nil)
                end
            end, "BecomeRagdollWhenNoParent", 0)
        end
    end, nil)

    if changelevel_ev ~= nil then
        StopListeningToGameEvent(changelevel_ev)
    end

    changelevel_ev = ListenToGameEvent('change_level_activated', function(info)
        SendToConsole("r_drawvgui 0")
    end, nil)

    if pickup_ev ~= nil then
        StopListeningToGameEvent(pickup_ev)
    end

    pickup_ev = ListenToGameEvent('physgun_pickup', function(info)
        SendToConsole("novr_resetads")
        local player = Entities:GetLocalPlayer()
        local ent = EntIndexToHScript(info.entindex)
        if ent then
            if ent:GetClassname() == "item_hlvr_grenade_frag" or ent:GetClassname() == "item_hlvr_grenade_xen" or ent:GetClassname() == "item_hlvr_combine_console_tank" or ent:GetClassname() == "item_healthvial" then
                ent:Attribute_SetIntValue("picked_up", 1)
                ent:SetThink(function()
                    SendToConsole("r_drawviewmodel 0")
                    if ent:GetMass() == 1 then
                        return 0
                    end

                    DoEntFireByInstanceHandle(ent, "RunScriptFile", "drop_object", 0, nil, nil)
                end, "CheckGrenadeDrop", 0.02)
            end
            local child = ent:GetChildren()[1]
            if child and child:GetClassname() == "prop_dynamic" then
                child:SetEntityName("held_prop_dynamic_override")
            end
            if ent:GetClassname() ~= "item_healthvial" and ent:GetClassname() ~= "item_hlvr_grenade_frag" and ent:GetClassname() ~= "item_hlvr_grenade_xen" and ent:GetClassname() ~= "item_hlvr_combine_console_tank" and ent:GetClassname() ~= "item_healthvial" then
                ent:Attribute_SetIntValue("picked_up", 1)
                ent:SetThink(function()
                    local ent2 = Entities:FindByName(nil, "hat_construction_viewmodel")
                    local ent3 = Entities:FindByName(nil, "respirator_viewmodel")
                    if ent2 == nil and ent3 == nil then
                        return
                    end

                    if ent:GetModelName() ~= "models/interaction/anim_interact/hand_crank_wheel/hand_crank_wheel.vmdl" then
                        SendToConsole("r_drawviewmodel 0")
                    end
                end, "DoesEntStillExist", 0.02)
            end
            player:Attribute_SetIntValue("picked_up", 1)
            player:SetThink(function()
                player:Attribute_SetIntValue("picked_up", 0)
            end, "ResetPickedUp", 0.02)
            if ent:GetModelName() == "models/props/barrel_plastic_1.vmdl" then
                SendToConsole("hlvr_physcannon_forward_offset 5")
            end
            DoEntFireByInstanceHandle(ent, "AddOutput", "OnPhysgunDrop>!self>RunScriptFile>drop_object>0.02>1", 0, nil, nil)
            DoEntFireByInstanceHandle(ent, "RunScriptFile", "useextra", 0, nil, nil)
        end
    end, nil)

    Convars:RegisterCommand("usemultitool", function()
        local viewmodel = Entities:FindByClassname(nil, "viewmodel")
        local player = Entities:GetLocalPlayer()
        local vmName = (viewmodel and viewmodel:GetModelName()) or ""
        local isMultiVm = string.match(vmName, "v_multitool")
            or string.match(vmName, "physcannon")
            or string.match(vmName, "gravgun")
            or string.match(vmName, "gravity")

        local activeWep = nil
        if player and player.GetActiveWeapon then
            activeWep = player:GetActiveWeapon()
        end
        local activeClass = (activeWep and activeWep.GetClassname and activeWep:GetClassname()) or ""
        local isPhyscannon = (activeClass == "weapon_physcannon")
            or (activeClass == "hlvr_multitool")
            or (activeClass == "" and isMultiVm)

        if isMultiVm and isPhyscannon then
            local startVector = player:EyePosition()
            local traceTable =
            {
                startpos = startVector;
                endpos = startVector + RotatePosition(Vector(0, 0, 0), player:GetAngles(), Vector(65, 0, 0));
                ignore = player;
                mask =  33636363
            }
            TraceLine(traceTable)

            if traceTable.hit then
                local ent = Entities:FindByClassnameNearest("info_hlvr_holo_hacking_plug", traceTable.pos, 20)
                if ent then
                    local name = ent:GetName()
                    local parent = ent:GetMoveParent()
                    if ent:Attribute_GetIntValue("used", 0) == 0 and not (parent and (vlua.find(parent:GetModelName(), "power_stake"))) and ent:GetGraphParameter("b_PlugDisabled") == false then

                        if parent and vlua.find(parent:GetName(), "Console") then
                            if GetMapName() == "a2_quarantine_entrance" then
                                local rack = Entities:FindByClassname(nil, "item_hlvr_combine_console_rack")
                                while rack do
                                    rack:RedirectOutput("OnCompletionA_Forward", "ShowHoldInteractTutorial", rack)
                                    rack = Entities:FindByClassname(rack, "item_hlvr_combine_console_rack")
                                end
                            end
                            local ents = Entities:FindAllByClassnameWithin("item_hlvr_combine_console_tank", parent:GetCenter(), 20)
                            for k, v in pairs(ents) do
                                DoEntFireByInstanceHandle(v, "DisablePickup", "", 0, player, nil)
                            end
                            SendToConsole("ent_fire 5325_3947_combine_console AddOutput OnTankAdded>item_hlvr_combine_console_tank>DisablePickup>>0>1")
                        end

                        if parent and parent:GetClassname() == "prop_hlvr_crafting_station_console" then
                            DoEntFireByInstanceHandle(parent, "RunScriptFile", "crafting_station", 0, nil, nil)
                        end

                        if parent and parent:GetName() == "254_16189_combine_locker" then
                            SpawnEntityFromTableSynchronous("prop_dynamic", {["solid"]=6, ["renderamt"]=0, ["model"]="models/props/industrial_door_2_40_92_white.vmdl", ["origin"]="-2018 -1828 216", ["angles"]="0 270 0", ["parentname"]="scanner_return_clip_door"})
                            SpawnEntityFromTableSynchronous("prop_dynamic", {["solid"]=6, ["renderamt"]=0, ["model"]="models/props/industrial_door_2_40_92_white.vmdl", ["origin"]="-1868 -1744 216", ["angles"]="0 180 0", ["parentname"]="scanner_return_clip", ["modelscale"]=10})
                        end

                        local ents = Entities:FindAllByClassnameWithin("baseanimating", ent:GetCenter(), 3)
                        for i = 1, #ents do
                            local ent = ents[i]
                            if ent:GetModelName() == "models/props_combine/combine_consoles/vr_combine_interface_01.vmdl" and ent:GetCycle() > 0 then
                                return
                            end
                        end

                        ent:Attribute_SetIntValue("used", 1)
                        DoEntFireByInstanceHandle(ent, "BeginHack", "", 0, player, player)

                        if not vlua.find(name, "cshield") and not vlua.find(name, "switch_box") then
                            DoEntFireByInstanceHandle(ent, "EndHack", "", 1.8, player, player)
                            ent:FireOutput("OnHackSuccess", player, player, nil, 1.8)
                            ent:FireOutput("OnPuzzleSuccess", player, player, nil, 1.8)
                        end
                        return
                    end
                end

            end
        end
    end, "", 0)

    Convars:RegisterCommand("toggle_noclip", function()
        local player = Entities:GetLocalPlayer()
        if player:Attribute_GetIntValue("noclip_tutorial_shown", 0) == 0 then
            player:Attribute_SetIntValue("noclip_tutorial_shown", 1)
            NoVR.ShowHint("noclip")
        end

        SendToConsole("noclip")
    end, "", 0)

    Convars:RegisterCommand("novr_unequip_wearable", function()
        local ent = Entities:FindByName(nil, "hat_construction_viewmodel")
        if ent then
            local hat = SpawnEntityFromTableSynchronous("prop_physics", {["model"]="models/props/construction/hat_construction.vmdl"})
            hat:SetOrigin(Entities:GetLocalPlayer():EyePosition())
            local angles = Entities:GetLocalPlayer():EyeAngles()
            hat:SetAngles(angles.x, angles.y, angles.z)

            if ent:GetMaterialGroupHash() < 0 then
                hat:SetSkin(1)
                local color = ent:GetRenderColor()
                hat:SetRenderColor(color.x, color.y, color.z)
            end

            ent:Kill()

            Entities:GetLocalPlayer():SetThink(function()
                SendToConsole("ent_fire npc_barnacle SetRelationship \"player D_HT 99\"")
            end, "HostileBarnacles", 0.2)
        else
            ent = Entities:FindByName(nil, "respirator_viewmodel")
            if ent then
                local respirator = SpawnEntityFromTableSynchronous("prop_physics", {["model"]="models/props/hazmat/respirator_01a.vmdl"})
                respirator:SetOrigin(Entities:GetLocalPlayer():EyePosition())
                local angles = Entities:GetLocalPlayer():EyeAngles()
                respirator:SetAngles(angles.x, angles.y, angles.z)

                SendToConsole("snd_sos_start_soundevent Player.Gasmask_Remove")
                SendToConsole("ent_fire !player suppresscough 0;ent_fire_output @player_proxy OnPlayerUncoverMouth")
                NoVR.SetActionSuppressed("+covermouth", 0)
                ent:Kill()

                Entities:GetLocalPlayer():SetThink(function()
                    SendToConsole("ent_fire npc_barnacle SetRelationship \"player D_HT 99\"")
                end, "HostileBarnacles", 0.2)
            end
        end
    end, "", 0)

    Convars:RegisterCommand("novr_cover_mouth", function()
        local viewmodel = Entities:FindByClassname(nil, "viewmodel")
        viewmodel:SetRenderAlpha(0)
        Entities:GetLocalPlayer():Attribute_SetIntValue("covering_mouth", 1)
    end, "", 0)

    Convars:RegisterCommand("novr_uncover_mouth", function()
        local viewmodel = Entities:FindByClassname(nil, "viewmodel")
        viewmodel:SetRenderAlpha(255)
        Entities:GetLocalPlayer():Attribute_SetIntValue("covering_mouth", 0)
    end, "", 0)

    Convars:RegisterCommand("novr_hacking_puzzle_failed", function()
        local player = Entities:GetLocalPlayer()
        local ent = Entities:FindByClassnameNearest("info_hlvr_holo_hacking_plug", player:GetCenter(), 100)
        DoEntFireByInstanceHandle(ent, "EndHack", "", 0, player, player)
        ent:FireOutput("OnHackFailed", player, player, nil, 0)
        ent:FireOutput("OnPuzzleFailed", player, player, nil, 0)
        ent:Attribute_SetIntValue("used", 0)
        SendToConsole("ent_fire player_speedmod ModifySpeed 1")
    end, "", 0)

    Convars:RegisterCommand("novr_hacking_puzzle_success", function()
        local player = Entities:GetLocalPlayer()
        local ent = Entities:FindByClassnameNearest("info_hlvr_holo_hacking_plug", player:GetCenter(), 100)
        DoEntFireByInstanceHandle(ent, "EndHack", "", 0, player, player)
        ent:FireOutput("OnHackSuccess", player, player, nil, 0)
        ent:FireOutput("OnPuzzleSuccess", player, player, nil, 0)
        SendToConsole("ent_fire player_speedmod ModifySpeed 1")
    end, "", 0)

    Convars:RegisterConvar("novr_chosen_weapon_upgrade", "", "", 0)

    Convars:RegisterConvar("novr_weapon_in_crafting_station", "", "", 0)

    Convars:RegisterConvar("novr_viewmodel_offset_y_additional", "0", "", 0)

    Convars:RegisterCommand("novr_quicksave", function()
        if NoVR.SavingDisabled() then return end
        SendToConsole("save quick")
        NoVR.FireGameSaved()
        NoVR.ShowHint("gamesaved")
    end, "", 0)

    local novrPauseMenuOpen = false
    local novrSavedCrosshair = 0
    local novrSavedReticle = 1
    local function novrPauseMenuCleanup()
        novrPauseMenuOpen = false
        SendToConsole("hlvr_main_menu_activate_exit_vignette")
        SendToServerConsole("unpause")
    end
    local function novrOpenPauseMenu()
        SendToServerConsole("pause")
        NoVR.PauseCarouselOpen()
        novrPauseMenuOpen = true
    end
    local function novrClosePauseMenu()
        NoVR.PauseCarouselClose()
    end

    Convars:RegisterCommand("novr_pausemenu_cleanup", function()
        novrPauseMenuCleanup()
    end, "", 0)

    Convars:RegisterCommand("novr_pausemenu_open", function()
        novrOpenPauseMenu()
    end, "", 0)

    Convars:RegisterCommand("novr_pausemenu_close", function()
        novrClosePauseMenu()
    end, "", 0)

    Convars:RegisterCommand("novr_pausemenu_toggle", function()
        NoVR.PauseCarouselRequestToggle()
    end, "", 0)

    Convars:RegisterCommand("mouse_invert_y", function(name, value)
        if value == "true" or value == "1" then
            SendToConsole("novr_invert_look_y 1")
        else
            SendToConsole("novr_invert_look_y 0")
        end
    end, "", 0)

    local function QueueCraftingUpgrade(cmd, cost)
        Convars:SetStr("novr_chosen_weapon_upgrade", cmd)
        SendToConsole("hlvr_addresources 0 0 0 -" .. tostring(cost))
        SendToConsole("ent_fire prop_hlvr_crafting_station_console RunScriptFile useextra")
    end

    Convars:RegisterCommand("novr_crafting_station_choose_upgrade", function(name, value)
        local t = {}
        Entities:GetLocalPlayer():GatherCriteria(t)

        for k, v in pairs(Entities:FindAllByName("weapon_in_fabricator_idle")) do
            v:SetEntityName("weapon_in_fabricator")
        end

        if Convars:GetStr("novr_weapon_in_crafting_station") == "pistol" then

            if value == "1" and t.current_crafting_currency >= 10 then
                QueueCraftingUpgrade("hlvr_energygun_grant_upgrade 1", 10)
                return

            elseif value == "2" and t.current_crafting_currency >= 20 then
                QueueCraftingUpgrade("hlvr_energygun_grant_upgrade 3", 20)
                return

            elseif value == "3" and t.current_crafting_currency >= 30 then
                QueueCraftingUpgrade("hlvr_energygun_grant_upgrade 2", 30)
                return

            elseif value == "4" and t.current_crafting_currency >= 35 then
                QueueCraftingUpgrade("hlvr_energygun_grant_upgrade 0", 35)
                return
            end
        elseif Convars:GetStr("novr_weapon_in_crafting_station") == "shotgun" then

            if value == "1" and t.current_crafting_currency >= 10 then
                QueueCraftingUpgrade("hlvr_shotgun_grant_upgrade 2", 10)
                return

            elseif value == "2" and t.current_crafting_currency >= 25 then
                QueueCraftingUpgrade("hlvr_shotgun_grant_upgrade 3", 25)
                return

            elseif value == "3" and t.current_crafting_currency >= 30 then
                QueueCraftingUpgrade("hlvr_shotgun_grant_upgrade 0", 30)
                return

            elseif value == "4" and t.current_crafting_currency >= 40 then
                QueueCraftingUpgrade("hlvr_shotgun_grant_upgrade 1", 40)
                return
            end
        elseif Convars:GetStr("novr_weapon_in_crafting_station") == "smg" then

            if value == "1" and t.current_crafting_currency >= 15 then
                QueueCraftingUpgrade("hlvr_rapidfire_grant_upgrade 4", 15)
                return

            elseif value == "2" and t.current_crafting_currency >= 25 then
                QueueCraftingUpgrade("hlvr_rapidfire_grant_upgrade 5", 25)
                return

            elseif value == "3" and t.current_crafting_currency >= 30 then
                QueueCraftingUpgrade("hlvr_rapidfire_grant_upgrade 6", 30)
                return
            end
        end

        SendToConsole("ent_fire text_resin SetText #HLVR_CraftingStation_NotEnoughResin")
        SendToConsole("ent_fire text_resin Display")
        SendToConsole("snd_sos_start_soundevent PlayerTeleport.Fail")
        SendToConsole("novr_crafting_station_cancel_upgrade")
    end, "", 0)

    Convars:RegisterCommand("novr_crafting_station_cancel_upgrade", function()
        Convars:SetStr("novr_chosen_weapon_upgrade", "cancel")
        SendToConsole("ent_fire weapon_in_fabricator_idle Kill")
        SendToConsole("ent_fire weapon_in_fabricator Kill")
        SendToConsole("ent_fire upgrade_ui kill")

        if Convars:GetStr("novr_weapon_in_crafting_station") == "pistol" then
            SendToConsole("give weapon_pistol")
        elseif Convars:GetStr("novr_weapon_in_crafting_station") == "shotgun" then
            SendToConsole("give weapon_shotgun")
        elseif Convars:GetStr("novr_weapon_in_crafting_station") == "smg" then
            SendToConsole("give weapon_ar2")
        end
        Convars:SetStr("novr_weapon_in_crafting_station", "")
        SendToConsole("viewmodel_update")
        SendToConsole("ent_fire prop_hlvr_crafting_station_console RunScriptFile useextra")
    end, "", 0)

    Convars:RegisterCommand("throwgrenade", function(name, launcher)
        local player = Entities:GetLocalPlayer()
        local player_holding_grenade = false
        local ents = Entities:FindAllByClassname("item_hlvr_grenade_frag")
        for k, v in pairs(ents) do
            if v:GetMass() == 1 then
                v:Kill()
                player_holding_grenade = true
            end
        end
        local player_holding_xen_grenade = false
        ents = Entities:FindAllByClassname("item_hlvr_grenade_xen")
        for k, v in pairs(ents) do
            if v:GetMass() == 1 then
                v:Kill()
                player_holding_grenade = true
                player_holding_xen_grenade = true
            end
        end

        local player_has_xen_grenade = WristPockets_PlayerHasXenGrenade()
        if not player_holding_grenade and not WristPockets_PlayerHasGrenade() and not player_has_xen_grenade then
            SendToConsole("snd_sos_start_soundevent PlayerTeleport.Fail")
            return
        end
        local pos = player:EyePosition()
        local class = "item_hlvr_grenade_frag"

        if player_holding_grenade then
            if player_holding_xen_grenade then
                class = "item_hlvr_grenade_xen"
            end
        else
            if player_has_xen_grenade then
                class = "item_hlvr_grenade_xen"
                WristPockets_UseXenGrenade()
            else
                WristPockets_UseGrenade()
            end
        end

        local ent = SpawnEntityFromTableSynchronous(class, {["targetname"]="player_grenade", ["origin"]=pos.x .. " " .. pos.y .. " " .. pos.z})
        ent:SetOwner(player)
        if class == "item_hlvr_grenade_frag" then
            local ent2 = Entities:FindByNameNearest("grenade_handle", ent:GetAbsOrigin(), 10)
            ent2:Kill()
        end
        if launcher then
            ent:ApplyAbsVelocityImpulse(player:GetForwardVector() * 1000)
            local velocity = GetPhysVelocity(ent)
            ent:SetThink(function()
                local new_velocity = GetPhysVelocity(ent)
                if (new_velocity:Length() - velocity:Length()) < -100 then
                    DoEntFireByInstanceHandle(ent, "SetTimer", "0", 0, nil, nil)
                    return nil
                end
                velocity = new_velocity
                return 0
            end, "ExplodeOnImpact", 0)
            StartSoundEventFromPosition("Shotgun.UpgradeLaunchGrenade", player:EyePosition())
            SendToConsole("viewmodel_update")
        else
            ent:ApplyAbsVelocityImpulse(player:GetForwardVector() * 500)
            SendToConsole("impulse 200")
            player:SetThink(function()
                SendToConsole("impulse 200")
                if not is_on_map_or_later("a5_vault") then
                    SendToConsole("r_drawviewmodel 1")
                end
            end, "FinishGrenadeThrow", 0.1)
        end
        DoEntFireByInstanceHandle(ent, "ArmGrenade", "", 0, nil, nil)
    end, "", 0)

    Convars:RegisterCommand("+novr_zoom", function()
        if not NovrAdsZoomed() then
            Entities:GetLocalPlayer():Attribute_SetIntValue("is_zoomed", 1)
            SendToConsole("+zoom")
        end
    end, "", 0)

    Convars:RegisterCommand("-novr_zoom", function()
        Entities:GetLocalPlayer():Attribute_SetIntValue("is_zoomed", 0)
        SendToConsole("-zoom")
    end, "", 0)

    Convars:RegisterCommand("novr_pipelift", function(name, value)
        NoVR.PipeLift(tonumber(value) or -1)
    end, "", 0)

    Convars:RegisterCommand("novr_climbmax", function(name, value)
        NoVR.ClimbMax(tonumber(value) or 18)
    end, "", 0)

    Convars:RegisterCommand("novr_stepprobe", function(name, value)
        NoVR.StepProbe(tonumber(value) or 1)
    end, "", 0)

    Convars:RegisterCommand("novr_movedebug", function(name, value)
        NoVR.MoveDebug(tonumber(value) or 1)
    end, "", 0)

    Convars:RegisterCommand("novr_movedump", function()
        NoVR.MoveDump()
    end, "", 0)

    Convars:RegisterCommand("novr_crouchspeed", function(name, value)
        NoVR.CrouchSpeed(tonumber(value) or 100)
    end, "", 0)

    Convars:RegisterCommand("novr_ceilfit", function(name, value)
        NoVR.CeilFit(tonumber(value) or 1)
    end, "", 0)

    Convars:RegisterCommand("novr_hullfloor", function(name, value)
        NoVR.HullFloor(tonumber(value) or 1)
    end, "", 0)

    Convars:RegisterCommand("novr_tracelog", function(name, value)
        NoVR.TraceLog(tonumber(value) or 1)
    end, "", 0)

    Convars:RegisterCommand("novr_stepbudget", function(name, value)
        NoVR.StepBudget(tonumber(value) or -1)
    end, "", 0)

    Convars:RegisterCommand("novr_probe", function()
        NoVR.MoveProbe()
    end, "", 0)

    Convars:RegisterCommand("novr_resetads", function()
        NovrClearAds()
    end, "", 0)

    Convars:RegisterCommand("+customattack2", function()
        local viewmodel = Entities:FindByClassname(nil, "viewmodel")
        local player = Entities:GetLocalPlayer()

        if player ~= nil and player:Attribute_GetIntValue("is_zoomed", 0) == 1 then
            return
        end

        if viewmodel and NovrAdsZoomed() and not string.match(viewmodel:GetModelName(), "_ads.vmdl") then
            ViewmodelAnimation_ResetAnimation()
            NoVR.AdsZoom(0)
            SendToConsole("hud_draw_fixed_reticle 1")
        end

        if viewmodel and not string.match(viewmodel:GetModelName(), "v_grenade") then
            if string.match(viewmodel:GetModelName(), "v_shotgun") then
                if player:Attribute_GetIntValue("shotgun_upgrade_doubleshot", 0) == 1 then
                    SendToConsole("+attack2")
                end
            elseif string.match(viewmodel:GetModelName(), "v_pistol") then
                if player:Attribute_GetIntValue("pistol_upgrade_aimdownsights", 0) == 1 then
                    if not NovrAdsZoomed() then
                        if player:Attribute_GetIntValue("ads_ready", 1) ~= 1 then
                            return
                        end
                        local ents = Entities:FindAllInSphere(player:GetCenter(), 80)
                        for k, v in pairs(ents) do
                            if v:Attribute_GetIntValue("picked_up", 0) == 1 then
                                return
                            end
                        end

                        cvar_setf("viewmodel_offset_z", -0.04)
                        NoVR.AdsZoom(1)
                        player:Attribute_SetIntValue("ads_ready", 0)
                        ViewmodelAnimation_HIPtoADS()
                        player:SetThink(function()
                            cvar_setf("viewmodel_offset_x", -0.005)
                            player:Attribute_SetIntValue("ads_ready", 1)
                        end, "ZoomActivate", 0.4)
                        SendToConsole("hud_draw_fixed_reticle 0")
                        SendToConsole("crosshair 0")
                        SendToConsole("pistol_use_new_accuracy 1")
                    else
                        NoVR.AdsZoom(0)
                        player:Attribute_SetIntValue("ads_ready", 1)
                        cvar_setf("viewmodel_offset_x", 0)
                        cvar_setf("viewmodel_offset_z", 0)
                        ViewmodelAnimation_ADStoHIP()
                        if player:Attribute_GetIntValue("pistol_upgrade_lasersight", 0) == 0 then
                            SendToConsole("hud_draw_fixed_reticle 1")
                            SendToConsole("pistol_use_new_accuracy 0")
                        else
                            SendToConsole("crosshair 1")
                        end
                    end
                end
            elseif string.match(viewmodel:GetModelName(), "v_smg1") then
                if player:Attribute_GetIntValue("smg_upgrade_aimdownsights", 0) == 1 then
                    if not NovrAdsZoomed() then
                        cvar_setf("viewmodel_offset_z", -0.045)
                        NoVR.AdsZoom(1)
                        ViewmodelAnimation_HIPtoADS()
                        player:SetThink(function()
                            cvar_setf("viewmodel_offset_x", 0.025)
                        end, "ZoomActivate", 0.5)
                        SendToConsole("hud_draw_fixed_reticle 0")
                        SendToConsole("crosshair 0")
                    else
                        NoVR.AdsZoom(0)
                        cvar_setf("viewmodel_offset_x", 0)
                        cvar_setf("viewmodel_offset_z", 0)
                        ViewmodelAnimation_ADStoHIP()
                        if player:Attribute_GetIntValue("smg_upgrade_lasersight", 0) == 0 then
                            SendToConsole("hud_draw_fixed_reticle 1")
                        else
                            SendToConsole("crosshair 1")
                        end
                    end
                end
            end
        end
    end, "", 0)

    Convars:RegisterCommand("-customattack2", function()
        SendToConsole("-attack")
        SendToConsole("-attack2")
    end, "", 0)

    Convars:RegisterCommand("+customattack3", function()
        local viewmodel = Entities:FindByClassname(nil, "viewmodel")
        local player = Entities:GetLocalPlayer()
        if viewmodel then
            if string.match(viewmodel:GetModelName(), "v_shotgun") then
                if player:Attribute_GetIntValue("shotgun_upgrade_grenadelauncher", 0) == 1 then
                    SendToConsole("throwgrenade true")
                end
            elseif string.match(viewmodel:GetModelName(), "v_pistol") then
                if player:Attribute_GetIntValue("pistol_upgrade_burstfire", 0) == 1 then
                    SendToConsole("sk_plr_dmg_pistol 9")
                    SendToConsole("+attack")
                    Entities:GetLocalPlayer():SetThink(function()
                        SendToConsole("-attack")
                    end, "StopAttack", 0.02)
                    Entities:GetLocalPlayer():SetThink(function()
                        SendToConsole("+attack")
                    end, "StartAttack2", 0.14)
                    Entities:GetLocalPlayer():SetThink(function()
                        SendToConsole("-attack")
                    end, "StopAttack2", 0.16)
                    Entities:GetLocalPlayer():SetThink(function()
                        SendToConsole("+attack")
                    end, "StartAttack3", 0.28)
                    Entities:GetLocalPlayer():SetThink(function()
                        SendToConsole("-attack")
                        SendToConsole("sk_plr_dmg_pistol 7")
                    end, "StopAttack3", 0.3)
                end
            end
        end
    end, "", 0)

    Convars:RegisterCommand("-customattack3", function()
    end, "", 0)

    Convars:RegisterCommand("shootadvisorvortenergy", function()
        local ent = SpawnEntityFromTableSynchronous("env_explosion", {["origin"]="886 -4111.625 -1188.75", ["explosion_type"]="custom", ["explosion_custom_effect"]="particles/vortigaunt_fx/vort_beam_explosion_i_big.vpcf"})
        DoEntFireByInstanceHandle(ent, "Explode", "", 0, nil, nil)
        StartSoundEventFromPosition("VortMagic.Throw", Vector(886, -4111.625, -1188.75))
        NoVR.SetActionSuppressed("shootadvisorvortenergy", 1)
        SendToConsole("ent_fire relay_advisor_dead Trigger")
    end, "", 0)

    Convars:RegisterCommand("shootvortenergy", function()
        local player = Entities:GetLocalPlayer()
        local startVector = player:EyePosition()
        local traceTable =
        {
            startpos = startVector;
            endpos = startVector + RotatePosition(Vector(0, 0, 0), player:GetAngles(), Vector(1000000, 0, 0));
            ignore = player;
            mask =  33636363
        }

        TraceLine(traceTable)

        if traceTable.hit then
            ent = SpawnEntityFromTableSynchronous("env_explosion", {["origin"]=traceTable.pos.x .. " " .. traceTable.pos.y .. " " .. traceTable.pos.z, ["explosion_type"]="custom", ["explosion_custom_effect"]="particles/vortigaunt_fx/vort_beam_explosion_i_big.vpcf"})
            DoEntFireByInstanceHandle(ent, "Explode", "", 0, nil, nil)
            SendToConsole("npc_kill")
            DoEntFire("!picker", "RunScriptFile", "vortenergyhit", 0, nil, nil)
            StartSoundEventFromPosition("VortMagic.Throw", startVector)
            local vortEnergyCell = Entities:FindByClassnameNearest("point_vort_energy", Vector(traceTable.pos.x,traceTable.pos.y,traceTable.pos.z), 15)
            if vortEnergyCell then
                vortEnergyCell:FireOutput("OnEnergyPulled", nil, nil, nil, 0)
            end
        end
    end, "", 0)

    Convars:RegisterCommand("useextra", function()
        local player = Entities:GetLocalPlayer()

        player:Attribute_SetIntValue("used_gravity_gloves", 0)
        player:Attribute_SetIntValue("use_released", 0)

        local startVector = player:EyePosition()
        local eyetrace =
        {
            startpos = startVector;
            endpos = startVector + RotatePosition(Vector(0,0,0), player:GetAngles(), Vector(1000,0,0));
            ignore = player;
            mask =  33636363
        }
        TraceLine(eyetrace)
        if eyetrace.hit then
            local ent = Entities:FindByClassnameNearest("prop_handpose", eyetrace.pos, 20)
            if ent then
                ent = Entities:FindAllByClassname("point_soundevent")
                for k, v in pairs(ent) do
                    if vlua.find(v:GetName(), "snd_car_horn") and VectorDistanceSq(eyetrace.pos, v:GetCenter()) < 3000 then
                        DoEntFireByInstanceHandle(v, "StartSound", "", 0, nil, nil)
                        v:SetThink(function()
                            DoEntFireByInstanceHandle(v, "StopSound", "", 0, nil, nil)
                        end, "StopSound", 1)
                    end
                end
            end

        end

        DoEntFire("!picker", "RunScriptFile", "check_useextra_distance", 0, nil, nil)

        if GetMapName() == "a1_intro_world" then
            if vlua.find(Entities:FindAllInSphere(Vector(-958, 1735, 118), 10), player) then
                DoEntFireByInstanceHandle(Entities:FindByName(nil, "205_8032_button_pusher_prop"), "RunScriptFile", "useextra", 0, nil, nil)
            elseif vlua.find(Entities:FindAllInSphere(Vector(648, -1757, -141), 10), player) then
                ClimbLadder(-64)
            elseif vlua.find(Entities:FindAllInSphere(Vector(530, -2331, -84), 25), player) then
                ClimbLadderSound()
                SendToConsole("fadein 0.2")
                SendToConsole("setpos_exact 574 -2328 -130")
            elseif vlua.find(Entities:FindAllInSphere(Vector(606, -2339, -217), 20), player) then
                if 135 < player:GetAngles().y or player:GetAngles().y < -135 then
                    DoEntFireByInstanceHandle(Entities:FindByName(nil, "979_518_button_pusher_prop"), "RunScriptFile", "useextra", 0, nil, nil)
                end
            end
        elseif GetMapName() == "a1_intro_world_2" then
            if vlua.find(Entities:FindAllInSphere(Vector(-1268, 576, -63), 10), player) and Entities:FindByName(nil, "balcony_ladder"):GetSequence() == "idle_open" then
                ClimbLadder(80)
            elseif vlua.find(Entities:FindAllInSphere(Vector(-911, 922, -68), 10), player) then
                ClimbLadder(-22)
            end

            local startVector = player:EyePosition()
            local traceTable =
            {
                startpos = startVector;
                endpos = startVector + RotatePosition(Vector(0, 0, 0), player:GetAngles(), Vector(80, 0, 0));
                ignore = player;
                mask = 33636363
            }

            TraceLine(traceTable)

            if traceTable.hit then
                local ent = Entities:FindByNameNearest("621_6487_button_pusher_prop", traceTable.pos, 10)
                if ent then
                    DoEntFireByInstanceHandle(ent, "RunScriptFile", "useextra", 0, nil, nil)
                end
            end
        elseif GetMapName() == "a2_pistol" then
            if vlua.find(Entities:FindAllInSphere(Vector(439, 896, 454), 10), player) then
                ClimbLadder(540)
            end
        elseif GetMapName() == "a2_hideout" then
            local startVector = player:EyePosition()
            local traceTable =
            {
                startpos = startVector;
                endpos = startVector + RotatePosition(Vector(0, 0, 0), player:GetAngles(), Vector(60, 0, 0));
                ignore = player;
                mask = 33636363
            }

            TraceLine(traceTable)

            if traceTable.hit then
                local ent = Entities:FindByClassnameNearest("func_physical_button", traceTable.pos, 5)
                if ent and ent:Attribute_GetIntValue("used", 0) == 0 then
                    ent:FireOutput("OnIn", nil, nil, nil, 0)
                    ent:Attribute_SetIntValue("used", 1)
                    StartSoundEventFromPosition("Button_Basic.Press", player:EyePosition())
                end
            end

            if vlua.find(Entities:FindAllInSphere(Vector(-702, -1024, -238), 20), player) then
                local ent = Entities:FindByName(nil, "bell")
                DoEntFireByInstanceHandle(ent, "RunScriptFile", "useextra", 0, nil, nil)
            end
        elseif GetMapName() == "a2_headcrabs_tunnel" and vlua.find(Entities:FindAllInSphere(Vector(354, -251, -62), 18), player) then
            ClimbLadder(22)
        elseif GetMapName() == "a3_station_street" then
            if vlua.find(Entities:FindAllInSphere(Vector(934, 1883, -135), 20), player) then
                SendToConsole("ent_fire_output 2_8127_elev_button_floor_1_call OnIn")
                SendToConsole("snd_sos_start_soundevent Button_Basic.Press")
            end
        elseif GetMapName() == "a3_hotel_lobby_basement" then
            if vlua.find(Entities:FindAllInSphere(Vector(1059, -1475, 200), 20), player) then
                if player:Attribute_GetIntValue("EnabledHotelLobbyPower", 0) == 1
                    or NoVR.TonerPathElectrified("toner_path_11") then
                    SendToConsole("ent_fire_output elev_button_floor_1 OnIn")
                else
                    SendToConsole("ent_fire elev_button_floor_1 Press")
                end
            elseif vlua.find(Entities:FindAllInSphere(Vector(976, -1487, 208), 15), player) then
                ClimbLadder(280)
            end
        elseif GetMapName() == "a3_hotel_underground_pit" then
            if vlua.find(Entities:FindAllInSphere(Vector(2239, -1017, 528), 15), player) then
                ClimbLadder(570)
            end
        elseif GetMapName() == "a3_hotel_interior_rooftop" then
            if vlua.find(Entities:FindAllInSphere(Vector(763.5, -1424, 578), 50), player) then
                if player:Attribute_GetIntValue("entered_hotel_rooftop_window", 0) == 0 then
                    SendToConsole("fadein 0.2")
                    SendToConsole("setpos 788 -1420 576")
                    CheckForGnome(nil, nil)
                    player:Attribute_SetIntValue("entered_hotel_rooftop_window", 1)
                end
            elseif vlua.find(Entities:FindAllInSphere(Vector(2381, -1841, 448), 10), player) then
                ClimbLadder(560)
            elseif vlua.find(Entities:FindAllInSphere(Vector(2335, -1832, 757), 20), player) then
                ClimbLadder(840, Vector(0, 0, 0))
            end
        elseif GetMapName() == "a3_c17_processing_plant" then
            local startVector = player:EyePosition()
            local traceTable =
            {
                startpos = startVector;
                endpos = startVector + RotatePosition(Vector(0, 0, 0), player:GetAngles(), Vector(60, 0, 0));
                ignore = player;
                mask = -1
            }

            TraceLine(traceTable)

            if traceTable.hit then
                local ent = Entities:FindByNameWithin(nil, "1517_3301_lift_button_attached_down_prop", traceTable.pos, 10)
                if ent then
                    player:Attribute_SetIntValue("activated_processing_plant_lift", 1)
                    SendToConsole("ent_fire_output lift_button_down onin")
                end
            end

            if vlua.find(Entities:FindAllInSphere(Vector(-80, -2215, 760), 15), player) and Entities:FindByName(nil, "factory_int_up_barnacle_npc_1"):GetHealth() <= 0 then
                ClimbLadder(890)
            end

            if vlua.find(Entities:FindAllInSphere(Vector(-237,-2856,392), 15), player) then
                player:SetVelocity(Vector(player:GetForwardVector().x, player:GetForwardVector().y, 0):Normalized() * 150)
                player:SetThink(function()
                    ClimbLadder(440)
                end, "ClimbLadder", 0.1)
            end

            if vlua.find(Entities:FindAllInSphere(Vector(414,-2459,328), 15), player) then
                player:SetVelocity(Vector(player:GetForwardVector().x, player:GetForwardVector().y, 0):Normalized() * 150)
                player:SetThink(function()
                    ClimbLadder(440)
                end, "ClimbLadder", 0.2)
            end

            if vlua.find(Entities:FindAllInSphere(Vector(326, -3491, 312), 20), player) then
                ClimbLadder(400)
            end

            if vlua.find(Entities:FindAllInSphere(Vector(-1630, -2045, 111), 15), player) then
                ClimbLadder(180)
            end

            if vlua.find(Entities:FindAllInSphere(Vector(-1393, -2493, 113), 10), player) then
                ClimbLadder(425, Vector(0, 0, -1))
            end

            if vlua.find(Entities:FindAllInSphere(Vector(-1420, -2482, 472), 30), player) then
                ClimbLadderSound()
                SendToConsole("fadein 0.2")
                SendToConsole("setpos_exact -1392 -2471 53")
            end
        elseif GetMapName() == "a3_distillery" then
            if vlua.find(Entities:FindAllInSphere(Vector(20, -496, 211), 10), player) then
                ClimbLadder(462)
            end

            if vlua.find(Entities:FindAllInSphere(Vector(-24, -151, 426), 5), player) then
                if player:Attribute_GetIntValue("pulled_larry_ladder", 0) == 0 then
                    DoEntFireByInstanceHandle(Entities:FindByName(nil, "larry_ladder"), "RunScriptFile", "useextra", 0, nil, nil)
                else
                    ClimbLadder(560)
                end
            end

            if vlua.find(Entities:FindAllInSphere(Vector(515, 1595, 578), 10), player) then
                ClimbLadder(690)
            end

            if vlua.find(Entities:FindAllInSphere(Vector(925, 1102, 578), 10), player) then
                SendToConsole("ent_fire_output 11578_2635_380_button_center_pusher OnIn")
            end
        elseif GetMapName() == "a4_c17_tanker_yard" then
            if vlua.find(Entities:FindAllInSphere(Vector(6980, 2591, 13), 10), player) then
                ClimbLadder(270)
            elseif vlua.find(Entities:FindAllInSphere(Vector(6618, 2938, 334), 10), player) then
                ClimbLadder(402)
            elseif vlua.find(Entities:FindAllInSphere(Vector(6069, 3902, 416), 10), player) then
                ClimbLadder(686)
            elseif vlua.find(Entities:FindAllInSphere(Vector(5456, 4876, 288), 10), player) then
                ClimbLadder(420)
            elseif vlua.find(Entities:FindAllInSphere(Vector(5434, 5755, 273), 10), player) then
                ClimbLadder(403, -player:GetRightVector())
            end
        elseif GetMapName() == "a4_c17_water_tower" then
            if vlua.find(Entities:FindAllInSphere(Vector(3314, 6048, 64), 10), player) then
                ClimbLadder(142)
            elseif vlua.find(Entities:FindAllInSphere(Vector(2981, 5879, -303), 10), player) then
                ClimbLadder(-43)
            elseif vlua.find(Entities:FindAllInSphere(Vector(2374, 6207, -177), 10), player) then
                ClimbLadder(-130)
            elseif vlua.find(Entities:FindAllInSphere(Vector(2432, 6662, 160), 10), player) then
                ClimbLadder(330)
            elseif vlua.find(Entities:FindAllInSphere(Vector(2848, 6130, 384), 10), player) then
                ClimbLadder(575)
            elseif vlua.find(Entities:FindAllInSphere(Vector(2848, 6162, 602), 10), player) then
                ClimbLadderSound()
                SendToConsole("fadein 0.2")
                SendToConsole("setpos_exact 2848 6130 360")
            end
        elseif GetMapName() == "a5_vault" then
            if vlua.find(Entities:FindAllInSphere(Vector(-445, 2900, -515), 10), player) then
                ClimbLadder(-440, Vector(0, 0, 0.5))
            end
        end
    end, "", 0)

    Convars:RegisterCommand("useextra_release", function()
        local player = Entities:GetLocalPlayer()
        player:Attribute_SetIntValue("use_released", 1)
    end, "", 0)

    Convars:RegisterCommand("novr_use_radial_cone", function(_, deg)
        NoVR.SetUseCone(tonumber(deg) or 30)
    end, "", 0)

    Convars:RegisterCommand("novr_throw", function(_, speed)
        NoVR.SetThrowCap(tonumber(speed) or 300)
    end, "", 0)

    Convars:RegisterCommand("novr_ragdoll_mass", function(_, kg)
        NoVR.SetRagdollMassMax(tonumber(kg) or 100)
    end, "", 0)

    if player_spawn_ev ~= nil then
        StopListeningToGameEvent(player_spawn_ev)
    end

    player_spawn_ev = ListenToGameEvent('player_activate', function(info)
        if not IsServer() then return end

        local loading_save_file = false
        local ent = Entities:FindByClassname(ent, "player_speedmod")
        if ent then
            loading_save_file = true
        else
            SpawnEntityFromTableSynchronous("player_speedmod", nil)
        end

        NoVR.AdsZoom(0)
        SendToConsole("snd_remove_soundevent HL2Player.UseDeny")

        NoVR.SetInputFreeze(0)
        SendToConsole("ent_fire novr_hint_* EndHint")
        SendToConsole("ent_fire novr_hint_* Kill")
        SendToConsole("ent_fire novr_hintgt_* Kill")
        NoVR.SetHintAnchor(0)
        NoVR.ResetActionSuppression()
        NoVR.ReturnBorrowedKeys()

        if GetMapName() == "startup" then
            SendToConsole("sv_cheats 1")
            SendToConsole("addon_enable novr")
            SendToConsole("hidehud 104")
            NoVR.ParkMenuClickKey(1)
            if loading_save_file then
                GoToMainMenu()
            end
            ent = Entities:FindByName(nil, "startup_relay")
            ent:RedirectOutput("OnTrigger", "GoToMainMenu", ent)
        else
            NoVR.ParkMenuClickKey(0)
            if Entities:FindByName(nil, "respirator_viewmodel") then
                NoVR.SetActionSuppressed("+covermouth", 1)
            end
            Entities:GetLocalPlayer():SetThink(function()

                SendToConsole("-covermouth")
            end, "SetGameUIState", 0.2)
            SendToConsole("sv_noclipaccelerate 1")

            SendToConsole("hlvr_move_ladder_continuous 0")
            SendToConsole("barnacle_vr_lift_type 2")
            SendToConsole("barnacle_vr_pull_duration 1.0")
            SendToConsole("barnacle_vr_visual_pull_duration 0")

            SendToConsole("barnacle_vr_lift_mindelta 10")
            SendToConsole("vr_continuous_unsticky_enable 1")

            SendToConsole("r_drawviewmodel 0")

            SendToConsole("sv_infinite_aux_power 0")
            SendToConsole("cc_spectator_only 1")
            SendToConsole("sv_gameinstructor_disable 0")
            SendToConsole("hud_draw_fixed_reticle 0")
            SendToConsole("hud_reticle_minalpha 255")
            SendToConsole("r_drawvgui 1")
            SendToConsole("ent_fire *_locker_door_* DisablePickup")
            SendToConsole("ent_fire *_hazmat_crate_lid DisablePickup")
            SendToConsole("ent_fire *electrical_panel_*_door* DisablePickup")
            SendToConsole("ent_fire *cabinet_door* DisablePickup")
            SendToConsole("ent_fire *panel_door* DisablePickup")
            SendToConsole("ent_fire *_washing_machine_door DisablePickup")
            SendToConsole("ent_fire *_washing_machine_loader DisablePickup")
            SendToConsole("ent_fire *_fridge_door_* DisablePickup")
            SendToConsole("ent_fire *_mailbox_*_door_* DisablePickup")
            SendToConsole("ent_fire *_dumpster_lid DisablePickup")
            SendToConsole("ent_fire *_portaloo_seat DisablePickup")
            SendToConsole("ent_fire *_drawer* DisablePickup")
            SendToConsole("ent_fire *_firebox_door DisablePickup")
            SendToConsole("ent_fire *_trashbin02_lid DisablePickup")
            SendToConsole("ent_fire *_car_door_rear DisablePickup")
            SendToConsole("ent_fire *_antenna_* DisablePickup")
            SendToConsole("ent_fire ticktacktoe_* DisablePickup")
            SendToConsole("ent_fire *_antique_globe DisablePickup")
            SendToConsole("ent_fire *_door1 DisablePickup")
            SendToConsole("ent_fire *_door2 DisablePickup")
            SendToConsole("ent_fire *_van_door_* DisablePickup")
            SendToConsole("ent_fire *_cage_door_* DisablePickup")
            SendToConsole("ent_fire firedoor DisablePickup")
            SendToConsole("ent_fire traincar_01_hatch DisablePickup")
            SendToConsole("ent_remove player_flashlight")
            SendToConsole("hl_headcrab_deliberate_miss_chance 0")
            SendToConsole("combine_grenade_timer 4")
            SendToConsole("sk_auto_reload_time 9999")
            SendToConsole("mouse_disableinput 0")
            SendToConsole("-attack")
            SendToConsole("-attack2")
            SendToConsole("sk_headcrab_runner_health 69")
            SendToConsole("sk_antlion_worker_spit_interval_max 2")
            SendToConsole("sk_antlion_worker_spit_interval_min 1")
            SendToConsole("sk_antlion_worker_spit_speed 1200")
            SendToConsole("sk_plr_dmg_pistol 7")
            SendToConsole("sk_plr_dmg_ar2 9")
            SendToConsole("sk_plr_dmg_smg1 5")
            SendToConsole("hlvr_physcannon_forward_offset -5")
            SendToConsole("physcannon_tracelength 0")
            SendToConsole("player_throwforce 500")
            ent = Entities:FindByClassname(nil, "prop_door_rotating_physics")
            while ent do

                ent:RedirectOutput("OnLockedUse", "PlayLockedDoorHandleAnimation", ent)

                ent = Entities:FindByClassname(ent, "prop_door_rotating_physics")
            end

            ent = Entities:FindByClassname(nil, "func_tracktrain")
            while ent do
                local name = ent:GetName()
                if name == "" then
                    name = "" .. thisEntity:GetEntityIndex()
                    ent:SetEntityName(name)
                end
                local traincontrols = SpawnEntityFromTableSynchronous("func_traincontrols", {["target"]=name})
                ent = Entities:FindByClassname(ent, "func_tracktrain")
            end

            SendToConsole("hud_draw_fixed_reticle 1")
            SendToConsole("crosshair 0")

            if Entities:GetLocalPlayer():Attribute_GetIntValue("pistol_upgrade_lasersight", 0) == 1 then
                SendToConsole("pistol_use_new_accuracy 1")
            else
                SendToConsole("pistol_use_new_accuracy 0")
            end

            SendToConsole("r_nearz 1.0")

            local vrAvatar = Entities:FindByClassname(nil, "prop_hmd_avatar")
            if vrAvatar then
                ent = SpawnEntityFromTableSynchronous("env_message", {["message"]="VR_SAVE_NOT_SUPPORTED"})
                DoEntFireByInstanceHandle(ent, "ShowMessage", "", 0, nil, nil)
                SendToConsole("snd_sos_start_soundevent Instructor.StartLesson")
            end

            if not loading_save_file then
                if is_on_map_or_later("a2_quarantine_entrance") then
                    SendToConsole("give weapon_pistol")

                    if is_on_map_or_later("a2_pistol") then
                        SendToConsole("give weapon_physcannon")

                        if is_on_map_or_later("a2_drainage") then
                            SendToConsole("give weapon_shotgun")

                            if is_on_map_or_later("a3_hotel_street") then
                                SendToConsole("give weapon_ar2")
                            end
                        end
                    end
                end

                SendToConsole("ent_fire npc_barnacle AddOutput \"OnGrab>held_prop_dynamic_override>DisableCollision>>0>-1\"")
                SendToConsole("ent_fire npc_barnacle AddOutput \"OnRelease>held_prop_dynamic_override>EnableCollision>>0>-1\"")

                local trigger_crouch = Entities:FindByClassname(nil, "trigger_multiple")
                while trigger_crouch do
                    if vlua.find(trigger_crouch:GetName(), "trigger_crouch") then
                        trigger_crouch:RedirectOutput("OnStartTouch", "StartCrouching", trigger_crouch)
                        trigger_crouch:RedirectOutput("OnEndTouch", "StopCrouching", trigger_crouch)
                    end
                    trigger_crouch = Entities:FindByClassname(trigger_crouch, "trigger_multiple")
                end
            else
                if is_on_map_or_later("a2_pistol") then
                    SendToConsole("give weapon_physcannon")
                end
            end

            ent = Entities:FindByName(nil, "lefthand")
            local viewmodel = Entities:FindByClassname(nil, "viewmodel")
            if not ent then
                ent = SpawnEntityFromTableSynchronous("prop_dynamic", {["targetname"]="lefthand", ["model"]="models/hands/alyx_glove_left.vmdl", ["disableshadows"]=true })
                ent:SetParent(viewmodel, "")
                DoEntFireByInstanceHandle(ent, "Disable", "", 0, nil, nil)
            end
            ent:SetAbsOrigin(viewmodel:GetOrigin() + RotatePosition(Vector(0, 0, 0), Entities:GetLocalPlayer():GetAngles(), Vector(4, 0, -3.5)))
            ent:SetLocalAngles(0, -90, 0)

            ent = Entities:GetLocalPlayer()
            if ent then
                ent:SetContextNum("headcrab_struggle_long", 1, 0)
                ent:SetContextNum("headcrab_post_struggle_long", 1, 0)

                local look_delta = QAngle(0, 0, 0)

                ent:SetThink(function()
                    if Convars:GetStr("novr_weapon_in_crafting_station") ~= "" and Convars:GetStr("novr_chosen_weapon_upgrade") == "" and Entities:FindByClassnameNearest("prop_hlvr_crafting_station", Entities:GetLocalPlayer():GetAbsOrigin(), 200) == nil then
                        SendToConsole("novr_crafting_station_cancel_upgrade")
                    end
                    return 1
                end, "ReturnFabricatorWeapon", 0)

                Convars:RegisterConvar("novr_current_vm_model", "", "", 0)
                local map_name = GetMapName()
                local cached_vm = nil
                local last_crouch = nil
                local last_off_y = nil
                local last_ads = false
                local last_model = ""
                local model_mult = -0.055
                local find_i = 0
                ent:SetThink(function()
                    if not cached_vm or cached_vm:IsNull() then
                        cached_vm = Entities:FindByClassname(nil, "viewmodel")
                    end
                    local viewmodel = cached_vm
                    local player = Entities:GetLocalPlayer()
                    if not viewmodel or not player then return 0 end

                    local current_vm_model = viewmodel:GetModelName()
                    if current_vm_model ~= last_model then
                        last_model = current_vm_model
                        model_mult = -0.055
                        if string.match(current_vm_model, "v_shotgun") then
                            model_mult = model_mult * 0.8
                        elseif string.match(current_vm_model, "v_smg1") then
                            model_mult = model_mult * 0.5
                        end
                        local stored_vm = Convars:GetStr("novr_current_vm_model")
                        if NovrHipViewmodelName(current_vm_model) ~= NovrHipViewmodelName(stored_vm) then
                            SendToConsole("novr_resetads")
                        end
                        Convars:SetStr("novr_current_vm_model", current_vm_model)
                    end

                    if map_name == "a3_c17_processing_plant" and player:Attribute_GetIntValue("activated_processing_plant_lift", 0) == 0 and player:GetAbsOrigin().z < 600 then
                        SendToConsole("snd_sos_start_soundevent Player.FallDamage")
                        SendToConsole("ent_fire !player SetHealth 0")
                        return nil
                    end

                    find_i = find_i + 1
                    if find_i >= 8 then
                        find_i = 0
                        if map_name == "a3_distillery" then
                            local cough = Entities:FindByName(nil, "coughtalk_trigger")
                            if cough and player:GetAbsOrigin().y > 0 and player:GetAbsOrigin().z < 500 then
                                SendToConsole("snd_sos_start_soundevent Player.FallDamage")
                                SendToConsole("ent_fire !player SetHealth 0")
                                return nil
                            end
                        end
                        local barnacle_tounge = Entities:FindByClassnameNearest("npc_barnacle_tongue_tip", player:GetOrigin(), 28)
                        if barnacle_tounge and barnacle_tounge:GetOrigin().z > player:GetOrigin().z - 15 then
                            SendToConsole("novr_unequip_wearable")
                        end
                        local shard = Entities:FindByClassnameNearest("shatterglass_shard", player:GetCenter(), 30)
                        if shard and shard:GetMoveParent() and #shard:GetMoveParent():GetChildren() > 1 then
                            DoEntFireByInstanceHandle(shard, "Break", "", 0, nil, nil)
                        end
                    end

                    local viewmodel_offset_y_additional = model_mult * (90 - 60)
                    local user_add_y = cvar_getf("novr_viewmodel_offset_y_additional")
                    local ads = NovrAdsZoomed()
                    if not ads then
                        if last_ads and string.match(current_vm_model, "_ads%.vmdl$") then
                            ViewmodelAnimation_ADStoHIP()
                        end
                        local off_y = viewmodel_offset_y_additional + user_add_y
                        if last_ads or last_off_y ~= off_y then
                            last_off_y = off_y
                            cvar_setf("viewmodel_offset_x", 0)
                            cvar_setf("viewmodel_offset_y", off_y)
                            cvar_setf("viewmodel_offset_z", 0)
                        end
                    end
                    last_ads = ads

                    local crouched = player:GetBoundingMaxs().z == 36
                    if last_crouch ~= crouched then
                        last_crouch = crouched
                        if crouched then
                            cvar_setf("cl_forwardspeed", 86)
                            cvar_setf("cl_backspeed", 86)
                            cvar_setf("cl_sidespeed", 86)
                        else
                            cvar_setf("cl_forwardspeed", 46)
                            cvar_setf("cl_backspeed", 46)
                            cvar_setf("cl_sidespeed", 46)
                        end
                    end
                    return 0
                end, "FixCrouchSpeed", 0)
            end

            SendToConsole("ent_remove text_resin")
            SendToConsole("ent_create game_text { targetname text_resin effect 2 spawnflags 1 color \"255 220 0\" color2 \"92 107 192\" fadein 0 fadeout 0.15 fxtime 0.25 holdtime 5 x 0.02 y 0.08 }")

            WristPockets_StartupPreparations()
            WristPockets_CheckPocketItemsOnLoading(Entities:GetLocalPlayer(), loading_save_file)
            Viewmodels_Init()
            if not loading_save_file then
                ViewmodelAnimation_LevelChange()
            end

            local function PrecacheModels()
                local ent_table = {
                    targetname = "novr_precachemodels",
                    vscripts = "novr_precache.lua"
                }
                SpawnEntityFromTableAsynchronous("logic_script", ent_table, nil, nil);
            end

            PrecacheModels()

            if is_on_map_or_later("a2_quarantine_entrance") then
                ent = Entities:GetLocalPlayer()
                WristPockets_StartUpdateLoop()
            end

            NoVR_PublishGravityGloves()

            if GetMapName() == "a1_intro_world" then
                if loading_save_file then
                    SendToConsole("novr_leavehingecam")
                    MoveFreely()
                else
                    NoVR_FreezeInput()
                    SendToConsole("give weapon_bugbait")
                    SendToConsole("hidehud 12")
                    NoVR.SetActionSuppressed("+covermouth", 1)
                    SendToConsole("ent_fire tv_apartment_decoy_door DisableCollision")

                    ent = Entities:FindByName(nil, "relay_start_intro_text")
                    ent:RedirectOutput("OnTrigger", "DisableUICursor", ent)
                    ent = Entities:FindByName(nil, "relay_start_dossier")
                    ent:RedirectOutput("OnTrigger", "DisableUICursor", ent)

                    ent = Entities:FindByName(nil, "relay_teleported_to_refuge")
                    ent:RedirectOutput("OnTrigger", "MoveFreely", ent)

                    ent = Entities:FindByClassnameNearest("trigger_once", Vector(-240, 1688, 208), 20)
                    ent:RedirectOutput("OnTrigger", "ShowQuickSaveTutorial", ent)

                    ent = Entities:FindByName(nil, "prop_dogfood")
                    local angles = ent:GetAngles()
                    ent:SetAngles(180,angles.y,angles.z)
                    ent:SetOrigin(ent:GetOrigin() + Vector(0,0,10))

                    ent = Entities:FindByName(nil, "relay_heist_monitors_callincoming")
                    ent:RedirectOutput("OnTrigger", "ShowInteractTutorial", ent)

                    ent = Entities:FindByName(nil, "51_ladder_hint_trigger")
                    ent:RedirectOutput("OnTrigger", "ShowLadderTutorial", ent)

                    ent = SpawnEntityFromTableSynchronous("prop_dynamic", {["targetname"]="light_switch_1", ["solid"]=6, ["renderamt"]=0, ["model"]="models/props/lightswitch_2_switch.vmdl", ["origin"]="-541.6 1770.1 133.4", ["angles"]="0 0 0", ["modelscale"]=2})
                    ent = SpawnEntityFromTableSynchronous("prop_dynamic", {["targetname"]="light_switch_2", ["solid"]=6, ["renderamt"]=0, ["model"]="models/props/lightswitch_2_switch.vmdl", ["origin"]="-903.2 1691.6 111", ["angles"]="0 0 0", ["modelscale"]=2})

                    ent = SpawnEntityFromTableSynchronous("prop_dynamic", {["targetname"]="washing_machine_button_1", ["solid"]=6, ["renderamt"]=0, ["model"]="models/props/lightswitch_2_switch.vmdl", ["origin"]="1473.99 -853.165 -347.75", ["angles"]="0 0 0", ["modelscale"]=2})
                    ent = SpawnEntityFromTableSynchronous("prop_dynamic", {["targetname"]="washing_machine_button_2", ["solid"]=6, ["renderamt"]=0, ["model"]="models/props/lightswitch_2_switch.vmdl", ["origin"]="1393.17 -923.015 -347.75", ["angles"]="0 0 0", ["modelscale"]=2})
                    ent = SpawnEntityFromTableSynchronous("prop_dynamic", {["targetname"]="washing_machine_button_3", ["solid"]=6, ["renderamt"]=0, ["model"]="models/props/lightswitch_2_switch.vmdl", ["origin"]="1393.17 -952.015 -347.75", ["angles"]="0 0 0", ["modelscale"]=2})
                    ent = SpawnEntityFromTableSynchronous("prop_dynamic", {["targetname"]="washing_machine_button_4", ["solid"]=6, ["renderamt"]=0, ["model"]="models/props/lightswitch_2_switch.vmdl", ["origin"]="1396.98 -982.97 -347.75", ["angles"]="0 0 0", ["modelscale"]=2})

                    SendToConsole("ent_fire 563_vent_door DisablePickup")
                    SendToConsole("ent_fire 563_vent_phys_hinge SetOffset 0.1")

                    ent = SpawnEntityFromTableSynchronous("prop_dynamic", {["solid"]=6, ["renderamt"]=0, ["model"]="models/props/industrial_door_1_40_92_white_temp.vmdl", ["origin"]="640 -1770 -210", ["angles"]="0 -10 0", ["modelscale"]=0.75})
                    ent = SpawnEntityFromTableSynchronous("prop_dynamic", {["solid"]=6, ["renderamt"]=0, ["model"]="models/props/industrial_door_1_40_92_white_temp.vmdl", ["origin"]="-233 1772 182", ["angles"]="90 0 0"})
                end

                Convars:RegisterCommand("novr_leavehingecam", function()
                    ent = Entities:FindByName(nil, "205_2724_hingecam")
                    if ent:Attribute_GetIntValue("active", 0) == 1 then
                        ent:StopThink("UsingHingeCam")
                        ent:FireOutput("OnInteractStop", nil, nil, nil, 0)
                        local gunAngle = ent:LoadQAngle("OrigAngle")
                        ent:SetAngles(gunAngle.x,gunAngle.y,gunAngle.z)
                        ent:Attribute_SetIntValue("active", 0)
                        SendToConsole("setpos_exact -831.591980 1946.499878 80")
                        SendToConsole("noclip")
                        SendToConsole("ent_fire 205_2724_hingecam enablecollision")
                        SendToConsole("ent_fire player_speedmod ModifySpeed 1")
                        NovrReturnFire()
                        NoVR.ReturnBorrowed("novr_leavehingecam")
                        NoVR.HideHint("hingecam")
                    end
                end, "", 0)
            elseif GetMapName() == "a1_intro_world_2" then
                if not loading_save_file then
                    ent = SpawnEntityFromTableSynchronous("env_message", {["message"]="CHAPTER1_TITLE"})
                    DoEntFireByInstanceHandle(ent, "ShowMessage", "", 0, nil, nil)
                    SendToConsole("ent_fire russell_entry_window SetCompletionValue 0.4")

                    SendToConsole("ent_fire car_door_rear DisablePickup")
                end

                ent = Entities:GetLocalPlayer()
                if ent:Attribute_GetIntValue("pistol", 0) == 0 then
                    if ent:Attribute_GetIntValue("gravity_gloves", 0) == 0 then
                        SendToConsole("hidehud 104")
                    else
                        SendToConsole("hidehud 8")
                        ent:SetThink(function()
                            SendToConsole("hidehud 9")
                        end, "", 0)
                    end
                    SendToConsole("give weapon_bugbait")
                else
                    SendToConsole("hidehud 72")
                    SendToConsole("r_drawviewmodel 1")
                end

                if ent:Attribute_GetIntValue("gravity_gloves", 0) ~= 0 then
                    WristPockets_StartUpdateLoop()
                end

                SendToConsole("combine_grenade_timer 7")

                if not loading_save_file then
                    ent = Entities:FindByName(nil, "trigger_post_gate")
                    ent:RedirectOutput("OnTrigger", "ShowSprintTutorial", ent)

                    ent = Entities:FindByName(nil, "@hint_crouch_locker_trigger")
                    ent:RedirectOutput("OnStartTouch", "ShowCrouchTutorial", ent)

                    ent = Entities:FindByName(nil, "timer_figure_nag")
                    ent:RedirectOutput("OnTimer", "ShowPickUpTutorial", ent)

                    ent = Entities:FindByName(nil, "gg_training_start_trigger")
                    ent:RedirectOutput("OnTrigger", "ShowGravityGlovesTutorial", ent)

                    ent = Entities:FindByName(nil, "gate_ammo_trigger")
                    local origin = ent:GetOrigin()
                    local angles = ent:GetAngles()
                    ent = SpawnEntityFromTableSynchronous("trigger_detect_bullet_fire", {["model"]="maps/a1_intro_world_2/entities/gate_ammo_trigger_621_2249_345.vmdl", ["origin"]= origin.x .. " " .. origin.y .. " " .. origin.z, ["angles"]= angles.x .. " " .. angles.y .. " " .. angles.z})
                    ent:RedirectOutput("OnDetectedBulletFire", "CheckTutorialPistolEmpty", ent)

                    ent = Entities:FindByName(nil, "relay_van_open")
                    ent:RedirectOutput("OnTrigger", "GetOutOfCrashedVan", ent)

                    ent = Entities:FindByName(nil, "relay_weapon_pistol_fakefire")
                    ent:RedirectOutput("OnTrigger", "RedirectPistol", ent)
                end
            else
                SendToConsole("hidehud 72")
                SendToConsole("r_drawviewmodel 1")
                Entities:GetLocalPlayer():Attribute_SetIntValue("gravity_gloves", 1)
                NoVR_PublishGravityGloves()

                if is_on_map_or_later("a2_drainage") then
                    Entities:GetLocalPlayer():Attribute_SetIntValue("has_flashlight", 1)
                end

                if GetMapName() == "a2_quarantine_entrance" then
                    if not loading_save_file then

                        ent = SpawnEntityFromTableSynchronous("env_message", {["message"]="CHAPTER2_TITLE"})
                        DoEntFireByInstanceHandle(ent, "ShowMessage", "", 0, nil, nil)

                        ent = Entities:FindByName(nil, "28677_hint_mantle_delay")
                        ent:RedirectOutput("OnTrigger", "ShowCrouchJumpTutorial", ent)

                        ent = Entities:FindByName(nil, "toner_trigger")
                        ent:RedirectOutput("OnTrigger", "ShowMultiToolTutorial", ent)

                        SendToConsole("setpos 3215 2456 465")
                        SendToConsole("ent_fire traincar_border_trigger Disable")
                    end
                elseif GetMapName() == "a2_pistol" then
                    if not loading_save_file then
                        ent = Entities:FindByName(nil, "trigger_if_player_navs_over_boards")
                        ent:RedirectOutput("OnTrigger", "ShowBreakBoardsTutorial", ent)

                        SendToConsole("ent_fire *_rebar EnablePickup")

                        Entities:FindByName(nil, "bullseye_explosion_platform_a"):SetOrigin(Vector(-128, 1123.933, 488))
                        Entities:FindByName(nil, "no_look_trigger_for_hc_intro"):SetOrigin(Vector(-1984, 390, 440))
                    end
                elseif GetMapName() == "a2_headcrabs_tunnel" then
                    if not loading_save_file then

                        ent = SpawnEntityFromTableSynchronous("env_message", {["message"]="CHAPTER3_TITLE"})
                        DoEntFireByInstanceHandle(ent, "ShowMessage", "", 0, nil, nil)

                        ent = SpawnEntityFromTableSynchronous("prop_physics_override", {["targetname"]="shotgun_pickup_blocker", ["parentname"]="12712_intro_shotgun", ["CollisionGroupOverride"]=5, ["renderamt"]=0, ["model"]="models/hacking/holo_hacking_sphere_prop.vmdl", ["modelscale"]=2})
                        ent:SetLocalOrigin(Vector(0, 0, 0))
                        DoEntFireByInstanceHandle(ent, "DisablePickup", "", 0, nil, nil)

                        Entities:FindByName(nil, "12712_shotgun_wheel"):Attribute_SetIntValue("used", 1)
                        ent = Entities:FindByName(nil, "12712_293_relay_zombies_hitting_wall")
                        ent:RedirectOutput("OnTrigger", "EnableShotgunWheel", ent)

                        ent = Entities:FindByName(nil, "15493_hint_mantle_delay")
                        ent:RedirectOutput("OnTrigger", "ShowCrouchJumpTutorial", ent)

                        ent = Entities:FindByClassnameNearest("trigger_once", Vector(-746, -943, -92), 10)
                        ent:Kill()

                        ent = Entities:FindByClassnameNearest("prop_door_rotating_physics", Vector(-807, -643, -80), 10)
                        DoEntFireByInstanceHandle(ent, "SetOpenDirection", "2", 0, nil, nil)
                    end
                elseif GetMapName() == "a2_hideout" then
                    if not loading_save_file then
                        ent = Entities:FindByName(nil, "8271_button_counter")
                        ent:RedirectOutput("OnHitMax", "DisableHideoutPuzzleButtons", ent)

                        ent = Entities:FindByName(nil, "8271_relay_reset_buttons")
                        ent:RedirectOutput("OnTrigger", "ResetHideoutPuzzleButtons", ent)

                        ent = Entities:FindByName(nil, "2861_4065_hint_mantle_delay")
                        ent:RedirectOutput("OnTrigger", "ShowCrouchJumpTutorial", ent)

                        ent = Entities:FindByName(nil, "13987_hint_mantle_delay")
                        ent:RedirectOutput("OnTrigger", "ShowCrouchJumpTutorial", ent)

                        ent = Entities:FindByName(nil, "relay_open_gate")
                        ent:RedirectOutput("OnTrigger", "OpenHideoutGate", ent)

                        ent = Entities:FindByName(nil, "exit_barrier")
                        local angles = ent:GetAngles()
                        local pos = ent:GetAbsOrigin()
                        local child = SpawnEntityFromTableSynchronous("prop_dynamic_override", {["targetname"]="hideout_gate_prop", ["CollisionGroupOverride"]=5, ["solid"]=6, ["DefaultAnim"]="vort_barrier_start_idle", ["renderamt"]=0, ["model"]=ent:GetModelName(), ["origin"]= pos.x .. " " .. pos.y .. " " .. pos.z, ["angles"]= angles.x .. " " .. angles.y .. " " .. angles.z - 20})
                        child:SetParent(ent, "")

                        local player_clip = Entities:FindByClassnameNearest("func_brush", Vector(-692, -1369.25, -243.875), 10)
                        if player_clip then
                            SendToConsole("ent_fire trigger_player_in_big_room AddOutput \"OnTrigger>" .. player_clip:GetName() .. ">Enable>>0>-1\"")
                            SendToConsole("ent_fire ss_kitchen_to_cardshow AddOutput \"OnScriptEvent01>" .. player_clip:GetName() .. ">Disable>>1>-1\"")
                        end
                    end
                else
                    if GetMapName() == "a2_drainage" then
                        if not loading_save_file then
                            ent = Entities:FindByName(nil, "wheel2_physics")
                            ent:SetOrigin(Vector(208, -2581, 420))
                            ent:SetAngles(-45,0,0)

                            SendToConsole("ent_fire math_count_wheel2_installment AddOutput \"OnChangedFromMin>relay_install_wheel2>Trigger>>0>1\"")
                            SendToConsole("ent_fire math_count_wheel_installment AddOutput \"OnChangedFromMin>relay_install_wheel>Trigger>>0>1\"")
                            SendToConsole("ent_fire wheel_physics DisablePickup")
                            ent = Entities:FindByClassnameNearest("npc_barnacle", Vector(941, -1666, 255), 10)
                            DoEntFireByInstanceHandle(ent, "AddOutput", "OnRelease>wheel_physics>EnablePickup>>0>1", 0, nil, nil)

                            ent = SpawnEntityFromTableSynchronous("trigger_detect_bullet_fire", {["targetname"]="bullet_trigger", ["StartDisabled"]=true, ["modelscale"]=1000, ["model"]="models/hacking/holo_hacking_sphere_prop.vmdl"})
                            DoEntFireByInstanceHandle(ent, "AddOutput", "OnDetectedBulletFire>player_speak>SpeakConcept>speech:gunshot_warning>0>1", 0, nil, nil)
                            DoEntFireByInstanceHandle(ent, "AddOutput", "OnDetectedBulletFire>!self>Kill>>0>1", 0, nil, nil)

                            ent = Entities:FindByName(nil, "trigger_gunshot_listener")
                            DoEntFireByInstanceHandle(ent, "AddOutput", "OnTrigger>bullet_trigger>Enable>>0>1", 0, nil, nil)

                            ent = Entities:FindByName(nil, "trigger_disable_listener")
                            DoEntFireByInstanceHandle(ent, "AddOutput", "OnTrigger>bullet_trigger>Kill>>0>1", 0, nil, nil)
                        end
                    elseif GetMapName() == "a2_train_yard" then
                        ent = Entities:FindByName(nil, "train_arrival_trigger")
                        if ent ~= nil then ent:RedirectOutput("OnTrigger", "EnableTrainLeverReleaseDialogue", ent) end

                        ent = Entities:FindByName(nil, "relay_train_will_crash")
                        ent:RedirectOutput("OnTrigger", "DisableTrainLever", ent)

                        ent = Entities:FindByName(nil, "mission_fail_relay")
                        ent:RedirectOutput("OnTrigger", "FailMission", ent)

                        ent = Entities:FindByName(nil, "trainwreck_endfade_relay")
                        ent:RedirectOutput("OnTrigger", "TeleportAfterTrainCrash", ent)

                        ent = Entities:FindByName(nil, "eli_rescue_3")
                        ent:RedirectOutput("OnCompletion", "ReachForEli", ent)

                        if not loading_save_file then

                            ent = SpawnEntityFromTableSynchronous("prop_dynamic", {["solid"]=6, ["renderamt"]=0, ["model"]="models/props/industrial_door_1_40_92_white_temp.vmdl", ["origin"]="-1080 3200 -350", ["angles"]="0 12 0", ["modelscale"]=5, ["targetname"]="elipreventfall"})
                            ent = Entities:FindByName(nil, "eli_rescue_3_relay")
                            ent:RedirectOutput("OnTrigger", "RemoveEliPreventFall", ent)
                        end
                    elseif GetMapName() == "a3_hotel_interior_rooftop" then
                        if not loading_save_file then
                            ent = SpawnEntityFromTableSynchronous("item_hlvr_prop_battery", {["origin"]="2045 -1717 886"})

                            ent = SpawnEntityFromTableSynchronous("prop_dynamic_override", {["solid"]=6, ["renderamt"]=0, ["model"]="models/architecture/metal_siding/metal_siding_32_a.vmdl", ["origin"]="2320 -1854 834", ["angles"]="0 0 0", ["modelscale"]=0.5})

                            SendToConsole("ent_fire window_sliding1* SetMass 501")
                        end
                    elseif GetMapName() == "a3_station_street" then
                        if not loading_save_file then

                            ent = SpawnEntityFromTableSynchronous("env_message", {["message"]="CHAPTER4_TITLE"})
                            DoEntFireByInstanceHandle(ent, "ShowMessage", "", 0, nil, nil)

                            ent = Entities:FindByName(nil, "door")
                            DoEntFireByInstanceHandle(ent, "SetOpenDirection", "" .. 2, 0, nil, nil)

                            ent = Entities:FindByName(nil, "patrol_trigger_seq_cancel")
                            ent:SetOrigin(Vector(1834, -40, -488))
                        end
                    elseif GetMapName() == "a3_hotel_lobby_basement" then
                        Entities:FindByName(nil, "power_stake_2_start"):Attribute_SetIntValue("used", 1)

                        if not loading_save_file then

                            ent = SpawnEntityFromTableSynchronous("env_message", {["message"]="CHAPTER5_TITLE"})
                            DoEntFireByInstanceHandle(ent, "ShowMessage", "", 0, nil, nil)

                            ent = Entities:FindByName(nil, "power_stake_1_start")
                            ent:Attribute_SetIntValue("used", 1)

                            ent = Entities:FindByName(nil, "417_149_powerunit_relay_battery_inserted")
                            ent:RedirectOutput("OnTrigger", "EnableHotelLobbyPower", ent)

                            ent = Entities:FindByName(nil, "base_dropdown_template_1")
                            ent:RedirectOutput("OnEntitySpawned", "DisableBarnacleAmmoPickup", ent)
                        end
                    elseif GetMapName() == "a3_hotel_underground_pit" then
                        ent = Entities:FindByClassnameNearest("prop_door_rotating_physics", Vector(2012, -1571, 408), 10)
                        DoEntFireByInstanceHandle(ent, "SetOpenDirection", "1", 0, nil, nil)
                    elseif GetMapName() == "a3_hotel_street" then
                        if not loading_save_file then

                            Entities:FindByName(nil, "elev_anim_door"):Attribute_SetIntValue("toggle", 1)

                            ent = Entities:FindByName(nil, "elev_anim_door")
                            ent:Attribute_SetIntValue("used", 1)
                            ent = Entities:FindByName(nil, "ss_elevator_move")
                            ent:RedirectOutput("OnEndSequence", "EnableStreetElevatorDoor", ent)

                            ent = Entities:FindByClassnameNearest("prop_door_rotating_physics", Vector(780, 1614, 336), 10)
                            ent:RedirectOutput("OnOpen", "ExplodeFirstDoorMine", ent)

                            ent = Entities:FindByName(nil, "167_18697_tripmine_trap_door_1")
                            DoEntFireByInstanceHandle(ent, "SetOpenDirection", "" .. 2, 0, nil, nil)
                        end
                    elseif GetMapName() == "a3_c17_processing_plant" then
                        if not loading_save_file then

                            ent = SpawnEntityFromTableSynchronous("prop_dynamic", {["solid"]=6, ["renderamt"]=0, ["model"]="models/props/construction/construction_yard_lift.vmdl", ["origin"]="-1984 -2456 154", ["angles"]="0 270 0", ["parentname"]="pallet_crane_platform"})

                            ent = SpawnEntityFromTableSynchronous("env_message", {["message"]="CHAPTER6_TITLE"})
                            DoEntFireByInstanceHandle(ent, "ShowMessage", "", 0, nil, nil)

                            SendToConsole("ent_fire vent_door DisablePickup")

                            SendToConsole("ent_fire pallet_move_linear SetMoveDistanceFromStart 115")
                        end
                    elseif GetMapName() == "a3_distillery" then
                        ent = Entities:FindByName(nil, "exit_counter")
                        ent:RedirectOutput("OnHitMax", "EnablePlugLever1", ent)

                        ent = Entities:FindByName(nil, "11578_2420_181_relay_unlock_controls")
                        ent:RedirectOutput("OnTrigger", "EnablePlugLever2", ent)

                        ent = Entities:FindByName(nil, "11578_2420_183_relay_unlock_controls")
                        ent:RedirectOutput("OnTrigger", "EnablePlugLever3", ent)

                        ent = Entities:FindByName(nil, "@branch_bz_locked_up")
                        ent:RedirectOutput("OnTrue", "EnablePlugLever4", ent)

                        ent = Entities:FindByName(nil, "11578_2420_183_relay_control_reset")
                        ent:RedirectOutput("OnTrigger", "EnablePlugLever1", ent)

                        if not loading_save_file then

                            ent = SpawnEntityFromTableSynchronous("env_message", {["message"]="CHAPTER7_TITLE"})
                            DoEntFireByInstanceHandle(ent, "ShowMessage", "", 0, nil, nil)

                            ent = Entities:FindByName(nil, "11478_6250_locked_door_relay_break_lock")
                            ent:RedirectOutput("OnTrigger", "FixJeffBatteryPuzzle", ent)

                            ent = Entities:FindByName(nil, "11632_223_cough_volume")
                            ent:RedirectOutput("OnStartTouch", "ShowCoverMouthTutorial", ent)

                            SendToConsole("ent_fire timer_gun_equipped Kill")
                            SendToConsole("ent_fire timer_gun_equipped_b Kill")
                            ent = Entities:FindByName(nil, "vcd_larry_talk_01")
                            ent:RedirectOutput("OnCompletion", "LarrySeesGun", ent)

                            ent = Entities:FindByName(nil, "spawner_larry_hat_sound_target")
                            ent:RedirectOutput("OnEntitySpawned", "LarrySeesWearable", ent)

                            ent = Entities:FindByClassnameNearest("prop_handpose", Vector(925, 1102, 578), 50)
                            if ent then
                                DoEntFireByInstanceHandle(ent, "Kill", "", 0, nil, nil)
                            end

                            ent = SpawnEntityFromTableSynchronous("trigger_detect_bullet_fire", {["targetname"]="bullet_trigger", ["modelscale"]=1000, ["model"]="models/hacking/holo_hacking_sphere_prop.vmdl"})
                            DoEntFireByInstanceHandle(ent, "AddOutput", "OnDetectedBulletFire>!player>GenerateBlindZombieSound>>0>-1", 0, nil, nil)
                        end
                    else
                        if GetMapName() == "a4_c17_zoo" then
                            if not loading_save_file then

                                ent = SpawnEntityFromTableSynchronous("env_message", {["message"]="CHAPTER8_TITLE"})
                                DoEntFireByInstanceHandle(ent, "ShowMessage", "", 0, nil, nil)

                                ent = Entities:FindByClassnameNearest("npc_barnacle", Vector(5126, -1957, 64), 10)
                                DoEntFireByInstanceHandle(ent, "AddOutput", "OnRelease>tiger_mask>EnablePickup>>0>1", 0, nil, nil)
                            end

                            ent = Entities:FindByName(nil, "relay_power_receive")
                            ent:RedirectOutput("OnTrigger", "MakeLeverUsable", ent)

                            ent = Entities:FindByClassnameNearest("trigger_multiple", Vector(5380, -1848, -117), 10)
                            ent:RedirectOutput("OnStartTouch", "CrouchThroughZooHole", ent)

                            SendToConsole("ent_fire @prop_phys_portaloo_door DisablePickup")
                        elseif GetMapName() == "a4_c17_tanker_yard" then
                            SendToConsole("ent_fire elev_hurt_player_* Kill")

                            if Entities:GetLocalPlayer():Attribute_GetIntValue("eavesdropping", 0) == 1 then
                                NoVR.SetActionSuppressed("+customattack", 1)
                                NoVR.SetActionSuppressed("+customattack2", 1)
                                NoVR.SetActionSuppressed("+customattack3", 1)
                                NoVR.SetActionSuppressed("inv_flashlight", 1)
                                SendToConsole("hidehud 12")
                            end

                            if not loading_save_file then

                                ent = SpawnEntityFromTableSynchronous("env_message", {["message"]="CHAPTER9_TITLE"})
                                DoEntFireByInstanceHandle(ent, "ShowMessage", "", 0, nil, nil)

                                ent = Entities:FindByClassnameNearest("trigger_once", Vector(6243, 4212, 612), 20)
                                ent:RedirectOutput("OnTrigger", "StartRevealEavesdrop", ent)

                                ent = Entities:FindByName(nil, "eavesdrop_mystery")
                                ent:RedirectOutput("OnTrigger2", "StopRevealEavesdrop", ent)

                                ent = Entities:FindByName(nil, "elevator_path_1")
                                ent:RedirectOutput("OnPass", "EnableToiletElevatorLever", ent)

                                ent = Entities:FindByName(nil, "elev_trigger_player_inside")
                                ent:SetOrigin(ent:GetOrigin() + Vector(0,0,50))
                                ent = Entities:FindByName(nil, "elev_trigger_player_inside_outer_trigger")
                                ent:SetOrigin(ent:GetOrigin() + Vector(0,0,50))

                                ent = Entities:FindByName(nil, "waste_vial_template_1")
                                ent:RedirectOutput("OnEntitySpawned", "DisableBarnacleHealthVialPickup", ent)

                                ent = Entities:FindByName(nil, "antlion_tanker_spitter_01")
                                ent:SetAbsOrigin(Vector(3310.622, 6371.935, 100))

                                SendToConsole("ent_fire @prop_phys_portaloo_door DisablePickup")
                                SendToConsole("ent_fire elev_exit_teleport_clip Kill")
                            end
                        elseif GetMapName() == "a4_c17_water_tower" then
                            if not loading_save_file then
                                ent = SpawnEntityFromTableSynchronous("env_message", {["message"]="CHAPTER10_TITLE"})
                                DoEntFireByInstanceHandle(ent, "ShowMessage", "", 0, nil, nil)

                                ent = Entities:FindByName(nil, "fade_out")
                                ent:RedirectOutput("OnBeginFade", "CheckForGnome", ent)

                                local player_clip = Entities:FindAllByClassname("func_brush")[1]
                                local player_clip_name = player_clip:GetName()
                                if vlua.find(player_clip_name, "fence_blocker_player")  then
                                    ent = Entities:FindByClassnameNearest("trigger_once", Vector(2752, 5740, 384), 20)
                                    DoEntFireByInstanceHandle(ent, "AddOutput", "OnTrigger>" .. player_clip_name .. ">Disable>>0>-1", 0, nil, nil)
                                end
                            end
                        elseif GetMapName() == "a4_c17_parking_garage" then
                            NoVR.SetMovementFreeze(0)
                            NoVR.SetPlatformCarry(0)
                            if loading_save_file then
                                SendToConsole("novr_leavecombinegun")
                            else
                                SendToConsole("setpos -958 -842 910")

                                SendToConsole("ent_fire template_spawn_black_headcrabs_01 AddOutput OnEntitySpawned>headcrab_black_underground_01>Kill>>0>-1\"")

                                ent = Entities:FindByName(nil, "falling_cabinet_door")
                                DoEntFireByInstanceHandle(ent, "DisablePickup", "", 0, nil, nil)

                                SendToConsole("ent_fire func_physbox DisableMotion")

                                ent = Entities:FindByName(nil, "relay_enter_ufo_beam")
                                ent:RedirectOutput("OnTrigger", "EnterVaultBeam", ent)

                                SendToConsole("ent_fire combine_gun_grab_handle ClearParent aim_gun")
                                SendToConsole("ent_fire combine_gun_grab_handle SetParent combine_gun_mechanical")

                                ent = Entities:FindByName(nil, "relay_shoot_gun")
                                ent:RedirectOutput("OnTrigger", "CombineGunHandleAnim", ent)

                                if Entities:GetLocalPlayer():Attribute_GetIntValue("HasGnome", 0) == 1 then
                                    Entities:GetLocalPlayer():SetThink(function()
                                        local gnome = SpawnEntityFromTableSynchronous("prop_physics", {["model"]="models/props/choreo_office/gnome.vmdl"})
                                        gnome:SetOrigin(Entities:GetLocalPlayer():GetCenter())
                                        gnome:SetEntityName("gnome")
                                    end, "SpawnGnome", 1.0)
                                end
                            end
                            Convars:RegisterCommand("novr_shootcombinegun", function()
                                ent = Entities:FindByName(nil, "combine_gun_interact")
                                if ent:Attribute_GetIntValue("ready", 0) == 1 then
                                    SendToConsole("ent_fire relay_shoot_gun trigger")
                                    ent:Attribute_SetIntValue("ready", 0)
                                end
                            end, "", 0)
                            Convars:RegisterCommand("novr_leavecombinegun", function()
                                ent = Entities:FindByName(nil, "combine_gun_interact")
                                if ent:Attribute_GetIntValue("active", 0) == 1 then
                                    ent:StopThink("UsingCombineGun")
                                    SendToConsole("setpos 1510.57 386.48 924")
                                    ent:FireOutput("OnInteractStop", nil, nil, nil, 0)
                                    local gunAngle = ent:LoadQAngle("OrigAngle")
                                    ent:SetAngles(gunAngle.x,gunAngle.y,gunAngle.z)
                                    ent:Attribute_SetIntValue("active", 0)
                                    SendToConsole("ent_fire combine_gun_mechanical enablecollision")
                                    SendToConsole("ent_fire player_speedmod ModifySpeed 1")
                                    NoVR.SetMovementFreeze(0)
                                    NovrReturnFire()
                                    SendToConsole("r_drawviewmodel 1")
                                    NoVR.ReturnBorrowed("novr_leavecombinegun")
                                    NoVR.HideHint("combinegun")
                                end
                            end, "", 0)
                        elseif GetMapName() == "a5_vault" then
                            NoVR.SetMovementFreeze(0)
                            NoVR.SetPlatformCarry(0)
                            SendToConsole("ent_fire player_speedmod ModifySpeed 1")
                            SendToConsole("use weapon_bugbait")
                            SendToConsole("r_drawviewmodel 0")
                            ent:SetThink(function()
                                SendToConsole("hidehud 75")
                            end, "", 0)
                            NoVR.SetActionSuppressed("inv_flashlight", 1)
                            WristPockets_DisableKeepAcrossMaps()

                            ent = Entities:FindByName(nil, "updownapt_exit_teleport_trigger")
                            if ent then ent:SetOrigin(Vector(-2480, -2280, -32)) end

                            if not loading_save_file then
                                Entities:GetLocalPlayer():Attribute_SetIntValue("grenade", 0)
                                Entities:GetLocalPlayer():Attribute_SetIntValue("pistol_upgrade_aimdownsights", 0)

                                ent = SpawnEntityFromTableSynchronous("env_message", {["message"]="CHAPTER11_TITLE"})
                                DoEntFireByInstanceHandle(ent, "ShowMessage", "", 0, nil, nil)

                                SendToConsole("ent_fire upsidedownroom_closetdoor* DisablePickup")

                                SendToConsole("ent_remove weapon_pistol;ent_remove weapon_shotgun;ent_remove weapon_ar2;ent_remove weapon_smg1;ent_remove weapon_physcannon")
                                SendToConsole("give weapon_bugbait")

                                ent = SpawnEntityFromTableSynchronous("prop_dynamic_override", {["CollisionGroupOverride"]=5, ["solid"]=6, ["model"]="models/architecture/doors_1/door_1b_40_92.vmdl", ["origin"]="-835 160 -539", ["angles"]="76 110 10"})

                                ent = SpawnEntityFromTableSynchronous("prop_dynamic_override", {["CollisionGroupOverride"]=5, ["solid"]=6, ["model"]="models/props/oldstyle_table_2.vmdl", ["origin"]="-345 2881 -695", ["angles"]="45 0 -90"})
                                ent = SpawnEntityFromTableSynchronous("prop_dynamic_override", {["CollisionGroupOverride"]=5, ["solid"]=6, ["model"]="models/props/oldstyle_table_2.vmdl", ["origin"]="-260 2881 -640", ["angles"]="45 0 -90"})

                                ent = Entities:FindByName(nil, "longcorridor_outerdoor1")
                                ent:RedirectOutput("OnFullyClosed", "GiveVortEnergy", ent)
                                ent:RedirectOutput("OnFullyClosed", "ShowVortEnergyTutorial", ent)

                                ent = Entities:FindByName(nil, "longcorridor_innerdoor")
                                ent:RedirectOutput("OnFullyClosed", "RemoveVortEnergy", ent)

                                ent = Entities:FindByName(nil, "longcorridor_energysource_01_activate_relay")
                                ent:RedirectOutput("OnTrigger", "GiveVortEnergy", ent)

                                local player_clip = Entities:FindByClassnameNearest("func_brush", Vector(-931, 264, -481), 10)
                                if player_clip then
                                    ent = Entities:FindByName(nil, "rooftop_concretedislodge_relay")
                                    DoEntFireByInstanceHandle(ent, "AddOutput", "OnTrigger>" .. player_clip:GetName() .. ">Disable>>0>-1", 0, nil, nil)
                                end
                            else
                                if Entities:GetLocalPlayer():Attribute_GetIntValue("vort_energy", 0) == 1 then
                                    GiveVortEnergy()
                                end
                            end
                        elseif GetMapName() == "a5_ending" then
                            SendToConsole("ent_remove weapon_pistol;ent_remove weapon_shotgun;ent_remove weapon_ar2;ent_remove weapon_smg1;ent_remove weapon_frag;ent_remove weapon_physcannon")
                            SendToConsole("use weapon_bugbait")
                            SendToConsole("r_drawviewmodel 0")
                            ent:SetThink(function()
                                SendToConsole("hidehud 75")
                            end, "", 0)
                            NoVR.SetActionSuppressed("inv_flashlight", 1)
                            NoVR.SetActionSuppressed("+covermouth", 1)
                            Entities:GetLocalPlayer():Attribute_SetIntValue("grenade", 0)
                            Entities:GetLocalPlayer():Attribute_SetIntValue("gravity_gloves", 0)
                            NoVR_PublishGravityGloves()

                            if not loading_save_file then
                                local player_clip = Entities:FindAllByClassname("func_brush")[1]
                                local player_clip_name = player_clip:GetName()
                                ent = Entities:FindByClassnameNearest("trigger_once", Vector(620, -144, -2432), 20)
                                if vlua.find(player_clip_name, "innervault_nobacktrack_brush_player")  then
                                    DoEntFireByInstanceHandle(ent, "AddOutput", "OnTrigger>" .. player_clip_name .. ">Enable>>0>-1", 0, nil, nil)
                                end
                                ent:RedirectOutput("OnTrigger", "GrabCandlers", ent)

                                ent = Entities:FindByName(nil, "timer_briefcase")
                                DoEntFireByInstanceHandle(ent, "RefireTime", "5", 0, nil, nil)

                                ent = Entities:FindByName(nil, "relay_advisor_void")
                                ent:RedirectOutput("OnTrigger", "GiveAdvisorVortEnergy", ent)

                                ent = Entities:FindByName(nil, "relay_first_credits_start")
                                ent:RedirectOutput("OnTrigger", "StartCredits", ent)

                                ent = Entities:FindByName(nil, "vcd_ending_eli")
                                ent:RedirectOutput("OnTrigger3", "EndCredits", ent)

                                ent = Entities:FindByName(nil, "ss_gordon")
                                ent:RedirectOutput("OnScriptEvent01", "GiveCrowbar", ent)
                            end
                        end
                    end
                end
            end
        end

    end, nil)

    function PlayerDied()
        SendToServerConsole("unpause")
        WristPockets_StopUpdateLoop()
        SendToConsole("disable_flashlight")
        NoVR.AdsZoom(0)
        ViewmodelAnimation_Reset()
        NoVR.HideHint()
        NoVR.SetHintAnchor(0)
        SendToConsole("ent_fire novr_hint_* EndHint")
        SendToConsole("ent_fire novr_hint_* Kill")
        SendToConsole("ent_fire novr_hintgt_* Kill")
    end

    function GoToMainMenu(a, b)
        SendToConsole("achievement_disable 0")
    end

    local NOVR_INPUT_FREEZE = "novr_input_freeze"

    function NoVR_FreezeInput(a, b)
        NovrClearAds()
        NoVR.SetInputFreeze(1)
        local ent = Entities:FindByName(nil, NOVR_INPUT_FREEZE)
        if not ent then
            ent = SpawnEntityFromTableSynchronous("point_hlvr_player_input_modifier", {
                targetname = NOVR_INPUT_FREEZE,
                start_enabled = true,
                disable_teleport = true,
            })
        end
        if ent then DoEntFireByInstanceHandle(ent, "Enable", "", 0, nil, nil) end
    end

    function NoVR_UnfreezeInput(a, b)
        NoVR.SetInputFreeze(0)
        local ent = Entities:FindByName(nil, NOVR_INPUT_FREEZE)
        if ent then DoEntFireByInstanceHandle(ent, "Disable", "", 0, nil, nil) end
    end

    function MoveFreely(a, b)
        NoVR_UnfreezeInput()
        SendToConsole("mouse_disableinput 0")
        SendToConsole("ent_fire player_speedmod ModifySpeed 1")
        SendToConsole("hidehud 104")
        NoVR.SetActionSuppressed("+covermouth", 0)
    end

    function DisableUICursor(a, b)
        SendToConsole("ent_fire point_clientui_world_panel IgnoreUserInput")
    end

    function CheckForGnome(a, b)

        local ents = Entities:FindAllByClassnameWithin("prop_physics", Entities:GetLocalPlayer():GetCenter(), 100)
        for k, v in pairs(ents) do
            if vlua.find(v:GetModelName(), "models/props/choreo_office/gnome.vmdl") then
                if GetMapName() == "a3_hotel_interior_rooftop" then
                    v:SetOrigin(Vector(792, -1420, 576))
                else
                    Entities:GetLocalPlayer():Attribute_SetIntValue("HasGnome", 1)
                end
            end
        end
    end

    function EquipHingeCam(player)
        SendToConsole("setpos_exact -844 1974 62;setang 0 90 0")
        SendToConsole("ent_fire player_speedmod ModifySpeed 0")
        NovrBorrowFire("novr_shootcombinegun")
        SendToConsole("r_drawviewmodel 0")

        local ent = Entities:FindByName(nil, "205_2724_hingecam")
        ent:Attribute_SetIntValue("active", 1)
        ent:FireOutput("OnInteractStart", nil, nil, nil, 0)
        ent:SetThink(function()
            ent:SetAngles(player:EyeAngles().x,player:EyeAngles().y,0)
            return 0.05
        end, "UsingHingeCam", 0)
    end

    function GetOutOfCrashedVan(a, b)
        Entities:GetLocalPlayer():SetThink(function()
            SendToConsole("fadeout 0.5")
        end, "FadeOut", 1.5)
        Entities:GetLocalPlayer():SetThink(function()
            SendToConsole("fadein 0.5")
            SendToConsole("setpos_exact -1408 2307 -114")
            SendToConsole("ent_fire 4962_car_door_left_front open")
        end, "FadeIn", 2)
    end

    function RedirectPistol(a, b)
        ent = Entities:FindByName(nil, "weapon_pistol")
        ent:RedirectOutput("OnPlayerPickup", "EquipPistol", ent)
    end

    function GivePistol(a, b)
        SendToConsole("ent_fire pistol_give_relay trigger")
    end

    function EquipPistol(a, b)
        local player = Entities:GetLocalPlayer()
        SendToConsole("ent_fire_output weapon_equip_listener OnEventFired")
        SendToConsole("hidehud 72")
        SendToConsole("ent_fire item_hlvr_weapon_energygun kill")
        player:Attribute_SetIntValue("pistol", 1)
        player:SetThink(function()
            SendToConsole("r_drawviewmodel 1")
        end, "ShowPistolViewmodel", 0.02)
    end

    function DisableHideoutPuzzleButtons(a, b)
        ent = Entities:FindByClassname(nil, "func_physical_button")
        while ent do
            ent:Attribute_SetIntValue("used", 1)
            ent = Entities:FindByClassname(ent, "func_physical_button")
        end
    end

    function ResetHideoutPuzzleButtons(a, b)
        ent = Entities:FindByClassname(nil, "func_physical_button")
        ent:SetThink(function()
            while ent do
                ent:Attribute_SetIntValue("used", 0)
                ent = Entities:FindByClassname(ent, "func_physical_button")
            end
        end, "", 3)
    end

    function EnableShotgunWheel(a, b)
        Entities:FindByName(nil, "12712_shotgun_wheel"):Attribute_SetIntValue("used", 0)
    end

    function EnableTrainLeverReleaseDialogue(a, b)
        Entities:GetLocalPlayer():Attribute_SetIntValue("enable_released_train_lever_dialogue", 1)
    end

    function DisableTrainLever(a, b)
        Entities:GetLocalPlayer():Attribute_SetIntValue("released_train_lever_once", 1)
    end

    function FailMission(a, b)
        NoVR_FreezeInput()
        SendToConsole("impulse 200")
        NoVR.SetActionSuppressed("+customattack", 1)
        NoVR.SetActionSuppressed("inv_flashlight", 1)
        SendToConsole("disable_flashlight")
        SendToConsole("hidehud 12")
    end

    function TeleportAfterTrainCrash(a, b)
        Entities:GetLocalPlayer():SetThink(function()
            SendToConsole("setpos 124 4066 60")
        end, "TeleportAfterTrainCrash", 1)
    end

    function RemoveEliPreventFall(a, b)
        ent = Entities:FindByName(nil, "elipreventfall")
        ent:Kill()
    end

    function ReachForEli()
        SendToConsole("ent_fire eli_fall_relay Trigger")
    end

    function EnableHotelLobbyPower(a, b)
        ent = Entities:FindByName(nil, "power_stake_1_start")
        ent:Attribute_SetIntValue("used", 0)
    end

    function ExplodeFirstDoorMine()
        local ent = Entities:FindByClassnameNearest("item_hlvr_weapon_tripmine", Vector(606, 1640, 410), 10)
        if ent then
            ent:FireOutput("OnExplode", nil, nil, nil, 0)
        end
    end

    function MakeLeverUsable(a, b)
        ent = Entities:FindByName(nil, "door_reset")
        ent:Attribute_SetIntValue("used", 0)
    end

    function CrouchThroughZooHole(a, b)
        SendToConsole("fadein 0.2")
        SendToConsole("setpos 5393 -1960 -125")

        local ent = Entities:FindByClassnameNearest("prop_physics", Vector(5126, -1957, -53), 10)
        DoEntFireByInstanceHandle(ent, "DisablePickup", "", 0, nil, nil)
        ent:SetEntityName("tiger_mask")
    end

    function PlayLockedDoorHandleAnimation(a, b)
        local ents = Entities:FindAllByClassnameWithin("prop_animinteractable", a:GetCenter(), 20)
        for k, v in pairs(ents) do
            if vlua.find(v:GetModelName(), "doorhandle") then
                DoEntFireByInstanceHandle(v, "PlayAnimation", "doorhandle_locked_anim", 0, nil, nil)
            end
        end
    end

    function StartCrouching(a, b)
        SendToConsole("+duck")
    end

    function StopCrouching(a, b)
        SendToConsole("-duck")
    end

    function ClimbLadder(height, push_direction)
    end

    function ClimbLadderSound()
        local sounds = 0
        local player = Entities:GetLocalPlayer()
        player:SetThink(function()
            if sounds < 3 then
                SendToConsole("snd_sos_start_soundevent Step_Player.Ladder_Single")
                sounds = sounds + 1
                return 0.15
            end
        end, "LadderSound", 0)
    end

    function FixJeffBatteryPuzzle()
        SendToConsole("ent_fire @barnacle_battery kill")
        SendToConsole("ent_create item_hlvr_prop_battery { origin \"959 1970 427\" }")
        SendToConsole("ent_fire @crank_battery kill")
        SendToConsole("ent_create item_hlvr_prop_battery { origin \"1325 2245 435\" }")
        SendToConsole("ent_fire @relay_installcrank Trigger")
    end

    local NOVR_KEYCAP_COLOR = "#ffff66"
    local function novrKeyCap(key)
        return string.format(
            "<font color='%s'><span class='KeyCap'>%s</span></font>%s",
            NOVR_KEYCAP_COLOR, tostring(key), string.rep("&#160;", 4))
    end

    local function novrKeyFor(command)
        local key = NoVR.KeyForCommand(command)
        if not key or key == "" then return "" end
        return novrKeyCap(key)
    end

    local function novrLoc(token, cap)
        local text = NoVR.Localize and NoVR.Localize(token) or ""
        if text == "" then return cap or "" end
        if cap then
            return (string.gsub(text, "%%s", cap, 1))
        end
        return text
    end

    NoVR.hints = {
        gamesaved  = { holdtime = 3,
                       caption = function() return novrLoc("HLVR_Lesson_GameSaved") end },
        sprint     = { holdtime = 10,
                       caption = function() return novrLoc("NOVR_Hint_Sprint", novrKeyFor("+iv_sprint")) end },
        crouch     = { holdtime = 10,
                       caption = function() return novrLoc("NOVR_Hint_Crouch", novrKeyFor("+iv_duck")) end },
        crouchjump = { holdtime = 10,
                       caption = function() return novrLoc("NOVR_Hint_Jump", novrKeyFor("+jump")) .. "<br/>"
                                 .. novrLoc("NOVR_Hint_CrouchMidAir", novrKeyFor("+iv_duck")) end },
        ladder     = { holdtime = 10,
                       caption = function() return novrLoc("NOVR_Hint_ClimbLadder", novrKeyFor("+useextra")) end },
        pickup     = { holdtime = 10,
                       caption = function() return novrLoc("NOVR_Hint_PickUpDrop", novrKeyFor("+useextra")) end },
        interact   = { holdtime = 10,
                       caption = function() return novrLoc("NOVR_Hint_Interact", novrKeyFor("+useextra")) end },

        gg         = { holdtime = 10,
                       caption = function() return novrLoc("NOVR_Hint_GravityGloves", novrKeyFor("+useextra")) end },
        vortenergy = { holdtime = 10,
                       caption = function() return novrLoc("NOVR_Hint_Lightning", novrKeyFor("+customattack")) end },
        noclip     = { holdtime = 10,
                       caption = function() return novrLoc("NOVR_Hint_Noclip", novrKeyFor("toggle_noclip")) end },
        breakboards= { holdtime = 10,
                       caption = function() return novrLoc("NOVR_Hint_BreakBoards", novrKeyFor("+useextra")) end },
        covermouth = { holdtime = 10,
                       caption = function() return novrLoc("NOVR_Hint_CoverMouth", novrKeyFor("+covermouth")) end },
        holdinteract = { holdtime = 10,
                         caption = function() return novrLoc("NOVR_Hint_RotateTanks", novrKeyFor("+useextra")) end },
        multitooluse = { holdtime = 10,
                         caption = function() return novrLoc("NOVR_Hint_MultiToolUse", novrKeyFor("+customattack")) end },
        syringe    = { holdtime = 10,
                       caption = function() return novrLoc("NOVR_Hint_PickUpSyringe", novrKeyFor("+useextra")) .. "<br/>"
                                 .. novrLoc("NOVR_Hint_Inject", novrKeyFor("wristpockets_healthpen")) end },
        quicksave  = { holdtime = 12,
                       caption = function() return novrLoc("NOVR_Hint_Save", novrKeyFor("novr_quicksave")) .. "<br/>"
                                 .. novrLoc("NOVR_Hint_Load", novrKeyFor("load quick")) end },

        multitoolequip = { holdtime = 10,
                           caption = function() return novrLoc("NOVR_Hint_EquipMultiTool") end },

        grenade    = { holdtime = 10,
                       caption = function() return novrLoc("NOVR_Hint_ThrowGrenade", novrKeyFor("throwgrenade")) end },
        wearable   = { holdtime = 10,
                       caption = function() return novrLoc("NOVR_Hint_UnequipWearable", novrKeyFor("novr_unequip_wearable")) end },
        wristpockets = { holdtime = 10,
                         caption = function() return novrLoc("NOVR_Hint_StoreObject", novrKeyFor("+useextra")) .. "<br/>"
                                   .. novrLoc("NOVR_Hint_DropStored", novrKeyFor("wristpockets_dropitem")) end },
        shoot      = { holdtime = 10,
                       caption = function() return novrLoc("NOVR_Hint_ShootLock", novrKeyFor("+customattack")) end },
        flashlight = { holdtime = 10,
                       caption = function() return novrLoc("NOVR_Hint_Flashlight", novrKeyFor("inv_flashlight")) end },
        pistolads  = { holdtime = 10,
                       caption = function() return novrLoc("NOVR_Hint_AimDownSights", novrKeyFor("+customattack2")) end },
        pistolburst= { holdtime = 10,
                       caption = function() return novrLoc("NOVR_Hint_BurstFire", novrKeyFor("+customattack3")) end },
        shotgundouble = { holdtime = 10,
                          caption = function() return novrLoc("NOVR_Hint_DoubleShot", novrKeyFor("+customattack2")) end },
        shotgungrenade = { holdtime = 10,
                           caption = function() return novrLoc("NOVR_Hint_GrenadeLauncher", novrKeyFor("+customattack3")) end },
        smgads     = { holdtime = 10,
                       caption = function() return novrLoc("NOVR_Hint_AimDownSights", novrKeyFor("+customattack2")) end },
        hingecam   = { holdtime = 0,
                       caption = function() return novrLoc("NOVR_Hint_GetOut", novrKeyFor("novr_leavehingecam")) end },
        combinegun = { holdtime = 0,
                       caption = function() return novrLoc("NOVR_Hint_GetOut", novrKeyFor("novr_leavecombinegun")) end },
    }

    local novrHintSerial = 0
    local novrHintLive = {}

    SendToConsole("ent_fire novr_hint_* EndHint")
    SendToConsole("ent_fire novr_hint_* Kill")
    SendToConsole("ent_fire novr_hintgt_* Kill")

    local function novrHintCaption(hint)
        if type(hint.caption) == "function" then
            local ok, text = pcall(hint.caption)
            if ok and text then return text end
            return ""
        end
        return hint.caption
    end

    local function novrReapHint(live)
        if live.hint and IsValidEntity(live.hint) then
            DoEntFireByInstanceHandle(live.hint, "EndHint", "", 0, nil, nil)
            DoEntFireByInstanceHandle(live.hint, "Kill", "", 0.8, nil, nil)
        end
        if live.target and IsValidEntity(live.target) then
            DoEntFireByInstanceHandle(live.target, "Kill", "", 0.8, nil, nil)
        end
    end

    local function novrShowInstructorHint(key, hint, player)
        for openKey, previous in pairs(novrHintLive) do
            novrHintLive[openKey] = nil
            novrReapHint(previous)
        end

        novrHintSerial = novrHintSerial + 1
        local instance = string.format("novr_hint_%s_%d", key, novrHintSerial)
        local targetName = string.format("novr_hintgt_%s_%d", key, novrHintSerial)
        local eye = player:EyePosition()
        local target = SpawnEntityFromTableSynchronous("info_target_instructor_hint", {
            targetname = targetName,
            origin = string.format("%f %f %f", eye.x, eye.y, eye.z),
        })
        if not target then return false end

        local ent = SpawnEntityFromTableSynchronous("env_instructor_vr_hint", {
            targetname = instance,
            hint_caption = novrHintCaption(hint),
            hint_target = targetName,
            hint_timeout = hint.holdtime,
            hint_vr_panel_type = 3,
        })
        if not ent then
            DoEntFireByInstanceHandle(target, "Kill", "", 0, nil, nil)
            return false
        end

        local live = { hint = ent, target = target }
        novrHintLive[key] = live
        DoEntFireByInstanceHandle(ent, "ShowHint", "", 0, player, player)
        NoVR.SetHintAnchor(target:GetEntityIndex())

        if (hint.holdtime or 0) > 0 then
            player:SetThink(function()
                if novrHintLive[key] == live then
                    novrHintLive[key] = nil
                    novrReapHint(live)
                end
                return nil
            end, instance, hint.holdtime + 1)
        end
        return true
    end

    local function novrShowHintNow(key, hint)
        local player = Entities:GetLocalPlayer()
        if player then
            novrShowInstructorHint(key, hint, player)
        end
        SendToConsole("snd_sos_start_soundevent Instructor.StartLesson")
    end

    function NoVR.ShowHint(key)
        local hint = NoVR.hints[key]
        if not hint then
            return
        end

        local player = Entities:GetLocalPlayer()
        if Convars:GetBool("sv_gameinstructor_disable") then
            SendToConsole("sv_gameinstructor_disable 0")
            if player then
                player:SetThink(function()
                    novrShowHintNow(key, hint)
                    return nil
                end, "NoVRHintEnable_" .. key, 0.2)
                return
            end
        end

        novrShowHintNow(key, hint)
    end

    function NoVR.HideHint(key)
        if key then
            local live = novrHintLive[key]
            if live then
                novrHintLive[key] = nil
                novrReapHint(live)
            end
            return
        end
        for openKey, live in pairs(novrHintLive) do
            novrHintLive[openKey] = nil
            novrReapHint(live)
        end
    end

    function ShowInteractTutorial()
        NoVR.ShowHint("interact")
    end

    function ShowLadderTutorial()
        NoVR.ShowHint("ladder")
    end

    function CheckTutorialPistolEmpty()
        local player = Entities:GetLocalPlayer()
        player:Attribute_SetIntValue("pistol_magazine_ammo", player:Attribute_GetIntValue("pistol_magazine_ammo", 0) - 1)
        if player:Attribute_GetIntValue("pistol_magazine_ammo", 0) == 0 then
            SendToConsole("ent_fire_output pistol_chambered_listener OnEventFired")
        end
    end

    function ShowSprintTutorial()
        NoVR.ShowHint("sprint")
    end

    function ShowCrouchTutorial()
        NoVR.ShowHint("crouch")
    end

    function ShowPickUpTutorial()
        NoVR.ShowHint("pickup")
    end

    function ShowGravityGlovesTutorial()
        local player = Entities:GetLocalPlayer()
        if player:Attribute_GetIntValue("gg_tutorial_done", 0) ~= 0 then
            return
        end
        player:SetThink(function()
            if player:Attribute_GetIntValue("gg_tutorial_done", 0) ~= 0 then
                return nil
            end
            NoVR.ShowHint("gg")
            return 10
        end, "GGTutorial", 0)
    end

    function ShowCrouchJumpTutorial()
        SendToConsole("ent_fire 28677_hint_mantle_delay Disable")
        SendToConsole("ent_fire 15493_hint_mantle_delay Disable")
        SendToConsole("ent_fire 13987_hint_mantle_delay Disable")
        SendToConsole("ent_fire 2861_4065_hint_mantle_delay Disable")
        NoVR.ShowHint("crouchjump")
    end

    function ShowMultiToolTutorial()
        SendToConsole("give weapon_physcannon")
        SendToConsole("use weapon_pistol")
        NoVR.ShowHint("multitoolequip")
        Entities:GetLocalPlayer():SetThink(function()
            NoVR.ShowHint("multitooluse")
        end, "MultiToolTutorial", 5)
    end

    function ShowBreakBoardsTutorial()
        local player = Entities:GetLocalPlayer()
        if player:Attribute_GetIntValue("break_boards_tutorial_shown", 0) == 0 then
            NoVR.ShowHint("breakboards")
        end
    end

    function ShowHoldInteractTutorial()
        local player = Entities:GetLocalPlayer()
        if player:Attribute_GetIntValue("hold_interact_tutorial_shown", 0) == 0 then
            player:Attribute_SetIntValue("hold_interact_tutorial_shown", 1)
            NoVR.ShowHint("holdinteract")
        end
    end

    function ShowCoverMouthTutorial()
        if Entities:GetLocalPlayer():Attribute_GetIntValue("covering_mouth", 0) == 0 then
            NoVR.ShowHint("covermouth")
        end
    end

    function ShowQuickSaveTutorial()
        NoVR.ShowHint("quicksave")
    end

    function OpenHideoutGate()
        SendToConsole("ent_fire hideout_gate_prop Kill")
    end

    function DisableBarnacleAmmoPickup()
        local ent = Entities:FindByClassnameNearest("npc_barnacle", Vector(1349, -1748, 239), 10)
        DoEntFireByInstanceHandle(ent, "AddOutput", "OnRelease>base_dropdown_barnacle_2_ammo>EnablePickup>>0>1", 0, nil, nil)
        DoEntFireByInstanceHandle(ent, "AddOutput", "OnRelease>base_dropdown_barnacle_2_ammo>RunScriptCode>thisEntity:Attribute_SetIntValue(\"used\", 0)>0>1", 0, nil, nil)

        ent = Entities:FindByName(nil, "base_dropdown_barnacle_2_ammo")
        ent:Attribute_SetIntValue("used", 1)
        SendToConsole("ent_fire base_dropdown_barnacle_2_ammo DisablePickup")
    end

    function EnableStreetElevatorDoor()
        local ent = Entities:FindByName(nil, "elev_anim_door")
        ent:SetThink(function()
            ent:Attribute_SetIntValue("used", 0)
        end, "EnableStreetElevatorDoor", 10)
    end

    function LarrySeesGun()
        SendToConsole("ent_fire_output @player_proxy OnWeaponActive")
    end

    function LarrySeesWearable()

        local ent = Entities:FindByName(nil, "hat_construction_viewmodel")
        if ent then
            SendToConsole("ent_fire_output @player_proxy OutPlayerIsWearingHat " .. ent:GetModelName())
        end
        ent = Entities:FindByName(nil, "respirator_viewmodel")
        if ent then
            SendToConsole("ent_fire_output @player_proxy OutPlayerIsWearingHat " .. ent:GetModelName())
        end

        ent = Entities:FindByName(nil, "respirator_viewmodel")
        if ent then
            SendToConsole("ent_fire_output @player_proxy OutPlayerIsWearingHat " .. ent:GetModelName())
        end
    end

    function EnablePlugLever1()
        Entities:GetLocalPlayer():Attribute_SetIntValue("plug_lever", 1)
    end

    function EnablePlugLever2()
        Entities:GetLocalPlayer():Attribute_SetIntValue("plug_lever", 2)
    end

    function EnablePlugLever3()
        Entities:GetLocalPlayer():Attribute_SetIntValue("plug_lever", 3)
    end

    function EnablePlugLever4()
        Entities:GetLocalPlayer():Attribute_SetIntValue("plug_lever", 4)
    end

    function StartRevealEavesdrop()
        SendToConsole("impulse 200")
        NoVR.SetActionSuppressed("+customattack", 1)
        NoVR.SetActionSuppressed("+customattack2", 1)
        NoVR.SetActionSuppressed("+customattack3", 1)
        NoVR.SetActionSuppressed("inv_flashlight", 1)
        SendToConsole("hidehud 12")
        SendToConsole("disable_flashlight")
        local player = Entities:GetLocalPlayer()
        player:Attribute_SetIntValue("eavesdropping", 1)

        local pos = player:GetAbsOrigin()
        local ent = SpawnEntityFromTableSynchronous("trigger_detect_bullet_fire", {["targetname"]="bullet_trigger", ["modelscale"]=100, ["model"]="models/hacking/holo_hacking_sphere_prop.vmdl", ["origin"]="" .. pos.x .. " " .. pos.y .. " " .. pos.z})
        DoEntFireByInstanceHandle(ent, "AddOutput", "OnDetectedBulletFire>relay_start_combat_early>Trigger>>0>1", 0, nil, nil)
    end

    function StopRevealEavesdrop()
        NoVR.SetActionSuppressed("+customattack", 0)
        NoVR.SetActionSuppressed("+customattack2", 0)
        NoVR.SetActionSuppressed("+customattack3", 0)
        NoVR.SetActionSuppressed("inv_flashlight", 0)
        SendToConsole("impulse 200")
        SendToConsole("hidehud 72")
        Entities:GetLocalPlayer():Attribute_SetIntValue("eavesdropping", 0)
    end

    function EnableToiletElevatorLever()
        local ent = Entities:FindByName(nil, "plug_console_starter_lever")
        ent:Attribute_SetIntValue("used", 0)
        DoEntFireByInstanceHandle(ent, "SetCompletionValue", "0", 0, nil, nil)
    end

    function DisableBarnacleHealthVialPickup()
        ent = Entities:FindByClassnameNearest("npc_barnacle", Vector(4733, 5708, 383), 10)
        DoEntFireByInstanceHandle(ent, "AddOutput", "OnRelease>waste_vial_item_1>EnablePickup>>0>1", 0, nil, nil)

        SendToConsole("ent_fire waste_vial_item_1 DisablePickup")
    end

    function EquipCombineGunMechanical(player)
        SendToConsole("setpos 1510.57 386.48 924;setang -11.64 177.98 0")
        SendToConsole("ent_fire player_speedmod ModifySpeed 0")
        NoVR.SetMovementFreeze(1)
        NovrBorrowFire("novr_shootcombinegun")
        SendToConsole("r_drawviewmodel 0")

        local ent = Entities:FindByName(nil, "combine_gun_interact")
        ent:Attribute_SetIntValue("active", 1)
        ent:FireOutput("OnCompletionB_Forward", nil, nil, nil, 0)
        ent:FireOutput("OnInteractStart", nil, nil, nil, 0)
        ent:SetThink(function()
            ent:SetAngles(player:EyeAngles().x * -1,player:EyeAngles().y - 180,0)
            return 0.05
        end, "UsingCombineGun", 0)
    end

    function CombineGunHandleAnim(a, b)
        local ent = Entities:FindByName(nil, "combine_gun_interact")
        ent:FireOutput("OnCompletionD_Forward", nil, nil, nil, 0)
        local handleState = 0
        ent:SetThink(function()
            if handleState < 1 then
                handleState = handleState + 0.05
                DoEntFireByInstanceHandle(ent, "SetCompletionValue", "" .. handleState, 0, nil, nil)
                return 0.05
            else
                ent:FireOutput("OnCompletionC_Forward", nil, nil, nil, 0)
                ent:Attribute_SetIntValue("ready", 1)
                return nil
            end
        end, "UsingCombineGunHandle", 0)
    end

    function EnterVaultBeam()
        SendToConsole("ent_remove weapon_pistol;ent_remove weapon_shotgun;ent_remove weapon_ar2;ent_remove weapon_smg1;ent_remove weapon_frag;ent_remove weapon_physcannon")
        SendToConsole("r_drawviewmodel 0")
        SendToConsole("ent_fire player_speedmod ModifySpeed 0")
        NoVR.SetMovementFreeze(1)
        NoVR.SetPlatformCarry(1)
        SendToConsole("hidehud 12")
        SendToConsole("phys_pushscale 1")
        SendToConsole("ent_remove hat_construction_viewmodel")
        SendToConsole("ent_remove respirator_viewmodel")
        WristPockets_DisableKeepAcrossMaps()
    end

    function ShowVortEnergyTutorial()
        NoVR.ShowHint("vortenergy")
    end

    function GiveVortEnergy(a, b)
        NovrBorrowFire("shootvortenergy")
        local player = Entities:GetLocalPlayer()
        player:Attribute_SetIntValue("vort_energy", 1)
    end

    function RemoveVortEnergy(a, b)
        NovrReturnFire()
        Entities:GetLocalPlayer():Attribute_SetIntValue("vort_energy", 0)
    end

    function GrabCandlers(a, b)
        local player = Entities:GetLocalPlayer()
        player:SetThink(function()
            SendToConsole("ent_fire innervault_energize_event_relay Kill")
            SendToConsole("ent_fire_output g_release_hand1 OnHandPosed")
            SendToConsole("ent_fire_output g_release_hand2 OnHandPosed")
            SendToConsole("ent_fire player_speedmod ModifySpeed 0")

            SendToConsole("hidehud 12")
            if Convars:GetStr("cc_subtitles") == "0" then
                SendToConsole("r_drawvgui 0")
            end
            SendToConsole("wristpockets_stopupdateloop")
        end, "GrabCandlers", 5)
    end

    function GiveAdvisorVortEnergy(a, b)
        NovrBorrowFire("shootadvisorvortenergy")
    end

    function StartCredits(a, b)
        NoVR_FreezeInput()
        Entities:GetLocalPlayer():SetThink(function()
            SendToConsole("ent_fire assignment_panel_1 IgnoreUserInput")
            SendToConsole("ent_fire assignment_panel_2 IgnoreUserInput")
            SendToConsole("ent_fire assignment_panel_3 IgnoreUserInput")
        end, "HideUICursorAssignment", 1.1)
        Entities:GetLocalPlayer():SetThink(function()
            SendToConsole("ent_fire credits_panel_left IgnoreUserInput")
            SendToConsole("ent_fire credits_panel_middle IgnoreUserInput")
            SendToConsole("ent_fire credits_panel_right IgnoreUserInput")
        end, "HideUICursorCredits", 14.1)
    end

    function EndCredits(a, b)
        NoVR_UnfreezeInput()
        SendToConsole("mouse_disableinput 0")
        SendToConsole("use weapon_bugbait")
        SendToConsole("hidehud 104")
    end

    function GiveCrowbar(a, b)
        Entities:GetLocalPlayer():SetThink(function()
            SendToConsole("give weapon_crowbar")
            SendToConsole("use weapon_crowbar")
            SendToConsole("r_drawviewmodel 1")
            SendToConsole("ent_fire_output prop_crowbar OnPlayerPickup")
            SendToConsole("ent_fire prop_crowbar Kill")
        end, "GiveCrowbar", 4.0)
        Entities:GetLocalPlayer():SetThink(function()
            SendToConsole("r_drawviewmodel 0")
            SendToConsole("hidehud 12")
        end, "HideCrowbar", 9.0)
    end

    function is_on_map_or_later(compare_map)
        local current_map = GetMapName()

        local maps = {

            {
                "a1_intro_world",
                "a1_intro_world_2",
                "a2_quarantine_entrance",
                "a2_pistol",
                "a2_hideout",
                "a2_headcrabs_tunnel",
                "a2_drainage",
                "a2_train_yard",
                "a3_station_street",
                "a3_hotel_lobby_basement",
                "a3_hotel_underground_pit",
                "a3_hotel_interior_rooftop",
                "a3_hotel_street",
                "a3_c17_processing_plant",
                "a3_distillery",
                "a4_c17_zoo",
                "a4_c17_tanker_yard",
                "a4_c17_water_tower",
                "a4_c17_parking_garage",
                "a5_vault",
                "a5_ending",
            },
        }

        for i = 1, #maps do
            local current_map_index = vlua.find(maps[i], current_map)
            local compare_map_index = vlua.find(maps[i], compare_map)

            if current_map_index and current_map_index < compare_map_index then
                return false
            end
        end

        return true
    end

    function NoVR_PublishGravityGloves()
        local player = Entities:GetLocalPlayer()
        if player == nil then return end
        local has = player:Attribute_GetIntValue("gravity_gloves", 0) ~= 0
        NoVR.SetGravityGloves(has and 1 or 0)
    end

    local ggFx = { hlIdx = nil, wispIdx = nil, loopEnt = nil }

    local function GGDestroyFx(which)
        local idx = ggFx[which .. "Idx"]
        if idx then
            ParticleManager:DestroyParticle(idx, true)
            ggFx[which .. "Idx"] = nil
        end
    end

    local function GGSpawnFx(which, particle, entindex)
        GGDestroyFx(which)
        local ent = entindex and EntIndexToHScript(entindex) or nil
        if not (ent and IsValidEntity(ent)) then
            return nil
        end
        local ok, err = pcall(function()
            local idx = ParticleManager:CreateParticle(
                particle, PATTACH_ABSORIGIN_FOLLOW, ent)
            ParticleManager:SetParticleControlEnt(
                idx, 0, ent, PATTACH_ABSORIGIN_FOLLOW, "", ent:GetAbsOrigin(), true)
            ParticleManager:SetParticleControlEnt(
                idx, 1, ent, PATTACH_ABSORIGIN_FOLLOW, "", ent:GetAbsOrigin(), true)
            local scale = 1.0
            local okScale, s = pcall(function() return ent:GetAbsScale() end)
            if okScale and type(s) == "number" and s > 0 then scale = s end
            ParticleManager:SetParticleControl(idx, 2, Vector(scale, 0, 0))
            ggFx[which .. "Idx"] = idx
        end)
        if not ok then
            return nil
        end
        return ent
    end

    local function GGStopLoop()
        if ggFx.loopEnt and IsValidEntity(ggFx.loopEnt) then
            StopSoundEvent("Inventory.ResinGloveHover", ggFx.loopEnt)
        end
        ggFx.loopEnt = nil
    end

    if gg_highlight_start_ev ~= nil then StopListeningToGameEvent(gg_highlight_start_ev) end
    if gg_highlight_stop_ev ~= nil then StopListeningToGameEvent(gg_highlight_stop_ev) end
    if gg_locked_on_start_ev ~= nil then StopListeningToGameEvent(gg_locked_on_start_ev) end
    if gg_locked_on_stop_ev ~= nil then StopListeningToGameEvent(gg_locked_on_stop_ev) end
    if gg_pull_ev ~= nil then StopListeningToGameEvent(gg_pull_ev) end

    gg_highlight_start_ev = ListenToGameEvent("grabbity_glove_highlight_start", function(data)
        GGStopLoop()
        GGSpawnFx("wisp", "particles/weapon_fx/grabbity_gloves_scan.vpcf", data.entindex)
        local ent = GGSpawnFx("hl", "particles/weapon_fx/grabbity_gloves.vpcf", data.entindex)
        if ent then
            StartSoundEvent("Inventory.ResinGloveHover", ent)
            ggFx.loopEnt = ent
        end
    end, nil)

    gg_highlight_stop_ev = ListenToGameEvent("grabbity_glove_highlight_stop", function(data)
        GGDestroyFx("hl")
        GGDestroyFx("wisp")
        GGStopLoop()
    end, nil)

    gg_locked_on_start_ev = ListenToGameEvent("grabbity_glove_locked_on_start", function(data)
        local ent = EntIndexToHScript(data.entindex)
        if ent and IsValidEntity(ent) then
            StartSoundEventFromPosition("Grabbity.HoverPing", ent:GetAbsOrigin())
        end
    end, nil)
    gg_locked_on_stop_ev = ListenToGameEvent("grabbity_glove_locked_on_stop", function(data)
        local ent = EntIndexToHScript(data.entindex)
        if ent and IsValidEntity(ent) then
            StartSoundEventFromPosition("Grabbity.HoverPingEnd", ent:GetAbsOrigin())
        end
    end, nil)

    gg_pull_ev = ListenToGameEvent("grabbity_glove_pull", function(data)
        local player = Entities:GetLocalPlayer()
        if player then
            StartSoundEventFromPosition("Grabbity.Grab", player:EyePosition())
            if player:Attribute_GetIntValue("gg_tutorial_done", 0) == 0 then
                player:Attribute_SetIntValue("gg_tutorial_done", 1)
                player:SetThink(function() return nil end, "GGTutorial", 0)
                if NoVR.HideHint then NoVR.HideHint("gg") end
            end
        end
        if data.item == "item_hlvr_clip_energygun" then
            local hammer = Entities:FindByName(nil, "ragdoll_dangler_hammer")
            if hammer ~= nil then
                DoEntFireByInstanceHandle(hammer, "Wake", "", 0, nil, nil)
            end
        end
    end, nil)

    if gg_catch_ev ~= nil then StopListeningToGameEvent(gg_catch_ev) end

    gg_catch_ev = ListenToGameEvent("grabbity_glove_catch", function(data)
        local player = Entities:GetLocalPlayer()
        if not player then return end
        local ent = data.entindex and EntIndexToHScript(data.entindex) or nil
        if not (ent and IsValidEntity(ent)) then return end

        if player:Attribute_GetIntValue("picked_up", 0) == 1
            or ent:Attribute_GetIntValue("picked_up", 0) == 1 then
            return
        end

        local okPocket, pocketed = pcall(WristPockets_PickUpValuableItem, player, ent)
        if okPocket and pocketed then
            return
        end

        local class = ent:GetClassname()
        if class == "item_hlvr_grenade_xen" or class == "item_hlvr_grenade_frag" then
            local pocket = WristPockets_PlayerHasFreePocketSlot(player)
                and (class == "item_hlvr_grenade_xen"
                    or ent:GetSequence() == "vr_grenade_unarmed_idle")
            if pocket then
                if class == "item_hlvr_grenade_xen" then
                    WristPockets_PickUpXenGrenade(player, ent)
                else
                    WristPockets_PickUpGrenade(player, ent)
                    SendToConsole("viewmodel_update")
                end
                FireGameEvent("item_pickup", {
                    userid = player:GetUserID(),
                    item = class,
                    item_name = ent:GetName(),
                })
                StartSoundEventFromPosition("Inventory.DepositItem", player:EyePosition())
                local viewmodel = Entities:FindByClassname(nil, "viewmodel")
                if viewmodel then viewmodel:RemoveEffects(32) end
                ent:Kill()
            end
            return
        end

        DoEntFireByInstanceHandle(ent, "Use", "", 0, player, player)
    end, nil)
end
