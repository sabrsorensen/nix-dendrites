# config-drift Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a `config-drift` CLI, installed via Home Manager, that reports drift between the live mutable copies of Claude Code's, Herdr's, and Codex's config files and their declarative Home Manager baseline — report-only, no auto-patching.

**Architecture:** A new broadcast Home Manager module (`modules/tooling/config-drift/`) computes a manifest of which files to check (gated on the same `my.features.*` flags that already gate those three apps), bakes it into the Nix store as JSON, and packages a `writeShellApplication` that walks the manifest at runtime: for each entry it resolves the file's exact declarative rendering from the *currently active* Home Manager generation (`$(readlink -f ~/.local/state/home-manager/gcroots/current-home)/home-files/<relpath>`), normalizes both the baseline and the live file (JSON via `jq -S`, TOML via Python's stdlib `tomllib` reduced to canonical JSON), and diffs the normalized forms.

**Tech Stack:** Nix (Home Manager module, `pkgs.writeShellApplication`, `pkgs.writeText`), bash (ShellCheck-clean via `writeShellApplication`), `jq`, Python 3 stdlib `tomllib` (comparison only, never writes TOML).

**Spec:** `docs/superpowers/specs/2026-09-17-config-drift-design.md`

## Global Constraints

- Report-only: the tool never writes to Nix source or to any live config file.
- Broadcast module; content gated on `config.my.features.claude || config.my.features.herdr || config.my.features.wslCodex` — no new user-facing feature toggle is introduced.
- VS Code is explicitly out of scope (different mechanism — Windows-side mutable file, not a Home Manager-managed path).
- No hook into `home-manager switch` — invocation is manual only, via the packaged `config-drift` binary and a `just config-drift` passthrough.
- JSON normalization: `jq -S .` (sorted keys). TOML normalization: parse with stdlib `tomllib`, re-emit as `json.dumps(..., indent=2, sort_keys=True)` — for comparison only, never round-tripped back to TOML.
- `writeShellApplication` scripts must stay ShellCheck-clean (enforced automatically at build).
- New untracked `.nix` files must be `git add -N`'d before any `nix eval`/`nix build`/`nix flake check`, per this repo's editing discipline (Nix reads the Git snapshot).

---

### Task 1: Manifest entries as a testable Home Manager option

**Files:**
- Create: `modules/tooling/config-drift/config-drift.nix`
- Create: `modules/tooling/config-drift/_config-drift.nix`

**Interfaces:**
- Consumes: existing broadcast options `config.my.features.claude`, `config.my.features.herdr`, `config.my.features.wslCodex` (already declared by `modules/home/claude/_claude-code.nix`, `modules/home/herdr/herdr.nix`, `modules/platforms/wsl/wsl-work-home/codex/_codex.nix`); `config.home.homeDirectory`, `config.xdg.configHome` (standard Home Manager options).
- Produces: `config.my.configDrift.entries` — a list of attrsets `{ app :: str; format :: "json"|"toml"; live :: str; baselineRelpath :: str; nixHint :: str; }`, one entry per enabled app. Task 2 extends the same `_config-drift.nix` file and reads the `entries` `let`-binding directly (same-file, no cross-file interface).

- [ ] **Step 1: Write the failing verification command**

This module doesn't exist yet, so evaluating the option must fail. From the repo root, run:

```bash
nix eval .#nixosConfigurations.zaphodbeeblebrox.config.home-manager.users.sam.my.configDrift.entries --json
```

- [ ] **Step 2: Run it to confirm it fails**

