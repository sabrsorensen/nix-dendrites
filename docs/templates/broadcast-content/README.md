# Broadcast/content module templates

These are small reference templates for modules in `modules/`. Copy the
closest template into a feature directory, replace `example`, and keep the
public module file beside its private configuration payload.

`example.nix` owns broadcast glue: flake inputs, `flake.modules.*`, gating,
and the translation from host facts to a payload's arguments. `_content.nix`
owns the operational NixOS or Home Manager configuration. This keeps a future
broadcast-model change largely confined to the public file.

Use a host-feature option only when the capability is independently useful.
For an inherent platform concern, gate on `config.my.host.platform`; for an
individual host fact, keep that selection in the host's content instead of
inventing a new model option.

Templates:

- `system-feature.nix` — NixOS configuration controlled by an existing host feature.
- `home-feature.nix` — Home Manager configuration controlled by an existing host feature.
- `external-input-home-feature.nix` — Home Manager configuration consuming a flake input.
