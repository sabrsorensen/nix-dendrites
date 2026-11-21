# Broadcast/content module templates

Copyable skeletons for modules in `modules/`. Pick the closest template, copy
each `# path` section into its own file, replace `example`/`Example`, and fill
in the payload. Every template follows the same split:

- `example.nix` (public, discovered by `import-tree`) owns broadcast glue:
  flake inputs, `flake.modules.*` / `dendritic.homeManagerModules`, option
  declarations, gating, and the translation from host facts to payload
  arguments.
- `_example*.nix` (private, `/_` hides it from `import-tree`) owns the
  operational NixOS or Home Manager configuration. It never gates itself.

This keeps a future broadcast-model change largely confined to the public file.

| Template | Use when | Gate | Reference module |
|---|---|---|---|
| `system-feature.nix` | NixOS configuration only | `my.host.features.<x>` | `modules/home/wayland/`, `modules/features/desktop/`, `modules/features/sddm/` |
| `home-feature.nix` | Home Manager configuration only | `my.features.<x>` (set at the HM boundary) | `modules/home/ghostty/` |
| `system-home-feature.nix` | distinct system *and* user configuration | both of the above | `modules/features/sonos/`, `modules/features/hyprland/`, `modules/features/niri/`, `modules/features/noctalia/` |
| `external-input-home-feature.nix` | Home Manager feature whose options come from a flake input | input presence + `my.features.<x>` | `modules/features/plasma/` |
| `service.nix` | a hosted system service | `my.host.services.<x>` | `modules/services/apprise/` |

Checklist after copying:

1. `git add -N` the new files (Nix reads the Git snapshot).
2. Home Manager features: add `<x> = host.features.<x>;` to the `my.features`
   block in `modules/home/home/_home.nix` — the managed-user boundary is the
   only place host facts become Home Manager feature state.
3. Enable it in a host's `my.host.features` / `my.host.services`.
4. If an aggregate (`features.gui`, …) should imply it, add a
   `lib.mkDefault` in `modules/system/host-context/_host-context.nix`.
5. `nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath`
   for one host that enables it and one that doesn't.

Use a host-feature option only when the capability is independently useful.
For an inherent platform concern, gate on `config.my.host.platform`; for an
individual host fact, use a host-specific override (see "Host-specific
overrides" in `docs/architecture.md`) instead of inventing a new option.
Never append a host-aware module to `dendritic.homeManagerModules`, and never
register a `flake.modules.nixos.home-<x>` module that only imports Home
Manager configuration.