Expected: an error like `error: attribute 'configDrift' missing` (or similar — the option doesn't exist yet).

- [ ] **Step 3: Write `modules/tooling/config-drift/_config-drift.nix`**

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  enabled =
    config.my.features.claude || config.my.features.herdr || config.my.features.wslCodex;

  mkEntry =
    {
      app,
      format,
      live,
      nixHint,
    }:
    {
      inherit app format live nixHint;
      baselineRelpath = lib.removePrefix "${config.home.homeDirectory}/" live;
    };

  claudeEntry = mkEntry {
    app = "claude";
    format = "json";
    live = "${config.home.homeDirectory}/.claude/settings.json";
    nixHint = "modules/home/claude/_claude-code.nix (programs.claude-code.settings)";
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
  };

  entries =
    lib.optional config.my.features.claude claudeEntry
    ++ lib.optional config.my.features.herdr herdrEntry
    ++ lib.optional config.my.features.wslCodex codexEntry;
in
{
  options.my.configDrift = {
    entries = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            app = lib.mkOption { type = lib.types.str; };
            format = lib.mkOption { type = lib.types.enum [ "json" "toml" ]; };
            live = lib.mkOption { type = lib.types.str; };
            baselineRelpath = lib.mkOption { type = lib.types.str; };
            nixHint = lib.mkOption { type = lib.types.str; };
          };
        }
      );
      default = [ ];
      description = "Mutable config files to check for drift against their declarative Home Manager baseline.";
    };
  };

  config = lib.mkIf enabled {
    my.configDrift.entries = entries;
  };
}
```

Note: `config.my.configDrift.entries` is only *set* when `enabled` (matches the constraint that the manifest is gated), but the *option itself* is always declared so `nix eval` against a host with none of the three features never errors — it just returns `[]`.

- [ ] **Step 4: Write `modules/tooling/config-drift/config-drift.nix`**

```nix
{ ... }:
let
  homeModule = { pkgs, ... }@args: import ./_config-drift.nix args;
in
{
  dendritic.homeManagerModules = [ homeModule ];
  flake.modules.homeManager.config-drift = homeModule;
}
```

Note the `{ pkgs, ... }@args:` destructuring on `homeModule` — this repo's module system only supplies `config`/`lib`/`pkgs`/etc. to a module function whose declared pattern names at least one of them (matching the working pattern in `modules/home/herdr/herdr.nix`'s `homeModule`). A plain `args: ...` binding gets called with an empty attrset here, which fails inside `_config-drift.nix` with "called without required argument 'pkgs'".

- [ ] **Step 5: Track the new files so Nix can see them**

```bash
git add -N modules/tooling/config-drift/config-drift.nix modules/tooling/config-drift/_config-drift.nix
```

- [ ] **Step 6: Format**

```bash
just fmt
```

- [ ] **Step 7: Run the verification command and check the values**

```bash
nix eval .#nixosConfigurations.zaphodbeeblebrox.config.home-manager.users.sam.my.configDrift.entries --json | jq -e '
  (length == 2)
  and (.[0].app == "claude")
  and (.[0].live == "/home/sam/.claude/settings.json")
  and (.[0].baselineRelpath == ".claude/settings.json")
  and (.[0].format == "json")
  and (.[1].app == "herdr")
  and (.[1].live == "/home/sam/.config/herdr/config.toml")
  and (.[1].baselineRelpath == ".config/herdr/config.toml")
  and (.[1].format == "toml")
