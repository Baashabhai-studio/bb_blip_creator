# 🗺️ BB Blip Creator

**by Baasha Bhai (BB)** · Free for the community

A **standalone, framework-agnostic** premium blip manager for FiveM. Your admins create
map blips through a sleek glassmorphism menu, see a **live preview on the map while they
build them**, and the blips instantly appear for **every player** on the server. Saved
automatically, survives restarts. No database, no dependencies, works on **any framework**
(QBCore, QBox, ESX, vRP, standalone…).

---

## ✨ Features
- 🎨 Modern dark glassmorphism UI.
- 🔍 Searchable sprite picker showing the **real GTA blip icons** (bundled, offline) — every documented sprite.
- 👁️ **Live in-world preview** — the blip shows on your map and updates instantly as you change sprite, color, scale, or label, so you always see the real icon before saving.
- 🎚️ Color palette (+ manual color id 0–85) and scale slider.
- 📍 Set location from **your current position** or **your map waypoint**.
- 🗂️ Manage tab: **create / edit / delete / teleport** to any blip.
- 💾 Blips are saved to `data/blips.json` and **synced to all players** in real time.
- 🛡️ **Auto admin detection** — zero setup on most servers.

---

## 📦 Installation

1. Drop the `bb_blip_creator` folder **anywhere inside your `resources` directory** —
   any subfolder works (e.g. directly in `resources/`, or inside `[standalone]`,
   `[scripts]`, `[custom]`, etc.). The folder name must stay `bb_blip_creator`.
2. Add this line to your `server.cfg`:
   ```cfg
   ensure bb_blip_creator
   ```
3. Restart your server. Done. ✅

> No SQL, no `import.sql`, no other resources required.

---

## 🛡️ Who can use it? (Admin access)

By default the script is in **`auto`** mode. It automatically gives the menu to your
**existing admins** — you usually don't have to configure anything. It recognises:

| Your setup | How you become an admin |
|---|---|
| **txAdmin / server.cfg** | the `group.admin` principal |
| **QBCore / QBox** | `god` or `admin` permission |
| **ESX** | `admin`, `superadmin`, or `mod` group |
| **Manual** | the optional `blips.admin` ACE, or a license in `Config.Admins` |

### 🚨 READ THIS FIRST — the #1 cause of "You do not have permission"

There are **two different kinds of restart**, and they reload different things. This trips
up almost everyone, so memorise it:

| What you run | Reloads the script (`config.lua` / Lua)? | Reloads `server.cfg` (`group.admin`, `add_principal`)? |
|---|---|---|
| `restart bb_blip_creator` (resource restart) | ✅ Yes | ❌ **No** |
| **Full server stop + start** | ✅ Yes | ✅ Yes |

👉 **If you add yourself as an admin in `server.cfg`, a resource restart will NOT make it
work — you must fully restart the server** (or run the `add_principal` line in the live
console, which applies it instantly without a restart).

### ✅ Two ways to make someone an admin (pick either)

You can grant access through your **server.cfg** OR through the script's **config.lua** —
whichever you prefer. Both work.

**Method 1 — server.cfg (best for whole teams).** Give the person the `group.admin`
principal. Add to `server.cfg` (or paste into the live console to apply instantly):
```
add_principal identifier.license:THEIR_LICENSE_HERE group.admin
```
⚠️ If you add it to `server.cfg`, you must **fully restart the server** for it to load
(a resource restart will NOT load it — see the table above).

**Method 2 — config.lua (easiest, works on a resource restart).** Open `config.lua` and
put the person's license in `Config.Admins`:
```lua
Config.Admins = {
    'license:THEIR_LICENSE_HERE',
}
```
Then run `restart bb_blip_creator`. Done — no full server restart needed.

> 🚀 **Releasing this to your community?** If you used Method 2 with your own license,
> **delete your license line from `Config.Admins`** before you share the resource, so your
> personal license isn't published. Your users will add their own.

> ℹ️ If a non-admin tries to open the menu, the in-game message tells them to check this
> README — so server owners always know where to look.

### "I'm an admin but still get denied" — checklist
1. **You added a `group.admin` line to `server.cfg` but only restarted the resource.**
   → Fully restart the server, **or** paste this into your **live console** to apply it now:
   ```
   add_principal identifier.license:YOUR_LICENSE_HERE group.admin
   ```
2. **You're the txAdmin owner but never set an in-game admin group.** Owning the server in
   txAdmin does **not** grant `group.admin` in-game. Add yourself once (line above).
3. **You're not actually a QBCore/ESX admin.** Set the permission in your framework first.
4. **Need it to work right now, guaranteed?** Put your license straight into `Config.Admins`
   in `config.lua` and run `restart bb_blip_creator`. Because that's a *script* setting, the
   resource restart is enough — no full server restart needed.

> 💡 **Don't know your license?** Set `Config.Debug = true` in `config.lua`, restart the
> resource, run `/blips`, and your server console prints your identifiers and exactly which
> permission check failed. Turn `Config.Debug` back to `false` when you're done.

