DoIncludeScript("novr_config.lua", nil)
if not NOVR_LUA then return end

SendToConsole("hlvr_physcannon_forward_offset -5")
thisEntity:Attribute_SetIntValue("picked_up", 0)
if Convars:GetInt("hidehud") ~= 104 and Convars:GetInt("hidehud") ~= 9 and Convars:GetInt("hidehud") ~= 75 then
    SendToConsole("r_drawviewmodel 1")
end
if thisEntity:GetClassname() == "item_item_crate" then
    local velocity = GetPhysVelocity(thisEntity)
    thisEntity:SetThink(function()
        local new_velocity = GetPhysVelocity(thisEntity)
        if (new_velocity:Length() - velocity:Length()) < 0 then
            DoEntFireByInstanceHandle(thisEntity, "SetHealth", "0", 0, nil, nil)
            return nil
        end
        velocity = new_velocity
        return 0
    end, "BreakOnImpact", 0)
end
