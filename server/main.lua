-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                    BLIP CREATOR - SERVER                           ║
-- ║  Stores shared blips in data/blips.json and syncs to all clients.  ║
-- ╚══════════════════════════════════════════════════════════════════╝

local RESOURCE   = GetCurrentResourceName()
local DATA_FILE  = 'data/blips.json'

local Blips  = {}   -- [id] = blipData
local NextId = 1

-- ── Persistence ────────────────────────────────────────────────────
local function LoadBlips()
    local raw = LoadResourceFile(RESOURCE, DATA_FILE)
    if raw and raw ~= '' then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == 'table' then
            Blips  = decoded.blips or {}
            NextId = decoded.nextId or 1
        end
    end
    -- Make sure NextId is always ahead of every existing id (keys look like 'b1', 'b2'...)
    for idStr in pairs(Blips) do
        local num = tonumber(tostring(idStr):match('%d+')) or 0
        if num >= NextId then NextId = num + 1 end
    end
    print(('[blip_creator] Loaded %d blip(s).'):format(GetTableSize(Blips)))
end

function GetTableSize(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

local function SaveBlips()
    local payload = json.encode({ blips = Blips, nextId = NextId })
    SaveResourceFile(RESOURCE, DATA_FILE, payload, -1)
end

-- ── Framework auto-detection (runs once on start) ──────────────────
local Framework = { name = 'none', obj = nil }

local function DetectFramework()
    -- QBCore / QBox
    local okQB, qb = pcall(function() return exports['qb-core']:GetCoreObject() end)
    if okQB and qb then Framework.name = 'qb'; Framework.obj = qb; return end
    -- ESX
    local okEsx, esx = pcall(function() return exports['es_extended']:getSharedObject() end)
    if okEsx and esx then Framework.name = 'esx'; Framework.obj = esx; return end
    -- older ESX fallback
    if GetResourceState('es_extended') == 'started' then Framework.name = 'esx'; return end
end

local function inAdminGroups(group)
    if not group then return false end
    for _, g in ipairs(Config.AdminGroups) do
        if group == g then return true end
    end
    return false
end

-- True if this player is an admin via the active framework.
local function IsFrameworkAdmin(src)
    if Framework.name == 'qb' and Framework.obj then
        -- 1) QBCore registers an ace principal per permission (qbcore.god / qbcore.admin)
        for _, g in ipairs(Config.AdminGroups) do
            if IsPlayerAceAllowed(src, 'qbcore.' .. g) then return true end
        end
        -- 2) qb-core HasPermission helper (string or table arg depending on version)
        local ok, has = pcall(function()
            local fn = Framework.obj.Functions.HasPermission
            return fn(src, 'admin') or fn(src, 'god') or fn(src, Config.AdminGroups)
        end)
        if ok and has then return true end
        -- 3) fall back to the player's stored permission (string OR list, depending on version)
        local okP, player = pcall(function() return Framework.obj.Functions.GetPlayer(src) end)
        if okP and player and player.PlayerData then
            local perm = player.PlayerData.permission
            if type(perm) == 'table' then
                for _, p in ipairs(perm) do if inAdminGroups(p) then return true end end
            elseif inAdminGroups(perm) then
                return true
            end
        end
    elseif Framework.name == 'esx' and Framework.obj then
        local okP, xPlayer = pcall(function() return Framework.obj.GetPlayerFromId(src) end)
        if okP and xPlayer then
            local group = xPlayer.getGroup and xPlayer.getGroup() or xPlayer.group
            if inAdminGroups(group) then return true end
        end
    end
    return false
end

-- ── Admin check (standalone, framework agnostic) ───────────────────
local function IsAdmin(src)
    if Config.AdminMode == 'everyone' then
        return true
    elseif Config.AdminMode == 'ace' then
        return IsPlayerAceAllowed(src, Config.AcePermission)
    elseif Config.AdminMode == 'identifiers' then
        for _, id in ipairs(GetPlayerIdentifiers(src)) do
            for _, allowed in ipairs(Config.Admins) do
                if id == allowed then return true end
            end
        end
    elseif Config.AdminMode == 'auto' then
        -- Zero-setup: covers txAdmin, framework admins, the optional ACE,
        -- and any identifiers you list in Config.Admins as a guaranteed override.
        for _, id in ipairs(GetPlayerIdentifiers(src)) do
            for _, allowed in ipairs(Config.Admins) do
                if id == allowed then return true end
            end
        end
        if IsPlayerAceAllowed(src, 'group.admin') then return true end       -- txAdmin / principals
        if IsPlayerAceAllowed(src, Config.AcePermission) then return true end -- optional custom ace
        if Framework.name == 'none' then DetectFramework() end               -- retry if FW started after us
        if IsFrameworkAdmin(src) then return true end                        -- QBCore / ESX admins

        if Config.Debug then
            print(('[BB Blip Creator] DENIED %s (id %s) | framework=%s | group.admin=%s | %s=%s'):format(
                GetPlayerName(src) or '?', src, Framework.name,
                tostring(IsPlayerAceAllowed(src, 'group.admin')),
                Config.AcePermission, tostring(IsPlayerAceAllowed(src, Config.AcePermission))))
            if Framework.name == 'qb' then
                local hp = 'n/a'
                if Framework.obj then
                    local ok, r = pcall(function() return Framework.obj.Functions.HasPermission(src, 'admin') or Framework.obj.Functions.HasPermission(src, 'god') end)
                    hp = ok and tostring(r) or 'error'
                end
                print(('[BB Blip Creator] -> qb: qbcore.god=%s qbcore.admin=%s HasPermission(admin/god)=%s'):format(
                    tostring(IsPlayerAceAllowed(src, 'qbcore.god')),
                    tostring(IsPlayerAceAllowed(src, 'qbcore.admin')), hp))
            end
            print('[BB Blip Creator] -> Their identifiers: ' .. table.concat(GetPlayerIdentifiers(src), ', '))
        end
    end
    return false
