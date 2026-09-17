{
  config,
  lib,
  pkgs,
  ...
}:
let
  enabled = config.my.features.claude || config.my.features.herdr || config.my.features.wslCodex;

  mkEntry =
    {
      app,
      format,
      live,
      nixHint,
      note ? null,
    }:
    {
      inherit
        app
        format
        live
        nixHint
        note
        ;
      baselineRelpath = lib.removePrefix "${config.home.homeDirectory}/" live;
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

  entries =
    lib.optional config.my.features.claude claudeEntry
    ++ lib.optional config.my.features.herdr herdrEntry
    ++ lib.optional config.my.features.wslCodex codexEntry;

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

      drifted=0
      failed=0
      count=$(jq 'length' "$manifest")

      for ((i = 0; i < count; i++)); do
        entry=$(jq -c ".[$i]" "$manifest")
        app=$(jq -r '.app' <<<"$entry")
        format=$(jq -r '.format' <<<"$entry")
        live=$(jq -r '.live' <<<"$entry")
        relpath=$(jq -r '.baselineRelpath' <<<"$entry")
        hint=$(jq -r '.nixHint' <<<"$entry")
        note=$(jq -r '.note // empty' <<<"$entry")

        if [ ! -e "$live" ]; then
          continue
        fi

        echo "== $app: $relpath =="

        baseline="$gen/home-files/$relpath"
        if [ ! -e "$baseline" ]; then
          echo "  warning: no baseline found in current generation ($baseline)" >&2
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
              ];
            };
            live = lib.mkOption { type = lib.types.str; };
            baselineRelpath = lib.mkOption { type = lib.types.str; };
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
  };
}
