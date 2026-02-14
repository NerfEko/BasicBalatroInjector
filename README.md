# Balatro Mod Injector

Standalone mod loader for Balatro. Injects the mod system into the game executable and syncs mods to the game directory—no game source edits required.

## Quick start

```bash
python3 injector.py --game-dir ~/.local/share/Steam/steamapps/common/Balatro
```

Then launch Balatro through Steam. Options → Mods to manage mods.

## Contents

| Path | Description |
|------|-------------|
| `injector.py` | Patches main.lua into Balatro.exe, syncs mods |
| `main.lua` | Patched game entry point (injected into exe) |
| `mods/` | Mod files (modlist.lua, trainer, docs) |
| `mods/MODLIST_API.md` | Full API reference for mod creators |
| `INJECTOR_README.md` | Detailed injector usage |

## Mod development

Edit mods in `mods/`, then re-run the injector to sync. The game loads mods from its own `mods/` folder next to the exe.
