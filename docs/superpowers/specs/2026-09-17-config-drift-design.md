# config-drift: detect drift in mutable declarative-config files

## Problem

Claude Code, Herdr, and Codex are all managed declaratively in this
repo, but each writes runtime state back into its config file after
activation (recent files, onboarding flags, theme toggles, hook
registrations, etc.). All three use an identical Home Manager
activation bridge (`modules/home/claude/_claude-code.nix`,
`modules/home/herdr/_herdr-home.nix`,
`modules/platforms/wsl/wsl-work-home/codex/_codex.nix`): Home Manager
links the file as a read-only symlink into the Nix store, then an
`entryAfter linkGeneration` activation script breaks the symlink into
a writable copy so the app can write to it. Every `home-manager
switch` resets that copy back to whatever's declared in Nix, silently
discarding any live edits.

There is currently no way to see what changed in a mutable file
before the next switch clobbers it, or to know which Nix source it
corresponds to in order to make a change permanent.

VS Code (`modules/home/vscode/wsl-vscode/_wsl-vscode.nix`) has a
similar mutable-drift problem but a different shape — its live file
lives on the Windows side of a WSL sync, not under a Home
Manager-managed path. Deliberately out of scope here; a separate
design later.

## Goal

A CLI tool, `config-drift`, that reports drift between each live
mutable config file and its declarative baseline, so the user can
decide per-change whether to hand-edit the Nix source to keep it, or
let the next switch discard it.

Out of scope: auto-patching Nix source, hooking into `home-manager
switch`, VS Code (different mechanism, separate problem — see above),
any host other than the ones where the relevant feature is enabled.

## Design

### Module placement

New broadcast module: `modules/tooling/config-drift/config-drift.nix`
(public registration) + `modules/tooling/config-drift/_config-drift.nix`
(implementation), following the existing tooling module shape (see
`modules/tooling/cli-tools/`).

The module is evaluated for every host (broadcast), but the generated
manifest — and therefore whether the package is installed at all — is
gated on the same feature flags that already gate the three config
files:

- `my.features.claude`
- `my.features.herdr`
- `my.features.wslCodex`

`home.packages` gets the `config-drift` package only when at least one
of these is true. On a host with none enabled, the module contributes
nothing.

### Manifest generation (Nix, build time)

The module builds a JSON manifest describing what to check on the
current host, written to the store with `pkgs.writeText` and read by
the script at runtime via `jq`. One entry per file:

```json
{
  "app": "claude",
  "format": "json",
  "live": "/home/sam/.claude/settings.json",
  "baseline_kind": "generation",
  "baseline_relpath": ".claude/settings.json",
  "nix_hint": "modules/home/claude/_claude-code.nix (programs.claude-code.settings)"
}
```

- **claude / herdr / codex** (when their feature is on): one entry
  each, `baseline_kind: "generation"`, `baseline_relpath` is the path
  relative to `$HOME` that Home Manager manages
  (`.claude/settings.json`, `.config/herdr/config.toml`,
  `.codex/config.toml`), format `json` or `toml` as appropriate.

### Runtime resolution (bash, `writeShellApplication`, ShellCheck-clean)

**`generation`-kind baselines** (all three entries use this): resolve
`gen=$(readlink -f ~/.local/state/home-manager/gcroots/current-home)`;
baseline file is `$gen/home-files/<relpath>` (itself a symlink into
the store — read through it with `readlink -f`). This is the exact
declarative rendering for the *currently active* generation, so it
stays correct across switches without re-evaluating Nix. If the path
doesn't exist in the generation, warn and skip that entry. If the live
file doesn't exist, skip silently (not installed on this host / never
written yet).

### Normalization + diff

Both sides are parsed and canonically re-serialized before comparing,
so whitespace/key-order differences introduced by whatever rewrote
the live file don't show up as noise:

- JSON: `jq -S .` (sorted keys, pretty-printed).
- TOML: a one-line `python3 -c` using stdlib `tomllib` to parse, then
  `json.dumps(..., sort_keys=True, indent=2)` to emit — comparison
  only, never round-tripped back to TOML.

Normalized output for both sides is diffed with `diff -u`.

### Output

For each manifest entry: a header naming the app and relative file
path, then either "no drift" or the unified diff. Once per app group
that had any drift, a trailing pointer line naming the `nix_hint`
file/option to hand-edit if a change is worth keeping. Exit code is 1
if any entry drifted, 0 otherwise (no current caller depends on this,
but it costs nothing and helps future scripting).

The tool is report-only — it never writes to the Nix source or to any
live config file. All 3 apps' checks run in one invocation; there are
no flags in the first version (YAGNI — add `--app <name>` filtering
later only if it's actually needed).

### Invocation

- Packaged as `config-drift`, added to `home.packages` per the gating
  above, on `PATH` after a switch.
- A thin `just config-drift` target in the repo justfile execs it,
  matching the justfile's existing wrapper style.
- No hook into `home-manager switch` (decided against — manual-only
  per user preference).

## Error handling

- Missing live file: skip that entry silently (nothing to compare).
- Missing baseline in the current generation: warn and skip (would
  indicate a manifest bug rather than normal operation).
- Any other unexpected error (e.g. malformed TOML/JSON on the live
  side) should surface as a clear per-entry error line, not abort the
  whole run — one broken file shouldn't hide drift in the other apps.

## Testing

No shell-test framework exists in this repo for tooling scripts;
`writeShellApplication` gets ShellCheck for free at build time. Manual
verification plan:

1. `just checknb` builds the derivation and catches Nix eval errors.
2. On ZaphodBeeblebrox (which has `claude` and `herdr` enabled but not
   `wslCodex`), run `config-drift` right after a switch: expect "no
   drift" for both applicable entries.
3. Hand-edit a live mutable file (e.g. flip a boolean in
   `~/.claude/settings.json`), rerun `config-drift`, confirm the diff
   shows exactly that change and nothing else, and that exit code is
   1.
