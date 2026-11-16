"""Key-level comparison of a live config file against what Nix declares.

Usage: declared-diff.py --shape SHAPE --snippet KIND DECLARED_JSON LIVE_JSON

Both inputs are JSON (config-drift normalizes TOML/JSONC first). Reports:
  undeclared  -- in the live file, not set by Nix (port it or delete it)
  overridden  -- set by Nix, but the live file holds a different value
  missing     -- set by Nix, absent from the live file
and, with --snippet nix, renders the undeclared/overridden live values as Nix
attribute assignments ready to paste into the declarative source.

--shape object        the file is one JSON object (settings files)
--shape keyed:FIELD   the file is a list of objects merged by FIELD, the way
                      Home Manager merges Zed's keymap.json by "context"

Exit status: 0 = matches, 1 = differences found, 2 = error.
"""

import argparse
import json
import re
import shutil
import subprocess
import sys

INDENT = "    "
MAX_INLINE = 100

NIX_KEYWORDS = {"if", "then", "else", "assert", "with", "let", "in", "rec", "inherit", "or"}
NIX_IDENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_'-]*$")


def merge(a, b):
    """jq's `*`: recursive object merge, right side wins."""
    if isinstance(a, dict) and isinstance(b, dict):
        out = dict(a)
        for key, value in b.items():
            out[key] = merge(out[key], value) if key in out else value
        return out
    return b


def keyed(data, field):
    if not isinstance(data, list):
        raise ValueError(f"expected a JSON list for --shape keyed:{field}")
    out = {}
    for item in data:
        if not isinstance(item, dict):
            raise ValueError("expected a list of JSON objects")
        rest = {k: v for k, v in item.items() if k != field}
        key = item.get(field, "")
        out[key] = merge(out.get(key, {}), rest)
    return out


def compare(declared, live, path, found):
    if isinstance(declared, dict) and isinstance(live, dict) and (declared or live):
        for key in sorted(set(declared) | set(live)):
            sub = path + [key]
            if key not in declared:
                found["undeclared"].append((sub, live[key]))
            elif key not in live:
                found["missing"].append((sub, declared[key]))
            else:
                compare(declared[key], live[key], sub, found)
    elif declared != live:
        found["overridden"].append((path, declared, live))


def show_path(path):
    return ".".join(nix_key(part) for part in path)


def show_value(value):
    text = json.dumps(value, ensure_ascii=False, separators=(", ", ": "))
    return text if len(text) <= MAX_INLINE else text[: MAX_INLINE - 3] + "..."


def nix_key(key):
    key = str(key)
    if NIX_IDENT.match(key) and key not in NIX_KEYWORDS:
        return key
    return nix_string(key)


def nix_string(text):
    escaped = (
        text.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("${", "\\${")
        .replace("\n", "\\n")
        .replace("\r", "\\r")
        .replace("\t", "\\t")
    )
    return f'"{escaped}"'


def nix_value(value):
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return json.dumps(value)
    if isinstance(value, str):
        return nix_string(value)
    if isinstance(value, list):
        return "[ " + " ".join(nix_value(v) for v in value) + " ]"
    if isinstance(value, dict):
        return "{ " + " ".join(f"{nix_key(k)} = {nix_value(v)};" for k, v in value.items()) + " }"
    raise TypeError(f"unsupported JSON value: {value!r}")


def nix_snippet(entries, keyed_field):
    """entries: [(path, live_value)] -> Nix source text (unformatted)."""
    if keyed_field is None:
        body = " ".join(f"{show_path(path)} = {nix_value(value)};" for path, value in entries)
        return "{ " + body + " }"
    # One list element per keyed group, e.g. { context = "..."; bindings.x = ...; }
    groups = {}
    for path, value in entries:
        groups.setdefault(path[0], []).append((path[1:], value))
    items = []
    for key, members in groups.items():
        parts = [f"{nix_key(keyed_field)} = {nix_string(key)};"] if key != "" else []
        for path, value in members:
            if path:
                parts.append(f"{show_path(path)} = {nix_value(value)};")
            else:
                parts.extend(f"{nix_key(k)} = {nix_value(v)};" for k, v in value.items())
        items.append("{ " + " ".join(parts) + " }")
    return "[ " + " ".join(items) + " ]"


def nixfmt(source):
    exe = shutil.which("nixfmt")
    if exe is None:
        return source
    result = subprocess.run([exe], input=source, capture_output=True, text=True)
    return result.stdout.rstrip("\n") if result.returncode == 0 else source


def label(path, keyed_field):
    if keyed_field is not None and path:
        head = f"[{keyed_field}={json.dumps(path[0])}]"
        return head + ("." + show_path(path[1:]) if len(path) > 1 else "")
    return show_path(path) or "(whole file)"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--shape", default="object")
    parser.add_argument("--snippet", default="none", choices=["nix", "none"])
    parser.add_argument("declared")
    parser.add_argument("live")
    args = parser.parse_args()

    keyed_field = None
    if args.shape.startswith("keyed:"):
        keyed_field = args.shape.split(":", 1)[1]
    elif args.shape != "object":
        print(f"  error: unknown shape '{args.shape}'", file=sys.stderr)
        return 2

    try:
        with open(args.declared, encoding="utf-8") as handle:
            declared = json.load(handle)
        with open(args.live, encoding="utf-8") as handle:
            live = json.load(handle)
        if keyed_field is not None:
            declared, live = keyed(declared, keyed_field), keyed(live, keyed_field)
    except (OSError, ValueError) as error:
        print(f"  error: {error}", file=sys.stderr)
        return 2

    found = {"undeclared": [], "overridden": [], "missing": []}
    compare(declared, live, [], found)

    if not any(found.values()):
        print("  vs declared in Nix: matches")
        return 0

    print("  vs declared in Nix:")
    if found["undeclared"]:
        print("    undeclared (live only -- port to Nix or delete from the live file):")
        for path, value in found["undeclared"]:
            print(f"      {label(path, keyed_field)} = {show_value(value)}")
    if found["overridden"]:
        print("    overridden (live value differs from Nix):")
        for path, declared_value, live_value in found["overridden"]:
            print(f"      {label(path, keyed_field)}: nix {show_value(declared_value)} -> live {show_value(live_value)}")
    if found["missing"]:
        print("    missing (declared in Nix, absent from the live file):")
        for path, value in found["missing"]:
            print(f"      {label(path, keyed_field)} = {show_value(value)}")

    portable = [(path, value) for path, value in found["undeclared"]]
    portable += [(path, live_value) for path, _, live_value in found["overridden"]]
    if args.snippet == "nix" and portable:
        print("    live values as Nix (merge into the declarative source):")
        for line in nixfmt(nix_snippet(portable, keyed_field)).splitlines():
            print(f"      {line}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
