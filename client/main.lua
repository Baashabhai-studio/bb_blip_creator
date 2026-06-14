-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                    BLIP CREATOR - CLIENT                           ║
-- ╚══════════════════════════════════════════════════════════════════╝

local activeBlips = {}   -- [id] = blip handle
local blipStore   = {}   -- [id] = data (mirror of server)
local isAdmin     = false
local isOpen      = false
local previewBlip = nil

-- ── Helpers ─────────────────────────────────────────────────────────
local function Notify(msg, kind)
    -- Simple native notification; swap for your framework's notify if desired.
    SetNotificationTextEntry('STRING')
    AddTextComponentSubstringPlayerName(msg)
    DrawNotification(false, true)
end

RegisterNetEvent('blip_creator:notify', function(msg, kind)
    Notify(msg, kind)
end)

-- ── World blip rendering ────────────────────────────────────────────
local function ClearAllBlips()
    for id, handle in pairs(activeBlips) do
        if DoesBlipExist(handle) then RemoveBlip(handle) end
    end
    activeBlips = {}
end

local function CreateWorldBlip(data)
    local b = AddBlipForCoord(data.coords.x + 0.0, data.coords.y + 0.0, data.coords.z + 0.0)
    SetBlipSprite(b, data.sprite or 1)
    SetBlipColour(b, data.color or 0)
    SetBlipScale(b, (data.scale or 0.8) + 0.0)
    SetBlipAsShortRange(b, data.shortRange and true or false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(data.label or 'Blip')
    EndTextCommandSetBlipName(b)
    return b
end

local function RenderAll()
    ClearAllBlips()
    for id, data in pairs(blipStore) do
        activeBlips[id] = CreateWorldBlip(data)
    end
end

RegisterNetEvent('blip_creator:sync', function(blips)
    blipStore = blips or {}
    RenderAll()
    -- keep the panel list fresh if it is open
    if isOpen then
        SendNUIMessage({ action = 'setBlips', blips = blipStore })
    end
end)

RegisterNetEvent('blip_creator:setAdmin', function(state)
    isAdmin = state and true or false
    if isOpen then
        SendNUIMessage({ action = 'setAdmin', isAdmin = isAdmin })
    end
end)

-- ── Live preview blip ───────────────────────────────────────────────
local function RemovePreview()
    if previewBlip and DoesBlipExist(previewBlip) then RemoveBlip(previewBlip) end
    previewBlip = nil
end

local function UpdatePreview(data)
    RemovePreview()
    if not data or not data.coords then return end
    previewBlip = CreateWorldBlip(data)
    SetBlipFlashes(previewBlip, true)   -- make the preview obvious in-world
end

-- ── Open / Close panel ──────────────────────────────────────────────
local function OpenPanel()
    if isOpen then return end
    isOpen = true
    SetNuiFocus(true, true)
    local ped = PlayerPedId()
    local c   = GetEntityCoords(ped)
    SendNUIMessage({
        action   = 'open',
        isAdmin  = isAdmin,
        blips    = blipStore,
        position = { x = c.x, y = c.y, z = c.z },
        config   = {
            defaultSprite = Config.DefaultSprite,
            defaultColor  = Config.DefaultColor,
            defaultScale  = Config.DefaultScale,
            maxLabel      = Config.MaxLabelLength,
            title         = Config.Locale.panel_title,
            subtitle      = Config.Locale.panel_subtitle,
        },
    })
end

local function ClosePanel()
    isOpen = false
    SetNuiFocus(false, false)
    RemovePreview()
    SendNUIMessage({ action = 'close' })
end

-- ── Command + Keybind ───────────────────────────────────────────────
-- Ask the server fresh each time (handles framework loading after this resource).
RegisterCommand(Config.Command, function()
    TriggerServerEvent('blip_creator:checkOpen')
end, false)

RegisterNetEvent('blip_creator:openResult', function(allowed, blips)
    isAdmin = allowed and true or false
    if blips then blipStore = blips; RenderAll() end
    if allowed then
        OpenPanel()
    else
        Notify(Config.Locale.no_permission, 'error')
    end
end)

if Config.UseKeybind then
    RegisterKeyMapping(Config.Command, 'Open Blip Creator', 'keyboard', Config.OpenKey)
end

-- ── NUI callbacks ───────────────────────────────────────────────────
RegisterNUICallback('close', function(_, cb)
    ClosePanel()
    cb('ok')
end)

RegisterNUICallback('getMyPosition', function(_, cb)
    local c = GetEntityCoords(PlayerPedId())
    cb({ x = c.x, y = c.y, z = c.z })
end)

RegisterNUICallback('getWaypoint', function(_, cb)
    local wp = GetFirstBlipInfoId(8)
    if DoesBlipExist(wp) then
        local coords = GetBlipInfoIdCoord(wp)
        -- waypoint has no Z; probe the ground, fall back to player Z
        local pz = GetEntityCoords(PlayerPedId()).z
        local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, pz + 100.0, false)
        cb({ x = coords.x, y = coords.y, z = found and groundZ or pz, ok = true })
    else
        cb({ ok = false })
    end
end)

RegisterNUICallback('preview', function(data, cb)
    UpdatePreview(data)
    cb('ok')
end)

RegisterNUICallback('clearPreview', function(_, cb)
    RemovePreview()
    cb('ok')
end)

RegisterNUICallback('create', function(data, cb)
    TriggerServerEvent('blip_creator:create', data)
    cb('ok')
end)

RegisterNUICallback('update', function(data, cb)
    TriggerServerEvent('blip_creator:update', data.id, data.blip)
    cb('ok')
end)

RegisterNUICallback('delete', function(data, cb)
    TriggerServerEvent('blip_creator:delete', data.id)
    cb('ok')
end)

RegisterNUICallback('teleport', function(data, cb)
    if not data.coords then return cb('ok') end
    local ped = PlayerPedId()
    SetEntityCoords(ped, data.coords.x + 0.0, data.coords.y + 0.0, data.coords.z + 0.0, false, false, false, true)
    cb('ok')
end)

-- ── Boot: ask the server for the current blip set ──────────────────
CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(250) end
    Wait(1000)
    TriggerServerEvent('blip_creator:requestSync')
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    ClearAllBlips()
    RemovePreview()
    if isOpen then SetNuiFocus(false, false) end
end)