end

exports('IsBlipAdmin', function(src) return IsAdmin(src) end)

-- ── Validation / sanitisation ──────────────────────────────────────
local function Sanitize(data)
    if type(data) ~= 'table' then return nil end
    if type(data.coords) ~= 'table' then return nil end
    local x = tonumber(data.coords.x)
    local y = tonumber(data.coords.y)
    local z = tonumber(data.coords.z)
    if not x or not y or not z then return nil end

    local label = tostring(data.label or 'Blip')
    if #label > Config.MaxLabelLength then label = label:sub(1, Config.MaxLabelLength) end

    return {
        label      = label,
        sprite     = math.floor(tonumber(data.sprite) or Config.DefaultSprite),
        color      = math.floor(tonumber(data.color) or Config.DefaultColor),
        scale      = math.min(2.0, math.max(0.1, tonumber(data.scale) or Config.DefaultScale)),
        shortRange = data.shortRange and true or false,
        coords     = { x = x + 0.0, y = y + 0.0, z = z + 0.0 },
    }
end

-- ── Sync ────────────────────────────────────────────────────────────
local function SyncToAll()
    TriggerClientEvent('blip_creator:sync', -1, Blips)
end

RegisterNetEvent('blip_creator:requestSync', function()
    local src = source
    TriggerClientEvent('blip_creator:sync', src, Blips)
    TriggerClientEvent('blip_creator:setAdmin', src, IsAdmin(src))
end)

-- Fresh admin check whenever a player tries to open the panel.
RegisterNetEvent('blip_creator:checkOpen', function()
    local src = source
    TriggerClientEvent('blip_creator:openResult', src, IsAdmin(src), Blips)
end)

-- ── Create ──────────────────────────────────────────────────────────
RegisterNetEvent('blip_creator:create', function(data)
    local src = source
    if not IsAdmin(src) then
        return TriggerClientEvent('blip_creator:notify', src, Config.Locale.no_permission, 'error')
    end
    local clean = Sanitize(data)
    if not clean then
        return TriggerClientEvent('blip_creator:notify', src, Config.Locale.invalid_data, 'error')
    end

    -- Non-numeric key ('b1', 'b2', ...) so json.encode always treats Blips as an
    -- object, never an array. Numeric-string keys ("1") get encoded as [] and lost.
    local id = 'b' .. NextId
    NextId   = NextId + 1
    Blips[id] = clean
    SaveBlips()
    SyncToAll()
    TriggerClientEvent('blip_creator:notify', src, Config.Locale.blip_created, 'success')
end)

-- ── Update ──────────────────────────────────────────────────────────
RegisterNetEvent('blip_creator:update', function(id, data)
    local src = source
    if not IsAdmin(src) then
        return TriggerClientEvent('blip_creator:notify', src, Config.Locale.no_permission, 'error')
    end
    id = tostring(id)
    if not Blips[id] then return end
    local clean = Sanitize(data)
    if not clean then
        return TriggerClientEvent('blip_creator:notify', src, Config.Locale.invalid_data, 'error')
    end
    Blips[id] = clean
    SaveBlips()
    SyncToAll()
    TriggerClientEvent('blip_creator:notify', src, Config.Locale.blip_updated, 'success')
end)

-- ── Delete ──────────────────────────────────────────────────────────
RegisterNetEvent('blip_creator:delete', function(id)
    local src = source
    if not IsAdmin(src) then
        return TriggerClientEvent('blip_creator:notify', src, Config.Locale.no_permission, 'error')
    end
    id = tostring(id)
    if not Blips[id] then return end
    Blips[id] = nil
    SaveBlips()
    SyncToAll()
    TriggerClientEvent('blip_creator:notify', src, Config.Locale.blip_deleted, 'success')
end)

-- ── Boot ────────────────────────────────────────────────────────────
AddEventHandler('onResourceStart', function(res)
    if res == RESOURCE then
        LoadBlips()
        if Config.AdminMode == 'auto' then
            DetectFramework()
            print(('[BB Blip Creator] Admin mode: auto | detected framework: %s'):format(Framework.name))
        end
    end
end)
