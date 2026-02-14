# Modlist API Reference

Modlist lets you change Balatro without editing game files. Place `.lua` mods in the `mods/` folder; they load automatically (except `modlist.lua`).

---

## API Reference

### `Modlist.register(id, data)`

Register your mod so it appears in the Mods menu with an enable toggle and optional settings button.

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique mod identifier (e.g. `"my_mod"`) |
| `data.name` | string | Display name in the Mods menu |
| `data.enabled` | boolean | Default enabled state |
| `data.settings_func` | string | Name of a function in `G.FUNCS` to open settings (e.g. `"my_mod_settings"`) |

```lua
Modlist.register("my_mod", {
  name = "My Mod",
  enabled = true,
  settings_func = "my_mod_settings",
})

G.FUNCS.my_mod_settings = function()
  G.SETTINGS.paused = true
  G.FUNCS.overlay_menu{ definition = create_UIBox_my_mod_settings() }
end
```

---

### `Modlist.patch(env, name, wrapper)`

Wrap any game function. Use this to add keybinds, change UI, or intercept logic.

| Param | Description |
|-------|--------------|
| `env` | Table containing the function (`_G` for globals, or e.g. `Controller`) |
| `name` | Function name as string |
| `wrapper` | `function(orig, ...)` — call `orig(...)` to invoke the original |

```lua
-- Patch a global function
Modlist.patch(_G, "create_UIBox_main_menu_buttons", function(orig)
  local t = orig()
  -- modify t, then return
  return t
end)

-- Patch a method (e.g. Controller)
Modlist.patch(Controller, "key_press_update", function(orig, self, key, dt)
  if key == "m" then
    my_handler()
    return  -- don't call original
  end
  return orig(self, key, dt)
end)
```

---

### `Modlist.hook(name, callback)`

Register a callback for a named hook. Modlist fires hooks at specific points so you can inject UI or logic without patching.

| Hook | Arguments | Description |
|------|-----------|-------------|
| `options_menu_contents` | `(contents, insert_at)` | Add items to the Options menu. `contents` is the nodes table; insert at index `insert_at` (before the Mods button). |

```lua
Modlist.hook("options_menu_contents", function(contents, insert_at)
  table.insert(contents, insert_at, UIBox_button{
    label = {"My Option"},
    button = "my_option",
    minw = 5,
    colour = G.C.BLUE,
  })
end)
```

---

## Examples

### Minimal mod (keybind only)

```lua
Modlist.register("quick_save", {
  name = "Quick Save",
  enabled = true,
})

Modlist.patch(Controller, "key_press_update", function(orig, self, key, dt)
  if key == "f5" and G.STAGE == G.STAGES.RUN then
    G:save_progress()
    return
  end
  return orig(self, key, dt)
end)
```

### Add an Options menu button

```lua
Modlist.register("dark_mode", {
  name = "Dark Mode",
  enabled = false,
  settings_func = "dark_mode_settings",
})

Modlist.hook("options_menu_contents", function(contents, insert_at)
  table.insert(contents, insert_at, UIBox_button{
    label = {"Dark Mode"},
    button = "dark_mode_toggle",
    minw = 5,
    colour = G.C.BLACK,
  })
end)

G.FUNCS.dark_mode_toggle = function()
  -- your logic
end
```

### Mod with settings overlay

```lua
local MOD_ID = "my_mod"

Modlist.register(MOD_ID, {
  name = "My Mod",
  enabled = true,
  settings_func = "my_mod_settings",
})

local function create_UIBox_my_mod_settings()
  return create_UIBox_generic_options({
    back_func = "exit_overlay_menu",
    contents = {
      {n = G.UIT.R, config = {align = "cm", padding = 0.12}, nodes = {
        {n = G.UIT.T, config = {text = "My Mod Settings", scale = 0.55, colour = G.C.WHITE, shadow = true}}
      }},
      {n = G.UIT.R, config = {align = "cm", padding = 0.06}, nodes = {
        UIBox_button{ label = {"Do Something"}, button = "my_mod_action", minw = 2.5, minh = 0.5, scale = 0.38, colour = G.C.BLUE, text_colour = G.C.WHITE },
      }},
    },
  })
end

G.FUNCS.my_mod_settings = function()
  G.SETTINGS.paused = true
  G.FUNCS.overlay_menu{ definition = create_UIBox_my_mod_settings() }
end
```

