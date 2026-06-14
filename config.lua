Config = {}

-- ╔══════════════════════════════════════════════════════════════════╗
-- ║                     BB BLIP CREATOR - CONFIG                       ║
-- ║          by Baasha Bhai (BB)                                       ║
-- ║  Standalone. Works with every framework. No dependencies.          ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- How the panel opens
Config.Command   = 'blips'       -- chat command: /blips
Config.OpenKey   = 'F6'          -- default keybind (players can rebind in GTA settings > Key Bindings > FiveM)
Config.UseKeybind = false          -- set false to disable the keybind entirely

-- ── Who is allowed to open the panel and manage blips ──────────────
-- Mode options:
--   'auto'        -> ZERO SETUP (default). Auto-detects your framework and
--                    grants access to existing admins automatically:
--                      • txAdmin admins (group.admin principal)
--                      • QBCore admins/gods (qb-core permissions)
--                      • ESX admin/superadmin/mod groups
--                      • anyone with the blips.admin ACE
--                    If you use one of these, you don't need to configure anything.
--   'ace'         -> only the server ACE permission (Config.AcePermission).
--   'identifiers' -> only identifiers listed in Config.Admins below.
--   'everyone'    -> anyone can manage (NOT recommended on public servers).
Config.AdminMode      = 'auto'
Config.AcePermission  = 'blips.admin'   -- optional extra perm: add_ace group.admin blips.admin allow

-- Framework admin groups treated as admins in 'auto' mode (edit if your server renames them).
Config.AdminGroups = { 'admin', 'superadmin', 'god', 'mod', 'moderator' }

-- When true, prints a line to the server console every time someone is denied,
-- showing what was checked. Turn on if admins can't open the panel, then read
-- your server console. Set back to false once it works.
Config.Debug = false

-- Always-allowed identifiers. Honored in BOTH 'auto' and 'identifiers' modes,
-- so you can guarantee specific people access regardless of framework perms.
-- Accepts any identifier type the server returns.
-- Example: 'license:abc123...', 'steam:110000...', 'discord:123456...', 'fivem:1234'
Config.Admins = {
    -- 'license:put_a_license_here',
}

-- ── Behaviour ──────────────────────────────────────────────────────
Config.DefaultScale     = 0.8     -- default blip scale for newly created blips
Config.DefaultColor     = 0       -- default blip color id
Config.DefaultSprite    = 1       -- default blip sprite id
Config.MaxLabelLength   = 50      -- max characters for a blip label
Config.NotifyDuration   = 4000    -- ms for built-in notifications

-- ── Localization (notifications / titles) ──────────────────────────
Config.Locale = {
    no_permission   = 'You do not have permission to manage blips. If you are the server owner, open the README.md (Admin Access section) to set yourself as admin.',
    blip_created    = 'Blip created and synced to everyone.',
    blip_updated    = 'Blip updated.',
    blip_deleted    = 'Blip deleted.',
    invalid_data    = 'Invalid blip data received.',
    panel_title     = 'BB Blip Creator',
    panel_subtitle  = 'by Baasha Bhai',
}
