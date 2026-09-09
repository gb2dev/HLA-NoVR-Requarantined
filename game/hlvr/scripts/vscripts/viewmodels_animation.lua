

local smg_viewmodel_holo = "models/weapons/v_smg1_holo.vmdl"
local smg_viewmodel_holo_ads = "models/weapons/v_smg1_holo_ads.vmdl"
local smg_viewmodel_casing = "models/weapons/v_smg1_casing.vmdl"
local smg_viewmodel_casing_ads = "models/weapons/v_smg1_casing_ads.vmdl"
local pistol_viewmodel_shroud = "models/weapons/v_pistol_shroud.vmdl"
local pistol_viewmodel_shroud_ads = "models/weapons/v_pistol_shroud_ads.vmdl"
local pistol_viewmodel_shroud_stock = "models/weapons/v_pistol_shroud_stock.vmdl"
local pistol_viewmodel_shroud_stock_ads = "models/weapons/v_pistol_shroud_stock_ads.vmdl"
local pistol_viewmodel_hopper = "models/weapons/v_pistol_hopper.vmdl"
local pistol_viewmodel_hopper_ads = "models/weapons/v_pistol_hopper_ads.vmdl"
local pistol_viewmodel_hopper_no_stock = "models/weapons/v_pistol_hopper_no_stock.vmdl"
local pistol_viewmodel_hopper_no_stock_ads = "models/weapons/v_pistol_hopper_no_stock_ads.vmdl"

function ViewmodelAnimation_LevelChange()

    local player = Entities:GetLocalPlayer()
    local viewmodel = Entities:FindByClassname(nil, "viewmodel")

    player:SetThink(function()

        viewmodel:ResetSequence("anim_prepare")
    end, "ViewmodelAnimationLevelChange", 1)

    player:SetThink(function()
        viewmodel:ResetSequence("idle")
    end, "ViewmodelAnimationLevelChangeIdle", 2)
end

local function ViewmodelAnimation_CancelThinks(player)
    if not player then return end
    player:StopThink("ViewmodelIdlePrepareAnimation")
    player:StopThink("ViewmodelHIPtoADSAnimation")
    player:StopThink("ViewmodelADStoHIPAnimation")
    player:StopThink("ZoomActivate")
    player:StopThink("ZoomDeactivate")
end

local function ViewmodelAnimation_PrepareAnimation(viewmodel, player)

    viewmodel:ResetSequence("anim_prepare")

    player:SetThink(function()
        viewmodel:ResetSequence("idle")
    end, "ViewmodelIdlePrepareAnimation", 0.1)

end

function ViewmodelAnimation_ResetAnimation()
    local viewmodel = Entities:FindByClassname(nil, "viewmodel")
    if viewmodel then
        local viewmodel_name = viewmodel:GetModelName()

		viewmodel:ResetSequence("idle")
	end
end

function ViewmodelAnimation_PlayInspectAnimation()
    local viewmodel = Entities:FindByClassname(nil, "viewmodel")
    local player = Entities:GetLocalPlayer()

    if viewmodel then
        local viewmodel_name = viewmodel:GetModelName()
		local viewmodel_sequence = viewmodel:GetSequence()

        if string.match(viewmodel_name, "v_pistol") or string.match(viewmodel_name, "v_smg1") or string.match(viewmodel_name, "v_shotgun") then

            animation_time = 2.3
            if string.match(viewmodel_name, "v_pistol") then
                animation_time = 3.6
            end
            if string.match(viewmodel_name, "v_shotgun") then
                animation_time = 3.4
            end

            ViewmodelAnimation_PrepareAnimation(viewmodel, player)

            player:SetThink(function()
                viewmodel:ResetSequence("inspect")
            end, "ViewmodelInspectAnimation", 0.12)

            player:SetThink(function()
                viewmodel:ResetSequence("idle")
            end, "ViewmodelIdleAnimation", animation_time)
        end
	end
end

