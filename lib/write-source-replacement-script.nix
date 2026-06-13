{ pkgs }:
{
  scriptName,
  replacements,
  defaultFile ? null,
}:
let
  replacementManifest = pkgs.writeText "${scriptName}.json" (builtins.toJSON replacements);
in
pkgs.writeText "${scriptName}.py" ''
  import json
  import pathlib
  import re
  import sys

  replacements = json.loads(pathlib.Path("${replacementManifest}").read_text())
  default_file = ${builtins.toJSON defaultFile}

  grouped = {}
  for replacement in replacements:
      file_name = replacement.get("file", default_file)
      if not file_name:
          print(f"replacement missing file target: {replacement['reason']}", file=sys.stderr)
          sys.exit(1)
      grouped.setdefault(file_name, []).append(replacement)

  for file_name, file_replacements in grouped.items():
      path = pathlib.Path(file_name)
      text = path.read_text(encoding="utf-8")

      for replacement in file_replacements:
          kind = replacement.get("kind", "literal")
          min_count = replacement.get("minCount", replacement.get("expectedCount", 1))
          max_count = replacement.get("maxCount", replacement.get("expectedCount", 1))

          if kind == "literal":
              old = replacement["old"]
              count = text.count(old)
              if count < min_count or count > max_count:
                  print(
                      f"unexpected match count in {file_name}: {replacement['reason']}",
                      file=sys.stderr,
                  )
                  print(f"expected between {min_count} and {max_count}, found {count}", file=sys.stderr)
                  print(old, file=sys.stderr)
                  sys.exit(1)
              if count != 0:
                  text = text.replace(old, replacement["new"], count)
              continue

          if kind == "regex":
              text, count = re.subn(
                  replacement["pattern"],
                  replacement["replacement"],
                  text,
                  count=max_count,
              )
              if count < min_count or count > max_count:
                  print(
                      f"failed to apply patch in {file_name}: {replacement['reason']}",
                      file=sys.stderr,
                  )
                  print(f"expected between {min_count} and {max_count}, found {count}", file=sys.stderr)
                  sys.exit(1)
              continue

          print(f"unsupported replacement kind '{kind}' in {file_name}", file=sys.stderr)
          sys.exit(1)

      path.write_text(text, encoding="utf-8")
''
