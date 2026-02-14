#!/usr/bin/env python3
"""
Balatro Mod Injector

Patches main.lua into Balatro.exe. Balatro is a Love2D fused executable:
the exe is [PE binary][zip archive]. This script replaces main.lua inside
the embedded zip with your modified version (containing the mod loader).

Usage:
  python injector.py
  python injector.py --game-dir /path/to/Balatro
  python injector.py --game-dir /path/to/Balatro --main-lua /path/to/main.lua

Run from the Balatro game directory, or use --game-dir. Creates a backup
(Balatro.exe.bak) before modifying.
"""

import argparse
import io
import os
import shutil
import struct
import sys
import tempfile
import zipfile
from pathlib import Path

# Zip End of Central Directory signature
EOCD_SIG = 0x06054B50  # "PK\x05\x06" little-endian


def find_zip_offset(data: bytes) -> int:
    """Find where the zip archive starts in a fused Love2D executable."""
    # EOCD is at the end; it can have a comment (up to 64KB). Search backwards.
    search_start = max(0, len(data) - 65557)  # 22 + 65535
    sig_bytes = struct.pack("<I", EOCD_SIG)
    pos = data.rfind(sig_bytes)
    if pos == -1:
        raise ValueError("Could not find zip EOCD signature in executable")
    # EOCD structure: sig(4) + disk(2) + disk_cd(2) + num_this(2) + num_total(2)
    #                 + central_size(4) + central_offset(4) + comment_len(2) + comment
    central_size = struct.unpack("<I", data[pos + 12 : pos + 16])[0]
    central_offset = struct.unpack("<I", data[pos + 16 : pos + 20])[0]
    zip_start = pos - central_size - central_offset
    if zip_start < 0:
        raise ValueError("Invalid zip structure: negative zip start")
    return zip_start


def inject(game_dir: Path, main_lua_path: Path, exe_name: str = "Balatro.exe") -> None:
    """Inject main.lua into the game executable."""
    exe_path = game_dir / exe_name
    if not exe_path.exists():
        raise FileNotFoundError(f"Executable not found: {exe_path}")
    if not main_lua_path.exists():
        raise FileNotFoundError(f"main.lua not found: {main_lua_path}")

    with open(exe_path, "rb") as f:
        data = bytearray(f.read())

    zip_start = find_zip_offset(data)
    pe_part = data[:zip_start]
    zip_data = bytes(data[zip_start:])

    # Extract zip to temp dir
    with tempfile.TemporaryDirectory() as tmpdir:
        tmp = Path(tmpdir)
        with zipfile.ZipFile(io.BytesIO(zip_data), "r") as zf:
            zf.extractall(tmp)

        # Replace main.lua
        target_main = tmp / "main.lua"
        if not target_main.exists():
            raise FileNotFoundError(
                "main.lua not found in game archive - is this a valid Balatro exe?"
            )
        shutil.copy(main_lua_path, target_main)

        # Create new zip in memory
        new_zip_buf = io.BytesIO()
        with zipfile.ZipFile(new_zip_buf, "w", zipfile.ZIP_DEFLATED) as zf:
            for root, _, files in os.walk(tmp):
                for name in files:
                    path = Path(root) / name
                    arcname = path.relative_to(tmp)
                    zf.write(path, arcname)

        new_zip_data = new_zip_buf.getvalue()

    # Backup
    backup_path = exe_path.with_suffix(exe_path.suffix + ".bak")
    if backup_path.exists():
        os.remove(backup_path)
    shutil.copy(exe_path, backup_path)

    # Write patched exe
    with open(exe_path, "wb") as f:
        f.write(pe_part)
        f.write(new_zip_data)

    print(f"Injected {main_lua_path} into {exe_path}")
    print(f"Backup saved to {backup_path}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Inject mod loader into Balatro.exe")
    parser.add_argument(
        "--game-dir",
        type=Path,
        default=None,
        help="Balatro game directory (default: parent of script, or cwd)",
    )
    parser.add_argument(
        "--main-lua",
        type=Path,
        default=None,
        help="Path to modified main.lua (default: export/main.lua next to game dir)",
    )
    parser.add_argument(
        "--exe",
        default="Balatro.exe",
        help="Executable name (default: Balatro.exe)",
    )
    args = parser.parse_args()

    # Resolve game dir: explicit, or parent of script, or cwd
    script_dir = Path(__file__).resolve().parent
    if args.game_dir:
        game_dir = Path(args.game_dir).resolve()
    elif (script_dir.parent / "Balatro.exe").exists():
        game_dir = script_dir.parent
    else:
        game_dir = Path.cwd()

    # Resolve main.lua: explicit, or script dir, or game dir/export
    if args.main_lua:
        main_lua = Path(args.main_lua).resolve()
    elif (script_dir / "main.lua").exists():
        main_lua = script_dir / "main.lua"
    else:
        main_lua = game_dir / "export" / "main.lua"

    # Sync mods from project to game dir (if mods/ exists in project)
    mods_src = script_dir / "mods"
    mods_dst = game_dir / "mods"
    if mods_src.exists():
        mods_dst.mkdir(parents=True, exist_ok=True)
        for f in mods_src.iterdir():
            dst = mods_dst / f.name
            if f.is_file():
                shutil.copy2(f, dst)
            elif f.is_dir():
                if dst.exists():
                    shutil.rmtree(dst)
                shutil.copytree(f, dst)
        print(f"Synced mods to {mods_dst}")

    try:
        inject(game_dir, main_lua, args.exe)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
