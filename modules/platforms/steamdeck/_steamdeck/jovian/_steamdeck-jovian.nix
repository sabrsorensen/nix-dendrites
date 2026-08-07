args@{ lib, ... }:
lib.mkMerge [
  (import ./_steamdeck-jovian-core.nix args)
  (import ./_steamdeck-jovian-desktop.nix args)
  (import ./_steamdeck-jovian-users.nix args)
  (import ./_steamdeck-jovian-system.nix args)
]
