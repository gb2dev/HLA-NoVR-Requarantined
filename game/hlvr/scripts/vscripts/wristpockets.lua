NoVR = NoVR or {}
require "storage"
DoIncludeScript("novr_config.lua", nil)
if not NOVR_LUA then return end

local itemsClasses = { "item_healthvial", "item_hlvr_grenade_frag", "item_hlvr_prop_battery", "prop_physics", "item_hlvr_health_station_vial", "prop_reviver_heart", "item_hlvr_grenade_xen" }

local PANO_ICON_NONE          = 0
local PANO_ICON_HEALTHPEN     = 1
local PANO_ICON_HEALTHVIAL    = 2
local PANO_ICON_BATTERY       = 3
local PANO_ICON_REVIVERHEART  = 4
local PANO_ICON_BOTTLE        = 5
local PANO_ICON_KEYCARD       = 6
local PANO_ICON_GRENADE       = 7
local PANO_ICON_XENGRENADE    = 8
local PANO_ICON_GENERIC       = 9

local slotItemPanoIcon = {
    [1] = PANO_ICON_HEALTHPEN,
    [2] = PANO_ICON_GRENADE,
    [3] = PANO_ICON_BATTERY,
    [5] = PANO_ICON_HEALTHVIAL,
    [6] = PANO_ICON_REVIVERHEART,
    [7] = PANO_ICON_XENGRENADE,
}

function WristPockets_StartupPreparations()
    SendToConsole("ent_remove text_pocketslots")
    SendToConsole("ent_remove text_pocketslots_empty")
end

local function GetSlotPanoIcon(slotItemId, slotId)
    if slotItemId == 0 then
        return PANO_ICON_NONE
    end
    if slotItemId == 4 then
        local objModel = Storage:LoadString("pocketslots_slot" .. slotId .. "_objmodel")
        if objModel == "models/props/distillery/bottle_vodka.vmdl" then
            return PANO_ICON_BOTTLE
        elseif objModel == "models/props/misc/keycard_001.vmdl" then
            return PANO_ICON_KEYCARD
        end
        return PANO_ICON_GENERIC
    end
    return slotItemPanoIcon[slotItemId] or PANO_ICON_GENERIC
end

function WristPockets_UpdateHUD()
    local player = Entities:GetLocalPlayer()
    if not player then return end
    NoVR.SetWristPockets(
        GetSlotPanoIcon(player:Attribute_GetIntValue("pocketslots_slot1", 0), 1),
        GetSlotPanoIcon(player:Attribute_GetIntValue("pocketslots_slot2", 0), 2))
end

function WristPockets_StartUpdateLoop()

    local player = Entities:GetLocalPlayer()
    player:SetThink(function()
        WristPockets_UpdateHUD()
        return 0.1
    end, "WristPockets_UpdateLoop", 0)
end

function WristPockets_StopUpdateLoop()

    local player = Entities:GetLocalPlayer()
    player:StopThink("WristPockets_UpdateLoop")
    NoVR.SetWristPockets(0, 0)
end

Convars:RegisterCommand("wristpockets_startupdateloop" , function()
    WristPockets_StartUpdateLoop()
end, "", 0)

Convars:RegisterCommand("wristpockets_stopupdateloop" , function()
    WristPockets_StopUpdateLoop()
end, "", 0)

local function GetFreePocketSlot(playerEnt)
    if playerEnt:Attribute_GetIntValue("pocketslots_slot1", 0) == 0 then
        return 1
    elseif playerEnt:Attribute_GetIntValue("pocketslots_slot2", 0) == 0 then
        return 2
    end
    return 0
end

function WristPockets_PlayerHasFreePocketSlot(playerEnt)
    if GetFreePocketSlot(playerEnt) ~= 0 then
        return true
    else
        return false
    end
end

local function ErasePocketSlot(playerEnt, itemSlot)
    if not Storage:LoadBoolean("pocketslots_slot" .. itemSlot .. "_keepacrossmaps") then
        playerEnt:Attribute_SetIntValue("pocketslots_slot" .. itemSlot .. "", 0)
        Storage:SaveString("pocketslots_slot" .. itemSlot .. "_objname", "")
        Storage:SaveString("pocketslots_slot" .. itemSlot .. "_objmodel", "")
        Storage:SaveBoolean("pocketslots_slot" .. itemSlot .. "_keepacrossmaps", false)
        Storage:SaveBoolean("pocketslots_slot" .. itemSlot .. "_keepiteminstance", false)
        Storage:SaveString("pocketslots_slot" .. itemSlot .. "_materialgrouphash", "")
    end
end

function WristPockets_DisableKeepAcrossMaps()
    Storage:SaveBoolean("pocketslots_slot1_keepacrossmaps", false)
    Storage:SaveBoolean("pocketslots_slot2_keepacrossmaps", false)
