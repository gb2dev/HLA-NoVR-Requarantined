DoIncludeScript("novr_config.lua", nil)
if not NOVR_LUA then return end

require "storage"
function Precache(context)
	PrecacheModel("models/props/choreo_office/gnome.vmdl", context)
	PrecacheModel("models/props/hazmat/respirator_01a.vmdl", context)
	PrecacheResource("particle", "particles/weapon_fx/grabbity_gloves_scan.vpcf", context)
	PrecacheResource("particle", "particles/weapon_fx/grabbity_gloves.vpcf", context)
	PrecacheResource("particle", "particles/weapon_fx/gravity_glove_hand_right.vpcf", context)
end
