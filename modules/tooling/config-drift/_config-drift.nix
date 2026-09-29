{
  config,
  lib,
  pkgs,
  ...
}:
let
  snapshotDir = "${config.xdg.stateHome}/config-drift/snapshots";

  # baselineKind "generation": the baseline is the file Home Manager links
  # into the current generation's home-files. "snapshot": the file isn't
  # linked by Home Manager but edited in place by an activation step, so the
  # baseline is a copy taken right after activation (see home.activation
  # below).
  mkEntry =
    {
      app,
      format,
      live,
      nixHint,
      note ? null,
      baselineKind ? "generation",
    }:
    let
      baselineRelpath = lib.removePrefix "${config.home.homeDirectory}/" live;
    in
    {
      inherit
        app
        format
        live
        nixHint
        note
        baselineKind
        baselineRelpath
        ;
      baselinePath = if baselineKind == "snapshot" then "${snapshotDir}/${baselineRelpath}" else null;
    };

  claudeEntry = mkEntry {
    app = "claude";
    format = "json";
    live = "${config.home.homeDirectory}/.claude/settings.json";
    nixHint = "modules/home/claude/_claude-code.nix (programs.claude-code.settings)";
    note = "Herdr's \"herdr integration install claude\" activation hook (modules/home/claude/_claude-code.nix) writes into this file after Home Manager links it -- some drift here is expected and not fixable by editing the Nix option above.";
  };

  herdrEntry = mkEntry {
    app = "herdr";
    format = "toml";
    live = "${config.xdg.configHome}/herdr/config.toml";
    nixHint = "modules/home/herdr/_herdr-home.nix (programs.herdr.settings)";
  };

  codexEntry = mkEntry {
    app = "codex";
    format = "toml";
    live = "${config.home.homeDirectory}/.codex/config.toml";
    nixHint = "modules/platforms/wsl/wsl-work-home/codex/_codex.nix (programs.codex.settings)";
    note = "Herdr's \"herdr integration install codex\" activation hook (modules/platforms/wsl/wsl-work-home/codex/_codex.nix) writes into this file after Home Manager links it -- some drift here is expected and not fixable by editing the Nix option above.";
  };

  ccstatuslineEntry = mkEntry {
    app = "ccstatusline";
    format = "json";
    live = "${config.xdg.configHome}/ccstatusline/settings.json";
    nixHint = "modules/home/claude/ccstatusline-settings.json (export from the ccstatusline TUI)";
  };

  # plasma-manager (github:nix-community/plasma-manager) doesn't link its rc
  # files -- its configure-plasma activation step merges the declared keys
  # into the live files in place. Check every file it writes to.
  plasmaFiles =
    let
      cfg = config.programs.plasma;
      under = prefix: attrs: map (path: "${prefix}/${path}") (builtins.attrNames attrs);
    in
    under config.home.homeDirectory cfg.file
    ++ under config.xdg.configHome cfg.configFile
    ++ under config.xdg.dataHome cfg.dataFile;

  plasmaEntries = map (
    live:
    mkEntry {
      app = "plasma";
      format = "kconfig";
      baselineKind = "snapshot";
      inherit live;
      nixHint = "modules/home/plasma/_plasma.nix (shared) or modules/hosts/<host>/plasma/_plasma.nix (per-host delta)";
      note = "Baseline is this file as plasma-manager left it at the last switch, so this shows every change since then, declared key or not (plasma-manager's own login-time theme scripts can show up here too). The next switch only resets keys declared in Nix -- undeclared changes stay live but drop out of this report. \"nix run github:nix-community/plasma-manager\" (rc2nix) renders the live Plasma config as programs.plasma Nix.";
    }
  ) plasmaFiles;

  entries =
    lib.optionals config.my.features.claude [
      claudeEntry
      ccstatuslineEntry
    ]
    ++ lib.optional config.my.features.herdr herdrEntry
    ++ lib.optional config.my.features.wslCodex codexEntry
    # my.features.plasma only exists when the plasma-manager input does.
    ++ lib.optionals (config.my.features.plasma or false) plasmaEntries;

  enabled = entries != [ ];

  snapshotEntries = builtins.filter (entry: entry.baselineKind == "snapshot") entries;

  manifestFile = pkgs.writeText "config-drift-manifest.json" (
    builtins.toJSON config.my.configDrift.entries
  );

  normalizeTomlPy = pkgs.writeText "config-drift-normalize-toml.py" ''
    import json
    import sys
    import tomllib

    with open(sys.argv[1], "rb") as handle:
        data = tomllib.load(handle)
    print(json.dumps(data, indent=2, sort_keys=True))
  '';

  # KConfig INI -> one fully qualified "[group][sub] key=value" line per key,
  # sorted, so diff lines stand alone without needing the group header as
  # context and key order/blank lines don't show up as noise. Values are
  # reduced to what plasma-manager actually declares, so KDE's runtime
  # rewrites of the same setting don't show up as drift.
  normalizeKconfigPy = pkgs.writeText "config-drift-normalize-kconfig.py" ''
    import os
    import re
    import sys

    # kglobalshortcutsrc values are "active,default,description". plasma-manager
    # writes only the active field ("Meta+D,,") and kglobalaccel fills in the
    # other two at login, so only the active field is declarative.
    shortcuts = os.path.basename(sys.argv[1]) == "kglobalshortcutsrc"


    def unescape(value):
        # plasma-manager writes some characters as \xNN ("Meta+\x3d"); KDE
        # rewrites them literally ("Meta+="). Compare the decoded form.
        return re.sub(r"\\x([0-9a-fA-F]{2})", lambda m: chr(int(m.group(1), 16)), value)


    group = ""
    lines = []
    with open(sys.argv[1], encoding="utf-8") as handle:
        for raw in handle:
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            if re.match(r"^\[.*\]$", line):
                group = line
                continue
            key, sep, value = line.partition("=")
            key = key.strip()
            value = value.strip()
            if shortcuts and key != "_k_friendly_name":
                value = re.split(r"(?<!\\),", value, maxsplit=1)[0]
            lines.append(f"{group} {key}{sep}{unescape(value)}".lstrip())
    for line in sorted(lines):
        print(line)
  '';

  configDriftPackage = pkgs.writeShellApplication {
    name = "config-drift";
    runtimeInputs = with pkgs; [
      coreutils
      diffutils
      jq
      python3
    ];
    text = ''
      manifest="${manifestFile}"
      gen_root="$HOME/.local/state/home-manager/gcroots/current-home"

      if [ ! -e "$gen_root" ]; then
        echo "config-drift: no home-manager generation found at $gen_root" >&2
        exit 1
      fi
      gen="$(readlink -f "$gen_root")"

      normalize_json() {
        jq -S . "$1"
      }

      normalize_toml() {
        python3 ${normalizeTomlPy} "$1"
      }

      normalize_kconfig() {
        python3 ${normalizeKconfigPy} "$1"
      }

      drifted=0
      failed=0
      count=$(jq 'length' "$manifest")

      for ((i = 0; i < count; i++)); do
        entry=$(jq -c ".[$i]" "$manifest")
        app=$(jq -r '.app' <<<"$entry")
        format=$(jq -r '.format' <<<"$entry")
        live=$(jq -r '.live' <<<"$entry")
        kind=$(jq -r '.baselineKind' <<<"$entry")
        relpath=$(jq -r '.baselineRelpath' <<<"$entry")
        hint=$(jq -r '.nixHint' <<<"$entry")
        note=$(jq -r '.note // empty' <<<"$entry")

        if [ ! -e "$live" ]; then
          continue
        fi

        echo "== $app: $relpath =="

        case "$kind" in
          generation)
            baseline="$gen/home-files/$relpath"
            ;;
          snapshot)
            baseline=$(jq -r '.baselinePath' <<<"$entry")
            ;;
          *)
            echo "  error: unknown baseline kind '$kind'" >&2
            echo
            failed=1
            continue
            ;;
        esac
        if [ ! -e "$baseline" ]; then
          echo "  warning: no $kind baseline found ($baseline) -- switch once to create it" >&2
          echo
          failed=1
          continue
        fi
        resolved_baseline="$(readlink -f "$baseline")"

        # writeShellApplication runs with errexit, so a malformed live/baseline
        # file must not abort the whole run -- every normalize call that can
        # fail is guarded by `if !` and reported per-entry instead.
        case "$format" in
          json)
            if ! base_norm=$(normalize_json "$resolved_baseline"); then
              echo "  error: failed to parse baseline ($resolved_baseline)" >&2
              echo
              failed=1
              continue
            fi
            if ! live_norm=$(normalize_json "$live"); then
              echo "  error: failed to parse live file ($live)" >&2
              echo
              failed=1
              continue
            fi
            ;;
          toml)
            if ! base_norm=$(normalize_toml "$resolved_baseline"); then
              echo "  error: failed to parse baseline ($resolved_baseline)" >&2
              echo
              failed=1
              continue
            fi
            if ! live_norm=$(normalize_toml "$live"); then
              echo "  error: failed to parse live file ($live)" >&2
              echo
              failed=1
              continue
            fi
            ;;
          kconfig)
            if ! base_norm=$(normalize_kconfig "$resolved_baseline"); then
              echo "  error: failed to parse baseline ($resolved_baseline)" >&2
              echo
              failed=1
              continue
            fi
            if ! live_norm=$(normalize_kconfig "$live"); then
              echo "  error: failed to parse live file ($live)" >&2
              echo
              failed=1
              continue
            fi
            ;;
          *)
            echo "  error: unknown format '$format'" >&2
            echo
            failed=1
            continue
            ;;
        esac

        if diff_output=$(diff -u --label "baseline ($relpath)" --label "live ($live)" <(printf '%s\n' "$base_norm") <(printf '%s\n' "$live_norm")); then
          echo "  no drift"
        else
          echo "$diff_output"
          if [ -n "$note" ]; then
            echo "  note: $note"
          fi
          echo "  -> declarative source: $hint"
          drifted=1
        fi
        echo
      done

      if [ "$failed" -eq 1 ]; then
        exit 2
      elif [ "$drifted" -eq 1 ]; then
        exit 1
      else
        exit 0
      fi
    '';
  };
