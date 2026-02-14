# BasicBalatroInjector

mod loader for balatro. patches the exe, no source edits. python 3.6+, stdlib only.

Also contains an optional modmenu and trainer in `mods/` 

## run it

```bash
python3 injector.py --game-dir /path/to/Balatro
```

linux steam:
```bash
python3 injector.py --game-dir ~/.local/share/Steam/steamapps/common/Balatro
```

then launch the game. options → mods.

## what it does

1. copies `mods/` into the game folder
2. patches `main.lua` into `Balatro.exe` (love2d fused exe = exe + zip, we swap the main.lua in the zip)
3. backs up the exe as `Balatro.exe.bak` first

## undo

```bash
cp Balatro.exe.bak Balatro.exe
```

or steam → right-click balatro → manage → verify integrity.

## game updated?

steam overwrites the exe. just run the injector again.

## layout

```
  injector.py   — run this
  main.lua      — gets injected
  mods/
    modlist.lua — loader (don't touch)
    trainer.lua — example (cheats, T key in-game)
```

## options

`--game-dir` — where Balatro.exe lives (required)
`--main-lua` — path to main.lua (default: ./main.lua)
`--exe` — exe name (default: Balatro.exe)

---

## making mods

put `.lua` files in `mods/`. they load automatically. don't touch `modlist.lua`.

### api

**Modlist.register(id, data)** — show up in options → mods. `data`: `name`, `enabled`, `settings_func` (string, e.g. `"my_settings"`).

**Modlist.patch(env, name, wrapper)** — wrap any game function. `wrapper(orig, ...)` gets the original; call `orig(...)` to run it. use for keybinds, ui changes, whatever.

**Modlist.hook(name, callback)** — run code at specific points. hooks: `options_menu_contents` → `(contents, insert_at)` to add stuff before the mods button.

### examples

keybind only:
```lua
Modlist.register("quick_save", { name = "Quick Save", enabled = true })
Modlist.patch(Controller, "key_press_update", function(orig, self, key, dt)
  if key == "f5" and G.STAGE == G.STAGES.RUN then G:save_progress(); return end
  return orig(self, key, dt)
end)
```

add options menu button:
```lua
Modlist.hook("options_menu_contents", function(contents, insert_at)
  table.insert(contents, insert_at, UIBox_button{
    label = {"My Option"}, button = "my_option", minw = 5, colour = G.C.BLUE,
  })
end)
G.FUNCS.my_option = function() -- your logic end
```

mod with settings overlay:
```lua
Modlist.register("my_mod", { name = "My Mod", enabled = true, settings_func = "my_mod_settings" })
G.FUNCS.my_mod_settings = function()
  G.SETTINGS.paused = true
  G.FUNCS.overlay_menu{ definition = create_UIBox_generic_options({
    back_func = "exit_overlay_menu",
    contents = {
      {n = G.UIT.R, config = {align = "cm", padding = 0.12}, nodes = {
        {n = G.UIT.T, config = {text = "My Mod", scale = 0.55, colour = G.C.WHITE}}
      }},
      {n = G.UIT.R, config = {align = "cm", padding = 0.06}, nodes = {
        UIBox_button{ label = {"Do Thing"}, button = "my_mod_do", minw = 2.5, minh = 0.5, scale = 0.38, colour = G.C.BLUE, text_colour = G.C.WHITE },
      }},
    },
  })}
end
```

check if mod enabled:
```lua
if G.MODS.registry.my_mod and G.MODS.registry.my_mod.enabled then ... end
```

defer action (if overlay breaks things like G.HUD):
```lua
G.FUNCS.my_cheat = function()
  G.FUNCS.exit_overlay_menu()
  G.E_MANAGER:add_event(Event({ trigger = "after", delay = 0.05, func = function()
    if G.STAGE == G.STAGES.RUN then ease_dollars(10) end
    return true
  end}))
end
```

### globals

stages: `G.STAGE == G.STAGES.RUN` (in run), `G.STAGES.MAIN_MENU`, `G.STAGES.BLIND_SELECT`

useful: `G`, `G.FUNCS`, `G.MODS.registry`, `G.GAME`, `G.P_CENTERS`, `G.P_BLINDS`, `G.P_TAGS`, `G.P_SEALS`, `G.E_MANAGER`, `Event`, `UIBox_button`, `create_toggle`, `create_UIBox_generic_options`, `Sprite`, `G.ASSET_ATLAS`, `G.UIT`, `G.C`

ui nodes: `G.UIT.R` (row), `G.UIT.C` (col), `G.UIT.T` (text), `G.UIT.O` (sprite). wrap in `{n = ..., config = {...}, nodes = {...}}`

### troubleshooting

- mod doesn't load → `*.lua` not `modlist.lua`, check console for `[modlist] Error`
- crash on action → close overlay first, defer with `G.E_MANAGER:add_event`
- button does nothing → `G.FUNCS.your_button` must exist
- patch fails "not a function" → function might not exist yet at load time