end

local function PrecacheModels()
    local ent_table = {
        targetname = "novr_precachemodels",
        vscripts = "wristpockets_precache.lua"
    }
    SpawnEntityFromTableAsynchronous("logic_script", ent_table, nil, nil);
end

function WristPockets_CheckPocketItemsOnLoading(playerEnt, saveLoading)
    if playerEnt:Attribute_GetIntValue("pocketslots_slot1", 0) ~= 0 or playerEnt:Attribute_GetIntValue("pocketslots_slot2", 0) ~= 0 then
        if not saveLoading then
            ErasePocketSlot(playerEnt, 1)
            ErasePocketSlot(playerEnt, 2)
        end
    end
    PrecacheModels()
end

local function GetPocketSlotToUse(slot1ItemId, slot2ItemId, targetItemId)
    if slot2ItemId == targetItemId then
        return 2
    elseif slot1ItemId == targetItemId then
        return 1
    end
    return 0
end

local function GetNonEmptyPocketSlotToUse(slot1ItemId, slot2ItemId)
    if slot2ItemId ~= 0 then
        return 2
    elseif slot1ItemId ~= 0 then
        return 1
    end
    return 0
end

local function GetValuableFirstPocketSlotToUse(slot1ItemId, slot2ItemId)
    if slot2ItemId == 3 or slot2ItemId == 4 or slot2ItemId == 5 or slot2ItemId == 6 then
        return 2
    elseif slot1ItemId == 3 or slot1ItemId == 4 or slot1ItemId == 5 or slot1ItemId == 6 then
        return 1
    elseif slot2ItemId ~= 0 then
        return 2
    elseif slot1ItemId ~= 0 then
        return 1
    end
    return 0
end

function WristPockets_PickUpHealthPen(playerEnt, itemEnt)
    local pocketSlotId = GetFreePocketSlot(playerEnt)
    if pocketSlotId ~= 0 then
        StartSoundEventFromPosition("Inventory.WristPocketGrabItem", playerEnt:EyePosition())
        itemEnt:Kill()
        playerEnt:Attribute_SetIntValue("pocketslots_slot" .. pocketSlotId .. "", 1)
        Storage:SaveBoolean("pocketslots_slot" .. pocketSlotId .. "_keepacrossmaps", true)
    end
end

function WristPockets_PickUpGrenade(playerEnt, itemEnt)
    local pocketSlotId = GetFreePocketSlot(playerEnt)
    if pocketSlotId ~= 0 then


        playerEnt:Attribute_SetIntValue("pocketslots_slot" .. pocketSlotId .. "", 2)
        Storage:SaveBoolean("pocketslots_slot" .. pocketSlotId .. "_keepacrossmaps", true)
    end
end

function WristPockets_PickUpXenGrenade(playerEnt, itemEnt)
    local pocketSlotId = GetFreePocketSlot(playerEnt)
    if pocketSlotId ~= 0 then
        playerEnt:Attribute_SetIntValue("pocketslots_slot" .. pocketSlotId .. "", 7)
        Storage:SaveBoolean("pocketslots_slot" .. pocketSlotId .. "_keepacrossmaps", true)
    end
end

