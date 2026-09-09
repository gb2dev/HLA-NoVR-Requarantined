require "wristpockets"

function Viewmodels_Init()
    local player = Entities:GetLocalPlayer()
    player:SetThink(function()
        Viewmodels_UpgradeModel()
    end, "ViewmodelUpgradeInit", 1)
    player:SetThink(function()
        if NoVR.ConsumeViewmodelRefresh and NoVR.ConsumeViewmodelRefresh() then
            Viewmodels_UpgradeModel()
        end
        return 0
    end, "ViewmodelGrantRefresh", 0)
end

function Viewmodels_UpgradeModel()
    local player = Entities:GetLocalPlayer()


    local pistol_aimdownsights = player:Attribute_GetIntValue("pistol_upgrade_aimdownsights", 0)
    local pistol_burstfire = player:Attribute_GetIntValue("pistol_upgrade_burstfire", 0)
    local pistol_hopper = player:Attribute_GetIntValue("pistol_upgrade_hopper", 0)
    local pistol_lasersight = player:Attribute_GetIntValue("pistol_upgrade_lasersight", 0)


    local pistol_search_str = "v_pistol"
    local pistol_viewmodel_shroud_stock = "models/weapons/v_pistol_shroud_stock.vmdl"
    local pistol_viewmodel_shroud_stock_ads = "models/weapons/v_pistol_shroud_stock_ads.vmdl"
    local pistol_viewmodel_stock = "models/weapons/v_pistol_stock.vmdl"
    local pistol_viewmodel_shroud = "models/weapons/v_pistol_shroud.vmdl"
    local pistol_viewmodel_shroud_ads = "models/weapons/v_pistol_shroud_ads.vmdl"
    local pistol_viewmodel_hopper = "models/weapons/v_pistol_hopper.vmdl"
    local pistol_viewmodel_hopper_ads = "models/weapons/v_pistol_hopper_ads.vmdl"
    local pistol_viewmodel_base = "models/weapons/v_pistol.vmdl"
    local pistol_viewmodel_hopper_no_shroud = "models/weapons/v_pistol_hopper_no_shroud.vmdl"
	local pistol_viewmodel_hopper_no_shroud_stock = "models/weapons/v_pistol_hopper_no_shroud_stock.vmdl"
	local pistol_viewmodel_hopper_no_stock = "models/weapons/v_pistol_hopper_no_stock.vmdl"
	local pistol_viewmodel_hopper_no_stock_ads = "models/weapons/v_pistol_hopper_no_stock_ads.vmdl"


    local shotgun_doubleshot = player:Attribute_GetIntValue("shotgun_upgrade_doubleshot", 0)
    local shotgun_grenadelauncher = player:Attribute_GetIntValue("shotgun_upgrade_grenadelauncher", 0)
    local shotgun_hopper = player:Attribute_GetIntValue("shotgun_upgrade_hopper", 0)
    local shotgun_lasersight = player:Attribute_GetIntValue("shotgun_upgrade_lasersight", 0)

    local shotgun_playerhasgrenade = WristPockets_PlayerHasGrenade()


    local shotgun_search_str = "v_shotgun"
    local shotgun_viewmodel_burst_grenade_attached = "models/weapons/v_shotgun_burst_grenade_attached.vmdl"
    local shotgun_viewmodel_burst_grenade = "models/weapons/v_shotgun_burst_grenade.vmdl"
    local shotgun_viewmodel_burst = "models/weapons/v_shotgun_burst.vmdl"
    local shotgun_viewmodel_grenade_attached = "models/weapons/v_shotgun_grenade_attached.vmdl"
    local shotgun_viewmodel_grenade = "models/weapons/v_shotgun_grenade.vmdl"
    local shotgun_viewmodel_hopper = "models/weapons/v_shotgun_hopper.vmdl"
    local shotgun_viewmodel_base = "models/weapons/v_shotgun.vmdl"
    local shotgun_viewmodel_hopper_grenade_attached = "models/weapons/v_shotgun_hopper_grenade_attached.vmdl"
	local shotgun_viewmodel_hopper_no_burst = "models/weapons/v_shotgun_hopper_no_burst.vmdl"
	local shotgun_viewmodel_hopper_no_burst_grenade_attached = "models/weapons/v_shotgun_hopper_no_burst_grenade_attached.vmdl"
	local shotgun_viewmodel_hopper_no_grenade = "models/weapons/v_shotgun_hopper_no_grenade.vmdl"
    local shotgun_viewmodel_hopper_no_burst_grenade = "models/weapons/v_shotgun_hopper_no_burst_grenade.vmdl"


    local smg_aimdownsights = player:Attribute_GetIntValue("smg_upgrade_aimdownsights", 0)
    local smg_fasterfirerate = player:Attribute_GetIntValue("smg_upgrade_fasterfirerate", 0)
    local smg_casing = player:Attribute_GetIntValue("smg_upgrade_casing", 0)
    local smg_lasersight = player:Attribute_GetIntValue("smg_upgrade_lasersight", 0)


    local smg_search_str = "v_smg1"
    local smg_viewmodel_holo = "models/weapons/v_smg1_holo.vmdl"
    local smg_viewmodel_holo_ads = "models/weapons/v_smg1_holo_ads.vmdl"
    local smg_viewmodel_powerpack = "models/weapons/v_smg1_powerpack.vmdl"
    local smg_viewmodel_base = "models/weapons/v_smg1.vmdl"
    local smg_viewmodel_casing = "models/weapons/v_smg1_casing.vmdl"
    local smg_viewmodel_casing_ads = "models/weapons/v_smg1_casing_ads.vmdl"
    local smg_viewmodel_casing_no_holo = "models/weapons/v_smg1_casing_no_holo.vmdl"
	local smg_viewmodel_casing_no_holo_powerpack = "models/weapons/v_smg1_casing_no_holo_powerpack.vmdl"


    local viewmodel = Entities:FindByClassname(nil, "viewmodel")
    if viewmodel then
        local viewmodel_name = viewmodel:GetModelName()

        if not NovrAdsZoomed() then
            SendToConsole("hud_draw_fixed_reticle 1")
            SendToConsole("crosshair 0")
        end


        if string.match(viewmodel_name, pistol_search_str) then

            if pistol_lasersight == 1 and not NovrAdsZoomed() then
                SendToConsole("hud_draw_fixed_reticle 0")
                SendToConsole("crosshair 1")
            end

            if pistol_hopper == 1 and pistol_aimdownsights == 1 and pistol_burstfire == 1 then
                if string.match(viewmodel_name, pistol_viewmodel_hopper) or string.match(viewmodel_name, pistol_viewmodel_hopper_ads) then
                    return
                else
                    viewmodel:SetModel(pistol_viewmodel_hopper)
                    return
                end

            elseif pistol_hopper == 1 and pistol_aimdownsights == 0 and pistol_burstfire == 1 then
                if string.match(viewmodel_name, pistol_viewmodel_hopper_no_shroud) then
                    return
                else
                    viewmodel:SetModel(pistol_viewmodel_hopper_no_shroud)
                    return
                end

            elseif pistol_hopper == 1 and pistol_aimdownsights == 1 and pistol_burstfire == 0 then
                if string.match(viewmodel_name, pistol_viewmodel_hopper_no_stock) or string.match(viewmodel_name, pistol_viewmodel_hopper_no_stock_ads) then
                    return
                else
                    viewmodel:SetModel(pistol_viewmodel_hopper_no_stock)
                    return
                end

            elseif pistol_hopper == 1 and pistol_aimdownsights == 0 and pistol_burstfire == 0 then
                if string.match(viewmodel_name, pistol_viewmodel_hopper_no_shroud_stock) then
                    return
                else
                    viewmodel:SetModel(pistol_viewmodel_hopper_no_shroud_stock)
                    return
                end

            elseif pistol_aimdownsights == 1 and pistol_burstfire == 1 then
                if string.match(viewmodel_name, pistol_viewmodel_shroud_stock) or string.match(viewmodel_name, pistol_viewmodel_shroud_stock_ads) then
                    return
                else
                    viewmodel:SetModel(pistol_viewmodel_shroud_stock)
                    return
                end

            elseif pistol_aimdownsights == 1 and pistol_burstfire == 0 then
                if string.match(viewmodel_name, pistol_viewmodel_shroud) or string.match(viewmodel_name, pistol_viewmodel_shroud_ads) then
                    return
                else
                    viewmodel:SetModel(pistol_viewmodel_shroud)
                    return
                end

            elseif pistol_aimdownsights == 0 and pistol_burstfire == 1 then
                if string.match(viewmodel_name, pistol_viewmodel_stock) then
                    return
                else
                    viewmodel:SetModel(pistol_viewmodel_stock)
                    return
                end
            end
        end


        if string.match(viewmodel_name, shotgun_search_str) then

            if shotgun_lasersight == 1 and not NovrAdsZoomed() then
                SendToConsole("hud_draw_fixed_reticle 0")
                SendToConsole("crosshair 1")
            end

            if shotgun_hopper == 1 and shotgun_doubleshot == 1 and shotgun_grenadelauncher == 1 then
                if string.match(viewmodel_name, shotgun_viewmodel_hopper_grenade_attached) and shotgun_playerhasgrenade then
                    return
                elseif string.match(viewmodel_name, shotgun_viewmodel_hopper) and shotgun_playerhasgrenade == false then
                    return
                else
                    if shotgun_playerhasgrenade then
                        viewmodel:SetModel(shotgun_viewmodel_hopper_grenade_attached)
                    else
                        viewmodel:SetModel(shotgun_viewmodel_hopper)
                    end
                    return
                end

            elseif shotgun_hopper == 1 and shotgun_doubleshot == 0 and shotgun_grenadelauncher == 1 then
                if string.match(viewmodel_name, shotgun_viewmodel_hopper_no_burst_grenade_attached) and shotgun_playerhasgrenade then
                    return
                elseif string.match(viewmodel_name, shotgun_viewmodel_hopper_no_burst) and shotgun_playerhasgrenade == false then
                    return
                else
                    if shotgun_playerhasgrenade then
                        viewmodel:SetModel(shotgun_viewmodel_hopper_no_burst_grenade_attached)
                    else
                        viewmodel:SetModel(shotgun_viewmodel_hopper_no_burst)
                    end
                    return
                end

            elseif shotgun_hopper == 1 and shotgun_doubleshot == 1 and shotgun_grenadelauncher == 0 then
                if string.match(viewmodel_name, shotgun_viewmodel_hopper_no_grenade) then
                    return
                else
                    viewmodel:SetModel(shotgun_viewmodel_hopper_no_grenade)
                    return
                end

            elseif shotgun_hopper == 1 and shotgun_doubleshot == 0 and shotgun_grenadelauncher == 0 then
                if string.match(viewmodel_name, shotgun_viewmodel_hopper_no_burst_grenade) then
                    return
                else
                    viewmodel:SetModel(shotgun_viewmodel_hopper_no_burst_grenade)
                    return
                end

            elseif shotgun_doubleshot == 1 and shotgun_grenadelauncher == 1 then
                if string.match(viewmodel_name, shotgun_viewmodel_burst_grenade_attached) and shotgun_playerhasgrenade then
                    return
                elseif string.match(viewmodel_name, shotgun_viewmodel_burst_grenade) and shotgun_playerhasgrenade == false then
                    return
                else
                    if shotgun_playerhasgrenade then
                        viewmodel:SetModel(shotgun_viewmodel_burst_grenade_attached)
                    else
                        viewmodel:SetModel(shotgun_viewmodel_burst_grenade)
                    end
                    return
                end

            elseif shotgun_doubleshot == 1 and shotgun_grenadelauncher == 0 then
                if string.match(viewmodel_name, shotgun_viewmodel_burst) then
                    return
                else
                    viewmodel:SetModel(shotgun_viewmodel_burst)
                    return
                end

            elseif shotgun_doubleshot == 0 and shotgun_grenadelauncher == 1 then
                if string.match(viewmodel_name, shotgun_viewmodel_grenade_attached) and shotgun_playerhasgrenade then
                    return
                elseif string.match(viewmodel_name, shotgun_viewmodel_grenade) and shotgun_playerhasgrenade == false then
                    return
                else
                    if shotgun_playerhasgrenade then
                        viewmodel:SetModel(shotgun_viewmodel_grenade_attached)
                    else
                        viewmodel:SetModel(shotgun_viewmodel_grenade)
                    end
                    return
                end
            end
        end


        if string.match(viewmodel_name, smg_search_str) then

            if smg_lasersight == 1 and not NovrAdsZoomed() then
                SendToConsole("hud_draw_fixed_reticle 0")
                SendToConsole("crosshair 1")
            end

            if smg_casing == 1 and smg_aimdownsights == 1 and (smg_fasterfirerate == 1 or smg_fasterfirerate == 0) then
                if string.match(viewmodel_name, smg_viewmodel_casing) or string.match(viewmodel_name, smg_viewmodel_casing_ads) then
                    return
                else
                    viewmodel:SetModel(smg_viewmodel_casing)
                    return
                end

            elseif smg_casing == 1 and smg_aimdownsights == 0 and smg_fasterfirerate == 1 then
                if string.match(viewmodel_name, smg_viewmodel_casing_no_holo) then
                    return
                else
                    viewmodel:SetModel(smg_viewmodel_casing_no_holo)
                    return
                end

            elseif smg_casing == 1 and smg_aimdownsights == 0 and smg_fasterfirerate == 0 then
                if string.match(viewmodel_name, smg_viewmodel_casing_no_holo_powerpack) then
                    return
                else
                    viewmodel:SetModel(smg_viewmodel_casing_no_holo_powerpack)
                    return
                end

            elseif smg_aimdownsights == 1 and (smg_fasterfirerate == 1 or smg_fasterfirerate == 0) then
                if string.match(viewmodel_name, smg_viewmodel_holo) or string.match(viewmodel_name, smg_viewmodel_holo_ads) then
                    return
                else
                    viewmodel:SetModel(smg_viewmodel_holo)
                    return
                end

            elseif smg_aimdownsights == 0 and smg_fasterfirerate == 1 then
                if string.match(viewmodel_name, smg_viewmodel_powerpack) then
                    return
                else
                    viewmodel:SetModel(smg_viewmodel_powerpack)
                    return
                end
            end
        end

    end
end

Convars:RegisterCommand("viewmodel_update" , function()
    local player = Entities:GetLocalPlayer()
    if player ~= nil then
        player:SetThink(function()
            Viewmodels_UpgradeModel()
        end, "ViewmodelUpdate", 0)
    end
end, "", 0)
