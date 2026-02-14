# BasicBalatroInjector

mod loader for balatro. patches the exe, no source edits. python 3.6+, stdlib only.

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

## making mods

put `.lua` files in `mods/`. `modlist.lua` is the loader (don't touch). everything else gets loaded. see `mods/MODLIST_API.md` for the api.

## layout

```
  injector.py   — run this
  main.lua      — gets injected
  mods/
    modlist.lua — loader + api
    trainer.lua — example (cheats, T key in-game)
    MODLIST_API.md
```

## options

`--game-dir` — where Balatro.exe lives (required)
`--main-lua` — path to main.lua (default: ./main.lua)
`--exe` — exe name (default: Balatro.exe)