function ViewmodelAnimation_HIPtoADS()
    local viewmodel = Entities:FindByClassname(nil, "viewmodel")
    local player = Entities:GetLocalPlayer()

    if viewmodel then
        ViewmodelAnimation_CancelThinks(player)
        local viewmodel_name = viewmodel:GetModelName()
		local viewmodel_sequence = viewmodel:GetSequence()

        if string.match(viewmodel_name, smg_viewmodel_holo) then
            viewmodel:SetModel(smg_viewmodel_holo_ads)
        end

        if string.match(viewmodel_name, smg_viewmodel_casing) then
            viewmodel:SetModel(smg_viewmodel_casing_ads)
        end

        if string.match(viewmodel_name, pistol_viewmodel_shroud) then
            viewmodel:SetModel(pistol_viewmodel_shroud_ads)
        end

        if string.match(viewmodel_name, pistol_viewmodel_shroud_stock) then
            viewmodel:SetModel(pistol_viewmodel_shroud_stock_ads)
        end

        if string.match(viewmodel_name, pistol_viewmodel_hopper) then
            viewmodel:SetModel(pistol_viewmodel_hopper_ads)
        end

        if string.match(viewmodel_name, pistol_viewmodel_hopper_no_stock) then
            viewmodel:SetModel(pistol_viewmodel_hopper_no_stock_ads)
        end

        viewmodel_name = viewmodel:GetModelName()

		ViewmodelAnimation_PrepareAnimation(viewmodel, player)

        player:SetThink(function()
            viewmodel:ResetSequence("hip_to_ads")
        end, "ViewmodelHIPtoADSAnimation", 0.12)

	end
end

function ViewmodelAnimation_ADStoHIP()
    local viewmodel = Entities:FindByClassname(nil, "viewmodel")
    local player = Entities:GetLocalPlayer()

    if viewmodel then
        ViewmodelAnimation_CancelThinks(player)
        local viewmodel_name = viewmodel:GetModelName()
		local viewmodel_sequence = viewmodel:GetSequence()

        if string.match(viewmodel_name, smg_viewmodel_holo_ads) then
            viewmodel:SetModel(smg_viewmodel_holo)
        end

        if string.match(viewmodel_name, smg_viewmodel_casing_ads) then
            viewmodel:SetModel(smg_viewmodel_casing)
        end

        if string.match(viewmodel_name, pistol_viewmodel_shroud_ads) then
            viewmodel:SetModel(pistol_viewmodel_shroud)
        end

        if string.match(viewmodel_name, pistol_viewmodel_shroud_stock_ads) then
            viewmodel:SetModel(pistol_viewmodel_shroud_stock)
        end

        if string.match(viewmodel_name, pistol_viewmodel_hopper_ads) then
            viewmodel:SetModel(pistol_viewmodel_hopper)
        end

        if string.match(viewmodel_name, pistol_viewmodel_hopper_no_stock_ads) then
            viewmodel:SetModel(pistol_viewmodel_hopper_no_stock)
        end

        viewmodel_name = viewmodel:GetModelName()

        viewmodel:ResetSequence("ads_to_hip")

        local ok, hold = pcall(function() return viewmodel:ActiveSequenceDuration() end)
        if not ok or type(hold) ~= "number" or hold <= 0 then hold = 0.85 end
        player:SetThink(function()
            ViewmodelAnimation_ResetAnimation()
        end, "ViewmodelADStoHIPAnimation", hold)
	end
end

function ViewmodelAnimation_Reset()
    local player = Entities:GetLocalPlayer()
    ViewmodelAnimation_CancelThinks(player)
    ViewmodelAnimation_ResetAnimation()
    cvar_setf("viewmodel_offset_x", 0)
    cvar_setf("viewmodel_offset_z", 0)
end

Convars:RegisterCommand("viewmodel_inspect_animation" , function()
	ViewmodelAnimation_PlayInspectAnimation()
end, "", 0)

Convars:RegisterCommand("viewmodel_reset" , function()
	ViewmodelAnimation_Reset()
end, "", 0)
