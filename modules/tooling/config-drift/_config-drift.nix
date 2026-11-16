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
  #
  # declared: what the live file is compared against key by key ("vs
  # declared in Nix"), so keys tried out at runtime stay listed until they're
  # ported to Nix or deleted. "baseline" reuses the generation file, which is
  # exactly what Nix declares when Home Manager writes the whole file; a store
  # path names the values a merge step layers into the file (Zed); null skips
  # the check (Plasma). shape/snippet: see _declared-diff.py.
  mkEntry =
    {
      app,
      format,
      live,
      nixHint,
      note ? null,
      baselineKind ? "generation",
      declared ? if baselineKind == "generation" then "baseline" else null,
      shape ? "object",
      snippet ? "nix",
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
        declared
        shape
        snippet
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
    # Declared as a JSON export, not Nix attrs.
    snippet = "none";
  };

  # With mutableUser* (the default) Home Manager doesn't link Zed's files --
  # its zed*Activation steps merge the declared values into the live files in
  # place, so the baseline is a post-activation snapshot like plasma's. Zed
  # accepts comments/trailing commas, hence "jsonc".
  zedCfg = config.programs.zed-editor;
  activation = config.home.activation;

  # The declared side of a Zed file is the JSON Home Manager's merge step
  # layers into it. For settings that's userSettings plus the
  # auto_install_extensions and context_servers (MCP) entries the module adds
  # itself, so it's read from the merge step rather than rebuilt here: the
  # step's script is the only place the generated file's path appears.
  # Only the manifest may force this: the entry list itself feeds
  # home.activation.configDriftSnapshot below, so deciding which entries
  # exist from home.activation would recurse.
  zedStatic =
    step: name:
    let
      found = lib.filter lib.isList (
        builtins.split "(${builtins.storeDir}/[a-z0-9]{32}-${name})" activation.${step}.data
      );
    in
    if !(activation ? ${step}) then
      null
    else if found == [ ] then
      throw "config-drift: no ${name} store path in home.activation.${step}; Home Manager's zed-editor merge step changed shape"
    else
      builtins.head (builtins.head found);

  zedEntry =
    {
      file,
      option,
      step,
      static,
      shape ? "object",
    }:
    mkEntry {
      app = "zed";
      format = "jsonc";
      baselineKind = "snapshot";
      declared = zedStatic step static;
      inherit shape;
      live = "${config.xdg.configHome}/zed/${file}";
      nixHint = "modules/home/zed/_zed.nix (programs.zed-editor.${option})";
      note = "\"since last switch\" compares against this file as Home Manager's merge left it, so it shows every change made from Zed since then. \"vs declared\" compares against the values Nix merges in, so undeclared keys stay listed across switches until you port them to Nix or delete them from the live file (a switch only resets declared keys).";
    };
  zedEntries =
    lib.optional zedCfg.mutableUserSettings (zedEntry {
      file = "settings.json";
      option = "userSettings";
      step = "zedSettingsActivation";
      static = "zed-user-settings";
    })
    ++ lib.optional (zedCfg.mutableUserKeymaps && zedCfg.userKeymaps != [ ]) (zedEntry {
      file = "keymap.json";
      option = "userKeymaps";
      step = "zedKeymapActivation";
      static = "zed-user-keymaps";
      # Home Manager merges keymap entries by context.
      shape = "keyed:context";
    });

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
    ++ lib.optionals config.my.features.zed zedEntries
    # my.features.plasma only exists when the plasma-manager input does.
    ++ lib.optionals (config.my.features.plasma or false) plasmaEntries;

  enabled = entries != [ ];

  snapshotEntries = builtins.filter (entry: entry.baselineKind == "snapshot") entries;

  manifestFile = pkgs.writeText "config-drift-manifest.json" (
    builtins.toJSON config.my.configDrift.entries
  );

  # Same JSON5 reader Home Manager's zed-editor module merges with.
  json5 = pkgs.python3Packages.toPythonApplication pkgs.python3Packages.json5;

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
      nixfmt
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

      normalize_jsonc() {
        ${lib.getExe json5} --as-json "$1" | jq -S .
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
        declared=$(jq -r '.declared // empty' <<<"$entry")
        shape=$(jq -r '.shape' <<<"$entry")
        snippet=$(jq -r '.snippet' <<<"$entry")

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
          jsonc)
            if ! base_norm=$(normalize_jsonc "$resolved_baseline"); then
              echo "  error: failed to parse baseline ($resolved_baseline)" >&2
              echo
              failed=1
              continue
            fi
            if ! live_norm=$(normalize_jsonc "$live"); then
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

        entry_drift=0

        # When the baseline is the declared file itself, the key-level
        # comparison below covers this diff, so it's only shown for snapshot
        # baselines (and entries without a declared check).
        if [ "$declared" != "baseline" ]; then
          if diff_output=$(diff -u --label "baseline ($relpath)" --label "live ($live)" <(printf '%s\n' "$base_norm") <(printf '%s\n' "$live_norm")); then
            echo "  since last switch: no changes"
          else
            echo "  since last switch:"
            echo "$diff_output"
            entry_drift=1
          fi
        fi

        if [ -n "$declared" ]; then
          decl_norm=""
          if [ "$declared" = "baseline" ]; then
            decl_norm="$base_norm"
          elif ! decl_norm=$(normalize_jsonc "$declared"); then
            echo "  error: failed to parse declared values ($declared)" >&2
            failed=1
          fi
          if [ -n "$decl_norm" ]; then
            status=0
            python3 ${./_declared-diff.py} --shape "$shape" --snippet "$snippet" \
              <(printf '%s\n' "$decl_norm") <(printf '%s\n' "$live_norm") || status=$?
            case "$status" in
              0) ;;
              1) entry_drift=1 ;;
              *) failed=1 ;;
            esac
          fi
        fi

        if [ "$entry_drift" -eq 1 ]; then
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
                "jsonc"
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
            declared = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
            };
            shape = lib.mkOption {
              type = lib.types.str;
              default = "object";
            };
            snippet = lib.mkOption {
              type = lib.types.enum [
                "nix"
                "none"
              ];
              default = "nix";
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

    # Refresh snapshot baselines once plasma-manager / Zed's merge steps have
    # rewritten their files. (entryAfter a step that doesn't exist on this
    # host is ignored.)
    home.activation.configDriftSnapshot = lib.mkIf (snapshotEntries != [ ]) (
      lib.hm.dag.entryAfter
        [
          "writeBoundary"
          "configure-plasma"
          "zedSettingsActivation"
          "zedKeymapActivation"
        ]
        (
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