'
```

Expected: prints `true` and exits 0 (ZaphodBeeblebrox has `claude` and `herdr` enabled, not `wslCodex`, so exactly 2 entries in that order).

- [ ] **Step 8: Commit**

```bash
git add modules/tooling/config-drift/config-drift.nix modules/tooling/config-drift/_config-drift.nix
git commit -m "Add config-drift manifest entries for claude/herdr/codex"
```

---

### Task 2: The config-drift CLI

**Files:**
- Modify: `modules/tooling/config-drift/_config-drift.nix` (adds the normalizer script, the `writeShellApplication`, the `package` option, and wires `home.packages`)
- Modify: `justfile` (adds a `config-drift` passthrough target)

**Interfaces:**
- Consumes: `entries` (`let`-binding from Task 1, same file) and `config.my.configDrift.entries`/manifest shape from Task 1.
- Produces: `config.my.configDrift.package` :: derivation — the built `config-drift` CLI, always defined (not gated) so it's buildable/testable regardless of which features are on. `home.packages` gains this package only when `enabled` (Task 1's `enabled` binding).

- [ ] **Step 1: Replace `_config-drift.nix` with the full version that adds the manifest file, TOML normalizer, and shell application**

This is the complete file — it replaces everything Task 1 wrote:

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  enabled =
    config.my.features.claude || config.my.features.herdr || config.my.features.wslCodex;

  mkEntry =
    {
      app,
      format,
      live,
      nixHint,
    }:
    {
      inherit app format live nixHint;
      baselineRelpath = lib.removePrefix "${config.home.homeDirectory}/" live;
    };

  claudeEntry = mkEntry {
    app = "claude";
    format = "json";
    live = "${config.home.homeDirectory}/.claude/settings.json";
    nixHint = "modules/home/claude/_claude-code.nix (programs.claude-code.settings)";
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
  };

  entries =
    lib.optional config.my.features.claude claudeEntry
    ++ lib.optional config.my.features.herdr herdrEntry
    ++ lib.optional config.my.features.wslCodex codexEntry;

  manifestFile = pkgs.writeText "config-drift-manifest.json" (builtins.toJSON entries);

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
      count=$(jq 'length' "$manifest")

      for ((i = 0; i < count; i++)); do
        entry=$(jq -c ".[$i]" "$manifest")
        app=$(jq -r '.app' <<<"$entry")
        format=$(jq -r '.format' <<<"$entry")
        live=$(jq -r '.live' <<<"$entry")
        relpath=$(jq -r '.baselineRelpath' <<<"$entry")
        hint=$(jq -r '.nixHint' <<<"$entry")

        if [ ! -e "$live" ]; then
          continue
        fi

        echo "== $app: $relpath =="

        baseline="$gen/home-files/$relpath"
        if [ ! -e "$baseline" ]; then
          echo "  warning: no baseline found in current generation ($baseline)" >&2
          echo
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
              continue
            fi
            if ! live_norm=$(normalize_json "$live"); then
              echo "  error: failed to parse live file ($live)" >&2
              echo
              continue
            fi
            ;;
          toml)
            if ! base_norm=$(normalize_toml "$resolved_baseline"); then
              echo "  error: failed to parse baseline ($resolved_baseline)" >&2
              echo
              continue
            fi
            if ! live_norm=$(normalize_toml "$live"); then
              echo "  error: failed to parse live file ($live)" >&2
              echo
              continue
            fi
            ;;
          *)
            echo "  error: unknown format '$format'" >&2
            echo
            continue
            ;;
        esac

        if diff_output=$(diff -u <(echo "$base_norm") <(echo "$live_norm")); then
          echo "  no drift"
        else
          echo "$diff_output"
          echo "  -> declarative source: $hint"
          drifted=1
        fi
        echo
      done

      exit "$drifted"
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
            format = lib.mkOption { type = lib.types.enum [ "json" "toml" ]; };
            live = lib.mkOption { type = lib.types.str; };
            baselineRelpath = lib.mkOption { type = lib.types.str; };
            nixHint = lib.mkOption { type = lib.types.str; };
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
```

Note this replaces Task 1's final `{ options = ...; config = lib.mkIf enabled { my.configDrift.entries = entries; }; }` block — `package` is now set unconditionally (outside `mkIf`) so it's always buildable for testing, while `entries` stays gated exactly as before (per-option `lib.mkIf`, not a whole-block one — cleaner than wrapping the entire `config` attrset) and `home.packages` gains the built package only when `enabled`.

- [ ] **Step 2: Add the justfile target**

Edit `justfile`, adding near the other simple wrappers (after `develop:`):

```just
config-drift:
    config-drift
```

- [ ] **Step 3: Format**

```bash
just fmt
```

- [ ] **Step 4: Build the package**

```bash
nix build .#nixosConfigurations.zaphodbeeblebrox.config.home-manager.users.sam.my.configDrift.package --no-link --print-out-paths
```