### Check if mod is enabled before acting

```lua
Modlist.patch(Controller, "key_press_update", function(orig, self, key, dt)
  if key == "t" and G.MODS.registry.my_mod and G.MODS.registry.my_mod.enabled then
    if G.STAGE == G.STAGES.RUN and not G.OVERLAY_MENU then
      G.FUNCS.my_mod_settings()
      return
    end
  end
  return orig(self, key, dt)
end)
```

### Defer action until overlay is closed

If your action needs `G.HUD` or other UI that breaks while an overlay is open, close the overlay first and run on the next frame:

```lua
G.FUNCS.my_mod_cheat = function()
  G.FUNCS.exit_overlay_menu()
  G.E_MANAGER:add_event(Event({
    trigger = "after",
    delay = 0.05,
    func = function()
      if G.STAGE == G.STAGES.RUN then
        ease_dollars(10)  -- or your logic
      end
      return true
    end
  }))
end
```

---

## Game State & Globals

### Stages

| Value | Description |
|-------|-------------|
| `G.STAGE == G.STAGES.RUN` | In an active run |
| `G.STAGE == G.STAGES.MAIN_MENU` | Main menu / collection |
| `G.STAGE == G.STAGES.BLIND_SELECT` | Choosing blind |

### Common globals

| Global | Description |
|--------|-------------|
| `G` | Game state, settings, functions |
| `G.FUNCS` | Button callbacks; add entries for `button = "my_func"` |
| `G.MODS.registry` | Registered mods (`id` → `{name, enabled, settings_func}`) |
| `G.STAGE`, `G.STAGES` | Current stage |
| `G.STATE`, `G.STATES` | Game state |
| `G.GAME` | Current run data (nil when not in run) |
| `G.P_CENTERS` | Jokers, Tarots, Planets, etc. |
| `G.P_BLINDS`, `G.P_TAGS`, `G.P_SEALS` | Blinds, tags, seals |
| `G.E_MANAGER` | Event queue; use `add_event(Event{...})` |
| `Event` | Event constructor |
| `UIBox_button` | Create a button node |
| `create_toggle` | Create a toggle/checkbox |
| `create_UIBox_generic_options` | Create an options-style overlay |
| `Sprite` | Sprite constructor |
| `G.ASSET_ATLAS` | Sprite atlases (e.g. `["icons"]`) |
| `G.UIT` | UI node types: `R`, `C`, `T`, `O`, `B` |
| `G.C` | Colors: `WHITE`, `BLACK`, `RED`, `GREEN`, `BLUE`, `PURPLE`, `ORANGE`, `CLEAR`, `UI.TEXT_LIGHT`, etc. |

### UI node structure

```lua
{n = G.UIT.R, config = {align = "cm", padding = 0.05}, nodes = { ... }}  -- row
{n = G.UIT.C, config = {align = "cm", padding = 0.05}, nodes = { ... }}  -- column
{n = G.UIT.T, config = {text = "Label", scale = 0.4, colour = G.C.WHITE}}
{n = G.UIT.O, config = {object = my_sprite}}
```

### Button config

```lua
UIBox_button{
  label = {"Button Text"},
  button = "func_name",   -- G.FUNCS.func_name
  minw = 2, minh = 0.5,
  scale = 0.4,
  colour = G.C.BLUE,
  text_colour = G.C.WHITE,
}
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Mod doesn't load | Check filename is `*.lua` and not `modlist.lua`. Check console for `[modlist] Error loading ...` |
| Game crashes on action | If triggered from an overlay, close it first and defer with `G.E_MANAGER:add_event` |
| Button does nothing | Ensure `G.FUNCS.your_button_name` exists and is a function |
| Settings button opens wrong menu | `settings_func` must match a key in `G.FUNCS` |
| Patch fails with "is not a function" | The function may not exist yet when your mod loads; patch after the game has initialized, or patch a function that's defined before mods load |