---

## 🎮 How to use (for admins)

1. Open the menu with the **`/blips`** command (or press **F6** if the keybind is enabled).
2. **Create tab:**
   - Type a **Label** (the name shown on the map).
   - Set the **Location**: click **Use my position** (where you're standing) or
     **Use waypoint** (your map marker), or type X/Y/Z manually.
   - Pick a **sprite** from the grid (search by name or id) — search "108" or "police".
   - Choose a **color** from the palette, or type a color id (0–85).
   - Adjust **Scale** and toggle **Short range** (short range = only visible when you're near it).
   - Watch the **live preview** appear on your map. When it looks right, click **Create blip**.
3. The blip is now **saved and visible to everyone** on the server.
4. **Manage tab:** see all blips. For each one you can **Teleport** to it, **Edit** it, or **Delete** it.
5. Press **ESC** or the ✕ to close.

---

## ⚙️ Configuration (`config.lua`)

| Setting | What it does |
|---|---|
| `Config.Command` | Chat command to open the menu (default `blips` → `/blips`). |
| `Config.OpenKey` | Default keybind (default `F6`). Players can rebind it in **Settings → Key Bindings → FiveM**. |
| `Config.UseKeybind` | `true`/`false` — enable or disable the keybind. |
| `Config.AdminMode` | `auto` (recommended), `ace`, `identifiers`, or `everyone`. |
| `Config.AcePermission` | The ACE used in `ace`/`auto` mode (default `blips.admin`). |
| `Config.AdminGroups` | Framework groups treated as admin in `auto` mode. |
| `Config.Admins` | Always-allowed identifiers (e.g. `license:...`). Works in `auto` and `identifiers`. |
| `Config.Debug` | `true` prints why someone was denied — great for troubleshooting. |
| `Config.DefaultScale/Color/Sprite` | Defaults for a new blip. |
| `Config.MaxLabelLength` | Max characters for a label. |
| `Config.Locale` | All on-screen / notification text + panel title. |

### Admin mode options explained
- **`auto`** *(default, recommended)* — detects txAdmin/QBCore/ESX admins automatically. Zero setup for most servers.
- **`ace`** — only players with the `Config.AcePermission` ACE. Add in `server.cfg`:
  ```
  add_ace group.admin blips.admin allow
  ```
- **`identifiers`** — only the licenses/identifiers you list in `Config.Admins`.
- **`everyone`** — anyone can manage blips. **Not recommended** on public servers.

---

## 🖼️ Real icons are built in

The picker shows the **actual GTA blip icons** for every sprite — bundled inside the resource
at `html/blips/<id>.png`, so it works **fully offline, no browser, no internet**. The icons
are recolored to white to match the dark UI. If a sprite ever has no bundled image, it
gracefully falls back to showing its number, and the live in-world preview is always the
true icon either way.

---

## ❓ Can players upload a photo to make a custom blip?

Short answer: **not as a live in-game upload** — and any script claiming otherwise is faking it.

GTA V can only use blip icons that are **compiled into a texture dictionary** (`.ytd`); the
engine has no way to turn an arbitrary uploaded PNG into a blip at runtime. The proper way to
add custom icons is a **streamed sprite system** (drop images into a `stream/` folder, which
activates on a server restart). That can be added as a **v2**. This version ships with
**800+ real GTA blip sprites** whose IDs and icons match `SetBlipSprite` exactly, covering
the vast majority of needs.

---

## 🧩 Troubleshooting

| Problem | Fix |
|---|---|
| "You do not have permission" but you're an admin | See the **Admin access** section above — usually a server.cfg principal that wasn't loaded (full restart, or run the `add_principal` line in the live console). |
| `/blips` does nothing | Make sure the resource is started (`ensure bb_blip_creator`) and check the F8 console for errors. |
| Blips don't show for other players | They appear on **map/minimap** at the saved coords — open your map (M). Check that `data/blips.json` exists and the resource has write access. |
| Keybind doesn't work | Set it in **Settings → Key Bindings → FiveM**, or use the `/blips` command. `Config.UseKeybind` must be `true`. |
| Want to see why access is denied | Set `Config.Debug = true`, restart resource, run `/blips`, read the server console. |

---

## 📁 File structure
```
bb_blip_creator/
├── fxmanifest.lua      # resource manifest
├── config.lua          # everything you can configure
├── client/main.lua     # blips, live preview, command/keybind
├── server/main.lua     # saving, syncing, admin checks
├── data/blips.json     # auto-created; your saved blips live here
├── html/
│   ├── index.html, style.css, script.js, blips_data.js
│   └── blips/          # 800+ real blip icons (id.png), bundled & offline
├── INSTALL.txt         # 1-minute quick start
└── README.md           # this file
```

---

## 📝 Credits & terms
Made by **Baasha Bhai (BB)** and released **free** to the community. Keep the credits intact.
Enjoy! If you build something cool with it, a shout-out is always appreciated. 💙
