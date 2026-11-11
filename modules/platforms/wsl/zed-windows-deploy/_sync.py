"""Apply Nix-rendered Zed files to the Windows user's mutable profile."""

import json
import os
import pathlib
import sys
import tempfile

import json5


def merge(existing, declared):
    for key, value in declared.items():
        if isinstance(value, dict) and isinstance(existing.get(key), dict):
            merge(existing[key], value)
        else:
            existing[key] = value
    return existing


def write_if_changed(path, content):
    if path.exists() and path.read_text(encoding="utf-8") == content:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        mode="w", encoding="utf-8", dir=path.parent, prefix=f".{path.name}.", delete=False
    ) as handle:
        temporary = pathlib.Path(handle.name)
        handle.write(content)
    try:
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def main():
    target, settings_file, keymap_file, theme_file = map(pathlib.Path, sys.argv[1:])
    declared = json.loads(settings_file.read_text(encoding="utf-8"))
    settings_path = target / "settings.json"
    existing = json5.loads(settings_path.read_text(encoding="utf-8")) if settings_path.exists() else {}
    if not isinstance(existing, dict):
        raise ValueError(f"{settings_path} must contain a JSON object")

    settings = merge(existing, declared)
    write_if_changed(settings_path, json.dumps(settings, indent=2, ensure_ascii=False) + "\n")
    write_if_changed(target / "keymap.json", keymap_file.read_text(encoding="utf-8") + "\n")
    write_if_changed(
        target / "themes" / "party-owl-84.json", theme_file.read_text(encoding="utf-8") + "\n"
    )


if __name__ == "__main__":
    main()
