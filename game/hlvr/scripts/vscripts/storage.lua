

if thisEntity then
    require "storage"
    return
end

local debug_allowed = false

local function Warn(msg)

    if debug_allowed then
        Warning(msg.."\n")
    end
end

local function resolveHandle(handle)

    if handle ~= nil and handle ~= Storage and IsValidEntity(handle) then
        return handle
    end


    local player = GetListenServerHost()
    if not player then
        Warn("Trying to save a global value before player has spawned!")


        return nil
    end
    return player
end

local separator = "::"

Storage = {}

Storage.type_to_class = {}
Storage.class_to_type = {}

function Storage.RegisterType(name, T)
    Storage.type_to_class[name] = T
    Storage.class_to_type[T] = name
end

function Storage.UnregisterType(name, T)
    Storage.type_to_class[name] = nil
    Storage.class_to_type[T] = nil
end

function Storage.Join(...)
    return table.concat({...}, separator)
end

function Storage.SaveType(handle, name, T)
    handle:SetContext(Storage.Join(name, "type"), T, 0)
end

function Storage.SaveString(handle, name, value)
    handle = resolveHandle(handle)
    if not handle then
        Warn("Invalid save handle ("..tostring(handle)..")!")
        return false
    end
    if #value > 62 then
        local index = 0
        while #value > 0 do
            index = index + 1
            local split_point = math.min(62, #value)
            handle:SetContext(name..separator.."split"..index, ":"..value:sub(1, split_point), 0)
            value = value:sub(split_point+1, #value)
        end
        handle:SetContextNum(name..separator.."splits", index, 0)
        handle:SetContext(name..separator.."type", "splitstring", 0)
    else
        handle:SetContext(name, ":"..value, 0)
        handle:SetContext(name..separator.."type", "string", 0)
    end
    return true
end

function Storage.SaveNumber(handle, name, value)
    handle = resolveHandle(handle)
    if not handle then
        Warn("Invalid save handle ("..tostring(handle)..")!")
        return false
    end
    handle:SetContextNum(name, value, 0)
    handle:SetContext(name..separator.."type", "number", 0)
    return true
end

function Storage.SaveBoolean(handle, name, bool)
    handle = resolveHandle(handle)
    if not handle then
        Warn("Invalid save handle ("..tostring(handle)..")!")
        return false
    end
    handle:SetContextNum(name, bool and 1 or 0, 0)
    handle:SetContext(name..separator.."type", "boolean", 0)
    return true
end

function Storage.SaveVector(handle, name, vector)
    handle = resolveHandle(handle)
    if not handle then
        Warn("Invalid save handle ("..tostring(handle)..")!")
        return false
    end
    handle:SetContext(name..separator.."type", "vector", 0)
    Storage.SaveNumber(handle, name .. ".x", vector.x)
    Storage.SaveNumber(handle, name .. ".y", vector.y)
    Storage.SaveNumber(handle, name .. ".z", vector.z)
    return true
end

function Storage.SaveQAngle(handle, name, qangle)
    handle = resolveHandle(handle)
    if not handle then
        Warn("Invalid save handle ("..tostring(handle)..")!")
        return false
    end
    handle:SetContext(name..separator.."type", "qangle", 0)
    Storage.SaveNumber(handle, name .. ".x", qangle.x)
    Storage.SaveNumber(handle, name .. ".y", qangle.y)
    Storage.SaveNumber(handle, name .. ".z", qangle.z)
    return true
end

function Storage.SaveTableCustom(handle, name, tbl, T, save_meta)
    handle = resolveHandle(handle)
    if not handle then
        Warn("Invalid save handle ("..tostring(handle)..")!")
        return false
    end
    local key_count = 0
    local name_sep = name..separator
    local key_concat = name_sep.."key"..separator
    local actual_saves = 0
    for key, value in pairs(tbl) do
        key_count = key_count + 1
        if save_meta or tostring(key):sub(1,2) ~= "__" then

            if  Storage.Save(handle, name_sep..actual_saves, value)
            and Storage.Save(handle, key_concat..actual_saves, key)
            then
                actual_saves = actual_saves + 1
            else
                Warn("Failing to save table value ("..tostring(key).." = "..tostring(value)..")")
            end
        end
    end
    handle:SetContextNum(name_sep.."key_count", actual_saves, 0)
    handle:SetContext(name_sep.."type", T, 0)
    return true
end

function Storage.SaveTable(handle, name, tbl)
    return Storage.SaveTableCustom(handle, name, tbl, "table")
end

function Storage.SaveEntity(handle, name, entity)
    handle = resolveHandle(handle)
    if not entity or not IsValidEntity(entity) then
        Storage.SaveString(handle, name..separator.."targetname", "")
        handle:SetContext(name..separator.."unique", "", 0)
        handle:SetContext(name..separator.."type", "entity", 0)
        return false
    end
    local ent_name = entity:GetName()
    local uniqueKey = DoUniqueString("saved_entity")
    if ent_name == "" then
        ent_name = uniqueKey
        entity:SetEntityName(ent_name)
    end

    entity:Attribute_SetIntValue(uniqueKey, 1)

    Storage.SaveString(handle, name..separator.."targetname", ent_name)
    handle:SetContext(name..separator.."unique", uniqueKey, 0)
    handle:SetContext(name..separator.."type", "entity", 0)
    return true
end

local _vector = Vector()
local _qangle = QAngle()

function Storage.Save(handle, name, value)
    local t = type(value)
    if t=="function" then Warn("Functions are not supported for saving yet.") return false
    elseif t=="nil" then Storage.SaveType(handle, name, "nil") return true
    elseif t=="string" then return Storage.SaveString(handle, name, value)
    elseif t=="number" then return Storage.SaveNumber(handle, name, value)
    elseif t=="boolean" then return Storage.SaveBoolean(handle, name, value)
    elseif t=="table" then
        if type(value.__self) == "userdata" then
            return Storage.SaveEntity(handle, name, value)
        elseif Storage.class_to_type[value.__index] then
            return value.__save(handle, name, value)
        else
            return Storage.SaveTable(handle, name, value)
        end

    elseif value.__index==_vector.__index then return Storage.SaveVector(handle, name, value)
    elseif value.__index==_qangle.__index then return Storage.SaveQAngle(handle, name, value)
    else
        Warn("Value ["..tostring(value)..","..type(value).."] is not supported. Please open at issue on the github.")
        return false
    end
end

function Storage.LoadString(handle, name, default)
    handle = resolveHandle(handle)
    local t = handle:GetContext(name..separator.."type")
    if t == "string" then
        local value = handle:GetContext(name)
        if value == nil then return default end
        return value:sub(2)
    elseif t == "splitstring" then
        local splits = handle:GetContext(name..separator.."splits")
        local str = ""
        for index = 1, splits do
            str = str .. (handle:GetContext(name..separator.."split"..index):sub(2))
        end
        return str
    end
    Warn("String " .. name .. " could not be loaded!")
    return default
end

function Storage.LoadNumber(handle, name, default)
    handle = resolveHandle(handle)
    local t = handle:GetContext(name..separator.."type")
    local value = handle:GetContext(name)
    if not value or t ~= "number" then
        Warn("Number " .. name .. " could not be loaded! ("..type(value)..", "..tostring(value)..")")
        return default
    end
    if type(value) == "number" then return value end
    return default
end

function Storage.LoadBoolean(handle, name, default)
    handle = resolveHandle(handle)
    local t = handle:GetContext(name..separator.."type")
    local value = handle:GetContext(name)
    if t ~= "boolean" or value == nil then
        Warn("Boolean " .. name .. " could not be loaded! ("..type(value)..", "..tostring(value)..")")
        return default
    end
    return value == 1
end

function Storage.LoadVector(handle, name, default)
    handle = resolveHandle(handle)
    local t = handle:GetContext(name..separator.."type")
    if t ~= "vector" then
        Warn("Vector " .. name .. " could not be loaded!")
        return default
    end
    local x = handle:GetContext(name .. ".x") or 0
    local y = handle:GetContext(name .. ".y") or 0
    local z = handle:GetContext(name .. ".z") or 0

    return Vector(x, y, z)
end

function Storage.LoadQAngle(handle, name, default)
    handle = resolveHandle(handle)
    local t = handle:GetContext(name..separator.."type")
    if t ~= "qangle" then
        Warn("QAngle " .. name .. " could not be loaded!")
        return default
    end
    local x = handle:GetContext(name .. ".x") or 0
    local y = handle:GetContext(name .. ".y") or 0
    local z = handle:GetContext(name .. ".z") or 0

    return QAngle(x, y, z)
end

function Storage.LoadTableCustom(handle, name, T, default)
    handle = resolveHandle(handle)
    local name_sep = name..separator
    local t = handle:GetContext(name_sep.."type")
    local key_count = handle:GetContext(name_sep.."key_count")
    if t ~= T or not key_count  then
        Warn("Table " .. name .. " could not be loaded!")
        return default
    end
    key_count = key_count - 1

    local key_concat = name_sep.."key"..separator
    local tbl = {}
    for i = 0, key_count do
        local key = Storage.Load(handle, key_concat..i)
        local value = Storage.Load(handle, name_sep..i)
        tbl[key] = value
    end
    return tbl
end

function Storage.LoadTable(handle, name, default)
    return Storage.LoadTableCustom(handle, name, "table", default)
end

function Storage.LoadEntity(handle, name, default)
    handle = resolveHandle(handle)
    local t = handle:GetContext(name..separator.."type")
    local uniqueKey = handle:GetContext(name..separator.."unique")
    local ent_name = Storage.LoadString(handle, name..separator.."targetname")
    if t ~= "entity" or not ent_name then
        Warn("Entity '" .. name .. "' could not be loaded! ("..type(ent_name)..", "..tostring(ent_name)..")")
        return default
    end
    local ents = Entities:FindAllByName(ent_name)
    if not ents then
        Warn("No entities of '" .. name .. "' found with saved name '" .. ent_name .. "', returning default.")
        return default
    end
    for _, ent in ipairs(ents) do
        if ent:Attribute_GetIntValue(uniqueKey, 0) == 1 then
            return ent
        end
    end

    Warn("No entities of '" .. name .. "' have saved attribute! Returning default.")
    return default
end

function Storage.Load(handle, name, default)
    handle = resolveHandle(handle)
    local t = handle:GetContext(name..separator.."type")
    if not t then
        Warn("Value " .. name .. " could not be loaded!")
        return default
    end

    if t=="nil" then return nil
    elseif t=="string" or t=="splitstring" then return Storage.LoadString(handle, name, default)
    elseif t=="number" then return Storage.LoadNumber(handle, name, default)
    elseif t=="boolean" then return Storage.LoadBoolean(handle, name, default)
    elseif t=="vector" then return Storage.LoadVector(handle, name, default)
    elseif t=="qangle" then return Storage.LoadQAngle(handle, name, default)
    elseif t=="table" then return Storage.LoadTable(handle, name, default)
    elseif t=="entity" then return Storage.LoadEntity(handle, name, default)
    elseif Storage.type_to_class[t] then
        local result = Storage.type_to_class[t].__load(handle, name)
        if result == nil then return default end
        return result
    else
        Warn("Unknown type '"..t.."' for name '"..name.."'")
        return default
    end
end

CBaseEntity.SaveString  = Storage.SaveString
CBaseEntity.SaveNumber  = Storage.SaveNumber
CBaseEntity.SaveBoolean = Storage.SaveBoolean
CBaseEntity.SaveVector  = Storage.SaveVector
CBaseEntity.SaveQAngle  = Storage.SaveQAngle
CBaseEntity.SaveTable   = Storage.SaveTable
CBaseEntity.SaveEntity  = Storage.SaveEntity
CBaseEntity.Save        = Storage.Save

CBaseEntity.LoadString  = Storage.LoadString
CBaseEntity.LoadNumber  = Storage.LoadNumber
CBaseEntity.LoadBoolean = Storage.LoadBoolean
CBaseEntity.LoadVector  = Storage.LoadVector
CBaseEntity.LoadQAngle  = Storage.LoadQAngle
CBaseEntity.LoadTable   = Storage.LoadTable
CBaseEntity.LoadEntity  = Storage.LoadEntity
CBaseEntity.Load        = Storage.Load

return Storage