function WristPockets_PickUpValuableItem(playerEnt, itemEnt)
    local itemClass = itemEnt:GetClassname()
    local itemModel = itemEnt:GetModelName()
    if itemClass == "item_hlvr_prop_battery" or itemModel == "models/props/misc/keycard_001.vmdl" or itemModel == "models/props/distillery/bottle_vodka.vmdl" or itemClass == "item_hlvr_health_station_vial" or itemClass == "prop_reviver_heart" then
        local itemId = 0
        if itemClass == "item_hlvr_prop_battery" then
            itemId = 3
        elseif itemClass == "prop_physics" then
            itemId = 4
        elseif itemClass == "item_hlvr_health_station_vial" then
            itemId = 5
        elseif itemClass == "prop_reviver_heart" then
            itemId = 6
        end
        local pocketSlotId = GetFreePocketSlot(playerEnt)

        if pocketSlotId ~= 0 and itemId ~= 0 then
            local keepItemInstance = true
            local keepAcrossMaps = false
            if itemEnt:GetName() == "" then
                keepItemInstance = false
            end

            if itemEnt:GetName() == "control_door_2_key_prop" or itemEnt:GetName() == "control_door_1_key_prop" then
                keepItemInstance = false
            end
            if itemModel == "models/props/distillery/bottle_vodka.vmdl" then
                keepItemInstance = false
                keepAcrossMaps = true
            end

            if itemId == 5 or itemId == 3 or itemId == 6 then
                keepItemInstance = false
                keepAcrossMaps = false
            end


            if playerEnt:Attribute_GetIntValue("wristpockets_tutorial_shown", 0) < 3 and itemId ~= 1 then
                playerEnt:Attribute_SetIntValue("wristpockets_tutorial_shown", playerEnt:Attribute_GetIntValue("wristpockets_tutorial_shown", 0) + 1)
                NoVR.ShowHint("wristpockets")
            end

            playerEnt:Attribute_SetIntValue("pocketslots_slot" .. pocketSlotId .. "", itemId)
            Storage:SaveString("pocketslots_slot" .. pocketSlotId .. "_objname", itemEnt:GetName())
            Storage:SaveString("pocketslots_slot" .. pocketSlotId .. "_objmodel", itemModel)


            if itemEnt:GetName() == "control_door_2_key_prop" or itemEnt:GetName() == "control_door_1_key_prop" then
                local MaterialGroupHash = itemEnt:GetMaterialGroupHash()

                Storage:SaveString("pocketslots_slot" .. pocketSlotId .. "_materialgrouphash", tostring(MaterialGroupHash))
            else
                Storage:SaveNumber("pocketslots_slot" .. pocketSlotId .. "_materialgrouphash", 0)
            end

            if keepItemInstance then
                itemEnt:DisableMotion()
                itemEnt:SetOrigin(Vector(-15000,-15000,-15000))
            else
                itemEnt:Kill()
            end
            Storage:SaveBoolean("pocketslots_slot" .. pocketSlotId .. "_keepiteminstance", keepItemInstance)
            Storage:SaveBoolean("pocketslots_slot" .. pocketSlotId .. "_keepacrossmaps", keepAcrossMaps)

            StartSoundEventFromPosition("Inventory.WristPocketGrabItem", playerEnt:EyePosition())

            return true
        end
    end
    return false
end

Convars:RegisterCommand("wristpockets_healthpen", function()
    local player = Entities:GetLocalPlayer()
    local slot1ItemId = player:Attribute_GetIntValue("pocketslots_slot1", 0)
    local slot2ItemId = player:Attribute_GetIntValue("pocketslots_slot2", 0)
    if slot1ItemId == 0 and slot2ItemId == 0 then
    else
        local pocketSlotId = GetPocketSlotToUse(slot1ItemId, slot2ItemId, 1)
        if pocketSlotId ~= 0 then
            if player:GetHealth() ~= player:GetMaxHealth() then
                player:SetHealth(min(player:GetHealth() + cvar_getf("hlvr_health_vial_amount"), player:GetMaxHealth()))
                StartSoundEventFromPosition("HealthPen.Stab", player:EyePosition())
                StartSoundEventFromPosition("HealthPen.Success01", player:EyePosition())
                StartSoundEventFromPosition("HealthPen.Success02", player:EyePosition())
                player:Attribute_SetIntValue("pocketslots_slot" .. pocketSlotId .. "" , 0)
            else
                StartSoundEventFromPosition("HealthStation.Deny", player:EyePosition())
            end
        end
    end
end, "", 0)

function WristPockets_PlayerHasGrenade()
    local player = Entities:GetLocalPlayer()
    local slot1ItemId = player:Attribute_GetIntValue("pocketslots_slot1", 0)
    local slot2ItemId = player:Attribute_GetIntValue("pocketslots_slot2", 0)
    if slot1ItemId == 0 and slot2ItemId == 0 then
        return false
    else
        local pocketSlotId = GetPocketSlotToUse(slot1ItemId, slot2ItemId, 2)
        if pocketSlotId ~= 0 then
            return true
        else
            return false
        end
    end
end

function WristPockets_UseGrenade()
    local player = Entities:GetLocalPlayer()
    local slot1ItemId = player:Attribute_GetIntValue("pocketslots_slot1", 0)
    local slot2ItemId = player:Attribute_GetIntValue("pocketslots_slot2", 0)
    if slot1ItemId == 0 and slot2ItemId == 0 then
        return false
    else
        local pocketSlotId = GetPocketSlotToUse(slot1ItemId, slot2ItemId, 2)
        if pocketSlotId ~= 0 then
            player:Attribute_SetIntValue("pocketslots_slot" .. pocketSlotId .. "" , 0)



            return true
        else
            return false
        end
    end
end

function WristPockets_PlayerHasXenGrenade()
    local player = Entities:GetLocalPlayer()
    local slot1ItemId = player:Attribute_GetIntValue("pocketslots_slot1", 0)
    local slot2ItemId = player:Attribute_GetIntValue("pocketslots_slot2", 0)
    if slot1ItemId == 0 and slot2ItemId == 0 then
        return false
    else
        local pocketSlotId = GetPocketSlotToUse(slot1ItemId, slot2ItemId, 7)
        if pocketSlotId ~= 0 then
            return true
        else
            return false
        end
    end
end

