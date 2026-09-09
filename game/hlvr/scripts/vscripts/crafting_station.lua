DoIncludeScript("novr_config.lua", nil)
if not NOVR_LUA then return end

local player = Entities:GetLocalPlayer()
if thisEntity:GetClassname() == "prop_hlvr_crafting_station_console" then
    local function AnimTagListener(sTagName, nStatus)
        if sTagName == 'Bootup Done' and nStatus == 2 then
            thisEntity:Attribute_SetIntValue("crafting_station_ready", 1)
        elseif sTagName == 'Crafting Done' and nStatus == 2 then
            local cmd = Convars:GetStr("novr_chosen_weapon_upgrade")
            local wep = Convars:GetStr("novr_weapon_in_crafting_station")
            if cmd ~= "" and cmd ~= "cancel" then
                SendToConsole(cmd)
                if wep == "pistol" then
                    SendToConsole("give weapon_pistol")
                elseif wep == "shotgun" then
                    SendToConsole("give weapon_shotgun")
                elseif wep == "smg" then
                    SendToConsole("give weapon_ar2")
                end
                SendToConsole("viewmodel_update")
                if cmd == "hlvr_energygun_grant_upgrade 0" then
                    SendToConsole("pistol_use_new_accuracy 1")
                end

                local hints = {
                    ["hlvr_energygun_grant_upgrade 1"] = "pistolads",
                    ["hlvr_energygun_grant_upgrade 3"] = "pistolburst",
                    ["hlvr_shotgun_grant_upgrade 1"] = "shotgungrenade",
                    ["hlvr_shotgun_grant_upgrade 3"] = "shotgundouble",
                    ["hlvr_rapidfire_grant_upgrade 4"] = "smgads",
                }
                local hint = hints[cmd]
                if hint then NoVR.ShowHint(hint) end


                if cmd == "hlvr_energygun_grant_upgrade 0"
                    or cmd == "hlvr_shotgun_grant_upgrade 2"
                    or cmd == "hlvr_rapidfire_grant_upgrade 5"
                    or cmd == "hlvr_rapidfire_grant_upgrade 6" then
                    local ent = SpawnEntityFromTableSynchronous("game_text", {["effect"]=2, ["spawnflags"]=1, ["color"]="230 230 230", ["color2"]="0 0 0", ["fadein"]=0, ["fadeout"]=0.15, ["fxtime"]=0.25, ["holdtime"]=10, ["x"]=-1, ["y"]=0.6})
                    DoEntFireByInstanceHandle(ent, "SetText", "This weapon upgrade does not have a model yet", 0, nil, nil)
                    DoEntFireByInstanceHandle(ent, "Display", "", 0, nil, nil)
                end
            end

            SendToConsole("ent_fire point_clientui_world_panel Enable")
            SendToConsole("ent_fire weapon_in_fabricator Kill")
            thisEntity:SetGraphParameterBool("bCrafting", false)
            Convars:SetStr("novr_chosen_weapon_upgrade", "")
            Convars:SetStr("novr_weapon_in_crafting_station", "")
        elseif sTagName == 'Trays Retracted' and nStatus == 2 then
            thisEntity:Attribute_SetIntValue("cancel_cooldown_done", 1)
        end
    end

    thisEntity:RegisterAnimTagListener(AnimTagListener)
end
