STEAM_DECK=false
DEFAULT_MENU=false
if GlobalSys:CommandLineCheck("-steamdeck") then
    STEAM_DECK=true
    DEFAULT_MENU=true
end
if GlobalSys:CommandLineCheck("-defaultmenu") then
    STEAM_DECK=false
    DEFAULT_MENU=true
end
NOVR_LUA = not GlobalSys:CommandLineCheck("-novr_nolua")

NoVR = NoVR or {}
setmetatable(NoVR, {
    __index = function()
        return function() end
    end,
})