function WristPockets_UseXenGrenade()
    local player = Entities:GetLocalPlayer()
    local slot1ItemId = player:Attribute_GetIntValue("pocketslots_slot1", 0)
    local slot2ItemId = player:Attribute_GetIntValue("pocketslots_slot2", 0)
    if slot1ItemId == 0 and slot2ItemId == 0 then
        return false
    else
        local pocketSlotId = GetPocketSlotToUse(slot1ItemId, slot2ItemId, 7)
        if pocketSlotId ~= 0 then
            player:Attribute_SetIntValue("pocketslots_slot" .. pocketSlotId .. "" , 0)

            return true
        else
            return false
        end
    end
end

Convars:RegisterCommand("wristpockets_dropitem", function()
    local player = Entities:GetLocalPlayer()
    local slot1ItemId = player:Attribute_GetIntValue("pocketslots_slot1", 0)
    local slot2ItemId = player:Attribute_GetIntValue("pocketslots_slot2", 0)
    if slot1ItemId == 0 and slot2ItemId == 0 then
    else
        local pocketSlotId = GetValuableFirstPocketSlotToUse(slot1ItemId, slot2ItemId)
        if pocketSlotId ~= 0 then
            local itemTypeId = player:Attribute_GetIntValue("pocketslots_slot" .. pocketSlotId .. "", 0)
            local player_ang = player:EyeAngles()
            local startVector = player:EyePosition()
            local traceTable =
            {
                startpos = startVector;
                endpos = startVector + RotatePosition(Vector(0,0,0), player_ang, Vector(40, 0, 0));
                ignore = player;
                mask = 33636363
            }
            TraceLine(traceTable)

            if traceTable.hit then
                local model = traceTable.enthit:GetModelName()
                if model == "models/props_combine/combine_battery/combine_battery_post.vmdl" or model == "models/props_combine/health_charger/combine_health_charger_guage.vmdl" then
                    traceTable.pos = traceTable.pos - (traceTable.pos - player:EyePosition()):Normalized() * 5
                else
                    SendToConsole("snd_sos_start_soundevent PlayerTeleport.Fail")
                    return
                end
            end

            if itemTypeId == 3 or itemTypeId == 4 or itemTypeId == 5 or itemTypeId == 6 then
                local entName = Storage:LoadString("pocketslots_slot" .. pocketSlotId .. "_objname")
                local keepItemInstance = Storage:LoadBoolean("pocketslots_slot" .. pocketSlotId .. "_keepiteminstance")

                if entName ~= "" and keepItemInstance then
                    ent = Entities:FindByName(nil, entName)
                    ent:EnableMotion()
                    ent:SetOrigin(traceTable.pos)
                    ent:SetAngles(0,player_ang.y,0)
                    ent:ApplyAbsVelocityImpulse(-GetPhysVelocity(ent))
                else
                    ent = SpawnEntityFromTableSynchronous(itemsClasses[itemTypeId], { ["origin"]= traceTable.pos.x .. " " .. traceTable.pos.y .. " " .. traceTable.pos.z, ["angles"]= player_ang, ["targetname"]= Storage:LoadString("pocketslots_slot" .. pocketSlotId .. "_objname"), ["model"]= Storage:LoadString("pocketslots_slot" .. pocketSlotId .. "_objmodel") })

                    if entName == "control_door_2_key_prop" or entName == "control_door_1_key_prop" then
                        local MaterialGroupHash = Storage:LoadString("pocketslots_slot" .. pocketSlotId .. "_materialgrouphash")
                        ent:SetMaterialGroupHash(tonumber(MaterialGroupHash))
                    end
                end

                StartSoundEventFromPosition("Inventory.DepositItem", player:EyePosition())

                Storage:SaveString("pocketslots_slot" .. pocketSlotId .. "_objname", "")
                Storage:SaveString("pocketslots_slot" .. pocketSlotId .. "_objmodel", "")
                Storage:SaveBoolean("pocketslots_slot" .. pocketSlotId .. "_keepacrossmaps", false)
                Storage:SaveBoolean("pocketslots_slot" .. pocketSlotId .. "_keepiteminstance", false)
                Storage:SaveString("pocketslots_slot" .. pocketSlotId .. "_materialgrouphash", "")

                ent:Attribute_SetIntValue("no_pick_up", 1)
                DoEntFireByInstanceHandle(ent, "Use", "", 0, player, player)
            else
                ent = SpawnEntityFromTableSynchronous(itemsClasses[itemTypeId], {["origin"]= traceTable.pos.x .. " " .. traceTable.pos.y .. " " .. traceTable.pos.z, ["angles"]= player_ang })
            end

            player:Attribute_SetIntValue("pocketslots_slot" .. pocketSlotId .. "" , 0)
        end
    end
end, "", 0)

Convars:RegisterCommand("wristpockets_recreate" , function()
    WristPockets_StartupPreparations()
end, "", 0)
