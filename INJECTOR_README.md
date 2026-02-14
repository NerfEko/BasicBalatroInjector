# Balatro Mod Injector

Patches the mod loader into `Balatro.exe` and syncs mods to the game directory. The game files are embedded inside the executable as a zip archive; this script replaces `main.lua` in that archive.

## Project layout

```
balatro-injector/
  injector.py      # Run this to install
  main.lua         # Patched entry point (injected into exe)
  mods/            # Mod files (synced to game dir)
    modlist.lua
    trainer.lua
    README.md
    MODLIST_API.md
  INJECTOR_README.md
```

## Requirements

- Python 3.6+
- No extra packages (standard library only)

## Usage

From this project directory:

```bash
python3 injector.py --game-dir /path/to/Balatro
```

Example (Steam on Linux):

```bash
python3 injector.py --game-dir ~/.local/share/Steam/steamapps/common/Balatro
```

### Options

| Option | Description |
|--------|-------------|
| `--game-dir` | Balatro game directory (where `Balatro.exe` lives). Required when not running from the game dir. |
| `--main-lua` | Path to modified main.lua (default: `main.lua` in this folder) |
| `--exe` | Executable name (default: `Balatro.exe`) |

## What it does

1. Syncs `mods/` from this project to `{game-dir}/mods/`
2. Finds the zip archive embedded in `Balatro.exe` (Love2D fused format)
3. Extracts it, replaces `main.lua` with the modified version
4. Repacks and writes back to the exe
5. Creates `Balatro.exe.bak` before modifying

## Restore original

To undo the injection:

```bash
cp Balatro.exe.bak Balatro.exe
```

Or verify game files in Steam (right-click Balatro → Properties → Installed Files → Verify integrity).

## After game updates

Steam will overwrite the exe when the game updates. Re-run the injector:

```bash
python3 injector.py --game-dir ~/.local/share/Steam/steamapps/common/Balatro
```