in
{
  options.my.configDrift = {
    entries = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            app = lib.mkOption { type = lib.types.str; };
            format = lib.mkOption {
              type = lib.types.enum [
                "json"
                "toml"
                "kconfig"
              ];
            };
            live = lib.mkOption { type = lib.types.str; };
            baselineKind = lib.mkOption {
              type = lib.types.enum [
                "generation"
                "snapshot"
              ];
              default = "generation";
            };
            baselineRelpath = lib.mkOption { type = lib.types.str; };
            baselinePath = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            nixHint = lib.mkOption { type = lib.types.str; };
            note = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
          };
        }
      );
      default = [ ];
      description = "Mutable config files to check for drift against their declarative Home Manager baseline.";
    };
    package = lib.mkOption {
      type = lib.types.package;
      description = "The config-drift CLI derivation.";
    };
  };

  config = {
    my.configDrift.package = configDriftPackage;
    my.configDrift.entries = lib.mkIf enabled entries;
    home.packages = lib.mkIf enabled [ configDriftPackage ];

    # Refresh snapshot baselines once plasma-manager has rewritten its files.
    # (entryAfter a step that doesn't exist on this host is ignored.)
    home.activation.configDriftSnapshot = lib.mkIf (snapshotEntries != [ ]) (
      lib.hm.dag.entryAfter [ "writeBoundary" "configure-plasma" ] (
        lib.concatMapStringsSep "\n" (entry: ''
          if [ -f ${lib.escapeShellArg entry.live} ]; then
            run mkdir -p ${lib.escapeShellArg (dirOf entry.baselinePath)}
            run cp ${lib.escapeShellArg entry.live} ${lib.escapeShellArg entry.baselinePath}
          else
            run rm -f ${lib.escapeShellArg entry.baselinePath}
          fi
        '') snapshotEntries
      )
    );
  };
}
