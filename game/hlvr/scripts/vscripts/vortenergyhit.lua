DoIncludeScript("novr_config.lua", nil)
if not NOVR_LUA then return end

local map = GetMapName()
local class = thisEntity:GetClassname()
local name = thisEntity:GetName()
local player = Entities:GetLocalPlayer()

if vlua.find(name, "_mug") then
    DoEntFireByInstanceHandle(thisEntity, "Break", "", 0, nil, nil)
end
