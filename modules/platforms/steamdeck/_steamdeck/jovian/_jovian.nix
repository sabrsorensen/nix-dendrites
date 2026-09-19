args@{ lib, ... }:
lib.mkMerge [
  (import ./_jovian-core.nix args)
  (import ./_jovian-desktop.nix args)
  (import ./_jovian-flatpak-launchers.nix args)
  (import ./_jovian-users.nix args)
  (import ./_jovian-system.nix args)
]
