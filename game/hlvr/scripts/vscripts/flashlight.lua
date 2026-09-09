

Convars:RegisterConvar("sv_flashlight_color", "255 255 255 255", "", FCVAR_REPLICATED)
Convars:RegisterConvar("sv_flashlight_brightness", "1", "", FCVAR_REPLICATED)
Convars:RegisterConvar("sv_flashlight_shadowtex_size", "1024", "", FCVAR_REPLICATED)
Convars:RegisterConvar("sv_flashlight_range", "700", "", FCVAR_REPLICATED)

local function destroy_flashlight()
	if flashlight_ent ~= nil and not flashlight_ent:IsNull() then
		flashlight_ent:Destroy()
		flashlight_ent = nil
	end

	if not flashlight_ent == nil and flashlight_ent:IsNull() then
		flashlight_ent = nil
	end
	EmitSoundOnClient("HL2Player.FlashLightOff",Entities:GetLocalPlayer())
end

local function create_flashlight()
	local player = Entities:GetLocalPlayer()

	local ang = player:EyeAngles()
	local rot = player:GetAngles():Forward()
	local size = Convars:GetStr("sv_flashlight_shadowtex_size")

	local lighttbl = {
		targetname = "player_flashlight",
		origin = player:EyePosition(),
		angles = ang,
		enabled = "1",
		color = Convars:GetStr("sv_flashlight_color"),
 		brightness = Convars:GetStr("sv_flashlight_brightness"),
 		range = Convars:GetStr("sv_flashlight_range"),
 		castshadows = "1",
 		shadowtexturewidth = size,
 		shadowtextureheight = size,
 		style = "0",
 		fademindist = "0",
 		fademaxdist = "6000",
 		bouncescale = "1.0",
 		renderdiffuse = "1",
 		renderspecular = "1",
 		directlight = "2",
 		indirectlight = "0",
 		attenuation1 = "0.0",
 		attenuation2 = "1.0",
 		innerconeangle = "10",
		outerconeangle = "32",
		lightcookie = "flashlight"
	}

	flashlight_ent = SpawnEntityFromTableSynchronous("light_spot", lighttbl)

	if flashlight_ent == nil then
		return
	end
	flashlight_ent:SetParent(player, "flashlight")



	flashlight_ent:SetThink(function()
		if flashlight_ent == nil then
			return
		end
		local player = Entities:GetLocalPlayer()
		local ang = player:EyeAngles()
		local flPos = player:EyePosition()
		flPos.x = flPos.x + 1
		flPos.y = flPos.y + 3.5
		flPos.z = flPos.z - 1
		flashlight_ent:SetLocalOrigin(flPos - player:GetOrigin())
		flashlight_ent:SetLocalAngles(ang.x, 0, 0)
		return FrameTime()
	end, "flashlight_think", 0)
	EmitSoundOnClient("HL2Player.FlashLightOn",player)
end

Convars:RegisterCommand("inv_flashlight", function()
	local player = Entities:GetLocalPlayer()
	if not player or player:Attribute_GetIntValue("has_flashlight", 0) == 0 then return end
	if flashlight_ent ~= nil then
		destroy_flashlight()
	else
		create_flashlight()
	end
end, "", 0)

Convars:RegisterCommand("disable_flashlight", function()
	if flashlight_ent ~= nil then
		destroy_flashlight()
	end
end, "", 0)