Expected: prints a `/nix/store/...-config-drift` path and exits 0. Keep this path — call it `$pkg` for the remaining steps in this task (`pkg=$(nix build ... --print-out-paths)`).

- [ ] **Step 5: Test the missing-generation error path**

This is fully isolated from the real system — it only points `$HOME` at an empty directory:

```bash
tmp_home=$(mktemp -d)
HOME="$tmp_home" "$pkg/bin/config-drift"; echo "exit=$?"
```

Expected: stderr line `config-drift: no home-manager generation found at <tmp_home>/.local/state/home-manager/gcroots/current-home`, and `exit=1`.

- [ ] **Step 6: Clean up the temp dir**

```bash
rmdir "$tmp_home"
```

- [ ] **Step 7: Verify `just --list` picks up the new target**

```bash
just --list --unsorted | grep config-drift
```

Expected: shows the `config-drift` recipe.

- [ ] **Step 8: Run `just checknb`**

```bash
just checknb
```

Expected: succeeds (composes every host's config, including this new broadcast module, without building every toplevel).

- [ ] **Step 9: Commit**

```bash
git add modules/tooling/config-drift/_config-drift.nix justfile
git commit -m "Add config-drift CLI package and just target"
```

---

### Task 3: End-to-end verification on ZaphodBeeblebrox

Pure verification — no source changes. This task proves the tool works against real, currently-live files. Read-only except for one explicit, immediately-reverted edit to the *mutable scratch copy* `~/.claude/settings.json` (a file that module's own comments already document as safe to hand-edit for exactly this kind of experimentation — see `modules/home/claude/_claude-code.nix`). **Pause and confirm with the user before Step 3**, since it edits a real file outside the repo, even though it's reverted by the end of the task.

**Files:** none.

**Interfaces:** Consumes `config.my.configDrift.package` from Task 2.

- [ ] **Step 1: Build the package fresh**

```bash
pkg=$(nix build .#nixosConfigurations.zaphodbeeblebrox.config.home-manager.users.sam.my.configDrift.package --no-link --print-out-paths)
```

- [ ] **Step 2: Run it against real current state and record the result**

```bash
"$pkg/bin/config-drift"; echo "exit=$?"
```

Read the output. Since this host was switched before any live edits were made in this plan, expect `== claude: .claude/settings.json ==` / `  no drift` and `== herdr: .config/herdr/config.toml ==` / `  no drift`, with `exit=0`. If either file *does* show drift already (pre-existing, from normal use), that's real signal, not a bug — note it, but don't try to "fix" it as part of this task.

- [ ] **Step 3: Confirm with the user, then introduce a known change**

Ask the user before running this — it edits their real `~/.claude/settings.json`:

```bash
jq '.theme = "light"' ~/.claude/settings.json > /tmp/config-drift-verify.json
mv /tmp/config-drift-verify.json ~/.claude/settings.json
```

- [ ] **Step 4: Re-run and confirm the diff is detected**

```bash
"$pkg/bin/config-drift"; echo "exit=$?"
```

Expected: the claude section now shows a unified diff with exactly the `theme` line changing from `"dark"` to `"light"`, followed by `  -> declarative source: modules/home/claude/_claude-code.nix (programs.claude-code.settings)`; herdr still shows `no drift`; `exit=1`.

- [ ] **Step 5: Revert the live edit**

```bash
jq '.theme = "dark"' ~/.claude/settings.json > /tmp/config-drift-verify.json
mv /tmp/config-drift-verify.json ~/.claude/settings.json
```

- [ ] **Step 6: Confirm it's back to clean**

```bash
"$pkg/bin/config-drift"; echo "exit=$?"
```

Expected: `no drift` for both entries again, `exit=0`.

- [ ] **Step 7: Report results to the user**

Summarize what was verified: no-drift baseline, detected diff, clean revert. No commit needed — this task changes no tracked files.
